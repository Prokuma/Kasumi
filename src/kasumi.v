module kasumi(
    input clk
);

wire [31:0] prog_mem_addr;
wire [31:0] prog_mem_data;
wire [31:0] data_mem_addr;
wire [31:0] data_mem_data;

core core(
    .clk(clk), .prog_mem_addr(prog_mem_addr), .prog_mem_data(prog_mem_data),
    .data_mem_addr(data_mem_addr), .data_mem_data(data_mem_data)
);

endmodule