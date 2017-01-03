`default_nettype none

module DataMemory(
  input wire clk,
  input wire [31:0] read_addr, write_addr, write_data,
  input wire we,
  output logic [31:0] read_data
);
  
  (* ram_style = "block" *)
  logic [31:0] memory[1023:0];
  
  always @(posedge clk) begin
    if (we) memory[write_addr] <= write_data;
    read_data <= memory[read_addr];
  end 
endmodule
`default_nettype wire