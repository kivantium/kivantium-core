`default_nettype none

module ExecBranch(
  input wire clk, reset, rs_dest, 
  input wire [139:0] rs_data,
  output logic rs_is_full,
  output logic [37:0] cdb_data
);
 
  // reservation size = 4
  logic [3:0] busy;
  logic [139:0] rs [0:3];

  assign rs_is_full = &busy[3:0];

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
           valid2[0], operand2[0], inst_pc[0], offset[0]} <= rs_data; 
        end else if(!busy[1]) begin
          busy[1] <= 1'b1;
          {operation[1], rob_dest[1], valid1[1], operand1[1],
           valid2[1], operand2[1], inst_pc[1], offset[1]} <= rs_data;
        end else if(!busy[2]) begin
          busy[2] <= 1'b1;
          {operation[2], rob_dest[2], valid1[2], operand1[2],
           valid2[2], operand2[2], inst_pc[2], offset[2]} <= rs_data;
        end else if(!busy[3]) begin
          busy[3] <= 1'b1;
          {operation[3], rob_dest[3], valid1[3], operand1[3],
           valid2[3], operand2[3], inst_pc[3], offset[3]} <= rs_data;          
        end      
      end
    end
  end
  
  logic ex_en;
  logic [3:0] ex_opr;
  logic [5:0] ex_dest;
  logic [31:0] ex_op1, ex_op2, ex_offset, ex_pc;
  
  always_ff @(posedge clk) begin
    if(busy[0] && valid1[0] && valid2[0]) begin
      busy[0] <= 1'b0;
      {ex_en, ex_opr, ex_dest, ex_op1, ex_op2, ex_offset, ex_pc} 
        <= {1'b1, operation[0], rob_dest[0], operand1[0], operand2[0], offset[0], inst_pc[0]};
    end else if(busy[1] && valid1[1] && valid2[1]) begin
      busy[1] <= 1'b0;
      {ex_en, ex_opr, ex_dest, ex_op1, ex_op2, ex_offset, ex_pc}
        <= {1'b1, operation[1], rob_dest[1], operand1[1], operand2[1], offset[1], inst_pc[1]};
    end else if(busy[2] && valid1[2] && valid2[2]) begin
      busy[2] <= 1'b0;
      {ex_en, ex_opr, ex_dest, ex_op1, ex_op2, ex_offset, ex_pc} 
        <= {1'b1, operation[2], rob_dest[2], operand1[2], operand2[2], offset[2], inst_pc[2]};
    end else if(busy[3] && valid1[3] && valid2[3]) begin
      busy[3] <= 1'b0;
      {ex_en, ex_opr, ex_dest, ex_op1, ex_op2, ex_offset, ex_pc}
        <= {1'b1, operation[3], rob_dest[3], operand1[3], operand2[3], offset[3], inst_pc[3]};
    end
  end

  always_comb begin
    if(!ex_en) begin
      cdb_data = {6'b000000, 32'bx};
    end else begin
      logic [31:0] next_pc;
      cdb_data = {ex_dest, next_pc};
      case(ex_opr)
        // JAL
        5'b10: begin
          next_pc = ex_pc + ex_offset;
        end
        // JALR
        5'b11: begin
          next_pc = ex_op1 + ex_offset;
        end
        // conditional branch
        5'b00: begin
          case(ex_opr[2:0])
            // BEQ
            3'b000: begin
              if(ex_op1 == ex_op2) begin
                next_pc = ex_pc + ex_offset;
              end else begin
                 next_pc = ex_pc + 32'd4;
               end
            end
            // BNE
            3'b001: begin
              if(ex_op1 != ex_op2) begin
                next_pc = ex_pc + ex_offset;
              end else begin
                next_pc = ex_pc + 32'd4;
              end
            end
            // BLT
            3'b100: begin
              if($signed(ex_op1) < $signed(ex_op2)) begin
                next_pc = ex_pc + ex_offset;
              end else begin
                next_pc = ex_pc + 32'd4;
              end
            end
            // BGE
            3'b101: begin
              if($signed(ex_op1) >= $signed(ex_op2)) begin
                next_pc = ex_pc + ex_offset;
              end else begin
                next_pc = ex_pc + 32'd4;
              end
            end
            // BLTU
            3'b110: begin
              if($unsigned(ex_op1) < $unsigned(ex_op2)) begin
                next_pc = ex_pc + ex_offset;
              end else begin
                next_pc = ex_pc + 32'd4;
              end
            end
            // BGEU
            3'b111: begin
              if($unsigned(ex_op1) >= $unsigned(ex_op2)) begin
                next_pc = ex_pc + ex_offset;
              end else begin
                next_pc = ex_pc + 32'd4;
              end
            end
            default: begin
            end
          endcase
        end
        default: begin
          next_pc = 32'dx;
        end

      endcase
    end
  end
endmodule

`default_nettype wire