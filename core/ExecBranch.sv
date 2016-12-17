`default_nettype none

module ExecBranch(
  input wire clk, reset, start,
  input wire [105:0] rs,
  input wire [31:0] pc,
  output logic finish,
  output logic [31:0] branch_pc
);
  
  logic [4:0] branch_op;
  logic [4:0] branch_rd;
  logic [31:0] branch_src1, branch_src2;
  logic [31:0] branch_imm;
  
  assign {branch_op, branch_rd, branch_src1, branch_src2, branch_imm} = rs;
  
  logic [31:0] next_branch_pc;
  
  always_ff @(posedge clk) begin
    branch_pc <= next_branch_pc;
  end
  
  always_comb begin
    case(branch_op[4:3])
      // JAL
      5'b10: begin
      end
      // JALR
      5'b11: begin
      end
      // conditional branch
      5'b00: begin
        case(branch_op[2:0])
          // BEQ
          3'b000: begin
            if(branch_src1 == branch_src2) begin
              next_branch_pc = pc + branch_imm;
            end else begin
               next_branch_pc = pc + 32'd4;
             end
          end
          // BNE
          3'b001: begin
            if(branch_src1 != branch_src2) begin
              next_branch_pc = pc + branch_imm;
            end else begin
              next_branch_pc = pc + 32'd4;
            end
          end
          // BLT
          3'b100: begin
            if($signed(branch_src1) < $signed(branch_src2)) begin
              next_branch_pc = pc + branch_imm;
            end else begin
              next_branch_pc = pc + 32'd4;
            end
          end
          // BGE
          3'b101: begin
            if($signed(branch_src1) >= $signed(branch_src2)) begin
              next_branch_pc = pc + branch_imm;
            end else begin
              next_branch_pc = pc + 32'd4;
            end
          end
          // BLTU
          3'b110: begin
            if($unsigned(branch_src1) < $unsigned(branch_src2)) begin
              next_branch_pc = pc + branch_imm;
            end else begin
              next_branch_pc = pc + 32'd4;
            end
          end
          // BGEU
          3'b111: begin
            if($unsigned(branch_src1) >= $unsigned(branch_src2)) begin
              next_branch_pc = pc + branch_imm;
            end else begin
              next_branch_pc = pc + 32'd4;
            end
          end
        endcase
      end
    endcase
  end
endmodule

`default_nettype wire