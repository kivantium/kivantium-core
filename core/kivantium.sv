module kivantium(
  input clk, reset, cpustate,
  input [31:0] pmemaddr, pmemdata, 
  input pmemwe, 
  output [31:0] stdout, pc, instruction
);
  /*logic [31:0] pc, instruction;*/
  logic [9:0] controls;
  logic [3:0] aluctrl;
  
  logic cpuclk;
  
  assign cpuclk = (cpustate == 1) ? clk : 0;
 
  Memory #(64) pmem(.clk(clk), .reset(reset), .writeaddr(pmemaddr), .writedata(pmemdata),
              .writeenable(pmemwe), .readaddr(pc), .readdata(instruction));
  Controller ctrl(.opcode(instruction[31:26]), .funct(instruction[5:0]), 
                   .controls(controls), .aluctrl(aluctrl));
  DataPath dp(.clk(cpuclk), .reset(reset), .instruction(instruction), 
               .controls(controls), .aluctrl(aluctrl), .pc(pc), .stdout(stdout));
endmodule
