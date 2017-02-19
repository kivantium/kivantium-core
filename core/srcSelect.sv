`timescale 1ns / 1ns
`default_nettype none

module srcSelect(arf_data1, arf_data2, arf_tag1, arf_tag2,
                rob_data1, rob_data2, src_data1, src_data2,
                cdb1, cdb2, cdb3);

  input wire [32:0] arf_data1, arf_data2, rob_data1, rob_data2;
  input wire [5:0] arf_tag1, arf_tag2;
  output logic [32:0] src_data1, src_data2;
  input wire [37:0] cdb1, cdb2, cdb3;

  always_comb begin
    if(arf_data1[32] == 1'b0)        src_data1 = {1'b1, arf_data1[31:0]};
    else if(arf_tag1 == cdb1[37:32]) src_data1 = {1'b1, cdb1[31:0]};
    else if(arf_tag1 == cdb2[37:32]) src_data1 = {1'b1, cdb2[31:0]};
    else if(arf_tag1 == cdb3[37:32]) src_data1 = {1'b1, cdb3[31:0]};
    else if(rob_data1[32] == 1'b1)   src_data1 = {1'b1, rob_data1[31:0]};
    else                             src_data1 = {27'b0, arf_tag1};
    
    if(arf_data2[32] == 1'b0)        src_data2 = {1'b1, arf_data2[31:0]};
    else if(arf_tag2 == cdb1[37:32]) src_data2 = {1'b1, cdb1[31:0]};
    else if(arf_tag2 == cdb2[37:32]) src_data2 = {1'b1, cdb2[31:0]};
    else if(arf_tag2 == cdb3[37:32]) src_data2 = {1'b1, cdb3[31:0]};
    else if(rob_data2[32] == 1'b1)   src_data2 = {1'b1, rob_data2[31:0]};
    else                             src_data2 = {27'b0, arf_tag2};
  end
endmodule
`default_nettype wire