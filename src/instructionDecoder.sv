`default_nettype none

module instructionDecoder(
    instruction, rs1_num, rs2_num, rd_num, imm, funct3, funct7,
    inst_op, inst_op_imm, inst_store, inst_load, inst_branch,
    inst_jal, inst_jalr, inst_lui, inst_auipc);

 input wire [31:0] instruction;
 output logic [4:0] rs1_num, rs2_num, rd_num;
 output logic [31:0] imm;
 output logic [2:0] funct3;
 output logic [6:0] funct7;
 output logic inst_op, inst_op_imm, inst_store, inst_load, inst_branch, inst_jal, inst_jalr,
            inst_lui, inst_auipc;
 
 logic [6:0] opcode;
 logic r_type, i_type, s_type, b_type, u_type, j_type;

 assign opcode = instruction[6:0];

 assign funct3 = instruction[14:12];
 assign funct7 = (instruction[6:0] == 7'b011011) ? instruction[31:25] : 7'b0;
 
 assign inst_op     = (opcode == 7'b0110011) ? 1'b1 : 1'b0;
 assign inst_op_imm = (opcode == 7'b0010011) ? 1'b1 : 1'b0;
 assign inst_store  = (opcode == 7'b0100011) ? 1'b1 : 1'b0;
 assign inst_load   = (opcode == 7'b0000011) ? 1'b1 : 1'b0;
 assign inst_branch = (opcode == 7'b1100011) ? 1'b1 : 1'b0;
 assign inst_jal    = (opcode == 7'b1101111) ? 1'b1 : 1'b0;
 assign inst_jalr   = (opcode == 7'b1100111) ? 1'b1 : 1'b0;
 assign inst_lui    = (opcode == 7'b0110111) ? 1'b1 : 1'b0;
 assign inst_auipc  = (opcode == 7'b0010111) ? 1'b1 : 1'b0;
 
 assign r_type = (opcode == 7'b0110011);
 assign i_type = (opcode == 7'b0000011) || (opcode == 7'b0010011) || (opcode == 7'b1100111);
 assign s_type = (opcode == 7'b0100011);
 assign b_type = (opcode == 7'b1100011);
 assign u_type = (opcode == 7'b0110111) || (opcode == 7'b0010111);
 assign j_type = (opcode == 7'b1101111);
 
 assign rd_num  = (r_type | i_type | u_type | j_type) ? instruction[11:7] : 5'd0;
 assign rs1_num = (r_type | i_type | s_type | b_type) ? instruction[19:15] : 5'd0;
 assign rs2_num = (r_type | s_type | b_type) ? instruction[24:20] : 5'd0;

always_comb begin
	 if      (i_type) imm = {{20{instruction[31]}}, instruction[31:20]};
	 else if (s_type) imm = {{20{instruction[31]}}, instruction[31:25], instruction[11:7]};
	 else if (b_type) imm = {{20{instruction[31]}}, instruction[7], instruction[30:25], instruction[11:8], 1'b0};
	 else if (u_type) imm = {instruction[31:12], 12'b000000000000};
	 else if (j_type) imm = {{12{instruction[31]}}, instruction[19:12], instruction[20], instruction[30:21], 1'b0};
	 else imm = 32'b0;
 end
 
endmodule
   
`default_nettype wire