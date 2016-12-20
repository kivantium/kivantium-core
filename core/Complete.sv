`default_nettype none

module Complete(
  input wire clk, kill, stall, 
  input wire [31:0] complete_data, 
  input wire [4:0] rd_complete,
  output logic [31:0] regwrite_data,
  output logic [4:0] regwrite_addr,
  output logic complete_we
);

  always_comb begin
    if(!stall) begin
      regwrite_data = complete_data;
      regwrite_addr = rd_complete;
      complete_we = 1'b1;
    end else begin
      regwrite_data = 32'bx;
      regwrite_addr = 5'bx;
      complete_we = 1'b0;
    end
  end
endmodule
`default_nettype wire