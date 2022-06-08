module fetch (
    input clk,
    input stop,
    input bubble,
    input wb_pc,
    input [31:0] wb_pc_data,
    input [31:0] data,

    output [31:0] mem_addr,
    output reg [31:0] command,
    output reg [31:0] now_pc
);

reg [31:0] pc;
assign mem_addr = pc;

always @(posedge clk) begin
    // Stop(pause) CPU
    if (stop) begin
        command <= command;
        now_pc <= now_pc;
    end

    // Pipeline Bubble(addi x0, x0, 0)
    else if (bubble) begin
        command <= 32'b00000000000000000000000000010011;
        now_pc <= now_pc;
        if (wb_pc)
            pc <= wb_pc_data;
        else
            pc <= pc;
    end

    // Normal Fetch
    else begin
        command <= data;
        now_pc <= mem_addr;
        pc <= pc + 32'd4;
    end
end

initial begin
    pc = 32'h80000000;
end

endmodule