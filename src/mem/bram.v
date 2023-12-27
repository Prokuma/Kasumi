module main_bram(
    input reset,
    input clk,
    input write,
    input [2:0] funct3,
    input [31:0] din,
    input [10:0] addr,
    output [31:0] dout
);

reg [7:0] ram0 [0:511];
reg [7:0] ram1 [0:511];
reg [7:0] ram2 [0:511];
reg [7:0] ram3 [0:511];

wire [10:0] addr_0 = addr[10:0];
wire [10:0] addr_1 = addr[10:0] + 11'd1;
wire [10:0] addr_2 = addr[10:0] + 11'd2;
wire [10:0] addr_3 = addr[10:0] + 11'd3;

wire [7:0] ram0_ptr = (addr_0[1:0] == 2'b00) ? ram0[addr_0[10:2]] : (
    (addr_0[1:0] == 2'b01) ? ram1[addr_0[10:2]] : (
        (addr_0[1:0] == 2'b10) ? ram2[addr_0[10:2]] : (
            (addr_0[1:0] == 2'b11) ? ram3[addr_0[10:2]] : 8'b0
        )
    )
);
wire [7:0] ram1_ptr = (addr_1[1:0] == 2'b00) ? ram0[addr_1[10:2]] : (
    (addr_1[1:0] == 2'b01) ? ram1[addr_1[10:2]] : (
        (addr_1[1:0] == 2'b10) ? ram2[addr_1[10:2]] : (
            (addr_1[1:0] == 2'b11) ? ram3[addr_1[10:2]] : 8'b0
        )
    )
);
wire [7:0] ram2_ptr = (addr_2[1:0] == 2'b00) ? ram0[addr_2[10:2]] : (
    (addr_2[1:0] == 2'b01) ? ram1[addr_2[10:2]] : (
        (addr_2[1:0] == 2'b10) ? ram2[addr_2[10:2]] : (
            (addr_2[1:0] == 2'b11) ? ram3[addr_2[10:2]] : 8'b0
        )
    )
);
wire [7:0] ram3_ptr = (addr_3[1:0] == 2'b00) ? ram0[addr_3[10:2]] : (
    (addr_3[1:0] == 2'b01) ? ram1[addr_3[10:2]] : (
        (addr_3[1:0] == 2'b10) ? ram2[addr_3[10:2]] : (
            (addr_3[1:0] == 2'b11) ? ram3[addr_3[10:2]] : 8'b0
        )
    )
);

wire is_ram0 = addr[1:0] == 2'b00;
wire is_ram1 = (addr[1:0] == 2'b01) || (funct3[1] == 1'b1) || (funct3[0] == 1'b1);
wire is_ram2 = (addr[1:0] == 2'b10) || (funct3[0] == 1'b1);
wire is_ram3 = (addr[1:0] == 2'b11) || (funct3[1] == 1'b1) || (funct3[0] == 1'b1)

integer i;
always @(posedge clk) begin
    if (reset) begin
        for (i = 0; i < 512; i = i + 1) begin
            ram0[i] <= 0;
            ram1[i] <= 0;
            ram2[i] <= 0;
            ram3[i] <= 0;
        end
    end
    else begin
        if (write) begin
            if (is_ram3) begin
                ram3_ptr <= din[31:24];
            end
            if (is_ram2) begin
                ram2_ptr <= din[23:16];
            end
            if (is_ram1) begin
                ram1_ptr <= din[15:8];
            end
            if (is_ram0) begin
                ram0_ptr <= din[7:0];
            end
        end
        else begin
            dout[31:24] <= ram3_ptr & {8{is_ram3}};
            dout[23:16] <= ram2_ptr & {8{is_ram2}};
            dout[15:8]  <= ram1_ptr & {8{is_ram1}};
            dout[7:0]   <= ram0_ptr & {8{is_ram0}};
        end
    end
end

endmodule