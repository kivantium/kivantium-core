`default_nettype none

module dataMemory(clk, reset, we, read_addr, read_data, write_addr, write_data,
                  stdout);
  input wire clk, reset, we;
  input wire [31:0] read_addr, write_addr, write_data;
  output logic [31:0] read_data;
  output logic [15:0] stdout;
  
  (* ram_style = "block" *) logic [31:0] dmem[1023:0];
  
  always_ff @(posedge clk) begin
    if(we) begin
      dmem[write_addr[11:2]] <= write_data;
    end
    read_data <= dmem[read_addr[11:2]];
  end
  
  always_ff @(posedge clk) begin
    if(we) begin
      if(write_addr == 32'b0) stdout <= write_data[15:0];
    end
  end
endmodule

`default_nettype wire