module memory_access (
    input clk,
    input stop,
    input [4:0] in_reg_d,
    /* MEM Stage Command
       in_mem_command[0]: Is it access to memory? (0: False, 1: True)
       in_mem_command[1]: Is it write to memory? (0: Read, 1: Write)       
       in_mem_command[4:2]: funct3
    */
    input [4:0] in_mem_command,
    input [31:0] in_alu_out, 
    input [31:0] in_mem_write_data, 
    input [31:0] in_now_pc,
    input [31:0] mem_data,
    input [31:0] csr_data,
    input [31:0] csr_trap_vec_data,
    input [31:0] csr_exception_pc_data,

    output [11:0] csr_addr,
    output [31:0] mem_addr,
    output reg is_mem_write,
    output wb_pc,
    output reg wb_csr,
    output reg [11:0] out_csr_addr,
    output [31:0] wb_pc_data,
    output reg [31:0] out_mem_addr,
    output reg [31:0] out_mem_data,
    output reg [31:0] out_wb_data,
    output reg [4:0] out_reg_d,
    output reg [31:0] out_now_pc,
    output reg [31:0] out_csr_data
);

assign mem_addr = in_alu_out;
assign csr_addr = in_mem_write_data[11:0];

assign wb_pc = (in_mem_command == 5'b00010);
assign wb_pc_data = (in_mem_write_data == 12'h0) ? csr_trap_vec_data : (
    (in_mem_write_data == 12'h1) ? csr_trap_vec_data : (
        (in_mem_write_data == 12'h302) ? csr_exception_pc_data : 12'h0
    )
);

wire [31:0] wb_pc_data_f_mtvect = csr_trap_vec_data;
wire [31:0] wb_pc_data_f_mepc = csr_exception_pc_data;

always @(posedge clk) begin
    if (in_mem_command[0]) begin
        // sb/sh/sw
        if (in_mem_command[1:0] == 2'b11) begin
            case (in_mem_command[4:2])
                3'b000: begin
                    out_mem_data[31:8] <= mem_data[31:8];
                    out_mem_data[7:0] <= in_mem_write_data[7:0];
                    is_mem_write <= 1'b1;
                end
                3'b001: begin
                    out_mem_data[31:16] <= mem_data[31:16];
                    out_mem_data[15:0] <= in_mem_write_data[15:0];
                    is_mem_write <= 1'b1;
                end
                3'b010: begin
                    out_mem_data <= in_mem_write_data;
                    is_mem_write <= 1'b1;
                end
                default: begin
                    out_mem_data <= mem_data;
                    is_mem_write <= 1'b0;
                end
            endcase
            out_wb_data <= in_alu_out;
        end

        // lb/lh/lw/lbu/lhu
        else if (in_mem_command[1:0] == 2'b01) begin
            case (in_mem_command[4:2])
                3'b000: begin
                    out_wb_data <= $signed(mem_data[7:0]);
                end
                3'b001: begin
                    out_wb_data <= $signed(mem_data[15:0]);
                end
                3'b010: begin
                    out_wb_data <= mem_data;
                end
                3'b100: begin
                    out_wb_data <= $unsigned(mem_data[7:0]);
                end
                3'b101: begin
                    out_wb_data <= $unsigned(mem_data[15:0]);
                end
                default: begin
                    out_wb_data <= mem_data;
                end
            endcase
            out_mem_data <= mem_data;
            is_mem_write <= 1'b0;
        end
        out_csr_data <= 32'b0;
        wb_csr <= 1'b0;
        out_mem_addr <= mem_addr;
    end

    // CSR
    else if (in_mem_command[1:0] == 2'b10) begin
        case(in_mem_command[4:2])
            3'b000: begin
                out_wb_data <= csr_data;
                out_csr_data <= in_alu_out;
            end
            3'b001: begin
                out_wb_data <= csr_data;
                out_csr_data <= in_alu_out;
            end
            3'b010: begin
                out_wb_data <= csr_data;
                out_csr_data <= csr_data | in_alu_out;
            end
            3'b011: begin
                out_wb_data <= csr_data;
                out_csr_data <= csr_data & ~in_alu_out;
            end
            3'b101: begin
                out_wb_data <= csr_data;
                out_csr_data <= in_alu_out;
            end
            3'b110: begin
                out_wb_data <= csr_data;
                out_csr_data <= csr_data | in_alu_out;
            end
            3'b111: begin
                out_wb_data <= csr_data;
                out_csr_data <= csr_data & ~in_alu_out;
            end
            default: begin
                out_wb_data <= 32'b0;
                out_csr_data <= csr_data;
            end
        endcase
        out_mem_data <= mem_data;
        is_mem_write <= 1'b0;
        wb_csr <= 1'b1;
        out_mem_addr <= mem_addr;
    end

    else begin
        out_mem_data <= mem_data;
        out_wb_data <= in_alu_out;
        is_mem_write <= 1'b0;
        out_csr_data <= 32'b0;
        wb_csr <= 1'b0;
        out_mem_addr <= mem_addr;
    end

    out_csr_addr <= csr_addr;
    out_reg_d <= in_reg_d;
    out_now_pc <= in_now_pc;
end

endmodule