module Controller(
  input [5:0] opcode, funct, 
  output logic [9:0] controls,
  output logic [3:0] aluctrl
);
  logic [1:0] aluop;
  /* controls = {alusrc, memtoreg, memwrite, regdst, regwrite,
                         brancheq, branchneq, jump, jumpandlink, jumpregister} */
  
  MainDecoder md(.opcode(opcode), .aluop(aluop), .controls(controls[9:1]));
  ALUDecoder ad(.aluop(aluop), .funct(funct), .aluctrl(aluctrl), .jumpregister(controls[0]));
endmodule