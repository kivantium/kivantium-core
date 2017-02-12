`default_nettype none

module fetch(clk, reset, stall, pc, nextpc, mispred, commit_pc);
  input wire clk, reset, stall;
  output logic [31:0] pc, nextpc;
  input wire mispred;
  input wire [31:0] commit_pc;
  
  logic [31:0] pred_pc;
  
  assign nextpc = (mispred == 1'b1) ? commit_pc : pred_pc;
  always_ff @(posedge clk) begin
    if(reset) begin
      pred_pc <= 32'd4;
      pc <= 32'd0;
    end else if(!stall) begin
      pc <= nextpc;
      pred_pc <= nextpc + 32'd4;
    end
  end
endmodule
`default_nettype wire