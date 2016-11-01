module Loader(
  input clk, RsRx, btnU, btnC,
  output logic reset, sysclk, 
  output logic [31:0] pmemaddr, pmemdata, 
  output logic pmemwe
);
  
  // Loader state 
  typedef enum logic [2:0] {
      WAIT, EXEC, ABORT, INTERRUPT
  } State;
  State state;
  
  // USART
  logic [15:0] recvcount;
  logic [7:0] USARTdata;
  logic [7:0] USARTdatatmp[0:3];
  logic recvready, recvreadybefore;
  Receiver recv(.clk(clk), .RX(RsRx), .data(USARTdata), .ready(recvready));
  
  // switches
  logic btnCBuf, btnUBuf;
  
  // counter for delayed logic
  logic [31:0] counter;
  
  always_ff @(posedge clk) begin
    // input check
    btnCBuf <= btnC;
    btnUBuf <= btnU;
    
    // Reset
    if(btnCBuf == 1) begin
      state <= WAIT;
      recvcount <= 0;
      reset <= 1;
    end else begin
      reset <= 0;
    end
    
    // state transition
    if(btnUBuf == 1) begin
      state <= EXEC;
    end

    // program loading
    if(state == WAIT) begin
      // when USART receive finished, save it to memory
      recvreadybefore <= recvready;
      if(recvreadybefore == 0 && recvready == 1) begin
        USARTdatatmp [recvcount[1:0]] <= USARTdata;
        if(recvcount[1:0] == 2'b11) begin
          pmemwe <= 1;
          sysclk <= 0;
          pmemaddr <= recvcount - 4;
          pmemdata[7:0]   <= USARTdatatmp[0];
          pmemdata[15:8]  <= USARTdatatmp[1];
          pmemdata[23:16] <= USARTdatatmp[2];
          pmemdata[31:24] <= USARTdatatmp[3];
        end else begin
          recvcount <= recvcount + 1;
        end
        if(pmemwe == 1) begin
          pmemwe <= 0;
          sysclk <= 1;
        end
      end
    end

    // provide delayed clock
    if(state == EXEC) begin
      if(counter == 50000000) begin
        sysclk <= !sysclk;
        counter <= 0;
      end else begin
        counter <= counter + 1;
      end
    end
  end
endmodule