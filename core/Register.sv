`default_nettype none

module Register(
  input wire clk, reset,
  input wire [4:0] readaddr1, readaddr2, writeaddr,
  input wire [31:0] writedata,
  input wire reg_we, 
  output logic [31:0] readdata1,
  output logic [31:0] readdata2
);

  (* ram_style = "distributed" *)
  logic [31:0] register [0:31];
    
  assign readdata1 = (readaddr1 == 0) ? 32'b0 : register[readaddr1];
  assign readdata2 = (readaddr2 == 0) ? 32'b0 : register[readaddr2];
  
  always_ff @(posedge clk) begin
    if(reg_we) begin
      register[writeaddr] <= writedata;
    end
  end
endmodule
`default_nettype wire