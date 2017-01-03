`default_nettype none

module BranchPrediction(
  input wire clk, reset, misprediction,
  input wire [31:0] current_pc, correct_pc,
  output logic [31:0] next_pc,
  output logic pred_taken
);
  
  assign pred_taken = 1'b0;
  always_comb begin
    if(!misprediction) next_pc = current_pc + 32'd4;
    else next_pc = correct_pc;
  end
endmodule
  
`default_nettype wire