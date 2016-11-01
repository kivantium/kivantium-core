module core(
  input clk,
  input RsRx,
  output RsTx,
  input btnC,
  input btnU,
  output logic [15:0] led,
  output [6:0] seg,
  output [3:0] an
  );
  
  
  // control bus
  logic SysClk, RegDst, MemtoReg, MemRead, MemWrite, ALUsrc, RegWrite, Branch, Jump, JumpALU;
  logic [2:0] ALUOp;
  
  // data bus
  logic [31:0] immediate;
  logic [4:0] RegDstData;
    
  // internal states
  logic [31:0] PC;
  logic [31:0] count;
  
  // program memory
  parameter DATA_WIDTH=32, ADDR_WIDTH=10, WORDS=1024;
  logic [31:0] ProgramMemoryDataIn;
  logic [31:0] Instruction;
  logic ProgramMemoryWrite;
  Memory ProgramMemory(.clk(SysClk), .addr(PC[ADDR_WIDTH-1:0]), .DataIn(ProgramMemoryDataIn), 
                       .DataOut(Instruction), .write(ProgramMemoryWrite));

  // register
  logic [4:0] WriteReg;
  logic [31:0] WriteData;
  logic [31:0] RegOut0;
  logic [31:0] RegOut1;
  logic [4:0] MUXWriteAddr;

  MUX5 writeaddr(.select(RegDst), .input0(Instruction[20:16]), .input1(Instruction[15:11]),
                .output0(MUXWriteAddr));
  Register register(.clk(SysClk), .ReadSelect0(Instruction[25:21]), .ReadSelect1(Instruction[20:16]),
           .WriteSelect(MUXWriteAddr), .WriteData(WriteData), .OutData0(RegOut0), .OutData1(RegOut1),
           .RegWrite(RegWrite));

  // ALU
  logic [31:0] ALUInput1;
  logic [31:0] ALUOutput;
  logic [3:0] ALUCtrl;
  logic ALUisZero;
  logic [31:0] ExtendedImm;
  MUX aluin1(.select(ALUSrc), .input0(RegOut1), .input1(ExtendedImm), .output0(ALUInput1));
  ALU alu(.input0(RegOut0), .input1(ALUInput1), .output0(ALUOutput), .isZero(ALUisZero), 
          .operation(ALUCtrl));
  SignExtend extimm(.in(Instruction[15:0]), .out(ExtendedImm));
  assign led = ALUOutput[15:0];          
                    
  // main memory
  logic [31:0] MemoryDataOut;
  Memory MainMemory(.clk(SysClk), .addr(ALUOutput[ADDR_WIDTH-1:0]), .DataIn(RegOut1),
                    .DataOut(MemoryDataOut), .write(MemWrite));
  MUX writeback(.select(MemtoReg), .input0(ALUOutput), .input1(MemoryDataOut), .output0(WriteData));
  
  // branch and jump
  logic [31:0] PCPLUS4;
  logic [31:0] PCAbsJump;
  logic [31:0] PCRelJump;
  logic [31:0] RelJumpAddr;
  logic [31:0] AbsJumpAddr;
  logic [31:0] NextPC;
  logic BranchNext;
  
  assign PCPLUS4 = PC + 4;
  assign PCAbsJump = {PCPLUS4[31:28], (Instruction[25:0] << 2)};
  assign PCRelJump = PCPLUS4 + (ExtendedImm << 2);
  assign BranchNext = Branch & ALUisZero;
  MUX reladdr(.select(BranchNext), .input0(PCPLUS4), .input1(PCRelJump), .output0(RelJumpAddr));
  MUX absaddr(.select(Jump), .input0(RelJumpAddr), .input1(PCAbsJump), .output0(AbsJumpAddr));
  MUX aluaddr(.select(JumpALU), .input0(AbsJumpAddr), .input1(ALUOutput), .output0(NextPC));
    
  // control unit
  always_comb begin
    case(Instruction[31:26])
      6'b000000: begin // addu, jr, syscall
        case(Instruction[5:0])
          6'b100001: begin // addu
            ALUOp = 3'b100;
            ALUsrc = 0;
            Branch = 0;
            Jump = 0;
            JumpALU = 0;
            MemtoReg = 0;
            MemRead = 0;
            MemWrite = 0;
            RegDst = 1;
            RegWrite = 1;
          end
          6'b001000: begin // jr
            ALUOp = 3'b100;
            ALUsrc = 0;
            Branch = 0;
            Jump = 0;
            JumpALU = 1;
            MemtoReg = 0;
            MemRead = 0;
            MemWrite = 0;
            RegDst = 0;
            RegWrite = 0;
          end
          6'b001100: begin //syscall
            ALUOp = 3'bXXX;
            ALUsrc = 0;
            Branch = 0;
            Jump = 0;
            JumpALU = 0;
            MemtoReg = 0;
            MemRead = 0;
            MemWrite = 0;
            RegDst = 0;
            RegWrite = 0;
          end
          default: begin
            ALUOp = 3'b000;
            ALUsrc = 0;
            Branch = 0;
            Jump = 0;
            JumpALU = 0;
            MemtoReg = 0;
            MemRead = 0;
            MemWrite = 0;
            RegDst = 0;
            RegWrite = 0;
          end
        endcase
      end
      6'b000010: begin // j
        ALUOp = 3'bXXX;
        ALUsrc = 1'bX;
        Branch = 0;
        Jump = 0;
        JumpALU = 0;
        MemtoReg = 0;
        MemRead = 0;
        MemWrite = 0;
        RegDst = 0;
        RegWrite = 0;
      end
      6'b000011: begin // jal
        ALUOp = 3'bXX;
        ALUsrc = 1'bX;
        Branch = 0;
        Jump = 1;
        JumpALU = 0;
        MemtoReg = 0;
        MemRead = 0;
        MemWrite = 0;
        RegDst = 0;
        RegWrite = 0;
      end
      6'b000100: begin // beq
        ALUOp = 3'b001;
        ALUsrc = 0;
        Branch = 1;
        Jump = 0;
        JumpALU = 0;
        MemtoReg = 0;
        MemRead = 0;
        MemWrite = 0;
        RegDst = 0;
        RegWrite = 0;
      end
      6'b001001: begin //addiu
        ALUOp = 3'b000;
        ALUsrc = 1'b1;
        Branch = 0;
        Jump = 0;
        JumpALU = 0;
        MemtoReg = 0;
        MemRead = 0;
        MemWrite = 0;
        RegDst = 1;
        RegWrite = 1;
      end
      6'b001010: begin // slti
        ALUOp = 3'b011;
        ALUsrc = 1;
        Branch = 0;
        Jump = 0;
        JumpALU = 0;
        MemtoReg = 0;
        MemRead = 0;
        MemWrite = 0;
        RegDst = 1;
        RegWrite = 1;
      end
      6'b001101: begin // ori
        ALUOp = 3'b010;
        ALUsrc = 1;
        Branch = 0;
        Jump = 0;
        JumpALU = 0;
        MemtoReg = 0;
        MemRead = 0;
        MemWrite = 0;
        RegDst = 1;
        RegWrite = 1;
      end
      6'b100010: begin // lw
        ALUOp = 3'b000;
        ALUsrc = 1;
        Branch = 0;
        Jump = 0;
        JumpALU = 0;
        MemtoReg = 1;
        MemRead = 1;
        MemWrite = 0;
        RegDst = 0;
        RegWrite = 1;
      end
      6'b101011: begin // sw
        ALUOp = 3'b000;
        ALUsrc = 1;
        Branch = 0;
        Jump = 0;
        JumpALU = 0;
        MemtoReg = 1;
        MemRead = 0;
        MemWrite = 1;
        RegDst = 0;
        RegWrite = 0;
      end
      default: begin
        ALUOp = 3'b000;
        ALUsrc = 0;
        Branch = 0;
        Jump = 0;
        JumpALU = 0;
        MemtoReg = 0;
        MemRead = 0;
        MemWrite = 0;
        RegDst = 0;
        RegWrite = 0;
      end
    endcase
  end
  
  always_comb begin
    case(ALUOp)
      3'b000: ALUCtrl = 4'b0010;
      3'b001: ALUCtrl = 4'b0110;
      3'b010: ALUCtrl = 4'b0001;
      3'b011: ALUCtrl = 4'b0111;
      3'b100: begin
        case(Instruction[5:0])
          6'b100001: ALUCtrl = 4'b0010;
          6'b001000: ALUCtrl = 4'b0010;
          default: ALUCtrl = 4'b0000;
        endcase
      end
      default: ALUCtrl = 4'b0000;
    endcase
  end
      
  
  assign led = Instruction[15:0];
endmodule

