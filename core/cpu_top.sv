`default_nettype none

module cpu_top(clk, reset, led);
  input wire clk, reset;
  output logic [15:0] led;
  
  logic stall;
  logic mispred, misload;
  logic signal_miss;
  logic [31:0] commit_pc;
  logic [31:0] nextpc;
  logic [31:0] if_pc, if_inst;        // fetch signals
  logic [31:0] dc_pc, dc_inst;        // dispatch signals
  logic [5:0] dc_src1, dc_src2;       // integer register tag
  logic [32:0] arf_data1, arf_data2;  // ARF data
  logic [32:0] rob_data1, rob_data2;  // RRF (@ ROB) data
  logic [32:0] src_data1, src_data2;  // source data
  logic [5:0] arf_tag1, arf_tag2;     // register tag
  logic [5:0] dc_rd;               // register destination
  logic [5:0] rob_free_entry;
  logic arf_we;                       // register write enable
  logic [5:0] commit_dest;            // commit destination
  logic [31:0] commit_data;           // commit data
  logic [5:0] commit_tag;
  logic [3:0] rs_dest;                // reservation station destination
  logic rs_int_we, rs_bj_we, rs_ls_we, rs_flt_we;
  logic rs_int_is_full, rs_bj_is_full, rs_ls_is_full;
  logic [113:0] dc2rs;
  logic [38:0] dc2rob;
  logic ex_int_en, ex_bj_en, ex_load_en, ex_store_en, loadbuf_en;
  logic [79:0] rs2exe_int;
  logic [111:0] rs2exe_bj;
  logic [104:0] rs2exe_ls;
  logic [37:0] cdb_int, cdb_bj, cdb_ls;
  logic [38:0] jump_addr;
  logic [69:0] store2rob;
  logic dmem_we;
  logic [31:0] dmem_read_addr, dmem_read_data, dmem_write_addr, dmem_write_data;
  logic [63:0] loadunit2buf;
  logic [2:0] loadbuf_free_entry, loadbuf_commit_entry;
  
  assign led = if_pc[15:0];
  
  fetch fc(
    .clk(clk),
    .reset(reset),
    .stall(stall),
    .pc(if_pc),
    .nextpc(nextpc),
    .mispred(signal_miss),
    .commit_pc(commit_pc)
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
    .kill(signal_miss),
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
    .rd_reg(dc_rd),
    .dest_rob(rob_free_entry),
    .src_data1(src_data1),
    .src_data2(src_data2),
    .dc2rob(dc2rob),
    .dc2rs(dc2rs),
    .rs_dest(rs_dest)
  );
  
  registerFile arf(
    .clk(clk),
    .reset(reset),
    .mispred(signal_miss),
    .read_reg1(dc_src1),
    .read_reg2(dc_src2), 
    .read_data1(arf_data1),
    .read_data2(arf_data2),
    .read_tag1(arf_tag1),
    .read_tag2(arf_tag2),
    .dc_rd(dc_rd),
    .rob_free_entry(rob_free_entry),
    .we(arf_we),
    .write_reg(commit_dest),
    .write_tag(commit_tag),
    .write_data(commit_data)
  );
  
  srcSelect srcsel(
    .arf_data1(arf_data1),
    .arf_data2(arf_data2),
    .arf_tag1(arf_tag1),
    .arf_tag2(arf_tag2),
    .rob_data1(rob_data1),
    .rob_data2(rob_data2),
    .src_data1(src_data1),
    .src_data2(src_data2),
    .cdb1(cdb_int),
    .cdb2(cdb_bj),
    .cdb3(cdb_ls)
  );
  assign {rs_int_we, rs_bj_we, rs_ls_we, rs_flt_we} = rs_dest;
  
  controller ctrl(
    .rs_dest(rs_dest),
    .rs_int_is_full(rs_int_is_full),
    .rs_bj_is_full(rs_bj_is_full),
    .rs_ls_is_full(rs_ls_is_full),
    .stall(stall),
    .mispred(mispred),
    .misload(misload),
    .signal_miss(signal_miss)
  );
  
  rsInteger rs_int(
    .clk(clk),
    .reset(reset),
    .we(rs_int_we),
    .kill(signal_miss),
    .is_full(rs_int_is_full),
    .dc2rs(dc2rs),
    .rs2exe(rs2exe_int),
    .ex_en(ex_int_en),
    .cdb1(cdb_int),
    .cdb2(cdb_bj),
    .cdb3(cdb_ls)
  );
  
  rsBranchJump rs_bj(
    .clk(clk),
    .reset(reset),
    .we(rs_bj_we),
    .kill(signal_miss),
    .is_full(rs_bj_is_full),
    .dc2rs(dc2rs),
    .rs2exe(rs2exe_bj),
    .ex_en(ex_bj_en),
    .cdb1(cdb_int),
    .cdb2(cdb_bj),
    .cdb3(cdb_ls)
  );
  
  exeInteger ex_int(
    .en(ex_int_en),
    .rs2exe(rs2exe_int),
    .cdb(cdb_int)
  );
  
  exeBranchJump ex_bj(
    .en(ex_bj_en),
    .rs2exe(rs2exe_bj),
    .cdb(cdb_bj),
    .jump_addr(jump_addr)
  );
  
  rsLoadStore rs_ls(
    .clk(clk),
    .reset(reset),
    .we(rs_ls_we),
    .kill(signal_miss),
    .is_full(rs_ls_is_full),
    .dc2rs(dc2rs),
    .rs2exe(rs2exe_ls),
    .load_en(ex_load_en),
    .store_en(ex_store_en),
    .cdb1(cdb_int),
    .cdb2(cdb_bj),
    .cdb3(cdb_ls)
  );
  
  exeLoadUnit ex_load(
    .clk(clk),
    .reset(reset),
    .enable(ex_load_en),
    .rs2exe(rs2exe_ls),
    .load_addr(dmem_read_addr),
    .load_data(dmem_read_data),
    .dmem_write_addr(dmem_write_addr),
    .dmem_write_data(dmem_write_data),
    .en_loadbuf(loadbuf_en),
    .loadunit2buf(loadunit2buf),
    .cdb(cdb_ls)
  );
    
  exeStoreUnit ex_store(
    .clk(clk),
    .reset(reset),
    .en(ex_store_en),
    .rs2exe(rs2exe_ls),
    .store2rob(store2rob)
  );
    
  loadBuffer loadbuf(
    .clk(clk),
    .reset(reset), 
    .kill(signal_miss),
    .en(loadbuf_en),
    .misload(misload),
    .unit2buf(loadunit2buf),
    .free_entry(loadbuf_free_entry),
    .commit_entry(loadbuf_commit_entry),
    .is_storing(dmem_we),
    .store_addr(dmem_write_addr),
    .store_data(dmem_write_data)
  );
  
  dataMemory dmem(
    .clk(clk),
    .reset(reset),
    .we(dmem_we),
    .read_addr(dmem_read_addr),
    .read_data(dmem_read_data),
    .write_addr(dmem_write_addr),
    .write_data(dmem_write_data),
    .stdout()
  );
  
  reorderBuffer rob(
    .clk(clk),
    .reset(reset),
    .stall(stall),
    .kill(signal_miss),
    .tag1(arf_tag1),
    .tag2(arf_tag2),
    .arf_dest(dc_rd),
    .read_data1(rob_data1),
    .read_data2(rob_data2),
    .dc2rob(dc2rob),
    .free_entry(rob_free_entry),
    .commit_dest(commit_dest),
    .commit_tag(commit_tag),
    .commit_data(commit_data),
    .commit_we(arf_we),
    .cdb1(cdb_int),
    .cdb2(cdb_bj),
    .cdb3(cdb_ls),
    .jump_addr(jump_addr),
    .mispred(mispred),
    .commit_pc(commit_pc),
    .store2rob(store2rob),
    .loadbuf_en(loadbuf_en),
    .loadbuf_free_entry(loadbuf_free_entry),
    .loadbuf_commit_entry(loadbuf_commit_entry),
    .dmem_we(dmem_we),
    .store_addr(dmem_write_addr),
    .store_data(dmem_write_data),
    .misload(misload)
  );

endmodule
`default_nettype wire