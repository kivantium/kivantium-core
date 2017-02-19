`timescale 1ns / 1ns
`default_nettype none

module controller(rs_dest, rs_int_is_full, rs_bj_is_full, rs_ls_is_full, stall,
                  mispred, misload, signal_miss);
  input wire [3:0] rs_dest;
  input wire rs_int_is_full, rs_bj_is_full, rs_ls_is_full;
  output logic stall;
  input wire mispred, misload;
  output logic signal_miss;

  logic rs_int_we, rs_bj_we, rs_ls_we, rs_flt_we;
  assign {rs_int_we, rs_bj_we, rs_ls_we, rs_flt_we} = rs_dest;

  always_comb begin
    if(rs_int_we == 1'b1 && rs_int_is_full == 1'b1) stall = 1'b1;
    else if(rs_bj_we == 1'b1 && rs_bj_is_full == 1'b1) stall = 1'b1;
    else if(rs_ls_we == 1'b1 && rs_ls_is_full == 1'b1) stall = 1'b1;
    else stall = 1'b0;
  end
  
  assign signal_miss = mispred || misload;

endmodule
`default_nettype wire