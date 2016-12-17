`default_nettype none

module DataCache(
  input wire clk,
  input wire [31:0] readaddr, writeaddr, writedata,
  input wire we,
  output logic readdata
);
  
  (* ram_style = "block" *)
  logic [31:0] memory[1023:0];
  
  always @(posedge clk) begin
    if (we) memory[writeaddr] <= writedata;
    readdata <= memory[readaddr];
  end 

endmodule
`default_nettype wire