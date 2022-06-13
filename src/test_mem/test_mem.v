module test_mem(
    input is_mem_write,
    input [31:0] addr,
    input [31:0] write_addr,
    input [31:0] in_data,
    output [47:0] tohost,
    output [31:0] data
);
localparam MAX_SIZE=16384;
localparam START_ADDR=32'h80000000;
localparam TO_HOST_ADDR = 32'h80001000;

reg [7:0] memory[START_ADDR:MAX_SIZE+START_ADDR-1];
assign tohost = {memory[TO_HOST_ADDR+5], memory[TO_HOST_ADDR+4], memory[TO_HOST_ADDR+3], 
memory[TO_HOST_ADDR+2], memory[TO_HOST_ADDR+1], memory[TO_HOST_ADDR]};
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
    //$readmemh("hex/rv32mi-p-breakpoint.vh", memory);
    //$readmemh("hex/rv32mi-p-csr.vh", memory);
    //$readmemh("hex/rv32mi-p-illegal.vh", memory);

    //$readmemh("hex/rv32ui-p-add.vh", memory);
    //$readmemh("hex/rv32ui-p-addi.vh", memory);
    //$readmemh("hex/rv32ui-p-and.vh", memory);
    //$readmemh("hex/rv32ui-p-andi.vh", memory);
    //$readmemh("hex/rv32ui-p-auipc.vh", memory);
    //$readmemh("hex/rv32ui-p-beq.vh", memory);
    //$readmemh("hex/rv32ui-p-bge.vh", memory);
    //$readmemh("hex/rv32ui-p-bgeu.vh", memory);
    //$readmemh("hex/rv32ui-p-blt.vh", memory);
    //$readmemh("hex/rv32ui-p-bltu.vh", memory);
    //$readmemh("hex/rv32ui-p-bne.vh", memory);
    //$readmemh("hex/rv32ui-p-fence_i.vh", memory);
    //$readmemh("hex/rv32ui-p-jal.vh", memory);
    //$readmemh("hex/rv32ui-p-jalr.vh", memory);
    //$readmemh("hex/rv32ui-p-lb.vh", memory);
    //$readmemh("hex/rv32ui-p-lbu.vh", memory);
    //$readmemh("hex/rv32ui-p-lh.vh", memory);
    //$readmemh("hex/rv32ui-p-lhu.vh", memory);
    //$readmemh("hex/rv32ui-p-lui.vh", memory);
    //$readmemh("hex/rv32ui-p-lw.vh", memory);
    //$readmemh("hex/rv32ui-p-or.vh", memory);
    //$readmemh("hex/rv32ui-p-ori.vh", memory);
    //$readmemh("hex/rv32ui-p-sb.vh", memory);
    //$readmemh("hex/rv32ui-p-sh.vh", memory);
    //$readmemh("hex/rv32ui-p-simple.vh", memory);
    //$readmemh("hex/rv32ui-p-sll.vh", memory);
    //$readmemh("hex/rv32ui-p-slli.vh", memory);
    //$readmemh("hex/rv32ui-p-slt.vh", memory);
    //$readmemh("hex/rv32ui-p-slti.vh", memory);
    //$readmemh("hex/rv32ui-p-sltiu.vh", memory);
    //$readmemh("hex/rv32ui-p-sltu.vh", memory);
    //$readmemh("hex/rv32ui-p-sra.vh", memory);
    //$readmemh("hex/rv32ui-p-srai.vh", memory);
    //$readmemh("hex/rv32ui-p-srl.vh", memory);
    //$readmemh("hex/rv32ui-p-srli.vh", memory);
    //$readmemh("hex/rv32ui-p-sub.vh", memory);
    //$readmemh("hex/rv32ui-p-sw.vh", memory);
    //$readmemh("hex/rv32ui-p-xor.vh", memory);
    //$readmemh("hex/rv32ui-p-xori.vh", memory);
end

endmodule