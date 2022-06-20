module cache(
    input cache_clk,
    input main_clk,
    input is_write,
    input [31:0] write_data,
    input [31:0] write_addr,
    input [31:0] prog_mem_addr,
    input [31:0] data_mem_addr,

    input [511:0] read_main_prog_data,
    input [511:0] read_main_data_data,

    output cache_miss,
    output [31:0] prog_mem_data,
    output [31:0] data_mem_data,

    output is_req_f_prog,
    output is_req_f_data,
    output [17:0] req_addr_f_prog,
    output [17:0] req_addr_f_data,

    output fifo_full,
    output fifo_empty,
    output [31:0] write_back_addr,
    output [31:0] write_back_data
);

assign cache_miss = cache_miss_f_prog | cache_miss_f_data;

wire [511:0] read_line_prog_data;

prog_cache prog_cache(
    .is_write(is_write), .in_fifo_clock(cache_clk & ~empty_prog_fifo), .read_addr(prog_mem_addr),
    .write_addr(write_addr), .write_data(write_data), .read_line_data(read_line_prog_data), .cache_miss(cache_miss_f_prog),
    .is_req(is_req_f_prog), .req_addr(req_addr_f_prog), .read_data(prog_mem_data)
);

wire empty_prog_fifo;

fifo_main_to_cache prog_fifo_main_to_cache(
    .read_clk(main_clk), .write_clk(cache_clk & is_req_f_prog),
    .write_data(read_main_data_data), .full(), .empty(empty_prog_fifo), 
    .read_data(read_line_prog_data)
);

wire [511:0] read_line_data_data;

data_cache data_cache(
    .is_write(is_write), .in_fifo_clock(cache_clk & ~empty_data_fifo), .read_addr(data_mem_addr),
    .write_addr(write_addr), .write_data(write_data), .read_line_data(read_line_data_data), .cache_miss(cache_miss_f_data),
    .is_req(is_req_f_data), .req_addr(req_addr_f_data), .read_data(data_mem_data)
);

fifo_cache_to_main data_fifo_cache_to_main(
    .read_clk(main_clk), .write_clk(cache_clk & is_write), .write_data(write_data),
    .write_addr(write_addr), .full(fifo_full), .empty(fifo_empty), 
    .read_data(write_back_data), .read_addr(write_back_addr)
);

wire empty_data_fifo;

fifo_main_to_cache data_fifo_main_to_cache(
    .read_clk(main_clk), .write_clk(cache_clk & is_req_f_data),
    .write_data(read_main_data_data), .full(), .empty(empty_data_fifo), 
    .read_data(read_line_data_data)
);

endmodule