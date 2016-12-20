`include "constants.vh"
`default_nettype none

module Dispatch(
  input wire clk, reset, kill, stall,
  input wire [63:0] decoded_inst0,
  input wire [31:0] decoded_inst0_pc,
  input wire [31:0] regdata1, regdata2,
  output logic [31:0] dispatched_pc,
  output logic [2:0] rs_destination,
  output logic [72:0] rs_integer,
  output logic [104:0] rs_loadstore,
  output logic [105:0] rs_branch,
  output logic [4:0] rs1, rs2
);

  logic [63:0] instruction0;
  
  logic [3:0] integer_aluop;
  logic [4:0] integer_rd;
  logic [31:0] integer_op1, integer_op2;
  
  logic loadstore_op;
  logic [2:0] loadstore_width;
  logic [31:0] loadstore_base, loadstore_imm;
  logic [31:0] loadstore_src;
  logic [4:0] loadstore_dest;
  
  logic [4:0] branch_op;
  logic [4:0] branch_rd;
  logic [31:0] branch_src1, branch_src2;
  logic [31:0] branch_imm;
  
  assign dispatched_pc = decoded_inst0_pc;
  assign rs_integer = {integer_aluop, integer_rd, integer_op1, integer_op2}; //4+5+32+32 = 73bit 
  assign rs_loadstore = {loadstore_op, loadstore_width, loadstore_base, loadstore_imm,
                   loadstore_src, loadstore_dest}; // 1+3+32+32+32+5 = 105
  assign rs_branch = {branch_op, branch_rd, branch_src1, branch_src2, branch_imm}; // 5+5+32+32+32 = 106

  always_ff @(posedge clk or posedge reset) begin
    if(reset) begin
      instruction0 <= 64'b0;
    end else begin
      if(!stall) instruction0 <= decoded_inst0;
    end
  end
  
  logic [6:0] opcode;
  logic [4:0] rd;
  logic [2:0] funct3;
  logic [6:0] funct7;
  logic [31:0] imm;

  assign {opcode, rd, rs1, rs2, funct3, funct7, imm} = instruction0;
  
  // integer_rs
  always_comb begin
    case(opcode)
      `OP, `OP_IMM: begin
        rs_destination = `RS_INTEGER;
        integer_rd = rd;
        integer_op1 = regdata1;
        integer_aluop[3:1] = funct3;
        if(opcode==`OP) begin
          integer_aluop[0] = funct7[5];
          integer_op2 = regdata2;
        end else if(opcode == `OP_IMM) begin
          integer_aluop[0] = 1'b0;
          integer_op2 = imm;
        end
        loadstore_width = 3'b000;
        loadstore_base = 32'b0;
        loadstore_imm = 32'b0;
        loadstore_op = 1'b0;
        loadstore_dest = 5'b0;
        loadstore_op = 1'b0;
        loadstore_src = 32'b0;
        branch_rd = 5'b0;
        branch_op = 32'b0;
        branch_src1 = 32'b0;
        branch_src2 = 32'b0;
        branch_imm = 32'b0;
      end
      `LUI: begin
        rs_destination = `RS_INTEGER;
        integer_aluop = 4'b0;
        integer_rd = rd;
        integer_op1 = 32'b0;
        integer_op2 = imm;
        loadstore_width = 3'b000;
        loadstore_base = 32'b0;
        loadstore_imm = 32'b0;
        loadstore_op = 1'b0;
        loadstore_dest = 5'b0;
        loadstore_op = 1'b0;
        loadstore_src = 32'b0;
        branch_rd = 5'b0;
        branch_op = 32'b0;
        branch_src1 = 32'b0;
        branch_src2 = 32'b0;
        branch_imm = 32'b0;
      end
      `LOAD, `STORE: begin
        rs_destination = `RS_LOAD_STORE;
        integer_aluop = 4'b0000;
        integer_rd = 5'b00000;
        integer_op1 = 32'b0;
        integer_op2 = 32'b0;
        branch_rd = 5'b0;
        branch_op = 32'b0;
        branch_src1 = 32'b0;
        branch_src2 = 32'b0;
        branch_imm = 32'b0;

        loadstore_width = funct3;
        loadstore_base = regdata1;
        loadstore_imm = imm;
        if(opcode == `LOAD) begin
          loadstore_op = 1'b0;
          loadstore_dest = rd;
          loadstore_src = 32'bx;
        end else if(opcode == `STORE) begin
          loadstore_op = 1'b1;
          loadstore_dest = 5'bx;
          loadstore_src = regdata2;
        end        
      end
      `BRANCH, `JAL, `JALR: begin
        rs_destination = `RS_BRANCH;

        integer_aluop = 4'b0000;
        integer_rd = 5'b00000;
        integer_op1 = 32'b0;
        integer_op2 = 32'b0;

        loadstore_width = 3'b000;
        loadstore_base = 32'b0;
        loadstore_imm = 32'b0;
        loadstore_op = 1'b0;
        loadstore_dest = 5'b0;
        loadstore_op = 1'b0;
        loadstore_src = 32'b0;

        if(opcode == `JAL) begin
          branch_op = 5'b10000;
          branch_rd = rd;
          branch_imm = imm;
        end else if(opcode == `JALR) begin
          branch_op = 5'b11000;
          branch_rd = rd;
          branch_src1 = regdata1;
          branch_imm = imm;
        end else if(opcode == `BRANCH) begin
          branch_rd = 5'b0;
          branch_op = {2'b00, funct3};
          branch_src1 = regdata1;
          branch_src2 = regdata2;
          branch_imm = imm;
        end 
      end
    endcase
  end
endmodule
`default_nettype wire