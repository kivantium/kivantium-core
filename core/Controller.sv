`default_nettype none

`define state_fetch     3'b000
`define state_decode    3'b001
`define state_dispatch  3'b011
`define state_execute1  3'b111
`define state_execute2  3'b110
`define state_complete  3'b100

module Controller(
  input wire clk, reset,
  output logic [5:0] stalls
);

  logic [2:0] state;
  always_ff @(posedge clk or posedge reset) begin
    if(reset) begin
      state <= `state_fetch;
    end else begin
      case(state)
        `state_fetch:    state <= `state_decode;
        `state_decode:   state <= `state_dispatch;
        `state_dispatch: state <= `state_execute1;
        `state_execute1: state <= `state_execute2;
        `state_execute2: state <= `state_complete;
        `state_complete: state <= `state_fetch;
        default        : state <= 3'bxxx; 
      endcase
    end
  end
  
  always_comb begin
    case(state)
      `state_fetch:    stalls = 5'b11111;
      `state_decode:   stalls = 5'b10111;
      `state_dispatch: stalls = 5'b11011;
      `state_execute1: stalls = 5'b11101;
      `state_execute2: stalls = 5'b11111;
      `state_complete: stalls = 5'b01110;
       default:        stalls = 5'bxxxxx;
    endcase
  end

endmodule
`default_nettype wire