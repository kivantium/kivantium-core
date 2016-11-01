 module Memory #(parameter SIZE = 256)(
  input clk,
  input [31:0] writeaddr, writedata, 
  input writeenable, 
  input [31:0] readaddr, 
  output logic [31:0] readdata
);
  
  logic [31:0] mem [SIZE-1:0];
  
  assign readdata = mem[readaddr[31:2]];
  
  initial begin
    $readmemh("/home/naruki/memfile.dat", mem);
  end
  
  always @(posedge clk) begin
    if(writeenable == 1) mem[writeaddr[31:2]] <= writedata;
  end
endmodule