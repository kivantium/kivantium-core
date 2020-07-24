`default_nettype none

module registerFile(
         clk, reset, read_reg1, read_reg2, read_data1, read_data2, 
         write_reg, write_data, write_enable, register1);

  input wire clk, reset;
  input wire [4:0] read_reg1, read_reg2;
  output logic [31:0] read_data1, read_data2;
  input wire write_enable;
  input wire [4:0] write_reg;
  input wire [31:0] write_data;
  output logic[15:0] register1;
  
  logic [31:0] rf [0:31];
  
  assign read_data1 = (read_reg1==5'd0) ? 32'd0 : rf[read_reg1];
  assign read_data2 = (read_reg2==5'd0) ? 32'd0 : rf[read_reg2];
  assign register1 = rf[5'd10];
  
  always_ff @(posedge clk) begin
    if(reset) begin
      for(int i=0; i<32; i++) begin
        rf[i] <= 32'd0;
      end
    end
    else if(write_enable) rf[write_reg] <= write_data;
  end
   
endmodule
`default_nettype wire