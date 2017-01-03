`include "constants.vh"
`default_nettype none

module Dispatch(
  input wire clk, reset, stall,
  input wire [63:0] fetch_data,
  input wire [32:0] src_data1, src_data2,
  input wire [2:0] rs_is_full,
  input wire [5:0] rob_free_entry,
  input wire pred_taken, rob_is_full,
  output logic [4:0] src_reg1, src_reg2,
  output logic [2:0] rs_destination,
  output logic [75:0] rs_integer,
  output logic [139:0] rs_branch,
  output logic [107:0] rs_loadstore,
  output logic [5:0] rob_dest,
  output logic [40:0] rob_data,
  output logic notify_stall_dp, dp_to_rob
);

  logic [31:0] instruction, inst_pc;
  always_ff @(posedge clk or posedge reset) begin
    if(reset) begin
      instruction <= 32'b0; 
      inst_pc <= 32'b0;
      dp_to_rob <= 1'b0;
    end else if(!stall) begin
      inst_pc <= fetch_data[63:32];
      instruction <= fetch_data[31:0];
      dp_to_rob <= 1'b1; 
    end
  end
  
  assign rob_dest = rob_free_entry;
  logic [2:0] operation;
  logic [2:0] inst_type;
  logic [4:0] arf_dest;
  logic valid1, valid2;
  logic [31:0] operand1, operand2, offset;

  logic rs_dest_integer, rs_dest_branch, rs_dest_loadstore;
  assign rs_destination = {rs_dest_integer, rs_dest_branch, rs_dest_loadstore};

  // 4+6+1+32+1+32 = 76
  assign rs_integer = {operation, rob_dest, valid1, operand1, valid2, operand2};
  // 4+6+1+32+1+32+32+32 = 140
  assign rs_branch = {operation, rob_dest, valid1, operand1, valid2, operand2, inst_pc, offset};
  // 4+6+1+32+1+32+32 = 108
  assign rs_loadstore = {operation, rob_dest, valid1, operand1, valid2, operand2, offset};
  assign rob_data = {inst_type, inst_pc, arf_dest, pred_taken};
  
  logic rs_integer_is_full, rs_branch_is_full, rs_loadstore_is_full;
  assign rs_is_full = {rs_integer_is_full, rs_branch_is_full, rs_loadstore_is_full};
  always_comb begin
    case(instruction[6:0])
      `OP,  `OP_IMM, `LUI: begin
        if(rs_integer_is_full || rob_is_full) notify_stall_dp = 1'b1;
        else notify_stall_dp = 1'b0;
      end
      `BRANCH, `JAL, `JALR: begin
        if(rs_branch_is_full || rob_is_full) notify_stall_dp = 1'b1;
        else notify_stall_dp = 1'b0;
      end
      `LOAD, `STORE: begin
        if(rs_loadstore_is_full || rob_is_full) notify_stall_dp = 1'b1;
        else notify_stall_dp = 1'b0;
      end
      default: begin
        notify_stall_dp = 1'b0;
      end
    endcase
  end
  
  always_comb begin
    case(instruction[6:0])
      `OP: begin                    // R-type
        rs_dest_integer = 1'b1;
        rs_dest_branch = 1'b0;
        rs_dest_loadstore = 1'b0;
        src_reg1 = instruction[19:15];
        src_reg2 = instruction[24:20];
        arf_dest = instruction[11:7];
        operation = {instruction[14:12], instruction[30]};
        {valid1, operand1} = src_data1;
        {valid2, operand2} = src_data2;
        offset = 32'b0;
        inst_type = `INST_INTEGER;
      end
      `OP_IMM: begin         // I-type
        rs_dest_integer = 1'b1;
        rs_dest_branch = 1'b0;
        rs_dest_loadstore = 1'b0;
        src_reg1 = instruction[19:15];
        src_reg2 = 5'b00000;
        arf_dest = instruction[11:7];
        operation = {instruction[14:12], 1'b0};
        {valid1, operand1} = src_data1;
        {valid2, operand2} = {1'b1, {20{instruction[31]}}, instruction[31:20]};
        offset = 32'b0;
        inst_type = `INST_INTEGER;
       end  
      `LUI: begin                  // U-type
        rs_dest_integer = 1'b1;
        rs_dest_branch = 1'b0;
        rs_dest_loadstore = 1'b0;
        src_reg1 = 5'b00000;
        src_reg2 = 5'b00000;
        arf_dest = instruction[11:7];
        operation = 4'b0000;
        {valid1, operand1} = src_data1;
        {valid2, operand2} = {1'b1, instruction[31:12], 12'b0};
        offset = 32'b0;
        inst_type = `INST_INTEGER;
      end
      `BRANCH: begin                // SB-type
        rs_dest_integer = 1'b0;
        rs_dest_branch = 1'b1;
        rs_dest_loadstore = 1'b0;
        src_reg1 = instruction[19:15];
        src_reg2 = instruction[24:20];
        arf_dest = 5'b00000;
        operation = {1'b1, instruction[14:12]};
        {valid1, operand1} = src_data1;
        {valid2, operand2} = src_data2;
        offset = {{20{instruction[31]}}, instruction[7], instruction[30:25], instruction[11:8], 1'b0};
        inst_type = `INST_BRANCH;
      end
      `JAL: begin
        rs_dest_integer = 1'b0;
        rs_dest_branch = 1'b1;
        rs_dest_loadstore = 1'b0;
        src_reg1 = 5'b00000;
        src_reg2 = 5'b00000;
        arf_dest = instruction[11:7];
        operation = 4'b0000;
        {valid1, operand1} = src_data1;
        {valid2, operand2} = src_data2;
        offset = {{12{instruction[31]}}, instruction[19:12], instruction[20], instruction[30:21]};
        inst_type = `INST_BRANCH;
      end
      `JALR: begin
       rs_dest_integer = 1'b0;
       rs_dest_branch = 1'b1;
       rs_dest_loadstore = 1'b0;
       src_reg1 = instruction[19:15];
       src_reg2 = 5'b00000;
       arf_dest = instruction[11:7];
       operation = 4'b1100;
       {valid1, operand1} = src_data1;
       {valid2, operand2} = src_data2;
       offset = {{20{instruction[31]}}, instruction[31:20]};
       inst_type = `INST_BRANCH;
      end
      `LOAD: begin  // I-type
        rs_dest_integer = 1'b0;
        rs_dest_branch = 1'b0;
        rs_dest_loadstore = 1'b1;
        src_reg1 = instruction[19:15];
        src_reg2 = 5'b00000;
        arf_dest = instruction[11:7];
        operation = {1'b0, instruction[14:12]};
        {valid1, operand1} = src_data1;
        {valid2, operand2} = src_data2;
        offset = {{20{instruction[31]}}, instruction[31:20]};
        inst_type = `INST_LOAD_STORE;
      end
      `STORE: begin                 // S-type
        rs_dest_integer = 1'b0;
        rs_dest_branch = 1'b0;
        rs_dest_loadstore = 1'b1;
        src_reg1 = instruction[19:15];
        src_reg2 = instruction[24:20];
        arf_dest = 5'b00000;
        operation = {1'b1, instruction[14:12]};
        {valid1, operand1} = src_data1;
        {valid2, operand2} = src_data2;
        offset = {{20{instruction[31]}}, instruction[31:25], instruction[11:7]};
        inst_type = `INST_LOAD_STORE;
      end
      default: begin
        rs_dest_integer = 1'bx;
        rs_dest_branch = 1'bx;
        rs_dest_loadstore = 1'bx;
        src_reg1 = 5'bxxxxx;
        src_reg2 = 5'bxxxxx;
        arf_dest = 5'bxxxxx;
        operation = 4'bxxxx;
        {valid1, operand1} = src_data1;
        {valid2, operand2} = src_data2;
        offset = 32'bx;
        inst_type = `INST_INTEGER;
      end
    endcase
  end
endmodule

`default_nettype wire