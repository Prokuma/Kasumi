module prog_cache #(
    parameter NUM_OF_BLOCKS = 4,
    parameter BLOCK_BIT_WIDTH = 2,
    parameter BLOCK_OF_LINES = 32,
    parameter LINE_BIT_WIDTH = 6,
    parameter LINE_WIDTH = 512,
    parameter LINE_WIDTH_PER_BYTE = LINE_WIDTH / 8,
    parameter CELL_WIDTH = 5,
    parameter TOP_ADDR_WIDTH = 32 - BLOCK_BIT_WIDTH - LINE_BIT_WIDTH - CELL_WIDTH,
    parameter ALL_OF_LINES = NUM_OF_BLOCKS * BLOCK_OF_LINES
) (
    input reset,
    input clk,
    input is_write,
    input fifo_full,
    input fifo_empty,
    input [6:0] fifo_addr,
    input [31:0] read_addr,
    input [31:0] write_addr,
    input [31:0] write_data,
    input [LINE_WIDTH-1:0] read_line_data,

    output cache_miss,
    output is_writing_now,
    output is_read,
    output reg is_req,
    output reg [20:0] req_addr,

    output [31:0] read_data
);
/*
    [31:14] TOP_ADDR
    [12:11] BLOCK_SELECT
    [11:0] LINE_SELECT
    [5:0] CELL_SELECT
*/
reg [TOP_ADDR_WIDTH:0] data_prop[0:ALL_OF_LINES-1];

reg waiting;
reg write_end;
reg p_empty;
assign is_read = ~p_empty & ~waiting;

wire [31:0] write_addr_1 = write_addr + 1;
wire [31:0] write_addr_2 = write_addr + 2;
wire [31:0] write_addr_3 = write_addr + 3;

wire [31:0] read_addr_1 = read_addr + 1;
wire [31:0] read_addr_2 = read_addr + 2;
wire [31:0] read_addr_3 = read_addr + 3;

wire cache_miss_f_write_addr = (data_prop[write_addr[12:6]][18:0] != write_addr[31:13]) | ~(data_prop[write_addr[12:6]][19]);
wire cache_miss_f_write_addr_3 = (data_prop[write_addr_3[12:6]][18:0] != write_addr_3[31:13]) | ~(data_prop[write_addr_3[12:6]][19]);

wire cache_miss_f_read_addr = (data_prop[read_addr[12:6]][18:0] != read_addr[31:13]) | ~(data_prop[read_addr[12:6]][18]);
wire cache_miss_f_read_addr_3 = (data_prop[read_addr_3[12:6]][18:0] != read_addr_3[31:13]) | ~(data_prop[read_addr_3[12:6]][19]);
        
assign cache_miss = (
    cache_miss_f_read_addr |
    cache_miss_f_read_addr_3
);

wire write_0 = (((write_addr[12:11] == 2'b00) & ~cache_miss_f_write_addr) | ((write_addr_3[12:11] == 2'b00) & ~cache_miss_f_write_addr_3)) & ~cache_miss & is_write;
wire write_1 = (((write_addr[12:11] == 2'b01) & ~cache_miss_f_write_addr) | ((write_addr_3[12:11] == 2'b01) & ~cache_miss_f_write_addr_3)) & ~cache_miss & is_write;
wire write_2 = (((write_addr[12:11] == 2'b10) & ~cache_miss_f_write_addr) | ((write_addr_3[12:11] == 2'b10) & ~cache_miss_f_write_addr_3)) & ~cache_miss & is_write;
wire write_3 = (((write_addr[12:11] == 2'b11) & ~cache_miss_f_write_addr) | ((write_addr_3[12:11] == 2'b11) & ~cache_miss_f_write_addr_3)) & ~cache_miss & is_write;
wire is_write_t_cache = (write_0 | write_1 | write_2 | write_3);
assign is_writing_now = (~write_end & is_write_t_cache);

