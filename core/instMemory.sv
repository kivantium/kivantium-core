`default_nettype none

module instMemory(clk, reset, addr, inst);
  input wire clk, reset;
  input wire [31:0] addr;
  output logic [31:0] inst;

  logic [31:0] rom [0:63];

  assign rom[0] = 32'b000000000001_00000_000_00001_0010011;    // 0: addi r1, r0, 1
  assign rom[1] = 32'b000000000010_00000_000_00010_0010011;    // 4: addi r2, r0, 2
  assign rom[2] = 32'b0_000000_00010_00001_000_0000_0_1100011; // 8: beq r1, r2, 0
  assign rom[3] = 32'b000000000001_00001_000_00001_0010011;    // c: addi r1, r1, 1
  assign rom[4] = 32'b1_1111111100_1_11111111_00000_1101111;    //10: jal r0, -8
  always_ff @(posedge clk) begin
    if(reset) begin
      inst <= rom[0];
    end else begin
      inst <= rom[addr[7:2]];
    end
  end

endmodule

`default_nettype none