module bram(
    input clk,
    input write,
    input write_line,
    input [2:0] write_mode,
    input [511:0] din_line,
    input [31:0] din,
    input [12:0] addr,
    output [31:0] dout
);

reg [511:0] ram [0:31];
reg [511:0] a_dout;
reg [511:0] b_dout;

wire [12:0] addr_1 = addr + 1;
wire [12:0] addr_2 = addr + 2;
wire [12:0] addr_3 = addr + 3;

reg [10:0] addr_0_p;
reg [10:0] addr_1_p;
reg [10:0] addr_2_p;
reg [10:0] addr_3_p;

wire [4:0] a_addr = addr_3[10:6];
wire [4:0] b_addr = addr[10:6];

wire [3:0] a_mask = {
    (write_mode == 3'b010),
    ((write_mode == 3'b010) & (addr_2[10:6] == a_addr)),
    (((write_mode == 3'b010) & (addr_1[10:6] == a_addr)) | ((write_mode == 3'b001) & (addr_1[10:6] != b_addr))),
    ((write_mode == 3'b010) & (b_addr == a_addr))
};

assign dout = {
    a_dout[{addr_3_p[5:0], 3'b0}+:8],
    ((addr_3_p[10:6] == addr_2_p[10:6]) ? a_dout[{addr_2_p[5:0], 3'b0}+:8] : b_dout[{addr_2_p[5:0], 3'b0}+:8]),
    ((addr_3_p[10:6] == addr_1_p[10:6]) ? a_dout[{addr_1_p[5:0], 3'b0}+:8] : b_dout[{addr_1_p[5:0], 3'b0}+:8]),
    ((addr_3_p[10:6] == addr_0_p[10:6]) ? a_dout[{addr_0_p[5:0], 3'b0}+:8] : b_dout[{addr_0_p[5:0], 3'b0}+:8])
};

integer i;
always @(posedge clk) begin
    if ((write & ((addr_3[12:11] == addr[12:11]) | (addr_3[10:6] > addr[10:6]))) | write_line) begin
        for (i = 0; i < 64; i = i + 1) begin
            if (((a_mask[3] & (i == addr_3[5:0])) | (a_mask[2] & (i == addr_2[5:0])) | 
                (a_mask[1] & (i == addr_1[5:0])) | (a_mask[0] & (i == addr[5:0]))) | write_line) ram[a_addr][i*8+:8] <= write_line ? din_line[i*8+:8] : (
                (a_mask[3] & (i == addr_3[5:0])) ? din[31:24] : (
                    (a_mask[2] & (i == addr_2[5:0])) ? din[23:16] : (
                        (a_mask[1] & (i == addr_1[5:0])) ? din[15:8] : din[7:0]
                    )
                )
            );
        end
    end
    a_dout <= ram[a_addr];
    addr_0_p <= addr[10:0];
    addr_1_p <= addr_1[10:0];
    addr_2_p <= addr_2[10:0];
    addr_3_p <= addr_3[10:0];
end

always @(posedge clk) begin
    if (write & ((addr_3[10:6] == addr[10:6]) | (addr_3[10:6] < addr[10:6]))) begin
        if (addr[5:0] == 6'd61) ram[b_addr][61*8+:8] <= din[7:0];
        if ((addr[5:0] == 6'd62) & (addr[5:0] == 6'd61)) ram[b_addr][62*8+:8] <= (addr[5:0] == 6'd61) ? din[15:8] : din[7:0];
        if ((addr[5:0] == 6'd63) & (addr[5:0] == 6'd62) & (addr[5:0] == 6'd61)) ram[b_addr][63*8+:8] <= (addr[5:0] == 6'd61) ? din[7:0] : ((addr[5:0] == 6'd62) ? din[15:8] : din[23:16]);
    end
    b_dout <= ram[b_addr];
end

endmodule