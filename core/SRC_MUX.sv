`default_nettype none


module SRC_MUX(
  input wire [31:0] arf_read_data1, arf_read_data2, rob_read_data1, rob_read_data2,
  input wire arf_busy1, arf_busy2, rob_valid1, rob_valid2,
  input wire [5:0] arf_tag1, arf_tag2,
  output logic [32:0] src_data1, src_data2
);

  always_comb begin
    if(arf_busy1) begin
      if(rob_valid1) src_data1 = {1'b1, rob_read_data1};
      else src_data1 = {1'b0, 26'b0, arf_tag1};
    end else begin
      src_data1 = {1'b1, arf_read_data1};
    end
    
    if(arf_busy2) begin
      if(rob_valid2) src_data2 = {1'b1, rob_read_data2};
      else src_data2 = {1'b0, 26'b0, arf_tag2};
    end else begin
      src_data2 = {1'b1, arf_read_data2};
    end
  end
endmodule

`default_nettype wire