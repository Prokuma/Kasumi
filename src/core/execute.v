module execute (
    input clk,
    input stop,
    input bubble,
    input [4:0] in_reg_d,
    /* MEM Stage Command
       mem_command[0]: Is access to memory? (0: False, 1: True)
       mem_command[1]: Is write to memory? (0: Read, 1: Write)       
       mem_command[4:2]: funct3
    */
    input [4:0] in_mem_command,
    /* EX Stage Command
       ex_command[2:0]: funct3(only available below execution type)
       - jal/jalr: 000->jal 001->jalr
       ex_command[5:3]: type of execution
       - 000: calculation imm for RV32I
       - 001: calculation reg for RV32I
       - 010: compare values
       - 011: reserve for RV32M
       - 100: jal/jalr
       - 101: ecall/ebreak/csr
       - 110: fence
    */
    input [5:0] ex_command,
    input [6:0] ex_command_f7,
    input [31:0] data_0,
    input [31:0] data_1,
    input [31:0] in_mem_write_data, 
    input [31:0] in_now_pc,

    output if_bubble,
    output id_bubble,
    output wb_pc,
    output reg [4:0] out_mem_command,
    output reg [4:0] out_reg_d,
    output reg [31:0] alu_out, 
    output reg [31:0] out_mem_write_data,
    output reg [31:0] out_now_pc,
    output [31:0] wb_pc_data
);

wire e_data = (data_0 == data_1);
wire ne_data = (data_0 != data_1);
wire ge_data_signed = ($signed(data_0) >= $signed(data_1));
wire ge_data_unsigned = ($unsigned(data_0) >= $unsigned(data_1));
wire lt_data_signed = ($signed(data_0) < $signed(data_1));
wire lt_data_unsigned = ($unsigned(data_0) < $unsigned(data_1));

wire [3:0] pred = data_1[3:0];
wire [3:0] succ = data_1[7:4];

assign wb_pc = jmp_f_b | jmp_f_f | jmp_f_j;
assign wb_pc_data = jmp_f_b ? wb_pc_data_f_b : (
    jmp_f_f ? wb_pc_data_f_f : (
        jmp_f_j ? wb_pc_data_f_j : 32'b0
    )
);
assign if_bubble = jmp_f_b | jmp_f_f | jmp_f_j;
assign id_bubble = jmp_f_b | jmp_f_f | jmp_f_j;

