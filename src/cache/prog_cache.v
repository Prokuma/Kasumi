module prog_cache (
    input reset,
    input clk,
    input is_write,
    input in_fifo_clock,
    input fifo_full,
    input fifo_empty,
    input [7:0] fifo_addr,
    input [31:0] read_addr,
    input [31:0] write_addr,
    input [31:0] write_data,
    input [LINE_WIDTH-1:0] read_line_data,

    output cache_miss,
    output reg is_req,
    output reg [17:0] req_addr,

    output [31:0] read_data
);
parameter NUM_OF_BLOCKS = 4;
parameter BLOCK_BIT_WIDTH = 2;
parameter BLOCK_OF_LINES = 64;
parameter LINE_BIT_WIDTH = 6;
parameter LINE_WIDTH = 512;
parameter CELL_WIDTH = 6;
parameter TOP_ADDR_WIDTH = 32 - BLOCK_BIT_WIDTH - LINE_BIT_WIDTH - CELL_WIDTH;
parameter ALL_OF_LINES = NUM_OF_BLOCKS * BLOCK_OF_LINES;

/*
    [31:14] TOP_ADDR
    [13:12] BLOCK_SELECT
    [11:6] LINE_SELECT
    [5:0] CELL_SELECT
*/

reg [LINE_WIDTH+TOP_ADDR_WIDTH:0] data_line[0:ALL_OF_LINES-1];

wire [31:0] write_addr_1 = write_addr + 1;
wire [31:0] write_addr_2 = write_addr + 2;
wire [31:0] write_addr_3 = write_addr + 3;

wire [31:0] read_addr_1 = read_addr + 1;
wire [31:0] read_addr_2 = read_addr + 2;
wire [31:0] read_addr_3 = read_addr + 3;

assign read_data = {
    data_line[read_addr_3[13:6]][{4'b0, read_addr_3[5:0]} << 4 +: 8],
    data_line[read_addr_2[13:6]][{4'b0, read_addr_2[5:0]} << 4 +: 8],
    data_line[read_addr_1[13:6]][{4'b0, read_addr_1[5:0]} << 4 +: 8],
    data_line[read_addr[13:6]][{4'b0, read_addr[5:0]} << 4 +: 8]
};

wire cache_miss_f_write_addr = (data_line[write_addr[13:6]][529:512] != write_addr[31:14]) | ~(data_line[write_addr[13:6]][530]);
wire cache_miss_f_write_addr_1 = (data_line[write_addr_1[13:6]][529:512] != write_addr_1[31:14]) | ~(data_line[write_addr_1[13:6]][530]);
wire cache_miss_f_write_addr_2 = (data_line[write_addr_2[13:6]][529:512] != write_addr_2[31:14]) | ~(data_line[write_addr_2[13:6]][530]);
wire cache_miss_f_write_addr_3 = (data_line[write_addr_3[13:6]][529:512] != write_addr_3[31:14]) | ~(data_line[write_addr_3[13:6]][530]);

wire cache_miss_f_read_addr = (data_line[read_addr[13:6]][529:512] != read_addr[31:14]) | ~(data_line[read_addr[13:6]][530]);
wire cache_miss_f_read_addr_3 = (data_line[read_addr_3[13:6]][529:512] != read_addr_3[31:14]) | ~(data_line[read_addr_3[13:6]][530]);

assign cache_miss = (
    cache_miss_f_read_addr |
    cache_miss_f_read_addr_3
);

integer i;
always @(posedge clk) begin
    if (reset) begin
        for (i = 0; i < ALL_OF_LINES; i = i + 1) begin
            data_line[i][LINE_WIDTH+TOP_ADDR_WIDTH] <= 0;
        end
    end 
end

always @(posedge is_write) begin
    if (~cache_miss_f_write_addr) begin
        data_line[write_addr[13:6]][{4'b0, read_addr[5:0]} << 4 +: 8] <= write_data[7:0];
    end
    if (~cache_miss_f_write_addr_1) begin
        data_line[write_addr_1[13:6]][{4'b0, read_addr_1[5:0]} << 4 +: 8] <= write_data[15:8];
    end
    if (~cache_miss_f_write_addr_2) begin
        data_line[write_addr_2[13:6]][{4'b0, read_addr_2[5:0]} << 4 +: 8] <= write_data[23:16];
    end
    if (~cache_miss_f_write_addr_3) begin
        data_line[write_addr_3[13:6]][{4'b0, read_addr_3[5:0]} << 4 +: 8] <= write_data[31:24];
    end
end

always @(posedge cache_miss_f_read_addr) begin
    req_addr <= read_addr[31:14];
    is_req <= 1'b1;
end

always @(posedge cache_miss_f_read_addr_3) begin
    if (~cache_miss_f_read_addr)
        req_addr <= read_addr_3[31:14];
        is_req <= 1'b1;
end

always @(posedge in_fifo_clock) begin
    if (~fifo_empty) begin
        data_line[fifo_addr][LINE_WIDTH-1:0] <= read_line_data;
        data_line[fifo_addr][TOP_ADDR_WIDTH+LINE_WIDTH-1:LINE_WIDTH] <= req_addr;
        data_line[fifo_addr][TOP_ADDR_WIDTH+LINE_WIDTH] <= 1'b1;
    end
    else begin
        is_req <= 1'b1 & cache_miss;
    end
end

endmodule