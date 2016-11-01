`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/01/2016 08:30:40 AM
// Design Name: 
// Module Name: IOMemory
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


 module IOMemory #(parameter SIZE = 256)(
  input clk,
  input [31:0] writeaddr, writedata, 
  input writeenable, 
  input [31:0] readaddr, 
  output logic [31:0] readdata,
  output logic [31:0] stdout
);
  
  logic [31:0] mem [SIZE-1:0];
  
  assign readdata = mem[readaddr[31:2]];
  assign stdout = mem[0];
  
  initial begin
    for(int i=0; i<SIZE; i=i+1) mem[i] = 0;
  end
  
  always @(posedge clk) begin
    if(writeenable == 1) mem[writeaddr[31:2]] <= writedata;
  end
endmodule
