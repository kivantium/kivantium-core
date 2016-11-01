module Register(
  input clk, reset,
  input [4:0] readaddr0, readaddr1, writeaddr,
  input [31:0] writedata,
  input regwe, 
  output logic [31:0] readdata0,
  output logic [31:0] readdata1
  );
  // expecting distributed RAM
  logic [31:0] register [0:31];
  
  integer i;
  initial begin
    for(i=0; i<32; ++i) register[i] = 0;
  end
  assign readdata0 = (readaddr0 != 0) ? register[readaddr0] : 0;
  assign readdata1 = (readaddr1 != 0) ? register[readaddr1] : 0;
  
  always_ff @(posedge clk) begin
    if(reset == 1) begin
      for(int i=0; i<32; i++) register[i] <= 0;
    end
    if(regwe == 1)
      register[writeaddr] <= writedata;
  end 
endmodule