`default_nettype none
module exeLoadUnit(clk, reset, enable, rs2exe, load_addr, load_data, dmem_write_addr, dmem_write_data, loadunit2buf, en_loadbuf, cdb);
  input wire clk, reset, enable;
  input wire [104:0] rs2exe;
  output logic [31:0] load_addr;
  input wire [31:0] load_data, dmem_write_addr, dmem_write_data;
  output logic [63:0] loadunit2buf;
  output logic en_loadbuf;
  output logic [37:0] cdb;
  
  logic [2:0] width;
  logic [5:0] dest;
  logic [31:0] opr1, opr2, offset;
  logic loading;
  assign {width, dest, opr1, opr2, offset} = rs2exe;
  
  logic [31:0] pipe_addr;
  logic [5:0] pipe_dest;
  logic [2:0] pipe_width;
  logic pipe_loading;
  logic [31:0] crop_data, bypass_data, raw_data;
  logic bypass;
  
  always_comb begin
    if(enable) begin
      load_addr = opr1 + offset;
      loading = 1'b1;
    end else begin
      load_addr = 32'bx;
      loading = 1'b0;
    end
  end
  
  always_ff @(posedge clk) begin
    if(load_addr == dmem_write_addr) begin
      bypass_data <= dmem_write_data;
      bypass <= 1'b1;
    end else begin
      bypass <= 1'b0;
    end
    pipe_addr <= load_addr;
    pipe_dest <= dest;
    pipe_width <= width;
    pipe_loading <= loading;
  end
  
  always_comb begin
    if(pipe_loading) begin
      if(bypass) raw_data = bypass_data;
      else raw_data = load_data;
      case(pipe_width) 
        3'b000: crop_data = {{24{raw_data[7]}}, raw_data[7:0]};
        3'b001: crop_data = {{16{raw_data[15]}}, raw_data[15:0]};
        3'b010: crop_data = raw_data;
        3'b100: crop_data = {24'b0, raw_data[7:0]};
        3'b101: crop_data = {16'b0, raw_data[15:0]};
        default: crop_data = 32'bx;
      endcase
      cdb = {pipe_dest, crop_data};
      loadunit2buf = {pipe_addr, crop_data};
      en_loadbuf = 1'b1;
    end else begin
      crop_data = 32'bx;
      cdb = {6'b000000, 32'bx};
      loadunit2buf = 64'bx;
      en_loadbuf = 1'b0;
    end
  end      
endmodule
`default_nettype wire