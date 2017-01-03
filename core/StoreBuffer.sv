`default_nettype none

module StoreBuffer(
  input wire clk, reset, we, mis_pred,
  input wire [31:0] store_data, store_addr,
  input wire [2:0] width,
  input wire [5:0] rob_dest,
  output logic is_full
);

  logic [31:0] data [0:7];
  logic [31:0] addr [0:7];
  logic [5:0] rob_entry [0:7];
  logic [0:0] is_complete [0:7];
  logic [2:0] free;
  always_ff @(posedge clk or posedge reset) begin
    if(reset) begin
      for(int i=0; i<8; i=i+1) rob_entry[i] <= 6'b000000;
    end else begin
      if(we) begin
        data[free] <= store_data;
        addr[free] <= store_addr;
        rob_entry[free] <= rob_dest;
        is_complete[free] <= 1'b0;
      end
    end
  end

  always_comb begin
    if(rob_entry[0] == 6'b000000) free = 3'b000;
    else if(rob_entry[1] == 6'b000000) free = 3'b001;
    else if(rob_entry[2] == 6'b000000) free = 3'b010;
    else if(rob_entry[3] == 6'b000000) free = 3'b011;
    else if(rob_entry[4] == 6'b000000) free = 3'b100;
    else if(rob_entry[5] == 6'b000000) free = 3'b101;
    else if(rob_entry[6] == 6'b000000) free = 3'b110;
    else if(rob_entry[7] == 6'b000000) free = 3'b111;
    else free = 2'bxx;
    
    if( rob_entry[0] != 6'b000000 && rob_entry[1] != 6'b000000
     && rob_entry[2] != 6'b000000 && rob_entry[3] != 6'b000000
     && rob_entry[4] != 6'b000000 && rob_entry[5] != 6'b000000
     && rob_entry[6] != 6'b000000 && rob_entry[7] != 6'b000000) is_full = 1'b1;
  end
  
endmodule

`default_nettype wire