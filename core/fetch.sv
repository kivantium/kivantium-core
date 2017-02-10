`default_nettype none

module fetch(clk, reset, stall, pc, nextpc);
  input wire clk, reset, stall;
  output logic [31:0] pc, nextpc;

  always_ff @(posedge clk) begin
    if(reset) begin
      nextpc <= 32'd4;
      pc <= 32'd0;
    end else if(!stall) begin
      pc <= nextpc;
      nextpc <= nextpc + 32'd4;
    end
  end
endmodule
`default_nettype wire