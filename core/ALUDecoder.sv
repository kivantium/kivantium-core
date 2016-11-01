module ALUDecoder(
  input [1:0] aluop, 
  input [5:0] funct,
  output logic [3:0] aluctrl, 
  output logic jumpregister
);
  always_comb begin
    case(aluop)
      2'b01: aluctrl = 4'b0010; // add
      2'b10: aluctrl = 4'b0110; // subtract
      2'b11: aluctrl = 4'b0111; // set less than
      2'b00: begin
        case(funct)
          6'b100001: aluctrl = 4'b0010; // addu
          6'b100100: aluctrl = 4'b0000; // and
          6'b001000: aluctrl = 4'b0010; // jr
          6'b100111: aluctrl = 4'b0011; // nor
          6'b100101: aluctrl = 4'b0001; // or
          6'b000000: aluctrl = 4'b0100; // sll
          6'b000010: aluctrl = 4'b0101; // slr
          6'b101010: aluctrl = 4'b0111; // slt
          6'b100011: aluctrl = 4'b0110; // subu
          default:   aluctrl = 4'bXXXX; // never reach
        endcase
      end
      default: aluctrl = 4'bXXXX;
    endcase
    
    if(aluop == 2'b00 && funct == 6'b001000) begin
      jumpregister = 1;
    end else begin
      jumpregister = 0;
    end
  end
endmodule