// beq/bge/begu/blt/bltu/bne
wire jmp_f_b = (ex_command[5:3] != 3'b010) ? 1'b0 : (
    ((ex_command[2:0] == 3'b000) & e_data) |
    ((ex_command[2:0] == 3'b001) & ne_data) |
    ((ex_command[2:0] == 3'b100) & lt_data_signed) |
    ((ex_command[2:0] == 3'b101) & ge_data_signed) |
    ((ex_command[2:0] == 3'b110) & lt_data_unsigned) |
    ((ex_command[2:0] == 3'b110) & ge_data_unsigned)
);

wire [31:0] wb_pc_data_f_b = in_now_pc + in_mem_write_data;

// fence/fence.i
wire jmp_f_f = 
((ex_command == 6'b110000) & ((pred[2] & succ[3]) | pred[0] & succ[1])) ? 1'b1 : (
    (ex_command == 6'b110001) ? 1'b1 : 1'b0
);

wire [31:0] wb_pc_data_f_f = in_now_pc + 32'd4;

// jal/jalr
wire jmp_f_j = (ex_command == 6'b100000) | (ex_command == 6'b100001);

wire [31:0] wb_pc_data_f_j = (ex_command[2:0] == 3'b000) ? (in_now_pc + data_1) : (
    (ex_command[2:0] == 3'b001) ? ((data_0 + data_1) & 32'b11111111111111111111111111111110) : 32'b0
);

always @(posedge clk) begin
    // Stop(pause) CPU
    if (stop) begin
        alu_out <= alu_out;
        out_mem_command <= out_mem_command;
        out_mem_write_data <= out_mem_write_data;
        out_reg_d <= out_reg_d;
        out_now_pc <= out_now_pc;
    end

    // Pipeline Bubble (addi x0, x0, 0)
    else if (bubble) begin
        alu_out <= 32'b0;
        out_mem_command <= 5'b0;
        out_mem_write_data <= 32'b0;
        out_reg_d <= 6'b0;
        out_now_pc <= in_now_pc;
    end

    // Normal Execution
    else begin
        // add/addi
        // lb/lh/lw/lbu/lhu
        // sb/sh/sw
        // lui
        // auipc
        if (ex_command == 6'b000000 | 
        (ex_command == 6'b001000 & ex_command_f7 == 7'b0000000)) begin
            alu_out <= data_0 + data_1; 
        end
        // sub
        else if (ex_command == 6'b001000 & ex_command_f7 == 7'b0100000) begin
            alu_out <= data_0 - data_1;
        end
        // xori/xor
        else if (ex_command == 6'b000100 | 
                (ex_command == 6'b001100 & ex_command_f7 == 7'b0000000)) begin
            alu_out <= data_0 ^ data_1;
        end
        // ori/or
        else if (ex_command == 6'b000110 | 
                (ex_command == 6'b001110 & ex_command_f7 == 7'b0000000)) begin
            alu_out <= data_0 | data_1;
        end
        // andi/and
        else if (ex_command == 6'b000111 | 
                (ex_command == 6'b001111 & ex_command_f7 == 7'b0000000)) begin
            alu_out <= data_0 & data_1;
        end
        // slli/sll
        else if ((ex_command == 6'b000001 & ex_command_f7 == 7'b0000000) |
                 (ex_command == 6'b001001 & ex_command_f7 == 7'b0000000)) begin
            alu_out <= data_0 << data_1[4:0];
        end
        // srli/srl
        else if ((ex_command == 6'b000101 & ex_command_f7 == 7'b0000000) |
                 (ex_command == 6'b001101 & ex_command_f7 == 7'b0000000)) begin
            alu_out <= data_0 >> data_1[4:0];
        end
        // srai/sra
        else if ((ex_command == 6'b000101 & ex_command_f7 == 7'b0100000) |
                 (ex_command == 6'b001101 & ex_command_f7 == 7'b0100000)) begin
            alu_out <= $signed(data_0) >>> data_1[4:0];
        end
        // slti/slt
        else if ((ex_command == 6'b000010) |
                 (ex_command == 6'b001010 & ex_command_f7 == 7'b0000000)) begin
            alu_out <= $signed(data_0) < $signed(data_1);
        end
        // sltui/sltu
        else if((ex_command == 6'b000011) |
                (ex_command == 6'b001011 & ex_command_f7 == 7'b0000000)) begin
            alu_out <= $unsigned(data_0) < $unsigned(data_1);
        end
        else if ((ex_command[5:3] != 3'b100) & (ex_command[5:3] != 3'b101)) begin
            alu_out <= 32'b0;
        end

        // jar/jalr
        else if (ex_command[5:3] == 3'b100) begin
            alu_out <= in_now_pc + 32'd4;
        end

        // beq/bge/begu/blt/bltu/bne
        else if (ex_command[5:3] == 3'b010) begin
            alu_out <= 32'b0;
        end

        // fence/fence.i
        else if (ex_command[5:3] == 3'b110) begin
            alu_out <= 32'b0;
        end

        // csr
        else if (ex_command[5:3] == 3'b101) begin
            if (ex_command[2:0] == 3'b000) begin
                alu_out <= 32'h11;
            end
            else begin
                alu_out <= data_0;
            end
        end

        out_mem_command <= in_mem_command;
        out_mem_write_data <= in_mem_write_data;
        out_reg_d <= in_reg_d;
        out_now_pc <= in_now_pc;
    end
end

endmodule