`default_nettype none
module Controller(
  input wire clk, reset, notify_stall_dp,
  output logic stall_if, stall_dp
);
  
  logic [1:0] state;
  assign stall_if = notify_stall_dp;
  assign stall_dp = (state == 2'b01) ? 1'b0 : 1'b1;
  
  always_ff @(negedge clk or posedge reset) begin
    if(reset) state <= 2'b00;
    else begin
      if(state == 2'b00) state <= 2'b01;
    end
  end
endmodule
`default_nettype wire
