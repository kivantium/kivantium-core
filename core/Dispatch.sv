`include "constants.vh"
`default_nettype none

module Dispatch(
  input wire clk, reset, kill, stall,
  input wire [65:0] decoded_inst0,
  input wire [31:0] decoded_inst0_pc,
  input wire [31:0] regdata1, regdata2,
  output logic [31:0] dispatched_pc,
  output logic [2:0] rs_destination,
  output logic [75:0] rs_integer,
  output logic [103:0] rs_loadstore,
  output logic [105:0] rs_branch,
  output logic [4:0] rs1, rs2
);

  logic [6:0] opcode;
  logic [4:0] rd, rs1, rs2, funct3;
  logic [6:0] funct7;
  logic [31:0] imm;
  assign {opcode, rd, rs1, rs2, funct3, funct7, imm} = decoded_inst0;
  

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
  
  always_ff @(posedge clk or negedge reset) begin
    if(reset == 1'b0) begin
      rs_integer <= 0;
      rs_loadstore <= 0;
      rs_branch <= 0;
    end else begin
      if(!stall) begin
        dispatched_pc <= decoded_inst0_pc;
        rs_integer <= {integer_aluop, integer_rd, integer_op1, integer_op2};
        rs_loadstore <= {loadstore_op, loadstore_width, loadstore_base, loadstore_imm,
                         loadstore_src, loadstore_dest};
        rs_branch <= {branch_op, branch_rd, branch_src1, branch_src2, branch_imm};
      end
    end
  end
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
      end
      `LOAD, `STORE: begin
        rs_destination <= `RS_LOAD_STORE;
        loadstore_width = funct3;
        loadstore_base = regdata1;
        loadstore_imm = imm;
        if(opcode == `LOAD) begin
          loadstore_op = 1'b0;
          loadstore_dest = rd;
        end else if(opcode == `STORE) begin
          loadstore_op = 1'b1;
          loadstore_src = regdata2;
        end        
      end
      `BRANCH, `JAL, `JALR: begin
        rs_destination <= `RS_BRANCH;
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