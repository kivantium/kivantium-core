`default_nettype none

module registerFile(clk, reset, read_reg1, read_reg2, read_data1, read_data2, read_tag1, read_tag2,
                    dc_rd, rob_free_entry);
  input wire clk, reset;
  input wire [5:0] read_reg1, read_reg2;
  output logic [32:0] read_data1, read_data2;
  output logic [5:0] read_tag1, read_tag2;
  input wire [5:0] dc_rd, rob_free_entry;
  
  logic [31:0] rf [0:63];
  logic [5:0] tag [0:63];
  logic [63:0] busy;
  
  assign read_data1 = (read_reg1==6'd0) ? {1'b0, 32'd0} : {busy[read_reg1], rf[read_reg1]};
  assign read_data2 = (read_reg2==6'd0) ? {1'b0, 32'd0} : {busy[read_reg2], rf[read_reg2]};
  assign read_tag1  = tag[read_reg1];
  assign read_tag2  = tag[read_reg2];
  
  always_ff @(posedge clk) begin
    if(reset) begin
      for(int i=0; i<64; i++) begin
        tag[i] <= 6'd0;
        busy[i] <= 1'b0;
      end
    end else begin
      busy[dc_rd] <= 1'b1;
      tag[dc_rd] <= rob_free_entry;
    end
  end
endmodule
`default_nettype wire