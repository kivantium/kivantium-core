`timescale 1ns / 100ps
`default_nettype none

module cpu_top(
  input wire clk, reset,
  output logic [31:0] current_pc
);
  
  logic stall_if, stall_dp;
  
  // Fetch
  logic [31:0] next_pc, correct_pc, instruction;
  logic [63:0] fetch_data;
  logic misprediction, pred_taken;
  
  ProgramCounter pc(.clk(clk), .reset(reset), .next_pc(next_pc), .current_pc(current_pc));
  InstructionMemory imem(.clk(clk), .current_pc(current_pc), .instruction(instruction));
  BranchPrediction branchpred(.clk(clk), .reset(reset), .current_pc(current_pc), .next_pc(next_pc), 
                              .misprediction(misprediction), .correct_pc(correct_pc), 
                              .pred_taken(pred_taken));
  Fetch ifetch(.clk(clk), .reset(reset), .stall(stall_if), 
               .instruction(instruction), .current_pc(current_pc), 
               .fetch_data(fetch_data));
  
  // Dispatch
  logic arf_busy1, arf_busy2, rob_valid1, rob_valid2;
  logic [4:0] src_reg1, src_reg2, complete_reg, dp_arf_dest;
  logic [5:0] arf_tag1, arf_tag2, rob_free_entry, dp_rob_dest;
  logic [31:0] arf_read_data1, arf_read_data2, rob_read_data1, rob_read_data2, complete_data;
  logic [32:0] src_data1, src_data2;
  logic arf_write_enable;
  logic [4:0] arf_write_reg;
  logic [31:0] arf_write_data;  
  logic consume_rrf, complete_we, execute_we;
  
  ARF arf(.clk(clk), .rob_free_entry(rob_free_entry), .dp_arf_dest(dp_arf_dest),
          .src_reg1(src_reg1), .arf_read_data1(arf_read_data1), .arf_busy1(arf_busy1), .arf_tag1(arf_tag1), 
          .src_reg2(src_reg2), .arf_read_data2(arf_read_data2), .arf_busy2(arf_busy2), .arf_tag2(arf_tag2),
          .arf_write_enable(arf_write_enable), .arf_write_reg(arf_write_reg),
          .arf_write_data(arf_write_data));
  
  logic [40:0] dp_rob_data;
  logic rob_is_full, notify_stall_dp;

  ReOrderBuffer rob(.clk(clk), .reset(reset), .rob_free_entry(rob_free_entry), .rob_is_full(rob_is_full),
                    .stall_dp(notify_stall_dp), .dp_rob_dest(dp_rob_dest), .dp_rob_data(dp_rob_data),
                    .read_entry1(arf_tag1), .rob_read_data1(rob_read_data1), .rob_valid1(rob_valid1),
                    .read_entry2(arf_tag2), .rob_read_data2(rob_read_data2), .rob_valid2(rob_valid2),
                    .cdb_integer(cdb_integer),
                    .arf_write_enable(arf_write_enable), .arf_write_reg(arf_write_reg), 
                    .arf_write_data(arf_write_data));
  
  SRC_MUX smux(.arf_read_data1(arf_read_data1), .arf_busy1(arf_busy1), .arf_tag1(arf_tag1), 
               .rob_read_data1(rob_read_data1), .rob_valid1(rob_valid1), .src_data1(src_data1),
               .arf_read_data2(arf_read_data2), .arf_busy2(arf_busy2), .arf_tag2(arf_tag2),  
               .rob_read_data2(rob_read_data2), .rob_valid2(rob_valid2), .src_data2(src_data2));
  logic [2:0] rs_is_full, rs_destination;
  logic rs_integer_is_full, rs_branch_is_full, rs_loadstore_is_full;
  logic rs_dest_integer, rs_dest_branch, rs_dest_loadstore;
  assign {rs_dest_integer, rs_dest_branch, rs_dest_loadstore} = rs_destination;
  assign rs_is_full = {rs_integer_is_full, rs_branch_is_full, rs_loadstore_is_full};
  
  logic [75:0] rs_integer;  
  logic [107:0] rs_loadstore;
  logic [139:0] rs_branch;
  
  Dispatch dp(.clk(clk), .reset(reset), .stall(stall_dp), .fetch_data(fetch_data),
               .src_reg1(src_reg1), .src_reg2(src_reg2), .src_data1(src_data1), .src_data2(src_data2),
               .rob_is_full(rob_is_full), .rob_free_entry(rob_free_entry), .pred_taken(pred_taken),
               .arf_dest(dp_arf_dest), .rob_dest(dp_rob_dest), .rob_data(dp_rob_data),
               .rs_is_full(rs_is_full), .notify_stall_dp(notify_stall_dp),
               .rs_destination(rs_destination),
               .rs_integer(rs_integer), .rs_branch(rs_branch), .rs_loadstore(rs_loadstore));
                   
  // temporary assignment
  assign stall_if = notify_stall_dp;
  assign stall_dp = notify_stall_dp;
  assign misprediction = 1'b0; // TODO: temporary
  
  logic [37:0] cdb_integer, cdb_branch, cdb_load_store;
  logic [31:0] dmem_read_addr, dmem_read_data;
  ExecInteger exec_int(.clk(clk), .reset(reset),  .rs_is_full(rs_integer_is_full),
             .rs_dest(rs_dest_integer), .rs_data(rs_integer), .cdb_data(cdb_integer));
  ExecBranch exec_br(.clk(clk), .reset(reset), .rs_is_full(rs_integer_is_full),
             .rs_dest(rs_dest_branch), .rs_data(rs_branch), .cdb_data(cdb_branch));
  ExecLoadStore exec_ls(.clk(clk), .reset(reset), .rs_is_full(rs_loadstore_is_full),
                .rs_dest(rs_dest_loadstore), .rs_data(rs_loadstore), .cdb_data(cdb_load_store),
                .dmem_read_addr(dmem_read_addr), .dmem_read_data(dmem_read_data));
  DataMemory dm(.clk(clk), .read_addr(dmem_read_addr), .read_data(dmem_read_data));
endmodule

`default_nettype wire
