module cache(
    input reset,
    input cache_clk,
    input main_clk,
    input is_write,
    input [31:0] write_data,
    input [31:0] write_addr,
    input [31:0] prog_mem_addr,
    input [31:0] data_mem_addr,

    input [511:0] read_main_prog_data,
    input [511:0] read_main_data_data,
    input [7:0] read_main_prog_addr,
    input [7:0] read_main_data_addr,

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
wire full_prog_fifo;
wire empty_prog_fifo;
wire [7:0] addr_prog_fifo;

prog_cache prog_cache(
    .reset(reset), .clk(cache_clk),
    .is_write(is_write), .in_fifo_clock(cache_clk & ~empty_prog_fifo), 
    .fifo_full(full_prog_fifo), .fifo_empty(empty_prog_fifo), .fifo_addr(addr_prog_fifo),
    .read_addr(prog_mem_addr), .write_addr(write_addr), .write_data(write_data), 
    .read_line_data(read_line_prog_data), .cache_miss(cache_miss_f_prog),
    .is_req(is_req_f_prog), .req_addr(req_addr_f_prog), .read_data(prog_mem_data)
);


fifo_main_to_cache prog_fifo_main_to_cache(
    .reset(reset),
    .read_clk(cache_clk), .write_clk(main_clk & is_req_f_prog), .write_addr(read_main_prog_addr),
    .write_data(read_main_data_data), .full(full_prog_fifo), .empty(empty_prog_fifo), 
    .read_data(read_line_prog_data), .read_addr(addr_prog_fifo)
);

wire [511:0] read_line_data_data;
wire full_data_fifo;
wire empty_data_fifo;
wire [7:0] addr_data_fifo;

data_cache data_cache(
    .reset(reset), .clk(cache_clk),
    .is_write(is_write), .in_fifo_clock(cache_clk & ~empty_data_fifo), 
    .fifo_full(full_data_fifo), .fifo_empty(empty_data_fifo), .fifo_addr(addr_data_fifo),
    .read_addr(data_mem_addr), .write_addr(write_addr), .write_data(write_data), 
    .read_line_data(read_line_data_data), .cache_miss(cache_miss_f_data),
    .is_req(is_req_f_data), .req_addr(req_addr_f_data), .read_data(data_mem_data)
);

fifo_cache_to_main data_fifo_cache_to_main(
    .reset(reset),
    .read_clk(main_clk), .write_clk(cache_clk & is_write), .write_data(write_data),
    .write_addr(write_addr), .full(fifo_full), .empty(fifo_empty), 
    .read_data(write_back_data), .read_addr(write_back_addr)
);

fifo_main_to_cache data_fifo_main_to_cache(
    .reset(reset),
    .read_clk(cache_clk), .write_clk(main_clk & is_req_f_data), .write_addr(read_main_data_addr),
    .write_data(read_main_data_data), .full(full_data_fifo), .empty(empty_data_fifo), 
    .read_data(read_line_data_data), .read_addr(addr_data_fifo)
);

endmodule