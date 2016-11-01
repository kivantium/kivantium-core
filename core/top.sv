module top(
  input clk,
  input RsRx,
  output RsTx,
  input btnC,
  input btnU,
  output logic [6:0] seg,
  output logic [3:0] an,
  output logic [15:0] led
);
  logic reset;   // when reset=1, program memory, register, pc, main memory is set to 0
  logic sysclk;  // delayed clock
  logic [31:0] pmemaddr; // program memory write address
  logic [31:0] pmemdata; // program memory write data
  logic pmemwe; // program memory write enable
  logic [31:0] pc, stdout, instruction;
  logic mode;
  
  assign led = pc[15:0];
  
  Loader ld(.clk(clk),.RsRx(RsRx), .btnU(btnU), .btnC(btnC), .reset(reset), .sysclk(sysclk),
            .pmemaddr(pmemaddr), .pmemdata(pmemdata), .pmemwe(pmemwe), .mode(mode));
  kivantium kv(.clk(sysclk), .reset(reset), .cpustate(mode), .pmemaddr(pmemaddr), .pmemdata(pmemdata),
               .pmemwe(pmemwe), .stdout(stdout), .pc(pc), .instruction(instruction));
  LEDSeg segment(.clk(clk), .reset(reset), .enable(mode), .data(stdout[15:0]), .k(seg), .a(an));
endmodule