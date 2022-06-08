module test_mem(
    input is_mem_write,
    input [31:0] addr,
    input [31:0] write_addr,
    input [31:0] in_data,
    output [7:0] tohost,
    output [31:0] data
);
localparam MAX_SIZE=16384;
localparam START_ADDR=32'h80000000;

reg [7:0] memory[START_ADDR:MAX_SIZE+START_ADDR-1];
assign tohost = memory[32'h80001000];
assign data = {memory[addr+3], memory[addr+2], memory[addr+1], memory[addr]};

always @(*) begin
    if (is_mem_write) begin
        memory[write_addr+3] <= in_data[31:24];
        memory[write_addr+2] <= in_data[23:16];
        memory[write_addr+1] <= in_data[15:8];
        memory[write_addr] <= in_data[7:0];
    end
end

initial begin
    $readmemh("hex/rv32ui-p-xori.vh", memory);     
end

endmodule