`default_nettype none
module ExecLoadStore(
  input wire clk, reset, enable,
  input wire [104:0] rs,
  input wire [31:0] memread_data,
  output logic [31:0] memread_addr, memwrite_addr, memwrite_data, complete_data,
  output logic [4:0] complete_rd,
  output logic memwrite_enable
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
  
  logic [1:0] state;
  
  always_ff @(posedge clk or posedge reset) begin
    if(reset) begin
      state <= 2'b00;
    end else if(enable) begin
      if(state == 2'b00) begin
        state <= 2'b01;
      end else if(state == 2'b01) begin
        state <= 2'b11;
      end else begin
        state <= 2'b00;
      end
    end else begin
      state <= 2'b00;
    end
  end

  always_comb begin
    if(loadstore_op == 1'b0) begin  // load
      memwrite_enable = 1'b0;
      memwrite_addr = 32'bx;
      if(state == 2'b01) begin
          memread_addr = loadstore_base + loadstore_imm;
          complete_data = memread_data;
          complete_rd = loadstore_dest;
      end else if(state == 2'b11) begin
          memread_addr = loadstore_base + loadstore_imm;
          complete_data = memread_data;
          complete_rd = loadstore_dest;
      end else begin
          memread_addr = loadstore_base + loadstore_imm;
          complete_data = memread_data;
          complete_rd = loadstore_dest;
      end
    end else begin                   // store
      complete_data = 32'bx;
      complete_rd = 5'b00000;
      memread_addr = 32'bx;
      if(state == 2'b01) begin
        memwrite_addr = loadstore_base + loadstore_imm;
        memwrite_data = loadstore_src;
        memwrite_enable = 1'b1;
      end else begin
        memwrite_enable = 1'b0;
        memwrite_addr = 32'bx;
      end
    end
  end        
endmodule
`default_nettype wire