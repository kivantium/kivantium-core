module DataPath(
  input clk, reset, 
  input [31:0] instruction, 
  input [9:0] controls, 
  input [3:0] aluctrl, 
  output logic [31:0] pc, 
  output logic [31:0] stdout
);

  logic alusrc, memtoreg, memwrite, regwrite, regdst, iszero,
        brancheq, branchne, jump, jumpandlink, jumpregister;
  logic [31:0] nextpc, pcplus4, signextimm, writedata, aluout,
               regwritedata, readdata1, alusrc0, alusrc1, memdataout;
  logic [4:0] regdstout, regwriteaddr;
      
  assign {alusrc, memtoreg, memwrite, regdst, regwrite, 
          brancheq, branchne, jump, jumpandlink, jumpregister} = controls;

  assign pcplus4 = pc + 4;

  // About Program Counter
  Counter pgmcr(.clk(clk), .reset(reset), .nextpc(nextpc), .pc(pc));
  NextPC npc(.pcplus4(pcplus4), .jumpsrc(instruction[25:0]), .signextimm(signextimm), 
             .jrsrc(aluout), .brancheq(brancheq), .branchne(branchne), .iszero(iszero),
             .jump(jump), .jumpandlink(jumpandlink), .jumpregister(jumpregister), .nextpc(nextpc));

  // About Register File
  MUX #(5) regdstmux(.in0(instruction[20:16]), .in1(instruction[15:11]), .out(regdstout), .sel(regdst));
  MUX #(5) jalmux(.in0(regdstout), .in1(5'd31), .out(regwriteaddr), .sel(jumpandlink));
  MUX #(32) wdmux(.in0(writedata), .in1(pcplus4), .out(regwritedata), .sel(jumpandlink));
  Register rf(.clk(clk), .reset(reset), .readaddr0(instruction[25:21]), .readaddr1(instruction[20:16]),
              .writeaddr(regwriteaddr), .writedata(regwritedata), .regwe(regwrite),
              .readdata0(alusrc0), .readdata1(readdata1));
  
  // About ALU input
  SignExtend se(.in(instruction[15:0]), .out(signextimm));
  MUX #(32) asmux(.in0(readdata1), .in1(signextimm), .out(alusrc1), .sel(alusrc));
  ALU alu(.in0(alusrc0), .in1(alusrc1), .shamt(instruction[5:0]),
          .op(aluctrl), .out(aluout), .iszero(iszero));
          
  // About memory input
  IOMemory #(64) mmem(.clk(clk), .writeaddr(aluout), .writedata(readdata1), .writeenable(memwrite),
                    .readaddr(aluout), .readdata(memdataout), .stdout(stdout));
  MUX #(32) mrmux(.in0(aluout), .in1(memdataout), .out(writedata), .sel(memtoreg));
endmodule