module fifo_main_to_cache #(
    parameter BLOCK_SIZE = 32,
    parameter FIFO_WIDTH = 512
)(
    input reset,
    input read_clk,
    input write_clk,
    input is_read,
    input is_write,
    input [FIFO_WIDTH-1:0] write_data,
    input [6:0] write_addr,

    output full,
    output empty,
    output reg [FIFO_WIDTH-1:0] read_data,
    output reg [6:0] read_addr
);

(* ram_style = "distributed" *) reg [FIFO_WIDTH-1:0] fifo[0:BLOCK_SIZE-1];
reg [6:0] fifo_addr[0:BLOCK_SIZE-1];

reg [4:0] fifo_start;
reg [4:0] fifo_end;

reg read_empty;
reg write_empty;
assign empty = read_empty | write_empty;

assign full = (~empty & (fifo_start == fifo_end));

always @(posedge read_clk) begin
    if (reset) begin
        fifo_start <= 5'b0;
        read_empty <= 1'b1;
    end
    else if (is_read & ~is_write) begin
        if (empty) begin // Empty
            read_data <= 512'b0;
            read_addr <= 7'b0;
        end
        else begin
            read_data <= fifo[fifo_start];
            read_addr <= fifo_addr[fifo_start];
            fifo_start <= fifo_start + 5'd1;
            if (fifo_start+5'd1 == fifo_end) read_empty <= 1'b1;
        end
    end
    else begin
        if (~write_empty) read_empty <= 1'b0;
    end
end

always @(posedge write_clk) begin
    if (reset) begin
        fifo_end <= 5'b0;
        write_empty <= 1'b1;
    end
    else if (is_write & ~is_read) begin
        fifo[fifo_end] <= write_data;
        fifo_addr[fifo_end] <= write_addr;
        fifo_end <= fifo_end + 5'd1;
        if (empty) write_empty <= 1'b0;
    end
    else begin
        if (read_empty) write_empty <= 1'b1;
    end
end

endmodule