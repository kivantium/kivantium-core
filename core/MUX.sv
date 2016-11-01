module MUX #(parameter WIDTH = 8)(
  input  [WIDTH-1:0] in0, in1, 
  output logic [WIDTH-1:0] out,
  input sel
);
  assign out = sel ? in1 : in0; 
endmodule