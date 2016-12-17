`include "constants.vh"
`default_nettype none

module Decode(
  input wire clk, reset, kill, stall,
  input wire [31:0] instruction0, inst0_pc,
  output logic [65:0] decoded_inst0,
  output logic [31:0] decoded_inst0_pc
);

  logic [6:0] opcode;
  logic [4:0] rd, rs1, rs2, funct3;
  logic [6:0] funct7;
  logic [31:0] imm;

  always_ff @(posedge clk or negedge reset) begin
    if(reset == 1'b0) begin
      decoded_inst0 <= 32'b0;
      decoded_inst0_pc <= 32'b0;
    end else  if(!stall) begin
      decoded_inst0 <= {opcode, rd, rs1, rs2, funct3, funct7, imm};
      decoded_inst0_pc <= inst0_pc;
    end 
  end
  
  always_comb begin
    opcode = instruction0[6:0];
    case(instruction0[6:0])
      `LOAD: begin
        rd = instruction0[11:7];
        rs1 = instruction0[19:15];
        funct3 = instruction0[14:12];
        imm = {{20{instruction0[31]}}, instruction0[31:20]};
      end
      `OP_IMM: begin
        rd = instruction0[11:7];
        rs1 = instruction0[19:15];
        funct3 = instruction0[14:12];
        imm = {{20{instruction0[31]}}, instruction0[31:20]};  
      end
      `STORE: begin
        funct3 = instruction0[14:12];
        rs1 = instruction0[19:15];
        rs2 = instruction0[24:20];
        imm = {{20{instruction0[31]}}, instruction0[31:25], instruction0[11:7]};
      end
      `OP: begin
        rd = instruction0[11:7];
        rs1 = instruction0[19:15];
        rs2 = instruction0[24:20];
        funct3 = instruction0[14:12];
        funct7 = instruction0[31:25];
      end
      `BRANCH: begin
        funct3 = instruction0[14:12];
        rs1 = instruction0[19:15];
        rs2 = instruction0[24:20];
        imm = {{20{instruction0[31]}}, instruction0[7], instruction0[30:25], instruction0[11:8], 1'b0};
      end
      `JALR: begin // JALR
        rd = instruction0[11:7];
        funct3 = instruction0[14:12];
        rs1 = instruction0[19:15];
        imm = {{20{instruction0[31]}}, instruction0[31:20]};
      end
      `JAL: begin // JAL
        rd = instruction0[11:7];
        imm = {{12{instruction0[31]}}, instruction0[19:12], instruction0[20], instruction0[30:21]};
      end
      default: begin
        opcode = 7'b1111111;
      end
    endcase
  end
endmodule
`default_nettype wire