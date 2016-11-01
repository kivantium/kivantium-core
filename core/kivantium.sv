module kivantium(
  input clk, reset, 
  input [31:0] pmemaddr, pmemdata, 
  input pmemwe, 
  output [31:0] stdout
);
  logic [31:0] pc, instruction;
  logic [9:0] controls;
  logic [3:0] aluctrl;
 
  Memory #(256) pmem(.clk(clk), .writeaddr(pmemaddr), .writedata(pmemdata),
              .writeenable(pmemwe), .readaddr(pc), .readdata(instruction));
  Controller ctrl(.opcode(instruction[31:26]), .funct(instruction[5:0]), 
                   .controls(controls), .aluctrl(aluctrl));
  DataPath dp(.clk(clk), .reset(reset), .instruction(instruction), 
               .controls(controls), .aluctrl(aluctrl), .pc(pc), .stdout(stdout));
endmodule
