module reg_file (
    input reset,
    input clk,
    input [4:0] rs1_addr,
    input [4:0] rs2_addr,

    input is_write,
    input [4:0] wb_addr,
    input [31:0] wb_data,

    output [31:0] rs1_data,
    output [31:0] rs2_data
);

reg [31:0] x_reg [1:31];

assign rs1_data = (rs1_addr != 5'b0) ? x_reg[rs1_addr] : 32'b0;
assign rs2_data = (rs2_addr != 5'b0) ? x_reg[rs2_addr] : 32'b0;

integer i;
always @(posedge clk) begin
    if (reset) begin
        for (i = 1; i < 32; i = i + 1) begin
            x_reg[i] <= 32'b0;
        end
    end
    else if(is_write & (wb_addr != 5'b0)) x_reg[wb_addr] <= wb_data;
end

initial begin
    for (i = 1; i < 32; i = i + 1) begin
        x_reg[i] = 32'b0;
    end
end

endmodule