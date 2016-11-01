module top(
  input clk,
  input RsRx,
  output RsTx,
  input btnC,
  input btnU,
  output logic [6:0] seg,
  output logic [3:0] an
);
  logic reset;   // when reset=1, program memory, register, pc, main memory is set to 0
  logic sysclk;  // delayed clock
  logic [31:0] pmemaddr; // program memory write address
  logic [31:0] pmemdata; // program memory write data
  logic pmemwe; // program memory write enable
  logic [31:0] stdout;
  
  Loader ld(.clk(clk),.RsRx(RsRx), .btnU(btnU), .btnC(btnC), .reset(reset), .sysclk(sysclk),
            .pmemaddr(pmemaddr), .pmemdata(pmemdata), .pmemwe(pmemwe));
  kivantium kv(.clk(sysclk), .reset(reset), .pmemaddr(pmemaddr), .pmemdata(pmemdata),
               .pmemwe(pmemwe), .stdout(stdout));
  LEDSeg segment(.clk(clk), .data(stdout[15:0]), .enable(1'b1), .k(seg), .a(an));
endmodule