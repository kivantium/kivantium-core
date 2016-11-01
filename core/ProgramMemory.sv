`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/28/2016 12:58:38 PM
// Design Name: 
// Module Name: ProgramMemory
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


module Memory #(parameter SIZE = 1024)(
  input clk, reset, 
  input [31:0] writeaddr, writedata, 
  input writeenable, 
  input [31:0] readaddr, 
  output logic [31:0] readdata
);
  
  logic [31:0] mem [SIZE-1:0];
  
  always @(posedge clk, posedge reset) begin
    if(reset == 1) begin
      for(int i=0; i<SIZE; i++) mem[i] = 0;
    end
    
    if(writeenable == 1) mem[writeaddr] <= writedata;
    readdata <= mem[readaddr];
  end
endmodule