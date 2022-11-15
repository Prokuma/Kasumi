module fetch (
    input reset,
    input clk,
    input stop,
    input bubble,
    input wb_pc,
    input [31:0] wb_pc_data,
    input [31:0] data,

    output [31:0] command,
    output reg [31:0] mem_addr,
    output reg [31:0] now_pc
);

reg is_nop;
assign command = is_nop ? 32'b0000000000000000000000000001001 : data;

always @(posedge clk) begin
    // Stop(pause) CPU
    if (stop) begin
        now_pc <= now_pc;
    end

    // Pipeline Bubble(addi x0, x0, 0)
    else if (bubble) begin
        now_pc <= now_pc;
        if (wb_pc)
            mem_addr <= wb_pc_data;
        else
            mem_addr <= mem_addr;
    end

    // Reset
    else if (reset) begin
        now_pc <= 32'b0;
        mem_addr <= 32'b0;
    end

    // Normal Fetch
    else begin
        now_pc <= mem_addr;
        mem_addr <= mem_addr + 32'd4;
    end

    is_nop <= (stop | bubble | reset);
end

endmodule