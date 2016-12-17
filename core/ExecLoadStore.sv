`default_nettype none
module ExecLoadStore(
  input wire clk, reset, start,
  input wire [103:0] rs,
  input wire [31:0] memread_data,
  output logic [31:0] memread_addr, memwrite_addr, load_data,
  output logic [4:0] complete_rd,
  output logic memwrite_enable,
  output logic finish
);

  logic loadstore_op;
  logic [2:0] loadstore_width;
  logic [31:0] loadstore_base, loadstore_imm;
  logic [31:0] loadstore_src;
  logic [4:0] loadstore_dest;
  
  assign {loadstore_op, loadstore_width, loadstore_base, loadstore_imm,
          loadstore_src, loadstore_dest} = rs;

  logic [31:0] loadstore_addr;
  assign loadstore_addr = loadstore_base + loadstore_imm;
  logic state;
  
  always_ff @(posedge clk) begin
    if(start && state == 1'b0) begin
      state <= 1'b1;
      finish <= 1'b0;
      if(loadstore_op == 1'b0) begin
        complete_rd <= 5'b00000;
        memread_addr <= loadstore_base + loadstore_imm;
      end else if(loadstore_op == 1'b1) begin
        memwrite_addr <= loadstore_base + loadstore_imm;
        memwrite_enable <= 1'b1;
      end
    end else if(state == 1'b1) begin
      state <= 1'b0;
      memwrite_enable <= 1'b0;
      load_data <= memread_data;
      finish <= 1'b1;
      complete_rd <= loadstore_dest;
    end
  end
          
endmodule
`default_nettype wire