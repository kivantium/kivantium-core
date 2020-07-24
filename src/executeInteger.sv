`default_nettype none

module executeInteger(rs1_data, rs2_data, imm_data, funct3, funct7, result, 
                      inst_op, inst_op_imm, inst_store, inst_load, inst_branch);
  input wire [31:0] rs1_data, rs2_data, imm_data;
  input wire [2:0] funct3;
  input wire [6:0] funct7;
  input wire inst_op, inst_op_imm, inst_store, inst_load, inst_branch;
  output logic [31:0] result;
  
  logic [31:0] opr2;

  assign opr2 = (inst_op_imm || inst_store || inst_load) ? imm_data : rs2_data;
  always_comb begin
    if(inst_op || inst_op_imm) begin
      case({funct7, funct3})
        // ADD, ADDI
        10'b0000000_000: result = rs1_data + opr2;
        // SUB
        10'b0100000_000: result = rs1_data - opr2;
        // SLL
        10'b0000000_001: result = rs1_data << opr2[4:0];
        // SLT, SLTI
        10'b0000000_010: result = $signed(rs1_data) < $signed(opr2) ? 32'b1 : 32'b0;
        // SLTU, SLTIU
        10'b0000000_011: result = $unsigned(rs1_data) < $unsigned(opr2) ? 32'b1 : 32'b0;
        // XOR, XORI
        10'b0000000_100: result = rs1_data ^ opr2;
        // SRL
        10'b0000000_101: result = $unsigned(rs1_data) >> opr2[4:0];
        // SRA
        10'b0100000_101: result = $signed(rs1_data) >> opr2[4:0];
        // OR, ORI
        10'b0000000_110: result = rs1_data | opr2;
        // AND, ANDI
        10'b0000000_111: result = rs1_data & opr2; 
        default: result = 32'b0;
      endcase
    end
    else if(inst_store || inst_load) result = rs1_data + opr2;
    else if(inst_branch) begin
      case(funct3)
        // BEQ
        3'b000: result = (rs1_data == opr2);
        // BNE
        3'b001: result = (rs1_data != opr2);
        // BLT
        3'b100: result = ($signed(rs1_data) < $signed(opr2));
        // BGE
        3'b101: result = ($signed(rs1_data) >= $signed(opr2));
        // BLTU
        3'b110: result = ($unsigned(rs1_data) < $unsigned(opr2));
        // BGEU
        3'b111: result = ($unsigned(rs1_data) >= $unsigned(opr2));
        default: result = 32'b0;
      endcase
    end
    else result = 32'b0;
  end
endmodule

`default_nettype wire