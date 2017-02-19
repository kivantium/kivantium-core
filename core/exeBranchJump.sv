`default_nettype none

module exeBranchJump(en, rs2exe, cdb, jump_addr);
  input wire en;
  input wire [111:0] rs2exe;
  output logic [37:0] cdb;
  output logic [38:0] jump_addr;

  logic [9:0] inst;
  logic [5:0] dest;
  logic [31:0] opr1, opr2, addr, result;
  logic is_taken;

  assign {inst, dest, opr1, opr2, addr} = rs2exe;

  always_comb begin
    if(en) begin
      case(inst[9:3])
        7'b1000000: begin    // JALR
          cdb = {dest, addr};
          jump_addr = {dest, 1'b1, opr1 + opr2};
        end 
        7'b0100000: begin    // JAL
          cdb = {dest, addr};
          jump_addr = {dest, 1'b1, opr1 + opr2};
        end
        // BEQ
        7'b0000000: begin
          cdb = {6'b0, 32'dx};
          case(inst[2:0])
            // BEQ
            3'b000: is_taken = (opr1 == opr2) ? 1'b1 : 1'b0;
            // BNE
            3'b001: is_taken = (opr1 != opr2) ? 1'b1 : 1'b0;
            // BLT
            3'b100: is_taken = ($signed(opr1) < $signed(opr2)) ? 1'b1 : 1'b0;
            // BGE
            3'b101: is_taken = ($signed(opr1) >= $signed(opr2)) ? 1'b1 : 1'b0;
            // BLTU
            3'b110: is_taken = ($unsigned(opr1) < $unsigned(opr2)) ? 1'b1 : 1'b0;
            // BGEU
            3'b111: is_taken = ($unsigned(opr1) >= $unsigned(opr2)) ? 1'b1 : 1'b0;
            default: is_taken = 1'bx;
          endcase
          jump_addr = {dest, is_taken, addr};
        end
        default: begin
          cdb = {6'b0, 32'dx};
          jump_addr = {6'b0, 1'b0, 32'dx};
        end
      endcase
    end else begin
      cdb = {6'b0, 32'dx};
      jump_addr = {6'b0, 1'b0, 32'dx};
    end
  end
endmodule

`default_nettype wire