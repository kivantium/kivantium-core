module MainDecoder(
  input [5:0] opcode, 
  output logic [1:0] aluop,
  output logic [8:0] controls
);
  always_comb begin
    case(opcode) 
      6'b000000: begin  // R format
        aluop = 2'b00;
        controls = 9'b000110000;
      end
      6'b001001: begin // addiu
        aluop = 2'b01;
        controls = 9'b100010000;
      end
      6'b000100: begin // beq
        aluop = 2'b10;
        controls = 9'b0X0X01000;
      end
      6'b000101: begin // bne
        aluop = 2'b10;
        controls = 9'b0X0X00100;
      end
      6'b100011: begin // lw
        aluop = 2'b01;
        controls = 9'b110010000;
      end
      6'b101011: begin // sw
        aluop = 2'b01;
        controls = 9'b1X1X00000;
      end
      6'b000010: begin // j
        aluop = 2'bXX;
        controls = 9'bXX0X00010;
      end
      6'b000011: begin // jal
        aluop = 2'bXX;
        controls = 9'bXX0X10001;

      end
      default: begin
        aluop = 2'bXX;
        controls = 9'bXXXXXXXXX;
      end
    endcase
  end
endmodule
