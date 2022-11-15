module memory_access (
    input reset,
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
    input [31:0] csr_data,
    input [31:0] csr_trap_vec_data,
    input [31:0] csr_exception_pc_data,

    output [11:0] csr_addr,
    output [31:0] mem_addr,
    output wb_pc,
    output reg wb_csr,
    output [31:0] write_data,
    output reg [11:0] out_csr_addr,
    output [31:0] wb_pc_data,
    output reg [31:0] out_wb_data,
    output reg [4:0] out_reg_d,
    output reg [31:0] out_csr_data
);

reg [31:0] prev_addr;
assign mem_addr = in_mem_command[0] ? in_alu_out : prev_addr;
assign write_data = in_mem_write_data;
assign csr_addr = in_mem_write_data[11:0];

assign wb_pc = (in_mem_command == 5'b00010);
assign wb_pc_data = (in_mem_write_data == 12'h0) ? csr_trap_vec_data : (
    (in_mem_write_data == 12'h1) ? csr_trap_vec_data : (
        (in_mem_write_data == 12'h302) ? csr_exception_pc_data : 12'h0
    )
);

always @(posedge clk) begin
    if (reset) begin
        wb_csr <= 1'b0;
        out_csr_addr <= 12'b0;
        out_reg_d <= 5'b0;
        out_csr_addr <= 32'b0;
    end
    else begin
        if (stop) begin
            out_wb_data <= in_alu_out;
            out_csr_data <= out_csr_data;
            wb_csr <= wb_csr;
        end
        else if (in_mem_command[0]) begin
            // sb/sh/sw
            if (in_mem_command[1:0] == 2'b11) begin
                out_wb_data <= in_alu_out;
            end
            else begin
                prev_addr <= in_alu_out;
            end
            out_csr_data <= 32'b0;
            wb_csr <= 1'b0;
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
            wb_csr <= 1'b1;
        end

        else begin
            out_wb_data <= in_alu_out;
            out_csr_data <= 32'b0;
            wb_csr <= 1'b0;
        end

        out_csr_addr <= csr_addr;
        out_reg_d <= in_reg_d;
    end
end

endmodule