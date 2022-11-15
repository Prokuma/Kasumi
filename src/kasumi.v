module kasumi(
    input reset,
    input reset_sys,
    input clk,
    input dram_clk,
    input is_write_prog_line,
    input is_write_data_line,
    input is_write_t_main,
    input [511:0] read_prog_data,
    input [511:0] read_data_data,
    input [6:0] read_prog_addr,
    input [6:0] read_data_addr,
    
    output is_req_f_prog,
    output is_req_f_data,
    output [20:0] req_addr_f_prog,
    output [20:0] req_addr_f_data,

    output fifo_empty,
    output [31:0] write_back_data,
    output [31:0] write_back_addr
);

wire [31:0] prog_mem_addr;
wire [31:0] prog_mem_data;
wire [31:0] data_mem_addr;
wire [31:0] data_mem_data;

wire is_mem_write;
wire [2:0] funct3;
wire [31:0] write_data;
wire cache_miss;
wire is_writing_now;

core core(
    // INPUT
    .reset(reset | reset_sys), .stop(cache_miss | is_req_f_prog | is_req_f_data | is_writing_now), 
    .clk(clk), .prog_mem_data(prog_mem_data), .data_mem_data(data_mem_data),

    // OUTPUT
    .is_mem_write(is_mem_write), .funct3(funct3), .write_data(write_data),
    .prog_mem_addr(prog_mem_addr), .data_mem_addr(data_mem_addr) 
);

cache cache(
    // INPUT
    .reset(reset | reset_sys),
    .cache_clk(clk), .main_clk(dram_clk), .is_write(is_mem_write), .is_write_t_main(is_write_t_main),
    .is_write_prog_line(is_write_prog_line), .is_write_data_line(is_write_data_line),
    .funct3(funct3), .write_data(write_data),
    .write_addr(data_mem_addr), .prog_mem_addr(prog_mem_addr), .data_mem_addr(data_mem_addr),
    .read_main_prog_data(read_prog_data), .read_main_data_data(read_data_data),
    .read_main_prog_addr(read_prog_addr), .read_main_data_addr(read_data_addr),

    // OUTPUT
    .cache_miss(cache_miss), .is_writing_now(is_writing_now),
    .prog_mem_data(prog_mem_data), .data_mem_data(data_mem_data),
    .is_req_f_prog(is_req_f_prog), .is_req_f_data(is_req_f_data), 
    .req_addr_f_prog(req_addr_f_prog), .req_addr_f_data(req_addr_f_data),
    .fifo_empty(fifo_empty), 
    .write_back_addr(write_back_addr), .write_back_data(write_back_data)
);

endmodule