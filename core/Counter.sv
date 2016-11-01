module Counter(
  input clk, reset,
  input [31:0] nextpc, 
  output logic [31:0] pc
);

  always_ff @(posedge clk, posedge reset) begin
    if (reset) pc <= 0;
    else       pc <= nextpc;
  end
endmodule
