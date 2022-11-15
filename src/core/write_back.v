module write_back(
    input [4:0] reg_d,
    input [31:0] in_wb_data,

    output is_write, 
    output [4:0] out_wb_addr,
    output [31:0] out_wb_data
);

assign is_write = (reg_d != 5'b00000);
assign out_wb_addr = reg_d;
assign out_wb_data = in_wb_data; 

endmodule