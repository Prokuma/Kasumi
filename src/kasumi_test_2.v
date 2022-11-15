module kasumi_test_2;
localparam MAX_STEP = 10000;
reg reset;
reg reset_sys;
reg clk;
reg dram_clk;

reg [511:0] read_prog_data;
reg [511:0] read_data_data;
reg [7:0] read_prog_addr;
reg [7:0] read_data_addr;

reg is_write_prog_line;
reg is_write_data_line;

wire is_req_f_prog;
wire is_req_f_data;
wire [19:0] req_addr_f_prog;
wire [19:0] req_addr_f_data;

wire fifo_empty;
wire is_write_t_main;
wire [31:0] write_back_data;
wire [31:0] write_back_addr;

wire [31:0] prog_mem_addr;
wire [31:0] prog_mem_data;
wire [31:0] data_mem_addr;
wire [31:0] data_mem_data;

wire is_mem_write;
wire [2:0] funct3;
wire [31:0] write_data;
wire cache_miss;
wire is_writing_now;

wire test_fifo_data_empty;
wire test_fifo_prog_empty;
wire [7:0] test_fifo_addr_prog_fifo;
wire [7:0] test_fifo_addr_data_fifo;
wire t;
wire [5:0] fifo_start;
wire [5:0] fifo_end;
wire [511:0] test_a_dout;
wire [13:0] test_addr_0;

core core(
    // INPUT
    .reset(reset | reset_sys), .stop(cache_miss | is_req_f_prog | is_req_f_data | is_writing_now), 
    .clk(clk), .prog_mem_data(prog_mem_data), .data_mem_data(data_mem_data),

    // OUTPUT
    .is_mem_write(is_mem_write), .funct3(funct3), .write_data(write_data),
    .prog_mem_addr(prog_mem_addr), .data_mem_addr(data_mem_addr) 
);

cache cache(
    // INPUT
    .reset(reset | reset_sys),
    .cache_clk(clk), .main_clk(dram_clk), .is_write(is_mem_write), .is_write_t_main(is_write_t_main),
    .is_write_prog_line(is_write_prog_line), .is_write_data_line(is_write_data_line),
    .funct3(funct3), .write_data(write_data),
    .write_addr(data_mem_addr), .prog_mem_addr(prog_mem_addr), .data_mem_addr(data_mem_addr),
    .read_main_prog_data(read_prog_data), .read_main_data_data(read_data_data),
    .read_main_prog_addr(read_prog_addr), .read_main_data_addr(read_data_addr),

    // OUTPUT
    .cache_miss(cache_miss), .is_writing_now(is_writing_now),
    .prog_mem_data(prog_mem_data), .data_mem_data(data_mem_data),
    .is_req_f_prog(is_req_f_prog), .is_req_f_data(is_req_f_data), 
    .req_addr_f_prog(req_addr_f_prog), .req_addr_f_data(req_addr_f_data),
    .fifo_empty(fifo_empty), 
    .write_back_addr(write_back_addr), .write_back_data(write_back_data),

    .test_fifo_data_empty(test_fifo_data_empty), .test_fifo_prog_empty(test_fifo_prog_empty),
    .test_fifo_addr_data_fifo(test_fifo_addr_data_fifo), .test_fifo_addr_prog_fifo(test_fifo_addr_prog_fifo), .test_prog_read_clk(t),
    .test_fifo_start(fifo_start), .test_fifo_end(fifo_end), .test_a_dout(test_a_dout)
);

reg is_first_prog;
reg is_first_data;

always @(posedge dram_clk) begin
    if (is_req_f_prog & is_first_prog) begin
        is_write_prog_line <= 1;
        is_first_prog <= 0;
    end
    else if (is_req_f_prog & (read_prog_addr[5:0] != 63)) begin
        read_prog_addr[7:6] <= req_addr_f_prog[1:0];
        read_prog_addr[5:0] <= read_prog_addr[5:0] + 1;
        is_write_prog_line <= 1;
    end
    else if (~is_req_f_prog & (read_prog_addr[5:0] == 63)) begin
        read_prog_addr <= 0;
        is_write_prog_line <= 0;
        is_first_prog <= 1;
    end
    else if (read_prog_addr[5:0] == 63) is_write_prog_line <= 0;

    if (is_req_f_data & is_first_data) begin
        is_write_data_line <= 1;
        is_first_data <= 0;
    end
    else if (is_req_f_data & (read_data_addr[5:0] != 63)) begin
        read_data_addr[7:6] <= req_addr_f_data[1:0];
        read_data_addr[5:0] <= read_data_addr[5:0] + 1;
        is_write_data_line <= 1;
    end
    else if (~is_req_f_data & (read_data_addr[5:0] == 63)) begin
        read_data_addr <= 0;
        is_write_data_line <= 0;
        is_first_data <= 1;
    end
    else if (read_data_addr[5:0] == 63) is_write_data_line <= 0;

    read_prog_addr[7:6] <= req_addr_f_prog;
    read_data_addr[7:6] <= req_addr_f_data;
end

integer i;
initial begin
    $dumpfile("kasumi_test_2.vcd");
    $dumpvars(1, kasumi_test_2);

    clk = 0;
    dram_clk = 0;
    reset = 1;
    reset_sys = 0;
    read_prog_data = {32'h00002023, {14{32'h00000013}}, 32'h00002023};
    read_data_data = 512'b0;
    read_prog_addr = 8'b0;
    read_data_addr = 8'b0;
    is_first_prog = 1;
    is_first_data = 1;
    for(i = 0; i < MAX_STEP; i = i + 1) begin
        #1 clk = ~clk;
        #1 dram_clk = ~dram_clk;
        if (i == 0) reset = 0;
    end
    $finish;
end

endmodule