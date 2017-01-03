`default_nettype none
module ExecLoadStore(
  input wire clk, reset, rs_dest, 
  input wire mis_pred,
  input wire [107:0] rs_data,
  input wire [31:0] dmem_read_data,
  output logic rs_is_full,
  output logic [37:0] cdb_data,
  output logic [31:0] dmem_read_addr
);
  // reservation size = 4
  logic [3:0] busy;
  logic [107:0] rs [0:3];
  logic [3:0] operation [0:3];
  logic [5:0] rob_dest [0:3];
  logic [3:0] valid1, valid2;
  logic [31:0] operand1 [0:3];
  logic [31:0] operand2 [0:3];
  logic [31:0] inst_pc [0:3];
  logic [31:0] offset [0:3];
  
  always_ff @(posedge clk or posedge reset) begin
    if(reset) begin
      busy <= 4'b0;
    end else begin
       if(rs_dest) begin
         if(!busy[0]) begin 
           busy[0] <= 1'b1;
           {operation[0], rob_dest[0], valid1[0], operand1[0], 
            valid2[0], operand2[0], offset[0]} <= rs_data; 
         end else if(!busy[1]) begin
           busy[1] <= 1'b1;
           {operation[1], rob_dest[1], valid1[1], operand1[1],
            valid2[1], operand2[1], offset[1]} <= rs_data;
         end else if(!busy[2]) begin
           busy[2] <= 1'b1;
           {operation[2], rob_dest[2], valid1[2], operand1[2],
            valid2[2], operand2[2], offset[2]} <= rs_data;
         end else if(!busy[3]) begin
           busy[3] <= 1'b1;
           {operation[3], rob_dest[3], valid1[3], operand1[3],
            valid2[3], operand2[3], offset[3]} <= rs_data;          
         end      
       end
     end
   end


   logic [31:0] load_data [0:7];
   logic [31:0] load_addr [0:7];
   logic [31:0] store_data, store_addr;
   logic load_buf_we, store_buf_we, load_is_full, store_is_full;
   logic [2:0] width;
   logic [5:0] rob_dest_buf;
   
   LoadBuffer lb(.clk(clk), .reset(reset), .we(load_buf_we), .is_full(load_is_full),
                 .load_data(dmem_read_data), .load_addr(dmem_read_addr), .width(width),
                 .rob_dest(rob_dest_buf), .cdb_data(cdb_data));
   StoreBuffer sb(.clk(clk), .reset(reset), .we(store_buf_we), .mis_pred(mis_pred),
                  .is_full(store_is_full), .store_data(store_data), .store_addr(store_addr),
                  .width(width), .rob_dest(rob_dest_buf));
   always_ff @(posedge clk) begin
     if(busy[0] && valid1[0] && valid2[0]) begin
       busy[0] <= 1'b0;
       width <= operation[0][2:0];
       rob_dest_buf <= rob_dest[0];
       if(operation[0][3] == 1'b0 && !load_is_full) begin
         dmem_read_addr <= operand1[0] + offset[0];
         load_buf_we <= 1'b1;
         store_buf_we <= 1'b0;
       end else if(operation[0][3] == 1'b1 && !store_is_full) begin
         store_addr <= operand1[0] + offset[0];
         store_data <= operand2[0]; 
         store_buf_we <= 1'b1;
         load_buf_we <= 1'b0;
      end
     end else if(busy[1] && valid1[1] && valid2[1]) begin
       busy[1] <= 1'b0;
       width <= operation[1][2:0];
       rob_dest_buf <= rob_dest[1];
       if(operation[1][3] == 1'b0 && !load_is_full) begin
         dmem_read_addr <= operand1[1] + offset[1];
         load_buf_we <= 1'b1;
         store_buf_we <= 1'b0;
       end else if(operation[1][3] == 1'b1 && !store_is_full) begin
         store_addr <= operand1[1] + offset[1];
         store_data <= operand2[1]; 
         store_buf_we <= 1'b1;
         load_buf_we <= 1'b0;
      end
     end else if(busy[2] && valid1[2] && valid2[2]) begin
       busy[2] <= 1'b0;
       width <= operation[1][2:0];
       rob_dest_buf <= rob_dest[1];
       if(operation[2][3] == 1'b0 && !load_is_full) begin
         dmem_read_addr <= operand1[2] + offset[2];
         load_buf_we <= 1'b1;
         store_buf_we <= 1'b0;
       end else if(operation[2][3] == 1'b1 && !store_is_full) begin
         store_addr <= operand1[2] + offset[2];
         store_data <= operand2[2]; 
         store_buf_we <= 1'b1;
         load_buf_we <= 1'b0;
      end
     end else if(busy[3] && valid1[3] && valid2[3]) begin
       busy[3] <= 1'b0;
       width <= operation[3][2:0];
       rob_dest_buf <= rob_dest[3];
       if(operation[3][3] == 1'b0 && !load_is_full) begin
         dmem_read_addr <= operand1[3] + offset[3];
         load_buf_we <= 1'b1;
         store_buf_we <= 1'b0;
       end else if(operation[3][3] == 1'b1 && !store_is_full) begin
         store_addr <= operand1[3] + offset[3];
         store_data <= operand2[3]; 
         store_buf_we <= 1'b1;
         load_buf_we <= 1'b0;
      end
      end else begin
        store_buf_we <= 1'b0;
        load_buf_we <= 1'b0;
      end
   end
endmodule
`default_nettype wire