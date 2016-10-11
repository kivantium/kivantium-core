module loopback( 
  input clk,
  input RsRx,
  output logic RsTx,
  output logic [15:0] led,
  output [6:0] seg,
  output [3:0] an
  );
  
  logic recv_ready, send_busy;
  logic [7:0] USART_data;
  logic SEG_newdata;
  logic [15:0] SEG_data;
  
  logic [31:0] counter;
  Receiver recv(.CLK(clk), .UART_RXD(RsRx), .DATA(USART_data), .READY(recv_ready));
  Sender send(.CLK(clk), .UART_TXD(RsTx), .DATA(USART_data), .START(recv_ready), .BUSY(send_busy));
  LEDSeg segment(.CLK(clk), .DATA(SEG_data), .NEW(SEG_newdata), .OUT_K(seg), .OUT_A(an));
  
  initial begin
    SEG_newdata = 0;
    SEG_data = 0;
    counter = 0;
  end
  
  always_ff @(posedge clk) begin
    led <= SEG_data;
    if(counter == 10000000) begin
      SEG_data <= SEG_data + 1;
      SEG_newdata <= 1;
      counter <= 0;
    end else begin
      counter = counter + 1;
      SEG_newdata <= 0;
    end    
  end
endmodule

module LEDSeg(
  input CLK,
  input [15:0] DATA,
  input NEW,
  output logic [6:0] OUT_K,
  output logic [3:0] OUT_A
  );
  
  logic [31:0] counter;
  logic [1:0] digit;
  logic [15:0] data;
  logic [3:0] num;
  
  initial begin
    counter = 0;
    digit = 0;
  end
  Decoder dec(.IN(num), .OUT(OUT_K));
  
  always_ff @(posedge CLK) begin

    if(NEW == 1) begin
      data <= DATA;
    end
    if(counter == 400000) begin
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
        OUT_A <= 4'b1110;
      end
      1: begin
        num <= data[7:4];
        OUT_A <= 4'b1101;
      end
      2: begin
        num <= data[11:8];
        OUT_A <= 4'b1011;
      end
      3: begin
        num <= data[15:12];
        OUT_A <= 4'b0111;
      end
    endcase
  end
endmodule

module Decoder(
  input [3:0] IN,
  output logic [6:0] OUT
  );
  always_comb begin
    case(IN)
      0:  OUT <= 7'b1000000;
      1:  OUT <= 7'b1111001;
      2:  OUT <= 7'b0100100;
      3:  OUT <= 7'b0110000;
      4:  OUT <= 7'b0011001;
      5:  OUT <= 7'b0010010;
      6:  OUT <= 7'b0000010;
      7:  OUT <= 7'b1011000;
      8:  OUT <= 7'b0000000;
      9:  OUT <= 7'b0011000;
      10: OUT <= 7'b0001000;
      11: OUT <= 7'b0000011;
      12: OUT <= 7'b0100111;
      13: OUT <= 7'b0100001;
      14: OUT <= 7'b0000110;
      15: OUT <= 7'b0001110;
    endcase
  end
endmodule

module Receiver(
  input CLK,
  input UART_RXD,
  output logic [7:0] DATA,
  output logic READY
  );
  logic [3:0] recv_bit;
  logic [16:0] count;
  logic status, rx_buf;
  initial begin
    DATA = 0;
    READY = 0;
    count = 0;
    rx_buf = 1;
    status = 0;
    recv_bit = 0;
  end
  
  
  always @(posedge CLK) begin
    rx_buf <= UART_RXD;
    if(status == 0 && rx_buf == 0) 
      status <= 1;
      READY <= 0;
    
    if(status == 1) begin
      if(count == 10416) begin
          count <= 0;
          if(recv_bit == 8) begin
            recv_bit <= 0;
            status <= 0;
            READY <= 1;
          end else
            recv_bit <= recv_bit + 1;
      end else begin
        count <= count + 1;
        if(count == 5000) begin
          case(recv_bit)
            1: DATA[0] <= rx_buf;
            2: DATA[1] <= rx_buf;
            3: DATA[2] <= rx_buf;
            4: DATA[3] <= rx_buf;
            5: DATA[4] <= rx_buf;
            6: DATA[5] <= rx_buf;
            7: DATA[6] <= rx_buf;
            8: DATA[7] <= rx_buf;
          endcase
        end
      end
    end
  end
endmodule

module Sender(
  input CLK, 
  output logic UART_TXD,
  input [7:0] DATA,
  input START,
  output logic BUSY
  );
  
  logic [7:0] buffer;
  logic status;
  logic [16:0] count;
  logic [3:0] send_bit;
  
  initial begin   
    count = 0;
    send_bit = 0;
  end

  always @(posedge CLK) begin
    if(START == 1) begin
      buffer <= DATA;
      status <= 1;
      BUSY <= 1;
    end
    if(status == 1) begin
      if(count == 10416) begin
        count <= 0;
        if(send_bit == 8) begin
          status <= 0;
          send_bit <= 0;
          UART_TXD <= 1;
          BUSY <= 0;
        end else begin
          send_bit = send_bit + 1;
        end
      end else begin
        count = count + 1;
        case(send_bit)
          0: UART_TXD <= 0;
          1: UART_TXD <= buffer[0];
          2: UART_TXD <= buffer[1];
          3: UART_TXD <= buffer[2];
          4: UART_TXD <= buffer[3];
          5: UART_TXD <= buffer[4];
          6: UART_TXD <= buffer[5];
          7: UART_TXD <= buffer[6];
          8: UART_TXD <= buffer[7];
        endcase
      end      
    end
  end
endmodule