`default_nettype none

module Complete(
  input wire clk, kill, stall, 
  input wire [31:0] complete_data, 
  input wire [4:0] rd_complete,
  output logic complete_we
);

  always_comb begin
    if(!stall) complete_we = 1'b1;
    else complete_we = 1'b0;
  end
endmodule
`default_nettype wire