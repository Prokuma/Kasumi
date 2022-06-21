module fifo_cache_to_main (
    input reset,
    input read_clk,
    input write_clk,
    input [FIFO_WIDTH-1:0] write_data,
    input [FIFO_WIDTH-1:0] write_addr,

    output full,
    output empty,
    output reg [FIFO_WIDTH-1:0] read_data,
    output reg [FIFO_WIDTH-1:0] read_addr
);
parameter BLOCK_SIZE = 64;
parameter FIFO_WIDTH = 32;

reg [FIFO_WIDTH-1:0] fifo[0:BLOCK_SIZE];
reg [FIFO_WIDTH-1:0] fifo_addr[0:BLOCK_SIZE];

reg [5:0] fifo_start;
reg [5:0] fifo_end;
reg [6:0] fifo_len;

assign full = fifo_len[6];
assign empty = (fifo_len == 6'b0);

always @(posedge read_clk) begin
    if (reset) begin
        fifo_start <= 6'b0;
        fifo_end <= 6'b0;
        fifo_len <= 7'b0;
        read_data <= 32'b0;
        read_addr <= 32'b0;
    end
    else if (empty) begin// Empty
        read_data <= 32'b0;
        read_addr <= 32'b0;
    end
    else begin
        read_data <= fifo[fifo_start];
        read_addr <= fifo_addr[fifo_start];
        fifo_len <= fifo_len - 6'b1;
        if (fifo_len != 6'd1)
            fifo_start <= fifo_start + 5'd1;
    end
end

always @(posedge write_clk) begin
    if (~full & ~empty) begin// is not full & is not empty
        fifo[fifo_end+1] <= write_data;
        fifo_addr[fifo_end+1] <= write_addr;
        fifo_end <= fifo_end + 5'd1;
        fifo_len <= fifo_len + 6'd1;
    end
    else if (~full & empty) begin
        fifo[fifo_end] <= write_data;
        fifo_addr[fifo_end] <= write_addr;
        fifo_len <= fifo_len + 6'd1;
    end
end

endmodule