module kasumi(
    input reset,
    input clk,
    input dram_clk,
    input [511:0] read_prog_data,
    input [511:0] read_data_data,
    input [7:0] read_prog_addr,
    input [7:0] read_data_addr,
    
    output is_req_f_prog,
    output is_req_f_data,
    output [17:0] req_addr_f_prog,
    output [17:0] req_addr_f_data,

    output fifo_empty,
    output [31:0] write_back_data,
    output [31:0] write_back_addr
);

wire [31:0] prog_mem_addr;
wire [31:0] prog_mem_data;
wire [31:0] data_mem_addr;
wire [31:0] data_mem_data;

wire is_write;
wire [31:0] write_data;
wire [31:0] write_addr;

core core(
    .reset(reset), .stop(cache_miss), 
    .clk(clk), .prog_mem_addr(prog_mem_addr), .prog_mem_data(prog_mem_data),
    .is_mem_write(is_mem_write), .mem_mem_wb_data(write_data), .out_mem_addr(write_addr),
    .data_mem_addr(data_mem_addr), .data_mem_data(data_mem_data)
);

wire cache_miss;

cache cache(
    // INPUT
    .cache_clk(clk), .main_clk(dram_clk), .is_write(is_write), .write_data(write_data),
    .write_addr(write_addr), .prog_mem_addr(prog_mem_addr), .data_mem_addr(data_mem_addr),
    .read_main_prog_data(read_prog_data), .read_main_data_data(read_data_data),
    .read_main_prog_addr(read_prog_addr), .read_main_data_addr(read_data_addr),

    // OUTPUT
    .cache_miss(cache_miss), .prog_mem_data(prog_mem_data), .data_mem_data(data_mem_data),
    .is_req_f_prog(is_req_f_prog), .is_req_f_data(is_req_f_data), 
    .req_addr_f_prog(req_addr_f_prog), .req_addr_f_data(req_addr_f_data),
    .fifo_full(), .fifo_empty(fifo_empty), 
    .write_back_addr(write_back_addr), .write_back_data(write_back_data)
);

endmodule