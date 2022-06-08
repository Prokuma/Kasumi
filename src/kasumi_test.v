module kasumi_test;
localparam MAX_STEP = 10000;
reg clk;
wire [31:0] prog_mem_addr;
wire [31:0] prog_mem_data;
wire [31:0] data_mem_addr;
wire [31:0] data_mem_data;

wire stop;
wire [4:0] rs1_addr;
wire [4:0] rs2_addr;
wire if_bubble = if_bubble_f_mem | if_bubble_f_exe | wb_pc;
wire id_bubble = id_bubble_f_mem | id_bubble_f_exe | wb_pc;
wire ex_bubble = ex_bubble_f_mem | wb_pc_f_mem;
wire wb_pc = wb_pc_f_ex | wb_pc_f_mem | wb_pc_f_hazard;
wire [31:0] wb_pc_data = 
wb_pc_f_mem ? wb_pc_data_f_mem : (
    wb_pc_f_ex ? wb_pc_data_f_ex : (
        wb_pc_f_hazard ? if_id_pc : 32'b0
    )
);

wire [31:0] wb_pc_data_f_ex;
wire [31:0] wb_pc_data_f_mem;

wire wb_pc_f_ex;
wire wb_pc_f_mem;
wire wb_pc_f_hazard = 
    wb_pc_f_hazard_id_ex | wb_pc_f_hazard_id_mem | wb_pc_f_hazard_id_wb;
