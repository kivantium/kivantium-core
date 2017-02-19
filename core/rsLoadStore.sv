module rsLoadStore(clk, reset, we, kill, is_full, dc2rs, rs2exe, load_en, store_en,
                   cdb1, cdb2, cdb3);
  input wire clk, reset, we, kill;
  output logic is_full;
  input wire [113:0] dc2rs;
  output logic [104:0] rs2exe;
  output logic load_en, store_en;
  input wire [37:0] cdb1, cdb2, cdb3;
  
  logic [9:0] rs_inst;
  logic [5:0] rs_dest;
  logic [32:0] rs_opr1, rs_opr2;
  logic [31:0] rs_pc, rs_offset;
 
  logic [3:0] busy, valid1, valid2; 
  logic [31:0] opr1 [0:3];
  logic [31:0] opr2 [0:3];
  logic [31:0] offset [0:3];
  logic [5:0] dest [0:3];
  logic [9:0] inst_type [0:3];
  logic [1:0] free_entry;
  logic [2:0] executing;
 
   assign {rs_inst, rs_dest, rs_opr1, rs_opr2, rs_offset} = dc2rs;
   assign is_full = &busy[3:0];
 
   always_ff @(posedge clk) begin
     if(reset || kill) begin
       busy <= 4'b0000;
     end else begin
       if(we && !is_full) begin
         busy[free_entry] <= 1'b1;
         valid1[free_entry] <= rs_opr1[32];
         opr1[free_entry] <= rs_opr1[31:0];
         valid2[free_entry] <= rs_opr2[32];
         opr2[free_entry] <= rs_opr2[31:0];
         inst_type[free_entry] <= rs_inst;
         offset[free_entry] <= rs_offset;
         dest[free_entry] <= rs_dest;
       end
   
       if(executing != 3'd4) busy[executing[1:0]] <= 1'b0;
   
       for(int i=0; i<4; i++) begin
         if(!valid1[i] && opr1[i]=={26'b0, cdb1[37:32]}) begin
           valid1[i] <= 1'b1;
           opr1[i] <= cdb1[31:0];
         end
         if(!valid2[i] && opr2[i]=={26'b0, cdb1[37:32]}) begin
           valid2[i] <= 1'b1;
           opr2[i] <= cdb1[31:0];
         end
         
         if(!valid1[i] && opr1[i]=={26'b0, cdb2[37:32]}) begin
           valid1[i] <= 1'b1;
           opr1[i] <= cdb2[31:0];
         end
         if(!valid2[i] && opr2[i]=={26'b0, cdb2[37:32]}) begin
           valid2[i] <= 1'b1;
           opr2[i] <= cdb2[31:0];
         end
         
         if(!valid1[i] && opr1[i]=={26'b0, cdb3[37:32]}) begin
           valid1[i] <= 1'b1;
           opr1[i] <= cdb3[31:0];
         end
         if(!valid2[i] && opr2[i]=={26'b0, cdb3[37:32]}) begin
           valid2[i] <= 1'b1;
           opr2[i] <= cdb3[31:0];
         end
       end
     end
   end
 
   always_comb begin
     if(busy[0]==1'b1 && valid1[0]==1'b1 && valid2[0]==1'b1) begin
       rs2exe = {inst_type[0][2:0], dest[0], opr1[0], opr2[0], offset[0]}; // 3+6+32*3 = 105
       executing = 3'd0;
       load_en = (inst_type[0][3] == 1'b0) ? 1'b1 : 1'b0;
       store_en = (inst_type[0][3] == 1'b0) ? 1'b0 : 1'b1;
     end else if(busy[1]==1'b1 && valid1[1]==1'b1 && valid2[1]==1'b1) begin
       rs2exe = {inst_type[1][2:0], dest[1], opr1[1], opr2[1], offset[1]};
       executing = 3'd1;
       load_en = (inst_type[1][3] == 1'b0) ? 1'b1 : 1'b0;
       store_en = (inst_type[1][3] == 1'b0) ? 1'b0 : 1'b1;
     end else if(busy[2]==1'b1 && valid1[2]==1'b1 && valid2[2]==1'b1) begin
       rs2exe = {inst_type[2][2:0], dest[2], opr1[2], opr2[2], offset[2]};
       executing = 3'd2;
       load_en = (inst_type[2][3] == 1'b0) ? 1'b1 : 1'b0;
       store_en = (inst_type[2][3] == 1'b0) ? 1'b0 : 1'b1;
     end else if(busy[3]==1'b1 && valid1[3]==1'b1 && valid2[3]==1'b1) begin
       rs2exe = {inst_type[3][2:0], dest[3], opr1[3], opr2[3], offset[3]};
       executing = 3'd3;
       load_en = (inst_type[3][3] == 1'b0) ? 1'b1 : 1'b0;
       store_en = (inst_type[3][3] == 1'b0) ? 1'b0 : 1'b1;
     end else begin
       rs2exe = 72'bx;
       executing = 3'd4;
       load_en = 1'b0;
       store_en = 1'b0;
     end
   end
 
   always_comb begin
     if(busy[0] == 1'b0) free_entry = 2'b00;
     else if(busy[1] == 1'b0) free_entry = 2'b01;
     else if(busy[2] == 1'b0) free_entry = 2'b10;
     else free_entry = 2'b11;
   end
   
endmodule
