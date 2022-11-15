module core (
    input reset,
    input stop,
    input clk,
    input [31:0] prog_mem_data,
    input [31:0] data_mem_data,

    output is_mem_write,
    output [2:0] funct3,
    output [31:0] write_data,
    output [31:0] prog_mem_addr,
    output [31:0] data_mem_addr
);

wire [4:0] rs1_addr;
wire [4:0] rs2_addr;

wire [31:0] wb_pc_data_f_ex;
wire [31:0] wb_pc_data_f_mem;

wire [4:0] id_ex_reg_d;
wire [4:0] ex_mem_reg_d;
wire [4:0] mem_wb_reg_d;

wire [4:0] ex_mem_mem_command;

wire [31:0] if_id_pc;
wire wb_pc_f_ex;
wire wb_pc_f_mem;

wire wb_pc_f_hazard_id_ex = ((id_ex_reg_d == rs1_addr) | 
    (id_ex_reg_d == rs2_addr)) & (id_ex_reg_d != 5'b0);
wire wb_pc_f_hazard_id_mem = (((ex_mem_reg_d == rs1_addr) |
    (ex_mem_reg_d == rs2_addr)) & (ex_mem_reg_d != 5'b0)) & (ex_mem_mem_command != 2'b00);
wire wb_pc_f_hazard = wb_pc_f_hazard_id_ex | wb_pc_f_hazard_id_mem;

wire wb_pc = wb_pc_f_ex | wb_pc_f_mem;
wire [31:0] wb_pc_data = wb_pc_f_mem ? wb_pc_data_f_mem : wb_pc_data_f_ex;

wire if_bubble = wb_pc | wb_pc_f_hazard;
wire id_bubble = wb_pc | wb_pc_f_hazard;
wire ex_bubble = wb_pc_f_mem;

wire is_write;
wire [4:0] wb_addr;
wire [31:0] wb_data;
wire [31:0] rs1_data_f_reg;
wire [31:0] rs2_data_f_reg;

reg_file reg_file(
    // INPUT
    .reset(reset), .clk(clk), .rs1_addr(rs1_addr), .rs2_addr(rs2_addr), .is_write(is_write),
    .wb_addr(wb_addr), .wb_data(wb_data),
    // OUTPUT
    .rs1_data(rs1_data_f_reg), .rs2_data(rs2_data_f_reg)
);

wire ex_mem_c_r = (ex_mem_reg_d != 5'b0) & (ex_mem_mem_command[1] == 1'b0);
wire ex_mem_c_r_rs1 = (ex_mem_reg_d == rs1_addr) & ex_mem_c_r;
wire ex_mem_c_r_rs2 = (ex_mem_reg_d == rs2_addr) & ex_mem_c_r;
wire mem_wb_c_r = (mem_wb_reg_d != 5'b0);
wire mem_wb_c_r_rs1 = (mem_wb_reg_d == rs1_addr) & mem_wb_c_r;
wire mem_wb_c_r_rs2 = (mem_wb_reg_d == rs2_addr) & mem_wb_c_r;
wire [31:0] command;
wire [31:0] alu_out;
wire [31:0] mem_wb_out;
wire [31:0] pre_wb_data = (ex_mem_mem_command[1:0] == 2'b01) ? data_mem_data : mem_wb_out;
wire [31:0] rs1_data = ex_mem_c_r_rs1 ? alu_out : (mem_wb_c_r_rs1 ? pre_wb_data : rs1_data_f_reg);
wire [31:0] rs2_data = ex_mem_c_r_rs2 ? alu_out : (mem_wb_c_r_rs2 ? pre_wb_data : rs2_data_f_reg);

reg [2:0] block_cnt;

always @(posedge clk) begin
    if (reset) block_cnt <= 0;
    else if (block_cnt != 4) block_cnt <= block_cnt + 1;
end

fetch fetch(
    // INPUT
    .reset(reset | (block_cnt < 1)), .clk(clk), .stop(stop), .bubble(if_bubble),
    .wb_pc(wb_pc), .wb_pc_data(wb_pc_data), .data(prog_mem_data),
    // OUTPUT
    .command(command), .mem_addr(prog_mem_addr), .now_pc(if_id_pc)
);

wire [4:0] id_ex_mem_command;
wire [5:0] ex_command;
wire [6:0] ex_command_f7;
wire [31:0] data_0;
wire [31:0] data_1;
wire [31:0] id_ex_mem_write_data;
wire [31:0] id_ex_pc;

decode decode(
    //INPUT
    .reset(reset | (block_cnt < 2)), .clk(clk), .stop(stop), .bubble(id_bubble), .rs1_data(rs1_data),
    .rs2_data(rs2_data), .in_now_pc(if_id_pc), .command(command),
    // OUTPUT
    .rs1_addr(rs1_addr), .rs2_addr(rs2_addr), .reg_d(id_ex_reg_d), 
    .mem_command(id_ex_mem_command), .ex_command(ex_command), 
    .ex_command_f7(ex_command_f7), .data_0(data_0), .data_1(data_1),
    .mem_write_data(id_ex_mem_write_data), .out_now_pc(id_ex_pc)
);

wire [31:0] ex_mem_mem_write_data;
wire [31:0] ex_mem_pc;
assign is_mem_write = (ex_mem_mem_command[1:0] == 2'b11) ? 1'b1 : 1'b0;
assign funct3 = ex_mem_mem_command[0] ? ex_mem_mem_command[4:2] : 3'b000;

execute execute(
    // INPUT
    .reset(reset | (block_cnt < 3)), .clk(clk), .stop(stop), .bubble(ex_bubble), .in_reg_d(id_ex_reg_d),
    .in_mem_command(id_ex_mem_command), .ex_command(ex_command),
    .ex_command_f7(ex_command_f7), .data_0(data_0), .data_1(data_1),
    .in_mem_write_data(id_ex_mem_write_data), .in_now_pc(id_ex_pc),
    // OUTPUT
    .wb_pc(wb_pc_f_ex),.out_mem_command(ex_mem_mem_command), 
    .out_reg_d(ex_mem_reg_d), .alu_out(alu_out),
    .out_mem_write_data(ex_mem_mem_write_data),
    .wb_pc_data(wb_pc_data_f_ex)
);

wire wb_csr;
wire [31:0] csr_data;
wire [31:0] csr_trap_vec_data;
wire [31:0] csr_exception_pc_data;
wire [11:0] csr_addr;
wire [11:0] write_csr_addr;
wire [31:0] out_csr_data;

memory_access memory_access(
    // INPUT
    .reset(reset | (block_cnt < 4)), .clk(clk), .stop(stop), .in_reg_d(ex_mem_reg_d), 
    .in_mem_command(ex_mem_mem_command), .in_alu_out(alu_out),
    .in_mem_write_data(ex_mem_mem_write_data),
    .csr_data(csr_data), .csr_trap_vec_data(csr_trap_vec_data),
    .csr_exception_pc_data(csr_exception_pc_data),
    // OUTPUT
    .csr_addr(csr_addr), .mem_addr(data_mem_addr), .wb_pc(wb_pc_f_mem), .wb_csr(wb_csr), .write_data(write_data),
    .out_csr_addr(write_csr_addr), .wb_pc_data(wb_pc_data_f_mem), .out_wb_data(mem_wb_out),
    .out_reg_d(mem_wb_reg_d), .out_csr_data(out_csr_data)
);

write_back write_back(
    // INPUT
    .reg_d(mem_wb_reg_d), .in_wb_data(pre_wb_data),
    // OUTPUT
    .is_write(is_write), .out_wb_addr(wb_addr), .out_wb_data(wb_data)
);

// CSR
csr csr(.reset(reset), .clk(clk), .wb_csr(wb_csr), .addr(csr_addr), .write_addr(write_csr_addr), .in_data(out_csr_data),
        .out_data(csr_data), .out_trap_vec(csr_trap_vec_data), .out_exception_pc(csr_exception_pc_data));


endmodule