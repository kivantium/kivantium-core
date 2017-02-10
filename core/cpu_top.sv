`default_nettype none

module cpu_top(clk, reset);
  input wire clk, reset;
  
  logic stall;
  logic [31:0] nextpc;
  logic [31:0] if_pc, if_inst;        // fetch signals
  logic [31:0] dc_pc, dc_inst;        // dispatch signals
  logic [5:0] dc_src1, dc_src2;       // integer register tag
  logic [32:0] arf_data1, arf_data2;  // ARF data
  logic [32:0] rob_data1, rob_data2;  // RRF (@ ROB) data
  logic [32:0] src_data1, src_data2;  // source data
  logic [5:0] arf_tag1, arf_tag2;     // register tag
  logic [5:0] dp_rd;               // register destination
  logic [5:0] rob_free_entry;
  logic arf_we;                       // register write enable
  logic [5:0] commit_dest;            // commit destination
  logic [31:0] commit_data;           // commit data
  logic [3:0] rs_dest;                // reservation station destination
  logic rs_int_we, rs_bj_we, rs_ls_we, rs_flt_we;
  logic rs_int_is_full;
  logic [111:0] dp2rs;
  logic [38:0] dp2rob;
  logic ex_int_en;
  logic [71:0] rs2exe_int;
  logic [37:0] cdb_int;
 
  fetch fc(
    .clk(clk),
    .reset(reset),
    .stall(stall),
    .pc(if_pc),
    .nextpc(nextpc)
  );
  
  instMemory imem(
    .clk(clk),
    .reset(reset),
    .addr(nextpc),
    .inst(if_inst)
  );
  
  pipeifdc ifdc_reg(
    .clk(clk),
    .reset(reset),
    .if_pc(if_pc),
    .if_inst(if_inst),
    .dc_pc(dc_pc),
    .dc_inst(dc_inst)
  );
  
  decode dc_stage(
    .pc(dc_pc),
    .inst(dc_inst),
    .src_reg1(dc_src1),
    .src_reg2(dc_src2),
    .rd_reg(dp_rd),
    .dest_rob(rob_free_entry),
    .src_data1(src_data1),
    .src_data2(src_data2),
    .dp2rob(dp2rob),
    .dp2rs(dp2rs),
    .rs_dest(rs_dest)
  );
  
  registerFile arf(
    .clk(clk),
    .reset(reset),
    .read_reg1(dc_src1),
    .read_reg2(dc_src2), 
    .read_data1(arf_data1),
    .read_data2(arf_data2),
    .read_tag1(arf_tag1),
    .read_tag2(arf_tag2),
    .dp_rd(dp_rd),
    .rob_free_entry(rob_free_entry)
  );
  
  srcSelect srcsel(
    .arf_data1(arf_data1),
    .arf_data2(arf_data2),
    .arf_tag1(arf_tag1),
    .arf_tag2(arf_tag2),
    .rob_data1(rob_data1),
    .rob_data2(rob_data2),
    .src_data1(src_data1),
    .src_data2(src_data2)
  );
  assign {rs_int_we, rs_bj_we, rs_ls_we, rs_flt_we} = rs_dest;
  
  controller ctrl(
    .rs_dest(rs_dest),
    .rs_int_is_full(rs_int_is_full),
    .stall(stall)
  );
  
  rsInteger rs_int(
    .clk(clk),
    .reset(reset),
    .we(rs_int_we),
    .is_full(rs_int_is_full),
    .dp2rs(dp2rs),
    .rs2exe(rs2exe_int),
    .ex_en(ex_int_en),
    .cdb1(cdb_int)
  );
  
  exeInteger ex_int(
    .en(ex_int_en),
    .rs2exe(rs2exe_int),
    .cdb(cdb_int)
  );
  
  reorderBuffer rob(
    .clk(clk),
    .reset(reset),
    .stall(stall),
    .tag1(arf_tag1),
    .tag2(arf_tag2),
    .arf_dest(dp_rd),
    .read_data1(rob_data1),
    .read_data2(rob_data2),
    .dp2rob(dp2rob),
    .free_entry(rob_free_entry),
    .commit_dest(commit_dest),
    .commit_data(commit_data),
    .commit_we(arf_we),
    .cdb_int(cdb_int)
  );
endmodule
`default_nettype wire