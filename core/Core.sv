module Core(
  input clk, reset,
  input [31:0] instruction, 
  output logic [31:0] pc, stdout
); 
  logic [9:0] controls;
  logic [3:0] aluctrl;

  Controller ctrl(.opcode(instruction[31:26]), .funct(instruction[5:0]), 
                  .controls(controls), .aluctrl(aluctrl));
  DataPath dp(.clk(clk), .reset(reset), .instruction(instruction), 
              .controls(controls), .aluctrl(aluctrl), .pc(pc), .stdout(stdout));
endmodule
