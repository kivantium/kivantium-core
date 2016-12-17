`default_nettype none

module InstCache(
  input wire clk,
  input wire [31:0] addr,
  output logic [31:0] inst0
);
  (* ram_style = "block" *)
  logic [31:0] memory[1023:0];
  int i;
  initial begin
    for(i=0; i<1023; i++) begin
      memory[i] = i;
    end
  end
  
  always @(posedge clk) begin
    inst0 <= memory[addr[11:2]];
  end
endmodule

`default_nettype wire