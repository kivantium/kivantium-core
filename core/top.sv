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

  logic reset;
  logic [31:0] pc;
  cpu_top cpu(.clk(clk), .reset(reset), .current_pc(pc));
  
  assign led = pc[15:0];
  
  always_ff @(posedge clk) begin
    if (RsRx) reset = 1'b1;
  end
    
endmodule

`default_nettype wire