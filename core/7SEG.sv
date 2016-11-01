module LEDSeg(
  input clk,
  input [15:0] data,
  input enable,
  output logic [6:0] k,
  output logic [3:0] a
);
  
  logic [31:0] counter;
  logic [1:0] digit;
  logic [15:0] data_buf;
  logic [3:0] num;
  
  Decoder dec(.in(num), .out(k));
  
  always_ff @(posedge clk) begin
    if(enable == 0) begin
      a <= 4'b1111;
    end else begin
      if(counter == 400000) begin
        data_buf <= data;
        digit <= 0;
        counter <= 0;
      end else begin
        case(counter)
          100000: digit <= 1;
          200000: digit <= 2;
          300000: digit <= 3;
        endcase
        counter <= counter + 1;
      end
        
      case(digit)
        0: begin
          num <= data[3:0];
          a <= 4'b1110;
        end
        1: begin
          num <= data[7:4];
          a <= 4'b1101;
        end
        2: begin
          num <= data[11:8];
          a <= 4'b1011;
        end
        3: begin
          num <= data[15:12];
          a <= 4'b0111;
        end
      endcase
    end
  end
endmodule

module Decoder(
  input [3:0] in,
  output logic [6:0] out
);
  always_comb begin
    case(in)
      0:  out <= 7'b1000000;
      1:  out <= 7'b1111001;
      2:  out <= 7'b0100100;
      3:  out <= 7'b0110000;
      4:  out <= 7'b0011001;
      5:  out <= 7'b0010010;
      6:  out <= 7'b0000010;
      7:  out <= 7'b1011000;
      8:  out <= 7'b0000000;
      9:  out <= 7'b0011000;
      10: out <= 7'b0001000;
      11: out <= 7'b0000011;
      12: out <= 7'b1000110;
      13: out <= 7'b0100001;
      14: out <= 7'b0000110;
      15: out <= 7'b0001110;
      default: out <= 7'bXXXXXXX;
    endcase
  end
endmodule