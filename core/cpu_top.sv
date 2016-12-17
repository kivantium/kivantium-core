`timescale 1ns / 1ps
`default_nettype none

module cpu_top(
  input wire clk, reset
);
  
  // Fetch
  logic kill_fc, stall_fc;
  logic [31:0] nextpc;
  logic [31:0] instruction0, inst0_pc;
  logic fetch_ready;
  Fetch fc(.clk(clk), .reset(reset), .kill(kill_fc), .stall(stall_fc), .nextpc(nextpc),
            .instruction0(instruction0), .inst0_pc(inst0_pc), .fetch_ready(fetch_ready));
  
  // Decode
  logic kill_dc, stall_dc;
  logic [65:0] decoded_inst0;
  logic [31:0] decoded_inst0_pc;
  Decode dc(.clk(clk), .reset(reset), .kill(kill_dc), .stall(stall_dc),
            .instruction0(instruction0), .inst0_pc(inst0_pc),
            .decoded_inst0(decoded_inst0), .decoded_inst0_pc(decoded_inst0_pc));
  
  // Dispatch
  logic kill_dp, stall_dp;
  logic [31:0] dispatched_pc;
  logic [2:0] rs_destination;
  logic [75:0] rs_integer;
  logic [103:0] rs_loadstore;
  logic [105:0] rs_branch;
  logic [4:0] dp_rs1, dp_rs2;
  Dispatch dp(.clk(clk), .reset(reset), .kill(kill_dp), .stall(stall_dp),
              .decoded_inst0(decoded_inst0), .decoded_inst0_pc(decoded_inst0_pc),
              .dispatched_pc(dispatched_pc),
              .rs_destination(rs_destination), .rs_integer(rs_integer), .rs_loadstore(rs_loadstore),
              .rs_branch(rs_branch),
              .rs1(dp_rs1), .rs2(dp_rs2), .regdata1(regdata1), .regdata2(regdata2));
  logic [31:0] regdata1, regdata2;
  
  logic [4:0] complete_rd;
  logic [31:0] complete_data;
  logic complete_we;
  
  Register rf(.clk(clk), .reset(reset), .readaddr1(dp_rs1), .readaddr2(dp_rs2),
              .readdata1(regdata1), .readdata2(regdata2),
              .writeaddr(complete_rd), .writedata(complete_data), .reg_we(complete_we));
  // Execute
  logic kill_ex, stall_ex;
  logic finish_ex;
  logic [31:0] memread_addr, memread_data, memwrite_addr, memwrite_data;
  logic memwrite_enable;
  logic [31:0] load_data, complete_data;
  logic [4:0] complete_rd;
  
  Execute ex(.clk(clk), .reset(reset), .kill(kill_ex), .stall(stall_ex), .finish_ex(finish_ex),
             .dispatched_pc(dispatched_pc), .nextpc(nextpc),
             .rs_destination(rs_destination), .rs_integer(rs_integer), .rs_loadstore(rs_loadstore),
             .rs_branch(rs_branch), .memread_data(memread_data), .memread_addr(memread_addr),
             .memwrite_addr(memwrite_addr), .memwrite_data(memwrite_data), 
             .memwrite_enable(memwrite_enable), .load_data(load_data),
             .complete_data(complete_data), .complete_rd(complete_rd));
    
  DataCache dcache(.clk(clk), .readaddr(memread_addr), .readdata(memread_data), 
                   .we(memwrite_enable), .writeaddr(memwrite_addr), .writedata(memwrite_data));
  // Complete
  logic kill_cp, stall_cp;
  Complete cp(.clk(clk), .kill(kill_cp), .stall(stall_cp), 
              .complete_data(complete_data), .complete_rd(complete_rd), .complete_we(complete_we));
    
  logic [4:0] stalls; 
  Controller ctrl(.clk(clk), .fetch_ready(fetch_ready), .stalls(stalls), .finish_ex(finish_ex));
  assign {stall_fc, stall_dc, stall_dp, stall_ex, stall_cp} = stalls;
    
endmodule
`default_nettype wire