wire wb_pc_f_hazard_id_ex = ((id_ex_reg_d == rs1_addr) | 
    (id_ex_reg_d == rs2_addr)) & (id_ex_reg_d != 5'b0);
wire wb_pc_f_hazard_id_mem = ((ex_mem_reg_d == rs1_addr) |
    (ex_mem_reg_d == rs2_addr)) & (ex_mem_reg_d != 5'b0);
wire wb_pc_f_hazard_id_wb = ((mem_wb_reg_d == rs1_addr) |
    (mem_wb_reg_d == rs2_addr)) & (mem_wb_reg_d != 5'b0);

wire is_write;
wire [4:0] wb_addr;
wire [31:0] wb_data;
wire [31:0] rs1_data;
wire [31:0] rs2_data;
wire [31:0] gp_data;

/*
reg_file reg_file(
    // INPUT
    .rs1_addr(rs1_addr), .rs2_addr(rs2_addr), .is_write(is_write),
    .wb_addr(wb_addr), .wb_data(wb_data),
    // OUTPUT
    .rs1_data(rs1_data), .rs2_data(rs2_data)
);
*/
reg_file_test reg_file_test(
    // INPUT
    .rs1_addr(rs1_addr), .rs2_addr(rs2_addr), .is_write(is_write),
    .wb_addr(wb_addr), .wb_data(wb_data),
    // OUTPUT
    .rs1_data(rs1_data), .rs2_data(rs2_data), .gp_data(gp_data)
);

wire [31:0] command;
wire [31:0] if_id_pc;

fetch fetch(
    // INPUT
    .clk(clk), .stop(stop), .bubble(if_bubble),
    .wb_pc(wb_pc), .wb_pc_data(wb_pc_data), .data(prog_mem_data),
    // OUTPUT
    .mem_addr(prog_mem_addr), .command(command), .now_pc(if_id_pc)
);

wire [4:0] id_ex_reg_d;
wire [4:0] id_ex_mem_command;
wire [5:0] ex_command;
wire [6:0] ex_command_f7;
wire [31:0] data_0;
wire [31:0] data_1;
wire [31:0] id_ex_mem_write_data;
wire [31:0] id_ex_pc;

decode decode(
    //INPUT
    .clk(clk), .stop(stop), .bubble(id_bubble), .rs1_data(rs1_data),
    .rs2_data(rs2_data), .in_now_pc(if_id_pc), .command(command),
    // OUTPUT
    .rs1_addr(rs1_addr), .rs2_addr(rs2_addr), .reg_d(id_ex_reg_d), 
    .mem_command(id_ex_mem_command), .ex_command(ex_command), 
    .ex_command_f7(ex_command_f7), .data_0(data_0), .data_1(data_1),
    .mem_write_data(id_ex_mem_write_data), .out_now_pc(id_ex_pc)
);

wire if_bubble_f_exe;
wire id_bubble_f_exe;
wire [4:0] ex_mem_mem_command;
wire [4:0] ex_mem_reg_d;
wire [31:0] alu_out;
wire [31:0] ex_mem_mem_write_data;
wire [31:0] ex_mem_pc;

execute execute(
    // INPUT
    .clk(clk), .stop(stop), .bubble(ex_bubble), .in_reg_d(id_ex_reg_d),
    .in_mem_command(id_ex_mem_command), .ex_command(ex_command),
    .ex_command_f7(ex_command_f7), .data_0(data_0), .data_1(data_1),
    .in_mem_write_data(id_ex_mem_write_data), .in_now_pc(id_ex_pc),
    // OUTPUT
    .if_bubble(if_bubble_f_exe), .id_bubble(id_bubble_f_exe), .wb_pc(wb_pc_f_ex),
    .out_mem_command(ex_mem_mem_command), .out_reg_d(ex_mem_reg_d), .alu_out(alu_out),
    .out_mem_write_data(ex_mem_mem_write_data), .out_now_pc(ex_mem_pc),
    .wb_pc_data(wb_pc_data_f_ex)
);

wire if_bubble_f_mem;
wire id_bubble_f_mem;
wire ex_bubble_f_mem;
wire is_mem_write;
wire wb_csr;
wire [31:0] mem_mem_wb_data;
wire [4:0] mem_wb_reg_d;
wire [31:0] mem_wb_pc;
wire [31:0] csr_data;
wire [31:0] csr_trap_vec_data;
wire [31:0] csr_exception_pc_data;
wire [11:0] csr_addr;
wire [11:0] write_csr_addr;
wire [31:0] out_csr_data;
wire [31:0] out_mem_addr;
wire [31:0] pre_wb_data;

memory_access memory_access(
    // INPUT
    .clk(clk), .stop(stop), .in_reg_d(ex_mem_reg_d), 
    .in_mem_command(ex_mem_mem_command), .in_alu_out(alu_out),
    .in_mem_write_data(ex_mem_mem_write_data), .in_now_pc(ex_mem_pc),
    .mem_data(data_mem_data), .csr_data(csr_data), .csr_trap_vec_data(csr_trap_vec_data),
    .csr_exception_pc_data(csr_exception_pc_data),
    // OUTPUT
    .csr_addr(csr_addr), .mem_addr(data_mem_addr), .is_mem_write(is_mem_write),
    .if_bubble(if_bubble_f_exe), .id_bubble(id_bubble_f_mem), .ex_bubble(ex_bubble_f_mem),
    .wb_pc(wb_pc_f_mem), .wb_csr(wb_csr),
    .out_csr_addr(write_csr_addr), .wb_pc_data(wb_pc_data_f_mem), .out_mem_addr(out_mem_addr),
    .out_mem_data(mem_mem_wb_data), .out_wb_data(pre_wb_data), .out_reg_d(mem_wb_reg_d), 
    .out_now_pc(mem_wb_pc), .out_csr_data(out_csr_data)
);

write_back write_back(
    // INPUT
    .clk(clk), .reg_d(mem_wb_reg_d), .in_wb_data(pre_wb_data), .now_pc(mem_wb_pc),
    // OUTPUT
    .is_write(is_write), .out_wb_addr(wb_addr), .out_wb_data(wb_data)
);

// CSR
csr csr(.wb_csr(wb_csr), .addr(csr_addr), .write_addr(write_csr_addr), .in_data(out_csr_data),
        .out_data(csr_data), .out_trap_vec(csr_trap_vec_data), .out_exception_pc(csr_exception_pc_data));

// TEST MEM
wire [7:0] tohost;
wire is_wb_prog_mem_avaliable = (prog_mem_addr != data_mem_addr);

test_mem prog_mem(.is_mem_write(is_wb_prog_mem_avaliable & is_mem_write), .addr(prog_mem_addr), .write_addr(out_mem_addr), .in_data(mem_mem_wb_data), .data(prog_mem_data), .tohost());
test_mem data_mem(.is_mem_write(is_mem_write), .addr(data_mem_addr), .in_data(mem_mem_wb_data), .write_addr(out_mem_addr), .data(data_mem_data), .tohost(tohost));

integer i;
initial begin
    $dumpfile("kasumi_test.vcd");
    $dumpvars(1, kasumi_test);

    clk = 0;
    for(i = 0; i < MAX_STEP; i = i + 1) begin
        #1 clk = ~clk;
    end
    $finish;
end

endmodule