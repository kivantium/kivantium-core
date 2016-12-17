`default_nettype none
module Fetch(
  input wire clk, reset, kill, stall,
  input wire [31:0] nextpc,
  output logic [31:0] instruction0, inst0_pc,
  output logic fetch_ready
);
  
  logic [31:0] pc;
  logic [31:0] next_inst0;
  
  InstCache icache(.clk(clk), .addr(pc), .inst0(next_inst0));
  
  always_ff @(posedge clk or negedge reset) begin
    if(reset) begin
      pc <= 0;
      fetch_ready <= 1'b0;
    end else if(!stall) begin
      if(fetch_ready) begin 
        pc <= nextpc;
        fetch_ready <= 1'b0;
      end else begin
        instruction0 <= next_inst0;
        inst0_pc <= pc;
        fetch_ready <= 1'b1;
      end
    end
  end
endmodule
`default_nettype wire
