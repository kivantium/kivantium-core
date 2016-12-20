`include "constants.vh"
`default_nettype none

module Decode(
  input wire clk, reset, kill, stall,
  input wire [31:0] fetched_inst0, fetched_inst0_pc,
  output logic [63:0] decoded_inst0,
  output logic [31:0] decoded_inst0_pc
);

  logic [6:0] opcode;
  logic [4:0] rd, rs1, rs2;
  logic [2:0] funct3;
  logic [6:0] funct7;
  logic [31:0] imm;
  
 logic [31:0] instruction0, inst0_pc;
 
  assign decoded_inst0 = {opcode, rd, rs1, rs2, funct3, funct7, imm};
  assign decoded_inst0_pc = inst0_pc;
 
  always_ff @(posedge clk or posedge reset) begin
    if(reset) begin
      instruction0 <= 32'b0; 
      inst0_pc <= 32'b0; 
    end else  if(!stall) begin
      instruction0 <= fetched_inst0; 
      inst0_pc <= fetched_inst0_pc; 
    end 
  end
  
  always_comb begin
    opcode = instruction0[6:0];
    case(instruction0[6:0])
      `OP: begin                    // R-type
        rd = instruction0[11:7];
        funct3 = instruction0[14:12];
        rs1 = instruction0[19:15];
        rs2 = instruction0[24:20];
        funct7 = instruction0[31:25];
        imm = 32'bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx;
      end
      `LOAD, `OP_IMM, `JALR: begin  // I-type
        rd = instruction0[11:7];
        funct3 = instruction0[14:12];
        rs1 = instruction0[19:15];
        rs2 = 5'b00000;
        funct7 = 7'b0000000;
        imm = {{20{instruction0[31]}}, instruction0[31:20]};
      end
      `STORE: begin                 // S-type
        funct3 = instruction0[14:12];
        rs1 = instruction0[19:15];
        rs2 = instruction0[24:20];
        imm = {{20{instruction0[31]}}, instruction0[31:25], instruction0[11:7]};
        funct7 = 7'b0000000;
        rd = 5'b00000;
      end
      `BRANCH: begin                // SB-type
        funct3 = instruction0[14:12];
        rs1 = instruction0[19:15];
        rs2 = instruction0[24:20];
        imm = {{20{instruction0[31]}}, instruction0[7], instruction0[30:25], instruction0[11:8], 1'b0};
        funct7 = 7'bxxxxxxx;
        rd = 5'bxxxxx;
      end
      `LUI: begin                  // U-type
        rd = instruction0[11:7];
        imm = {instruction0[31:12], 12'b0};
        funct3 = 3'bx;
        rs1 = 5'bx;
        rs2 = 5'bx;
        funct7 = 7'bx;
      end
      `JAL: begin                  // UJ-type
        rd = instruction0[11:7];
        imm = {{12{instruction0[31]}}, instruction0[19:12], instruction0[20], instruction0[30:21]};
        funct3 = 3'bx;
        rs1 = 5'bx;
        rs2 = 5'bx;
        funct7 = 7'bx;
      end
      default: begin
        rd = 5'bx;
        funct3 = 3'bx;
        rs1 = 5'bx;
        rs2 = 5'bx;
        funct7 = 7'bx;
        imm = 32'bx;
      end
    endcase
  end
endmodule
`default_nettype wire