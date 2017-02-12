`default_nettype none

module pipeifdc(clk, reset, kill, if_pc, if_inst, dc_pc, dc_inst);
  input wire clk, reset, kill;
  input wire [31:0] if_pc, if_inst;
  output logic [31:0] dc_pc, dc_inst;
  
  always_ff @(posedge clk) begin
    if(reset || kill) begin
      dc_pc <= 32'd0;
      dc_inst <= 32'd0;
    end else begin
      dc_pc <= if_pc;
      dc_inst <= if_inst;
    end
  end
endmodule  

`default_nettype wire