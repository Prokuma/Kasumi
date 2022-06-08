module csr(
    input wb_csr,
    input [11:0] addr,
    input [11:0] write_addr,
    input [31:0] in_data,
    output [31:0] out_data,
    output [31:0] out_trap_vec,
    output [31:0] out_exception_pc
);

reg [31:0] csr_register [0:4095];
assign out_data = csr_register[addr];
assign out_trap_vec = csr_register[12'h305];
assign out_exception_pc = csr_register[12'h341];

always @(*) begin
    if (wb_csr)
        csr_register[write_addr] <= in_data;
end

integer i;
initial begin
    for(i = 0; i < 4096; i = i + 1) begin
        csr_register[i] = 32'b0;
    end
end

endmodule