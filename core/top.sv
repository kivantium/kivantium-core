module top(clk, btnC, led);
  input wire clk, btnC;
  output logic[15:0] led;
  
  logic [31:0] buffer;
  logic sysclk;
  
  always_ff @(posedge clk) begin
    if (btnC) buffer <= 3'b0;
    else if(buffer == 32'd10000000) buffer <= 32'd0;
    else buffer <= buffer + 3'd1;
  end
  assign sysclk = (buffer > 5000000) ? 1'b0 : 1'b1;
  
  cpu_top kivantium(.clk(sysclk), .reset(btnC), .led(led));
endmodule
