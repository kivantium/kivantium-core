module loader( 
  input clk,
  input RsRx,
  input btnC,
  input btnU,
  output logic RsTx,
  output logic [15:0] led,
  output [6:0] seg,
  output [3:0] an
  );
  typedef enum logic [2:0] {
      RECV, EXEC
  } State;
  State state;
  
  logic btnC_buf, btnU_buf;
  logic recv_ready, recv_ready_before, send_busy;
  logic [7:0] USART_data;
  logic SEG_enable;
  logic [15:0] SEG_data;
  
  logic [15:0] recv_count;
  logic [7:0] memory [0:1023];
  
  logic [31:0] PC;
  logic [31:0] count;
  logic delayed_clk;
  Receiver recv(.CLK(clk), .UART_RXD(RsRx), .DATA(USART_data), .READY(recv_ready));
  Sender send(.CLK(clk), .UART_TXD(RsTx), .DATA(USART_data), .START(recv_ready), .BUSY(send_busy));
  LEDSeg segment(.CLK(clk), .DATA(SEG_data), .ENABLE(SEG_enable), .OUT_K(seg), .OUT_A(an));
  
  initial begin
    SEG_enable = 0;
    SEG_data = 0;
    count = 0;
    PC = 0;
    recv_count = 0;
    state = RECV;
    for(int i=0; i<1024; i++)
      memory[i] <= 0;
  end
  
  always_ff @(posedge clk) begin
    // restore input to FF
    btnC_buf <= btnC;
    btnU_buf <= btnU;    
    // Reset
    if(btnC_buf == 1) begin
      state <= RECV;
      SEG_enable <= 0;
      PC <= 0;
      recv_count <= 0;
      for(int i=0; i<1024; i++)
        memory[i] <= 0;
    end
    // Change to Execution mode
    if(btnU_buf == 1) begin
      state = EXEC;
      SEG_enable <= 1;
    end
    
    if(state == RECV) begin
      // when USART receive finished, save it to memory
      recv_ready_before <= recv_ready;
      if(recv_ready_before == 0 && recv_ready == 1) begin
        memory[recv_count] <= USART_data;
        recv_count <= recv_count + 1;  
      end
    end else if(state == EXEC) begin
      if(count == 100000000) begin
        count <= 0;
        SEG_data <= PC + 1;
        PC <= PC + 1;
        led <= memory[PC];
      end else begin       
        count <= count + 1;
      end
    end
  end
endmodule

module LEDSeg(
  input CLK,
  input [15:0] DATA,
  input ENABLE,
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
    if(ENABLE == 0) begin
      OUT_A <= 4'b1111;
    end else begin
      if(counter == 400000) begin
        data <= DATA;
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
      12: OUT <= 7'b1000110;
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
