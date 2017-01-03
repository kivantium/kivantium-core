`default_nettype none
module ProgramCounter(
  input wire clk, reset,
  input wire [31:0] next_pc,
  output logic [31:0] current_pc
);
  
  always_ff @(posedge clk or posedge reset) begin
    if(reset) current_pc <= 32'b0;
    else current_pc <= next_pc;    
  end
endmodule
`default_nettype wire