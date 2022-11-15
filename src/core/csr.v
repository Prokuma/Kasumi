module csr(
    input reset,
    input clk,
    input wb_csr,
    input [11:0] addr,
    input [11:0] write_addr,
    input [31:0] in_data,
    output [31:0] out_data,
    output [31:0] out_trap_vec,
    output [31:0] out_exception_pc
);

integer i;
// Machine Mode CSR
reg [31:0] csr_register [12'h300:12'h3ff];

assign out_data = csr_register[addr];
assign out_trap_vec = csr_register[12'h305];
assign out_exception_pc = csr_register[12'h341];

always @(posedge clk) begin
    if (wb_csr & (write_addr[11:10] != 2'b11))
        csr_register[write_addr] <= in_data;
    if (reset)
        for (i = 12'h300; i < 12'h3ff; i = i + 1) begin
            case (i)
                12'h301: csr_register[i] <= 32'b01_0000_0000000000000000100000000;
                default: csr_register[i] <= 32'b0;
            endcase
        end
end

endmodule