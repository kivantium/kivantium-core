`default_nettype none

module loadBuffer(clk, reset, kill, en, misload, unit2buf, free_entry, commit_entry,
                  is_storing, store_addr, store_data);
  input wire clk, reset, kill, en;
  output logic misload;
  input wire [63:0] unit2buf;
  output logic [2:0] free_entry;
  input wire [2:0] commit_entry;
  input wire is_storing;
  input wire [31:0] store_addr, store_data;
  
  logic [7:0] busy;
  logic [31:0] addr [0:7];
  logic [31:0] data [0:7];
  logic [7:0] miss;
  
  assign misload = miss[commit_entry];
  
  always_ff @(posedge clk) begin
    if(reset || kill) begin
      busy <= 8'd1;
      miss <= 8'd0;
    end else begin
      if(en) begin
        busy[free_entry] <= 1'b1;
        addr[free_entry] <= unit2buf[63:32];
        data[free_entry] <= unit2buf[31:0];
        if(is_storing && store_addr==unit2buf[63:32]) miss[free_entry] <= 1'b1;
        else miss[free_entry] <= 1'b0;
      end
      if(commit_entry != 3'b000) begin
        busy[commit_entry] <= 1'b0;
      end
      if(is_storing) begin
        if     (busy[1] == 1'b1 && addr[1] == store_addr && data[1] != store_data) miss[1] <= 1'b1;
        else if(busy[2] == 1'b1 && addr[2] == store_addr && data[2] != store_data) miss[2] <= 1'b1;
        else if(busy[3] == 1'b1 && addr[3] == store_addr && data[3] != store_data) miss[3] <= 1'b1;
        else if(busy[4] == 1'b1 && addr[4] == store_addr && data[4] != store_data) miss[4] <= 1'b1;
        else if(busy[5] == 1'b1 && addr[5] == store_addr && data[5] != store_data) miss[5] <= 1'b1;
        else if(busy[6] == 1'b1 && addr[6] == store_addr && data[6] != store_data) miss[6] <= 1'b1;
        else if(busy[7] == 1'b1 && addr[7] == store_addr && data[7] != store_data) miss[7] <= 1'b1;
      end
    end
  end
  
  always_comb begin
    if     (busy[1] == 1'b0) free_entry = 3'b001;
    else if(busy[2] == 1'b0) free_entry = 3'b010;
    else if(busy[3] == 1'b0) free_entry = 3'b011;
    else if(busy[4] == 1'b0) free_entry = 3'b100;
    else if(busy[5] == 1'b0) free_entry = 3'b101;
    else if(busy[6] == 1'b0) free_entry = 3'b110; 
    else if(busy[6] == 1'b0) free_entry = 3'b110;
    else                     free_entry = 3'b000;
  end
endmodule

`default_nettype wire