module core( 
  input clk,
  input RsRx,
  output RsTx,
  input btnC,
  input btnU,
  //output logic RsTx,
  output logic [15:0] led,
  output [6:0] seg,
  output [3:0] an
  );
  // state definition
  typedef enum logic [3:0] {
      RECV, FETCH, DECODE, EXEC, MEMORY, WRITE, ABORT
  } State;
  State state;
  
  // core
  logic [31:0] PC;
  logic [31:0] instruction;
  logic [31:0] Register [0:31];
  logic [31:0] count; // for delay
  
  // memory
  parameter DATA_WIDTH=32, ADDR_WIDTH=12, WORDS=4096;
  logic [ADDR_WIDTH-1:0] memory_addr;
  logic [DATA_WIDTH-1:0] memory_data_in;
  logic [DATA_WIDTH-1:0] memory_data_out;
  logic memory_read_write;
  RAM memory(.clk(clk), .addr(memory_addr), .data_in(memory_data_in), 
             .data_out(memory_data_out), .read_write(memory_read_write)); 
  
  // USART
  logic recv_ready, recv_ready_before;
  // logic send_busy;
  logic [7:0] USART_data;
  logic [15:0] recv_count;
  logic [7:0] USART_data_tmp[0:3];
  Receiver recv(.CLK(clk), .UART_RXD(RsRx), .DATA(USART_data), .READY(recv_ready));
  //Sender send(.CLK(clk), .UART_TXD(RsTx), .DATA(USART_data), .START(recv_ready), .BUSY(send_busy));
  
  // I/O
  logic btnC_buf, btnU_buf;
  logic SEG_enable;
  logic [15:0] SEG_data;
  LEDSeg segment(.CLK(clk), .DATA(SEG_data), .ENABLE(SEG_enable), .OUT_K(seg), .OUT_A(an));
  
  initial begin
    SEG_enable = 0;
    SEG_data = 0;
    count = 0;
    PC = 0;
    recv_count = 0;
    state = RECV;
    Register[0]  <= 0;
    Register[29] <= WORDS*4-8;
    Register[30] <= WORDS*4-4;
    Register[31] <= 32'hffffffff;
  end
  
  always_ff @(posedge clk) begin
    // restore input to FF
    btnC_buf <= btnC;
    btnU_buf <= btnU;
    SEG_data <= PC[15:0];
    // Reset
    if(btnC_buf == 1) begin
      SEG_enable <= 0;
      count <= 0;
      PC <= 0;
      recv_count <= 0;
      state <= RECV;
      led <= 0;
      Register[0]  <= 0;
      Register[29] <= WORDS*4-8;
      Register[30] <= WORDS*4-4;
      Register[31] <= 32'hffffffff;
    end
    // Change to Execution mode
    else if(btnU_buf == 1) begin
      state <= FETCH;
      SEG_enable <= 1;
      count <= 0;
    end
    
    else begin
    case(state)    
      RECV: begin
      // when USART receive finished, save it to memory
      recv_ready_before <= recv_ready;
      if(recv_ready_before == 0 && recv_ready == 1) begin
        USART_data_tmp [recv_count[1:0]] <= USART_data;
        recv_count <= recv_count + 1;
      end
      else if(recv_ready_before == 1 && recv_count[1:0] == 2'b00) begin
        memory_read_write <= 1;
        memory_addr <= recv_count[ADDR_WIDTH-1:0]-4;
        memory_data_in[7:0]   <= USART_data_tmp[0];
        memory_data_in[15:8]  <= USART_data_tmp[1];
        memory_data_in[23:16] <= USART_data_tmp[2];
        memory_data_in[31:24] <= USART_data_tmp[3];
      end
      if(memory_read_write == 1) begin
        memory_read_write <= 0;
      end
    end      
    FETCH: begin
        memory_addr <= PC[ADDR_WIDTH-1:0];
        if(count == 100000000) begin
          if(PC == 32'hffffffff) begin
            state <= ABORT;
          end else begin
            state <= DECODE;
            count <= 0;
            instruction[7:0] <= memory_data_out[7:0];
            instruction[15:8] <= memory_data_out[15:8];
            instruction[23:16] <= memory_data_out[23:16];
            instruction[31:24] <= memory_data_out[31:24];
            PC <= PC + 4;
          end
        end else begin       
          count <= count + 1;
        end
      end
      DECODE: begin
        if(count == 100000000) begin
          state <= MEMORY;
          count <= 0;
          case(instruction[31:26])
            6'b000010: begin  // j
              PC <= PC[31:28] + (instruction[25:0]<<2) - 4;
            end
            6'b000011: begin // jal
              Register[31] <= PC + 4;
              PC <= PC[31:28] + (instruction[25:0]<<2) - 4;
            end
            6'b000100: begin // beq
              if(Register[instruction[25:21]]==Register[instruction[20:16]]) begin
                PC <= PC + (instruction[15:0]<<2) - 4;
              end
            end
            6'b001001: begin  // addiu TODO: sign_extend
              Register[instruction[20:16]] <= Register[instruction[25:21]] + $signed(instruction[15:0]);
            end
            6'b001010: begin  // slti TODO: sign_extend
              if(Register[instruction[25:21]] < instruction[15:0]) begin 
                Register[instruction[20:16]] <= 1;
              end else begin
                Register[instruction[20:16]] <= 0;
              end
            end
            6'b001101: begin  // ori TODO: sign_extend
              Register[instruction[20:16]] <= instruction[15:0] | Register[instruction[25:21]];
            end
            6'b100011: begin // lw
              memory_addr <= Register[instruction[25:21]][ADDR_WIDTH-1:0]+instruction[ADDR_WIDTH-1:0];
            end
            6'b101011: begin // sw
              memory_addr <= Register[instruction[25:21]][ADDR_WIDTH-1:0]+instruction[ADDR_WIDTH-1:0];
              memory_data_in <= Register[instruction[20:16]];
              memory_read_write <= 1;
            end
            6'b00000: begin
              case(instruction[5:0])
                6'b001000: begin // jr
                  PC <= Register[instruction[25:21]];
                end
                6'b001100: begin // syscall
                  if(Register[2] == 1) begin
                    led <= Register[4];
                  end
                end
                6'b100001: begin // addu
                  Register[instruction[15:11]] <= Register[instruction[25:21]] + Register[instruction[20:16]];
                end
              endcase
            end
          endcase
        end else begin       
          count <= count + 1;
        end
      end
      MEMORY: begin
        if(instruction[31:26] == 6'b100011) begin //lw
           Register[instruction[20:16]] <= memory_data_out;
        end
        else if(instruction[31:26] == 6'b101011) begin //sw
          memory_read_write <= 0;
        end
        state <= FETCH;
      end
    endcase
  end
  end
endmodule

module RAM(clk, addr, data_in, data_out, read_write);
  parameter DATA_WIDTH=32, ADDR_WIDTH=12, WORDS=4096;

  input clk, read_write;
  input [ADDR_WIDTH-1:0] addr;
  input [DATA_WIDTH-1:0] data_in;
  output logic [DATA_WIDTH-1:0] data_out;
  (* RAM_STYLE="BLOCK" *) logic [DATA_WIDTH-1:0] mem [WORDS-1:0];

  integer i;
  initial begin
    for(i=0; i<WORDS; i=i+1) mem[i]=0;
  end
  
  always @(posedge clk) begin
    if(read_write == 1) mem[addr] <= data_in;
    else data_out <= mem[addr];
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
