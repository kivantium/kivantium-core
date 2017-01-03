`default_nettype none

module BranchPred(
  input wire clk,
  input wire [31:0] pc,
  output logic [31:0] nextpc
);
  always_ff @(posedge clk) begin
    nextpc <= pc + 8;
  end
endmodule

`default_nettype wire