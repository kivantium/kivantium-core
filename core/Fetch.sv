`default_nettype none
module Fetch(
  input wire clk, reset, stall,
  input wire [31:0] instruction, current_pc,
  output logic [63:0] fetch_data
);
  logic [31:0] fetched_pc;
  
  always_ff @(posedge clk or posedge reset) begin
    if(reset) fetched_pc <= 32'b0;
    else fetched_pc <= current_pc;
  end
  always_comb begin
    fetch_data = {fetched_pc, instruction};
  end
endmodule
`default_nettype wire
