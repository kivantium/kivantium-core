`default_nettype none

module ExecInteger(
  input wire clk, reset, enable,
  input wire [72:0] rs,
  output logic [31:0] result,
  output logic finish,
  output logic [4:0] complete_rd
);
  
  logic [3:0] aluop;
  logic [4:0] rd;
  logic [31:0] op1, op2;
  
  assign {aluop, rd, op1, op2} = rs;
    
  always_comb begin
    complete_rd = rd;
    if(enable) begin
      case(aluop)
        // ADD, ADDI
        4'b0000: result = op1 + op2;
        // SUB
        4'b0001: result = op1 - op2;
        // SLL
        4'b0010: result = op1 << op2[4:0];
        // SLT, SLTI
        4'b0100: result = $signed(op1) < $signed(op2) ? 32'b1 : 32'b0;
        // SLTU, SLTIU
        4'b0110: result = $unsigned(op1) < $unsigned(op2) ? 32'b1 : 32'b0;
        // XOR, XORI
        4'b1000: result = op1 ^ op2;
        // SRL
        4'b1010: result = $unsigned(op1) >> op2[4:0];
        // SRA
        4'b1011: result = $signed(op1) >> op2[4:0];
        // OR, ORI
        4'b1100: result = op1 | op2;
        // AND, ANDI
        4'b1110: result = op1 & op2; 
      endcase
    end
  end
  
endmodule

`default_nettype wire