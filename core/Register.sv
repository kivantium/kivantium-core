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
    
  assign readdata1 = (readaddr1 != 0) ? register[readaddr1] : 0;
  assign readdata2 = (readaddr2 != 0) ? register[readaddr2] : 0;
   
  always_ff @(posedge clk or negedge reset) begin
    if(reset == 1'b0) begin
      for(int i=0; i<32; i++) register[i] <= 0;
    end
    if(reg_we == 1) begin
      register[writeaddr] <= writedata;
    end
  end
endmodule
`default_nettype wire