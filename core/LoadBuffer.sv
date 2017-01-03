`default_nettype none
module LoadBuffer(
  input wire clk, reset, we,
  input wire [31:0] load_addr, load_data,
  input wire [2:0] width,
  input wire [5:0] rob_dest,
  output logic is_full,
  output logic [37:0] cdb_data
);

  logic [1:0] free;
  logic [31:0] addr [0:3];
  logic [31:0] data [0:3];
  logic [5:0] rob_entry [0:3];
  always_ff @(posedge clk or posedge reset) begin
    if(reset) begin
      for(int i=0; i<4; i=i+1) rob_entry[i] <= 3'b000;
    end else if(we) begin
      data[free] <= load_data;
      addr[free] <= load_addr;
      rob_entry[free] <= rob_dest;
    end
  end
  
  always_comb begin
    if(rob_entry[0] == 6'b000000) free = 2'b00;
    else if(rob_entry[1] == 6'b000000) free = 2'b01;
    else if(rob_entry[2] == 6'b000000) free = 2'b10;
    else if(rob_entry[3] == 6'b000000) free = 2'b11;
    else free = 2'bxx;
    
    if( rob_entry[0] != 6'b000000 && rob_entry[1] != 6'b000000
     && rob_entry[2] != 6'b000000 && rob_entry[3] != 6'b000000) is_full = 1'b1;
  end
      
endmodule
`default_nettype wire