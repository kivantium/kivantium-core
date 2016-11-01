module ALU(
  input [31:0] in0,
  input [31:0] in1,
  input [5:0] shamt,
  input [3:0] op,
  output logic [31:0] out,
  output logic iszero
  );
  always_comb begin
    case(op)
      4'b0000: out = in0 & in1;
      4'b0001: out = in0 | in1;
      4'b0010: out = in0 + in1;
      4'b0100: out = in1 << shamt;
      4'b0101: out = in1 >> shamt;
      4'b0110: out = in0 - in1;
      4'b0111: out = (in0 < in1);
      4'b1100: out = ~(in0 | in1);
      default: out = 0;
    endcase
    if(out == 0) iszero = 1;
    else iszero = 0;
  end
endmodule      