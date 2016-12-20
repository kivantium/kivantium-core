`default_nettype none
module Fetch(
  input wire clk, reset, kill, stall,
  input wire [31:0] nextpc,
  output logic [31:0] instruction0, inst0_pc
);
  
  logic [31:0] pc;
  
  InstCache icache(.clk(clk), .addr(pc), .inst0(instruction0));
  assign inst0_pc = pc;
  
  always_ff @(posedge clk or posedge reset) begin
    if(reset) begin
      pc <= 0;
    end else if(!stall) begin
      pc <= nextpc;
    end
  end
endmodule
`default_nettype wire
