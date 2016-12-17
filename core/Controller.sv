`timescale 1ns / 1ps
`default_nettype none

`define state_fetch    3'b001
`define state_decode   3'b011
`define state_dispatch 3'b111
`define state_execute  3'b110
`define state_complete 3'b100
`define state_retire   3'b000

module Controller(
  input wire clk, reset, fetch_ready, finish_ex,
  output logic [5:0] stalls
);

  logic stall_fc, stall_dc, stall_dp, stall_ex, stall_cp, stall_rt;
  
  assign stalls = {stall_fc, stall_dc, stall_dp, stall_ex, stall_cp, stall_rt}; 
  
  logic [3:0] state;
  
  always_ff @(posedge clk or negedge reset) begin
    if(reset == 1'b0) begin
      state <= `state_fetch;
    end
    
    case(state)
      `state_fetch: begin
        if(fetch_ready) state <= `state_decode;
      end
      `state_decode: begin
        state <= `state_dispatch;
      end
      `state_dispatch: begin
        state <= `state_execute;
      end
       `state_execute: begin
        if(finish_ex) state <= `state_complete;
      end       
    endcase
  end
  
  always_comb begin
    case(state)
      `state_fetch: begin
        if(fetch_ready) stall_dc = 1'b0;
        else            stall_dc = 1'b1;
      end
      default: begin
      end
    endcase
  end

endmodule
`default_nettype wire