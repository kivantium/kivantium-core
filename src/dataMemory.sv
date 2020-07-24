`default_nettype none

module dataMemory(
    clk, reset, read_addr, read_data, write_addr, write_data, write_enable);
  
  input wire clk, reset, write_enable;
  input wire [31:0] read_addr, write_addr, write_data;
  output logic[31:0] read_data;
  
  (* ram_style = "block" *) 
  logic [31:0] mem [0:4095];
  
  always_ff @(posedge clk) begin
    if(reset) begin
      for(int i=0; i<4096; i=i+1) mem[i] <= 32'd0;      
    end else begin
      read_data <= mem[read_addr[8:2]];
      if(write_enable) begin
       mem[write_addr[8:2]] <= write_data;
      end
    end
  end
endmodule
`default_nettype wire