wire [31:0] out_0;
wire [31:0] out_1;
wire [31:0] out_2;
wire [31:0] out_3;
wire write_line_0 = (fifo_addr[6:5] == 2'b00) & is_read;
wire write_line_1 = (fifo_addr[6:5] == 2'b01) & is_read;
wire write_line_2 = (fifo_addr[6:5] == 2'b10) & is_read;
wire write_line_3 = (fifo_addr[6:5] == 2'b11) & is_read;

reg [31:0] read_data_reg;
reg [12:0] p_read_addr;
reg [12:0] p_read_addr_1;
reg [12:0] p_read_addr_2;
reg [12:0] p_read_addr_3;

assign read_data[31:24] = write_end & is_write_t_cache ? read_data_reg[31:24] : (
    (p_read_addr_3[12:11] == 2'b00) ? out_0[31:24] : (
        (p_read_addr_3[12:11] == 2'b01) ? out_1[31:24] : (
            (p_read_addr_3[12:11] == 2'b10) ? out_2[31:24] : (
                (p_read_addr_3[12:11] == 2'b11) ? out_3[31:24] : 32'b0
            )
        )
    )
);

assign read_data[23:16] = write_end & is_write_t_cache ? read_data_reg[23:16] : (
    (p_read_addr_2[12:11] == 2'b00) ? out_0[23:16] : (
        (p_read_addr_2[12:11] == 2'b01) ? out_1[23:16] : (
            (p_read_addr_2[12:11] == 2'b10) ? out_2[23:16] : (
                (p_read_addr_2[12:11] == 2'b11) ? out_3[23:16] : 32'b0
            )
        )
    )
);

assign read_data[15:8] = write_end & is_write_t_cache ? read_data_reg[15:8] : (
    (p_read_addr_1[12:11] == 2'b00) ? out_0[15:8] : (
        (p_read_addr_1[12:11] == 2'b01) ? out_1[15:8] : (
            (p_read_addr_1[12:11] == 2'b10) ? out_2[15:8] : (
                (p_read_addr_1[12:11] == 2'b11) ? out_3[15:8] : 32'b0
            )
        )
    )
);

assign read_data[7:0] = write_end & is_write_t_cache ? read_data_reg[7:0] : (
    (p_read_addr[12:11] == 2'b00) ? out_0[7:0] : (
        (p_read_addr[12:11] == 2'b01) ? out_1[7:0] : (
            (p_read_addr[12:11] == 2'b10) ? out_2[7:0] : (
                (p_read_addr[12:11] == 2'b11) ? out_3[7:0] : 32'b0
            )
        )
    )
);

wire [12:0] addr_0 = write_line_0 ? {fifo_addr, 6'b0} : ((write_0 & ~write_end) ? (write_addr[12:11] == 2'b00 ? write_addr[12:0] : write_addr_3[12:0]) : (read_addr[12:11] == 2'b00 ? read_addr[12:0] : read_addr_3[12:0]));
wire [12:0] addr_1 = write_line_1 ? {fifo_addr, 6'b0} : ((write_1 & ~write_end) ? (write_addr[12:11] == 2'b01 ? write_addr[12:0] : write_addr_3[12:0]) : (read_addr[12:11] == 2'b01 ? read_addr[12:0] : read_addr_3[12:0]));
wire [12:0] addr_2 = write_line_2 ? {fifo_addr, 6'b0} : ((write_2 & ~write_end) ? (write_addr[12:11] == 2'b10 ? write_addr[12:0] : write_addr_3[12:0]) : (read_addr[12:11] == 2'b10 ? read_addr[12:0] : read_addr_3[12:0]));
wire [12:0] addr_3 = write_line_3 ? {fifo_addr, 6'b0} : ((write_3 & ~write_end) ? (write_addr[12:11] == 2'b11 ? write_addr[12:0] : write_addr_3[12:0]) : (read_addr[12:11] == 2'b11 ? read_addr[12:0] : read_addr_3[12:0]));
bram bram_0(.clk(clk), .write(write_0 & ~write_end), .write_line(write_line_0), .write_mode(3'b010), .din_line(read_line_data), .din(write_data), .addr(addr_0), .dout(out_0));
bram bram_1(.clk(clk), .write(write_1 & ~write_end), .write_line(write_line_1), .write_mode(3'b010), .din_line(read_line_data), .din(write_data), .addr(addr_1), .dout(out_1));
bram bram_2(.clk(clk), .write(write_2 & ~write_end), .write_line(write_line_2), .write_mode(3'b010), .din_line(read_line_data), .din(write_data), .addr(addr_2), .dout(out_2));
bram bram_3(.clk(clk), .write(write_3 & ~write_end), .write_line(write_line_3), .write_mode(3'b010), .din_line(read_line_data), .din(write_data), .addr(addr_3), .dout(out_3));

integer i;
always @(posedge clk) begin
    if (reset) begin
        for (i = 0; i < ALL_OF_LINES; i = i + 1) begin
            data_prop[i][TOP_ADDR_WIDTH] <= 0;
        end
        waiting <= 1'b1;
    end
    else begin
        if (is_read) begin
            data_prop[fifo_addr][TOP_ADDR_WIDTH-1:0] <= req_addr[20:2];
            data_prop[fifo_addr][TOP_ADDR_WIDTH] <= 1'b1;
        end
        else begin
            is_req <= 1'b0 | cache_miss;
            if (fifo_full) waiting <= 1'b0;
            else waiting <= 1'b1;
        end

        if (is_writing_now) write_end <= 1;
        else write_end <= 0;

        if (~is_write) begin
            p_read_addr_3 <= read_addr[12:0] + 3;
            p_read_addr_2 <= read_addr[12:0] + 2;
            p_read_addr_1 <= read_addr[12:0] + 1;
            p_read_addr <= read_addr[12:0];
        end

        if (cache_miss_f_read_addr) begin
            req_addr <= read_addr[31:11];
            is_req <= 1'b1;
        end
        else if(cache_miss_f_read_addr_3) begin
            req_addr <= read_addr[31:11];
            is_req <= 1'b1;
        end
        else read_data_reg <= read_data;

        p_empty <= fifo_empty;
    end 
end

initial begin
    waiting = 1;
end

endmodule