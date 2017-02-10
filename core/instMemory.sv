`default_nettype none

module instMemory(clk, reset, addr, inst);
  input wire clk, reset;
  input wire [31:0] addr;
  output logic [31:0] inst;

  logic [31:0] rom [0:63];

  assign rom[0] = 32'b000000000001_00000_000_00001_0010011;
  assign rom[1] = 32'b0000000_00001_00001_000_00010_0110011;
  assign rom[2] = 32'b0000000_00001_00010_000_00011_0110011;
  assign rom[3] = 32'b0100000_00011_00001_000_00001_0110011;
  always_ff @(posedge clk) begin
    if(reset) begin
      inst <= rom[0];
    end else begin
      inst <= rom[addr[7:2]];
    end
  end

endmodule

`default_nettype none