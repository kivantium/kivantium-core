`default_nettype none


module reorderBuffer(clk, reset, stall, tag1, tag2, arf_dest, read_data1, read_data2,
                     dc2rob, free_entry, commit_dest, commit_data, commit_we,
                     cdb_int);
  input wire clk, reset, stall;
  input wire [5:0] tag1, tag2, arf_dest;
  output logic [32:0] read_data1, read_data2;
  input wire [38:0] dc2rob;
  output logic [5:0] free_entry;
  output logic [5:0] commit_dest;
  output logic [31:0] commit_data;
  output logic commit_we;
  input wire [37:0] cdb_int; 

  logic [63:0] busy, valid;
  logic [31:0] pc [0:63];
  logic [5:0] dest [0:63];
  logic [6:0] inst_type [0:63];
  logic [31:0] reg_data [0:63];

  logic [31:0] dc_pc;
  logic [6:0] dc_inst_type;
  logic [5:0] head;

  assign {dc_pc, dc_inst_type} = dc2rob;

  always_comb begin
    read_data1 = {valid[tag1], reg_data[tag1]};
    read_data2 = {valid[tag2], reg_data[tag2]};
  end

  always_ff @(posedge clk) begin
    if(reset) begin
      head <= 6'd1;
    end else begin
      if(valid[head]) begin
        commit_dest <= dest[head];
        commit_data <= reg_data[head];
        commit_we <= 1'b1;
        if(head == 6'd63) head <= 6'd1;
        else head <= head + 1'd1;
      end else begin
        commit_we <= 1'b0;
      end
    end
  end
  
  always_ff @(posedge clk) begin
    if(!stall) begin
      busy[free_entry] <= 1'b1;
      valid[free_entry] <= 1'b0;
      pc[free_entry] <= dc_pc;
      inst_type[free_entry] <= dc_inst_type;
      dest[free_entry] <= arf_dest;
    end
    valid[cdb_int[37:32]] <= 1'b1;
    reg_data[cdb_int[37:32]] <= cdb_int[31:0];
  end

  always_ff @(posedge clk) begin
    if(reset) begin
      free_entry <= 6'd0;
    end else if(!stall) begin
      if(free_entry == 6'd63) begin
        free_entry <= 6'd1;
      end else begin
        free_entry <= free_entry + 6'd1;
      end
    end
  end
endmodule

`default_nettype none