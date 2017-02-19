`default_nettype none
`include "constants.vh"

module reorderBuffer(clk, reset, stall, kill, tag1, tag2, arf_dest, read_data1, read_data2,
                     dc2rob, free_entry, commit_dest, commit_tag, commit_data, commit_we,
                     cdb1, cdb2, cdb3, jump_addr, mispred, commit_pc,
                     store2rob, loadbuf_en, loadbuf_free_entry, loadbuf_commit_entry,
                     dmem_we, store_addr, store_data, misload,
                     rob_head_pc);
  input wire clk, reset, stall, kill;
  input wire [5:0] tag1, tag2, arf_dest;
  output logic [32:0] read_data1, read_data2;
  input wire [38:0] dc2rob;
  output logic [5:0] free_entry;
  output logic [5:0] commit_dest, commit_tag;
  output logic [31:0] commit_data;
  output logic commit_we;
  input wire [37:0] cdb1, cdb2, cdb3;
  input wire [38:0] jump_addr;
  output logic mispred;
  output logic [31:0] commit_pc;
  input wire [69:0] store2rob;
  input wire loadbuf_en;
  input wire [2:0] loadbuf_free_entry;
  output logic [2:0] loadbuf_commit_entry;
  output logic dmem_we;
  output logic [31:0] store_addr, store_data;
  input wire misload;
  output logic [31:0] rob_head_pc;

  logic [63:0] busy, valid, taken;
  logic [5:0] dest [0:63];
  logic [6:0] inst_type [0:63];
  logic [2:0] load_entry [0:63];
  logic commit_we_pre;
  // warning: could not implement as ram
  logic [31:0] reg_data [0:63];
  logic [31:0] pc [0:63];
  logic [31:0] addr [0:63];

  logic [31:0] dc_pc;
  logic [6:0] dc_inst_type;
  logic [5:0] head;

  assign {dc_pc, dc_inst_type} = dc2rob;
  assign commit_we = (misload == 1'b1) ? 1'b0 : commit_we_pre; 

  always_comb begin
    read_data1 = {valid[tag1], reg_data[tag1]};
    read_data2 = {valid[tag2], reg_data[tag2]};
  end

  assign rob_head_pc = pc[head];
  always_ff @(posedge clk) begin
    if(reset || kill) begin
      head <= 6'd1;
    end else begin
      if(valid[head]) begin
        busy[head] <= 1'b0;
        if(head == 6'd63) head <= 6'd1;
        else head <= head + 1'd1;
      end
    end
  end
  
  always_comb begin
    if(valid[head]) begin
      if(inst_type[head] == `STORE || inst_type[head] == `STORE_FP) begin
        dmem_we = 1'b1;
        store_addr = addr[head];
        store_data = reg_data[head];
        commit_we_pre = 1'b0;
        commit_dest = 6'bx;
        commit_tag = 6'bx;
        commit_data = 32'bx;   
        loadbuf_commit_entry = 3'b000;
        commit_pc = 32'bx;
        mispred = 1'b0;
      end else if(inst_type[head] == `LOAD || inst_type[head] == `LOAD_FP) begin
        dmem_we = 1'b0;
        store_addr = 32'bx;
        store_data = 32'bx;
        commit_we_pre = 1'b1;
        commit_dest = dest[head];
        commit_tag = head;
        commit_data = reg_data[head];          
        loadbuf_commit_entry = load_entry[head];
        commit_pc = pc[head];
        mispred = 1'b0;
      end else begin
        dmem_we = 1'b0;
        store_addr = 32'bx;
        store_data = 32'bx;
        commit_we_pre = 1'b1;
        commit_dest = dest[head];
        commit_tag = head;
        commit_data = reg_data[head];
        loadbuf_commit_entry = 3'b000;
        if(taken[head]) begin
          mispred = 1'b1;
          commit_pc = addr[head];
        end else begin
          mispred = 1'b0;
          commit_pc = 32'bx;
        end
      end
    end else begin
      dmem_we = 1'b0;
      store_addr = 32'bx;
      store_data = 32'bx;
      commit_we_pre = 1'b0;
      commit_dest = 6'bx;
      commit_tag = 6'bx;
      commit_data = 32'bx;   
      loadbuf_commit_entry = 3'b000;
      commit_pc = 32'bx;
      mispred = 1'b0;
    end
  end
  
  always_ff @(posedge clk) begin
    if(reset || mispred) begin
      busy <= 64'b0;
      valid <= 64'b0;
      taken <= 64'b0;
    end else begin
      if(!stall) begin
        busy[free_entry] <= 1'b1;
        valid[free_entry] <= 1'b0;
        taken[free_entry] <= 1'b0;
        pc[free_entry] <= dc_pc;
        inst_type[free_entry] <= dc_inst_type;
        dest[free_entry] <= arf_dest;
      end
      valid[cdb1[37:32]] <= 1'b1;      
      reg_data[cdb1[37:32]] <= cdb1[31:0];
      valid[cdb2[37:32]] <= 1'b1;
      reg_data[cdb2[37:32]] <= cdb2[31:0];
      valid[cdb3[37:32]] <= 1'b1;
      reg_data[cdb3[37:32]] <= cdb3[31:0];
      
      if(loadbuf_en) begin 
        load_entry[cdb3[37:32]] <= loadbuf_free_entry;
      end
      
      addr[jump_addr[38:33]] <= jump_addr[31:0];
      taken[jump_addr[38:33]] <= jump_addr[32];
      valid[jump_addr[38:33]] <= 1'b1;
      valid[store2rob[69:64]] <= 1'b1;
      addr[store2rob[69:64]] <= store2rob[63:32];
      reg_data[store2rob[69:64]] <= store2rob[31:0];
    end
  end

  always_ff @(posedge clk) begin
    if(reset || mispred) begin
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