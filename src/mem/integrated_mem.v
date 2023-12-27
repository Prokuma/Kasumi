module integrated_mem(
    input reset,
    input clk,
    input [2:0] funct3,
    input [31:0] write_data,
    input [31:0] write_addr,
    input [31:0] prog_mem_addr,
    input [31:0] data_mem_addr,
    input [31:0] reg_data,

    output is_writing_now,
    output reg_write,
    output [31:0] prog_mem_data,
    output [31:0] data_mem_data,
    output [31:0] reg_addr,
    output [31:0] write_reg_data
);

is_writing_now = is_write_prog;
reg_addr = data_mem_addr[14:0];

wire is_reg = data_mem_addr[14];
wire data_mem_data = is_reg ? reg_data : mem_data_mem_data;
wire mem_data_mem_data;
wire is_write_prog = is_write & ~data_mem_addr[13];

mem prog_mem(
    .reset(reset), .clk(clk & ~is_reg), .write(is_write_prog), .funct3(funct3), .din(write_data), .addr(write_addr), .dout(prog_mem_data)
);

mem data_mem(
    .reset(reset), .clk(clk & ~is_reg), .write(is_write), .funct3(funct3), .din(write_data), .addr(write_addr), .dout(mem_data_mem_data)
);

endmodule