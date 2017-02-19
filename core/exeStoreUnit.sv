`default_nettype none

module exeStoreUnit(clk, reset, en, rs2exe, store2rob);
  input wire clk, reset, en;
  input wire [104:0] rs2exe;
  output logic [69:0] store2rob;
  
  logic [2:0] width;
  logic [5:0] dest;
  logic [31:0] opr1, opr2, offset, addr, cropped_data;
  
  assign {width, dest, opr1, opr2, offset} = rs2exe;
  
  always_comb begin
    if(en) begin
      addr = opr1 + offset;
      case(width) 
        3'b000: cropped_data = {{24{opr2[7]}}, opr2[7:0]};   // SB
        3'b001: cropped_data = {{16{opr2[15]}}, opr2[15:0]}; // SH
        3'b010: cropped_data = opr2;                         // SW
        default: cropped_data = 32'bx;
      endcase
      store2rob = {dest, addr, cropped_data};
    end else begin
      store2rob = {6'b000000, 32'bx, 32'bx};
    end
  end
endmodule

`default_nettype wire