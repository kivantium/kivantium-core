`default_nettype none

module exeInteger(en, rs2exe, cdb);
  input wire en;
  input wire [79:0] rs2exe;
  output logic [37:0] cdb;

  logic [9:0] inst;
  logic [5:0] dest;
  logic [31:0] opr1, opr2, result;

  assign {inst, dest, opr1, opr2} = rs2exe;

  always_comb begin
    case(inst)
      // ADD, ADDI
      10'b0000000_000: result = opr1 + opr2;
      // SUB
      10'b0100000_000: result = opr1 - opr2;
      // SLL
      10'b0000000_001: result = opr1 << opr2[4:0];
      // SLT, SLTI
      10'b0000000_010: result = $signed(opr1) < $signed(opr2) ? 32'b1 : 32'b0;
      // SLTU, SLTIU
      10'b0000000_011: result = $unsigned(opr1) < $unsigned(opr2) ? 32'b1 : 32'b0;
      // XOR, XORI
      10'b0000000_100: result = opr1 ^ opr2;
      // SRL
      10'b0000000_101: result = $unsigned(opr1) >> opr2[4:0];
      // SRA
      10'b0100000_101: result = $signed(opr1) >> opr2[4:0];
      // OR, ORI
      10'b0000000_110: result = opr1 | opr2;
      // AND, ANDI
      10'b0000000_111: result = opr1 & opr2; 
      default: result = 32'bx;
    endcase
    if(en) cdb = {dest, result};
    else cdb = {6'd0, result};
  end
endmodule

`default_nettype wire