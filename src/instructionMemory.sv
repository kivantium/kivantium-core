`default_nettype none

module instructionMemory(clk, reset, addr, inst);
  input wire clk, reset;
  input wire [31:0] addr;
  output logic [31:0] inst;

  (* ram_style = "block" *) 
  logic [31:0] mem [0:63];
    
  initial begin
    $readmemh("/home/kivantium/test.hex", mem);
    
  end
     
  always_ff @(posedge clk) begin
    if(!reset) begin
      inst <= mem[addr[7:2]];
    end
  end

endmodule

`default_nettype none
