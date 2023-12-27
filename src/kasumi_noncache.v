module kasumi_noncache(
    input reset,
    input reset_sys,
    input clk,
    input load,
    input [31:0] load_data,
    input [31:0] load_addr,
    input [31:0] reg_data,

    output reg_write,
    output [31:0] write_reg_data,
    output [31:0] reg_addr,
);

wire [31:0] prog_mem_addr;
wire [31:0] prog_mem_data;
wire [31:0] data_mem_addr;
wire [31:0] data_mem_data;

wire is_mem_write;
wire [2:0] funct3;
wire [31:0] write_data;
wire is_writing_now;

core core(
    // INPUT
    .reset(reset | reset_sys), .stop(is_writing_now | load), 
    .clk(clk), .prog_mem_data(prog_mem_data), .data_mem_data(data_mem_data),

    // OUTPUT
    .is_mem_write(is_mem_write), .funct3(funct3), .write_data(data_mem_data),
    .prog_mem_addr(prog_mem_addr), .data_mem_addr(data_mem_addr) 
);

wire write_addr = load ? load_addr : data_mem_addr;
wire write_data = load ? load_data : data_mem_data;

integrated_mem mem(
    .reset(reset | reset_sys), .clk(clk), .is_write(is_mem_write | load), .funct3(funct3), .write_data(write_data),
    .write_addr(write_addr), .prog_mem_addr(prog_mem_addr), .data_mem_addr(data_mem_addr),
    .is_writing_now(is_writing_now), .prog_mem_data(prog_mem_data), .data_mem_data(data_mem_data)
    .reg_addr(reg_addr), .reg_data(reg_data), .reg_write(reg_write), .write_reg_data(write_reg_data)
)

endmodule