module top(clk, btnC, led, seg, an);
  input wire clk, btnC;
  output logic[15:0] led;
  output logic[6:0] seg;
  output logic[3:0] an;
  
  logic [31:0] count;
  logic [31:0] count_seg;
  logic [15:0] seg_data;
  logic sysclk;

  core core_module(.clk(sysclk), .reset(btnC), .led(led), .seg_data(seg_data));
  
  // Create sysclk by delaying clk
  always_ff @(posedge clk) begin
    if (btnC) count <= 32'd0;
    else if(count == 32'd100000) count <= 32'd0;
    else count <= count + 32'd1;
  end
  assign sysclk = (count > 32'd50000) ? 1'b0 : 1'b1;

  // Dynamic display of 7 seg led
  always_ff @(posedge clk) begin
    if (btnC) count_seg <= 32'd0;
    else if(count_seg == 32'd400000) count_seg <= 32'd0;
    else count_seg <= count_seg + 32'd1;
 end

  function [6:0] DECODER (
        input [3:0] INPUT
    );
    begin
        case (INPUT)
            4'b0000: DECODER = 7'b1000000; // 0
            4'b0001: DECODER = 7'b1111001; // 1
            4'b0010: DECODER = 7'b0100100; // 2
            4'b0011: DECODER = 7'b0110000; // 3
            4'b0100: DECODER = 7'b0011001; // 4
            4'b0101: DECODER = 7'b0010010; // 5
            4'b0110: DECODER = 7'b0000010; // 6
            4'b0111: DECODER = 7'b1011000; // 7
            4'b1000: DECODER = 7'b0000000; // 8
            4'b1001: DECODER = 7'b0010000; // 9
            4'b1010: DECODER = 7'b0001000; // A
            4'b1011: DECODER = 7'b0000011; // b
            4'b1100: DECODER = 7'b1000110; // C
            4'b1101: DECODER = 7'b0100001; // d
            4'b1110: DECODER = 7'b0000110; // E
            4'b1111: DECODER = 7'b0001110; // F
        endcase
    end
  endfunction
    
  always_comb begin
     if(count_seg < 32'd100000) begin
        an = 4'b1110;
        seg = DECODER(seg_data%10);
     end
     else if(count_seg < 32'd200000) begin
        an = 4'b1101;
        seg = DECODER(seg_data/10%10);
     end
     else if(count_seg < 32'd300000) begin
        an = 4'b1011;
        seg = DECODER(seg_data/100%10);
     end
     else begin
        an = 4'b0111;
        seg = DECODER(seg_data/1000%10);
      end
  end
endmodule