module decode (
    input reset,
    input clk,
    input stop,
    input bubble,
    input [31:0] rs1_data,
    input [31:0] rs2_data,
    input [31:0] in_now_pc,
    input [31:0] command,

    output [4:0] rs1_addr,
    output [4:0] rs2_addr,
    output reg [4:0] reg_d,
    /* MEM Stage Command
       mem_command[0]: Is access to memory? (0: False, 1: True)
       mem_command[1]: Is write to memory? (0: Read, 1: Write)   
       mem_command[1:0] == 10: CSR Mode   
       mem_command[4:2]: funct3
    */
    output reg [4:0] mem_command,
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
    output reg [5:0] ex_command,
    output reg [6:0] ex_command_f7,
    output reg [31:0] data_0,
    output reg [31:0] data_1,
    output reg [31:0] mem_write_data, 
    output reg [31:0] out_now_pc
);

wire [6:0] opcode;

wire [2:0] funct3;
wire [6:0] funct7;
wire [31:0] imm_U;
wire [20:0] imm_J;
wire [12:0] imm_B;
wire [11:0] imm_I;
wire [11:0] imm_S;
wire [4:0] rd;
wire [4:0] rs1;
wire [4:0] rs2;

assign opcode = command[6:0];
assign funct3 = command[14:12];
assign funct7 = command[31:25];
assign imm_U[31:12] = command[31:12];
assign imm_U[11:0] = 12'b0;
assign imm_J[20] = command[31];
assign imm_J[19:12] = command[19:12];
assign imm_J[11] = command[20];
assign imm_J[10:1] = command[30:21];
assign imm_J[0] = 1'b0;
assign imm_B[12] = command[31];
assign imm_B[11] = command[7];
assign imm_B[10:5] = command[30:25];
assign imm_B[4:1] = command[11:8];
assign imm_B[0] = 1'b0;
assign imm_I = command[31:20];
assign imm_S[11:5] = command[31:25];
assign imm_S[4:0] = command[11:7];

assign rd = command[11:7];
assign rs1 = command[19:15];
assign rs2 = command[24:20];

assign rs1_addr = command[19:15];
assign rs2_addr = command[24:20];

always @(posedge clk) begin
    // Stop(pause) CPU
    if (stop) begin
        mem_command <= mem_command;
        ex_command <= ex_command;
        data_0 <= data_0;
        data_1 <= data_1;
        reg_d <= reg_d;
        mem_write_data <= mem_write_data;
        ex_command_f7 <= ex_command_f7;
        out_now_pc <= out_now_pc;
    end

    // Pipeline Bubble(addi x0, x0, 0)
    else if (bubble) begin
        mem_command <= 5'b0;
        ex_command <= 6'b0;
        data_0 <= 32'b0;
        reg_d <= 5'b0;
        mem_write_data <= 32'b0;
        ex_command_f7 <= funct7;
        out_now_pc <= in_now_pc;
    end

    else if (reset) begin
        mem_command <= 5'b0;
        ex_command <= 6'b0;
        data_0 <= 32'b0;
        reg_d <= 5'b0;
        mem_write_data <= 32'b0;
        ex_command_f7 <= 7'b0;
        out_now_pc <= 32'b0;
    end

    // Normal Decode
    else begin
        case (opcode)
            // U Format
            // lui
            7'b0110111: begin
                mem_command <= 5'b0;
                ex_command <= 6'b0;
                data_0 <= imm_U;
                data_1 <= 32'b0;
                reg_d <= rd;
                mem_write_data <= 32'b0;
            end
            // auipc
            7'b0010111: begin
                mem_command <= 5'b0;
                ex_command <= 6'b0;
                data_0 <= imm_U;
                data_1 <= in_now_pc;
                reg_d <= rd;
                mem_write_data <= 32'b0;
            end

            // J Format
            // jal
            7'b1101111: begin
                mem_command <= 5'b0;
                ex_command <= 6'b100000;
                data_0 <= 32'b0;
                data_1 <= $signed(imm_J);
                reg_d <= rd;
                mem_write_data <= 32'b0;
            end

            // I format
            // jalr
            7'b1100111: begin
                mem_command <= 5'b0;
                ex_command <= 6'b100001;
                data_0 <= rs1_data;
                data_1 <= $signed(imm_I);
                reg_d <= rd;
                mem_write_data <= 32'b0;
            end
            // lb/lh/lw/lbu/lhu
            7'b0000011: begin
                mem_command[4:2] <= funct3;
                mem_command[1:0] <= 2'b01;
                ex_command <= 6'b0;
                data_0 <= rs1_data;
                data_1 <= $signed(imm_I);
                reg_d <= rd;
                mem_write_data <= 32'b0;
            end
            // addi/slti/sltiu/xori/ori/andi/slli/srli/srail
            7'b0010011: begin
                mem_command <= 5'b0;
                ex_command[5:3] <= 3'b0;
                ex_command[2:0] <= funct3;
                data_0 <= rs1_data;
                data_1 <= $signed(imm_I);
                reg_d <= rd;
                mem_write_data <= 32'b0;
            end
            // fence/fence.i
            7'b0001111: begin
                mem_command <= 5'b0;
                ex_command[5:3] <= 3'b110;
                ex_command[2:0] <= funct3;
                data_0 <= 32'b0;
                data_1[31:12] <= 20'b0;
                data_1[11:0] <= imm_I;
                reg_d <= 5'b0;
                mem_write_data <= 32'b0;
            end
            // ecall/ebreak/csrrw/csrrs/csrrc/csrrsi/csrrci
            7'b1110011: begin
                mem_command[4:2] <= funct3;
                mem_command[1:0] <= 2'b10;
                ex_command[5:3] <= 3'b101;
                ex_command[2:0] <= funct3;
                if (funct3[2]) begin
                    data_0[31:5] <= 27'b0;
                    data_0[4:0] <= rs1;
                end
                else
                    data_0 <= rs1_data;
                data_1 <= 32'b0;
                mem_write_data[31:12] <= 20'b0;
                mem_write_data[11:0] <= imm_I;
                reg_d <= rd;
            end

            // B Format
            // beq/bne/blt/bge/bltu/bgeu
            7'b1100011: begin
                mem_command <= 5'b0;
                ex_command[5:3] <= 3'b010;
                ex_command[2:0] <= funct3;
                data_0 <= rs1_data;
                data_1 <= rs2_data;
                mem_write_data <= $signed(imm_B);
                reg_d <= 5'b0;
            end

            // S Format
            // sb/sh/sw
            7'b0100011: begin
                mem_command[4:2] <= funct3;
                mem_command[1:0] <= 2'b11;
                ex_command <= 6'b0;
                data_0 <= rs1_data;
                data_1 <= $signed(imm_S);
                mem_write_data <= rs2_data;
                reg_d <= 5'b0;
            end

            // R Format
            // add/sub/sll/slt/sltu/xor/srl/sra/or/and
            7'b0110011: begin
                mem_command <= 5'b0;
                ex_command[5:3] <= 3'b001;
                ex_command[2:0] <= funct3;
                data_0 <= rs1_data;
                data_1 <= rs2_data;
                mem_write_data <= 32'b0;
                reg_d <= rd;
            end

            // default
            // addi x0, x0, 0
            default: begin
                mem_command <= 5'b0;
                ex_command <= 6'b0;
                data_0 <= 32'b0;
                data_1 <= 32'b0;
                mem_write_data <= 32'b0;
                reg_d <= 5'b0;
            end
        endcase
        ex_command_f7 <= funct7;
        out_now_pc <= in_now_pc;
    end
end

endmodule