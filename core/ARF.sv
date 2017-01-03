`default_nettype none

// Architected Register File
module ARF(
  input wire clk, arf_write_enable,
  input wire [4:0] src_reg1, src_reg2, dp_arf_dest, arf_write_reg,
  input wire [5:0] rob_free_entry,
  input wire [31:0] arf_write_data,
  output logic [31:0] arf_read_data1, arf_read_data2,
  output logic arf_busy1, arf_busy2,
  output logic [5:0] arf_tag1, arf_tag2
);
 (* ram_style = "distributed" *)
 logic [31:0] data [0:31];
 logic [0:0] busy [0:31];
 logic [5:0] tag [0:31];
 
 assign arf_read_data1 = (src_reg1 == 5'b0) ? 32'b0 : data[src_reg1];
 assign arf_read_data2 = (src_reg2 == 5'b0) ? 32'b0 : data[src_reg2];
 assign arf_busy1 = (src_reg1 == 5'b0) ? 1'b0 : busy[src_reg1];
 assign arf_busy2 = (src_reg2 == 5'b0) ? 1'b0 : busy[src_reg2];
 assign arf_tag1  = (src_reg1 == 5'b0) ? 6'b0 : tag[src_reg1];
 assign arf_tag2  = (src_reg1 == 5'b0) ? 6'b0 : tag[src_reg2];
  
  always_ff @(posedge clk) begin
    if(dp_arf_dest != 5'b00000) begin
      busy[dp_arf_dest] <= 1'b1;
      tag[dp_arf_dest] <= rob_free_entry;
    end
    if(arf_write_enable) begin
      data[arf_write_reg] <= arf_write_data;
      busy[arf_write_reg] <= 1'b0;
    end
  end
endmodule

`default_nettype wire