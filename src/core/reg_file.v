module reg_file (
    input [4:0] rs1_addr,
    input [4:0] rs2_addr,

    input is_write,
    input [4:0] wb_addr,
    input [31:0] wb_data,

    output reg [31:0] rs1_data,
    output reg [31:0] rs2_data
);

reg [31:0] x_reg [0:31];

always @(*) begin
    rs1_data <= x_reg[rs1_addr];
    rs2_data <= x_reg[rs2_addr];

    if (is_write & (wb_addr != 5'b0))
        x_reg[wb_addr] <= wb_data;
end

integer i;
initial begin
    for(i = 0; i < 32; i = i + 1) begin
        x_reg[i] = 32'b0;
    end
end

endmodule