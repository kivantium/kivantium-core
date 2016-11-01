module Receiver(
  input clk,
  input RX,
  output logic [7:0] data,
  output logic ready
);
  logic [3:0] recv_bit;
  logic [16:0] count;
  logic status, rx_buf;
  
  always @(posedge clk) begin
    rx_buf <= RX;
    if(status == 0 && rx_buf == 0) 
      status <= 1;
      ready <= 0;
    
    if(status == 1) begin
      if(count == 10416) begin
          count <= 0;
          if(recv_bit == 8) begin
            recv_bit <= 0;
            status <= 0;
            ready <= 1;
          end else
            recv_bit <= recv_bit + 1;
      end else begin
        count <= count + 1;
        if(count == 5000) begin
          case(recv_bit)
            1: data[0] <= rx_buf;
            2: data[1] <= rx_buf;
            3: data[2] <= rx_buf;
            4: data[3] <= rx_buf;
            5: data[4] <= rx_buf;
            6: data[5] <= rx_buf;
            7: data[6] <= rx_buf;
            8: data[7] <= rx_buf;
            default: ;
          endcase
        end
      end
    end
  end
endmodule

/*module Sender(
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
endmodule*/