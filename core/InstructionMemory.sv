`default_nettype none

module InstructionMemory(
  input wire clk,
  input wire [31:0] current_pc,
  output logic [31:0] instruction
);
  (* ram_style = "block" *)
  logic [31:0] imem[1023:0];
  int i;
  initial begin
    imem[0] = 32'b000000000011_00000_000_00001_0010011;
    imem[1] = 32'b000000000101_00001_000_00010_0010011;
    imem[2] = 32'b0100000_00001_00010_000_00011_0110011;
    imem[3] = 32'b0000000_00001_00011_001_00011_0010011;
  end
  
  always @(posedge clk) begin
    instruction <= imem[current_pc[11:2]];
  end
endmodule

`default_nettype wire