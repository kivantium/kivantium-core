`default_nettype none

module top(
  input wire clk,
  input wire RsRx,
  output logic RsTx,
  input wire btnC,
  input wire btnU,
  output logic [6:0] seg,
  output logic [3:0] an,
  output logic [15:0] led
);

  cpu_top cpu(.clk(clk));
  
endmodule

`default_nettype wire