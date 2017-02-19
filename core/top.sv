module top(clk, btnC, led);
  input wire clk, btnC;
  output logic[15:0] led;
  
  cpu_top kivantium(.clk(clk), .reset(btnC), .led(led));
endmodule
