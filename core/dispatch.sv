`default_nettype none
`include "constants.vh"

module decode(pc, inst, src_reg1, src_reg2, rd_reg, dest_rob,
                src_data1, src_data2, dc2rob, dc2rs, rs_dest);
  input wire [31:0] pc, inst;
  output logic [5:0] src_reg1, src_reg2, rd_reg;
  input wire [5:0] dest_rob;
  input wire [32:0] src_data1, src_data2;
  output logic [38:0] dc2rob;
  output logic [113:0] dc2rs;
  output logic [3:0] rs_dest;

  logic [6:0] inst_type;

  assign dc2rob = {pc, inst_type};
  assign inst_type = inst[6:0];

  logic [9:0] rs_inst;
  logic [32:0] rs_opr1, rs_opr2;
  logic [31:0] rs_offset;

  assign dc2rs = {rs_inst, dest_rob, rs_opr1, rs_opr2, rs_offset}; // 10+6+33*2+32 = 114

  always_comb begin
    case(inst_type)
      `LOAD: begin
        rs_dest = 4'b0010;
        src_reg1 = {1'b0, inst[19:15]};
        src_reg2 = {1'b0, 6'd0};
        rd_reg = {1'b0, inst[11:7]};
        rs_inst = {7'b0, inst[14:12]};
        rs_opr1 = src_data1;
        rs_opr2 = src_data2;
        rs_offset = {{20{inst[31]}}, inst[31:20]};
      end
      `LOAD_FP: begin
        rs_dest = 4'b0010;
        src_reg1 = {1'b0, inst[19:15]};
        src_reg2 = {1'b0, 6'd0};
        rd_reg = {1'b1, inst[11:7]};
        rs_inst = {7'b0, inst[14:12]};
        rs_opr1 = src_data1;
        rs_opr2 = src_data2;
        rs_offset = {{20{inst[31]}}, inst[31:20]};
      end
      `OP_IMM: begin
        rs_dest = 4'b1000;
        src_reg1 = {1'b0, inst[19:15]};
        src_reg2 = 6'd0;
        rd_reg = {1'b0, inst[11:7]};
        rs_inst = {7'b0, inst[14:12]};
        rs_opr1 = src_data1;
        rs_opr2 = {1'b1, {20{inst[31]}}, inst[31:20]};
        rs_offset = 32'd0;
       end  
      `STORE: begin
        rs_dest = 4'b0010;
        src_reg1 = {1'b0, inst[19:15]};
        src_reg2 = {1'b0, inst[24:20]};
        rd_reg = 6'd0;
        rs_inst = {7'b1, inst[14:12]};
        rs_opr1 = src_data1;
        rs_opr2 = src_data2;
        rs_offset = {{20{inst[31]}}, inst[31:25], inst[11:7]};
      end
      `STORE_FP: begin
        rs_dest = 4'b0010;
        src_reg1 = {1'b0, inst[19:15]};
        src_reg2 = {1'b1, inst[24:20]};
        rd_reg = 6'd0;
        rs_inst = {7'b1, inst[14:12]};
        rs_opr1 = src_data1;
        rs_opr2 = src_data2;
        rs_offset = {{20{inst[31]}}, inst[31:25], inst[11:7]};
      end
      `OP: begin
        rs_dest = 4'b1000;
        src_reg1 = {1'b0, inst[19:15]};
        src_reg2 = {1'b0, inst[24:20]};
        rd_reg = {1'b0, inst[11:7]};
        rs_inst = {inst[31:25], inst[14:12]};
        rs_opr1 = src_data1;
        rs_opr2 = src_data2;
        rs_offset = 32'd0;
      end
      `LUI: begin
        rs_dest = 4'b1000;
        src_reg1 = 6'd0;
        src_reg2 = 6'd0;
        rd_reg = {1'b0, inst[11:7]};
        rs_inst = 10'b0;
        rs_opr1 = src_data1;
        rs_opr2 = {1'b1, inst[31:12], 12'b0};
        rs_offset = 32'bx;
      end
      `OP_FP: begin
        rs_dest = 4'b0001;
        src_reg1 = {1'b1, inst[19:15]};
        src_reg2 = {1'b1, inst[24:20]};
        rd_reg = {1'b1, inst[11:7]};
        rs_inst = {inst[31:25], inst[14:12]};
        rs_opr1 = src_data1;
        rs_opr2 = src_data2;
        rs_offset = 32'bx;
      end
      `BRANCH: begin
        rs_dest = 4'b0100;
        src_reg1 = {1'b0, inst[19:15]};
        src_reg2 = {1'b0, inst[24:20]};
        rd_reg = 6'd0;
        rs_inst = {7'b0, inst[14:12]};
        rs_opr1 = src_data1;
        rs_opr2 = src_data2;
        rs_offset = pc + {{20{inst[31]}}, inst[7], inst[30:25], inst[11:8], 1'b0};
      end
      `JALR: begin
        rs_dest = 4'b0100;
        src_reg1 = {1'b0, inst[19:15]};
        src_reg2 = 6'd0;
        rd_reg = inst[11:7];
        rs_inst = 10'b1000000_000;
        rs_opr1 = src_data1;
        rs_opr2 = {1'b1, {{20{inst[31]}}, inst[31:20]}};
        rs_offset = pc + 32'd4;
      end
      `JAL: begin
        rs_dest = 4'b0100;
        src_reg1 = 6'd0;
        src_reg2 = 6'd0;
        rd_reg = inst[11:7];
        rs_inst = 10'b0100000_000;
        rs_opr1 = {1'b1, pc};
        rs_opr2 = {1'b1, {12{inst[31]}}, inst[19:12], inst[20], inst[30:21], 1'b0};
        rs_offset = pc + 32'd4;
      end
      default: begin
        rs_dest = 4'b0000;
        src_reg1 = 6'bxxxxx;
        src_reg2 = 6'bxxxxx;
        rd_reg = 6'bxxxxx;
        rs_inst = 10'bxxxx;
        rs_opr1 = 33'bx;
        rs_opr2 = 33'bx;
        rs_offset = 32'bx;
      end
    endcase
  end
endmodule

`default_nettype wire