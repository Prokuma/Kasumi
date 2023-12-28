module mem(
    input reset,
    input clk,
    input write,
    input [2:0] funct3,
    input [31:0] din,
    input [12:0] addr,
    output [31:0] dout
);

wire [31:0] out [1:0];

wire clk0 = (addr[12:11] == 2'd0) ? clk : 0;
wire clk1 = (addr[12:11] == 2'd1) ? clk : 0;
wire clk2 = (addr[12:11] == 2'd2) ? clk : 0;
wire clk3 = (addr[12:11] == 2'd3) ? clk : 0;

wire [31:0] dout = out[addr[12:11]];

main_bram bram0(.reset(reset), .clk(clk0), .write(write), .funct3(funct3), .din(din), .addr(addr[10:2]), .dout(out[0]));
main_bram bram1(.reset(reset), .clk(clk1), .write(write), .funct3(funct3), .din(din), .addr(addr[10:2]), .dout(out[1]));
main_bram bram2(.reset(reset), .clk(clk2), .write(write), .funct3(funct3), .din(din), .addr(addr[10:2]), .dout(out[2]));
main_bram bram3(.reset(reset), .clk(clk3), .write(write), .funct3(funct3), .din(din), .addr(addr[10:2]), .dout(out[3]));

endmodule