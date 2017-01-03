`default_nettype none

module ExecInteger(
  input wire clk, reset, rs_dest,
  input wire [75:0] rs_data,
  output logic rs_is_full,
  output logic [37:0] cdb_data
);

  // reservation size = 4
  logic [3:0] busy;
  
  assign rs_is_full = &busy[3:0];
  
  logic [3:0] aluop [0:3];
  logic [5:0] rob_dest [0:3];
  logic [3:0] valid1, valid2;
  logic [31:0] operand1 [0:3];
  logic [31:0] operand2 [0:3];

  always_ff @(posedge clk or posedge reset) begin
    if(reset) begin
      busy <= 4'b0;
    end else begin
      if(rs_dest) begin
        if(!busy[0]) begin 
          busy[0] <= 1'b1;
          {aluop[0], rob_dest[0], valid1[0], operand1[0], valid2[0], operand2[0]} <= rs_data; 
        end else if(!busy[1]) begin
          busy[1] <= 1'b1;
          {aluop[1], rob_dest[1], valid1[1], operand1[1], valid2[1], operand2[1]} <= rs_data;         
        end else if(!busy[2]) begin
          busy[2] <= 1'b1;
          {aluop[2], rob_dest[2], valid1[2], operand1[2], valid2[2], operand2[2]} <= rs_data;         
        end else if(!busy[3]) begin
          busy[3] <= 1'b1;
          {aluop[3], rob_dest[3], valid1[3], operand1[3], valid2[3], operand2[3]} <= rs_data;
        end      
      end
    end
  end
  
  logic ex_en;
  logic [3:0] ex_opr;
  logic [5:0] ex_dest;
  logic [31:0] ex_op1, ex_op2;
  
  always_ff @(posedge clk) begin
    if(busy[0] && valid1[0] && valid2[0]) begin
      {ex_en, ex_opr, ex_dest, ex_op1, ex_op2} <= {1'b1, aluop[0], rob_dest[0], operand1[0], operand2[0]};
      busy[0] <= 1'b0;
    end else if(busy[1] && valid1[1] && valid2[1]) begin
      {ex_en, ex_opr, ex_dest, ex_op1, ex_op2} <= {1'b1, aluop[1], rob_dest[1], operand1[1], operand2[1]};
      busy[1] <= 1'b0;
    end else if(busy[2] && valid1[2] && valid2[2]) begin
      {ex_en, ex_opr, ex_dest, ex_op1, ex_op2} <= {1'b1, aluop[2], rob_dest[2], operand1[2], operand2[2]};
      busy[2] <= 1'b0;
    end else if(busy[3] && valid1[3] && valid2[3]) begin
      {ex_en, ex_opr, ex_dest, ex_op1, ex_op2} <= {1'b1, aluop[3], rob_dest[3], operand1[3], operand2[3]};
      busy[3] <= 1'b0;
    end else begin
      {ex_en, ex_opr, ex_dest, ex_op1, ex_op2} <= {1'b0, 4'bx, 32'bx, 32'bx};
    end
  end
  
  logic [31:0] result;
  always_comb begin
    if(!ex_en) begin
      cdb_data = {6'b000000, 32'bx};
    end else begin
      case(ex_opr)
        // ADD, ADDI
        4'b0000: result = ex_op1 + ex_op2;
        // SUB
        4'b0001: result = ex_op1 - ex_op2;
        // SLL
        4'b0010: result = ex_op1 << ex_op2[4:0];
        // SLT, SLTI
        4'b0100: result = $signed(ex_op1) < $signed(ex_op2) ? 32'b1 : 32'b0;
        // SLTU, SLTIU
        4'b0110: result = $unsigned(ex_op1) < $unsigned(ex_op2) ? 32'b1 : 32'b0;
        // XOR, XORI
        4'b1000: result = ex_op1 ^ ex_op2;
        // SRL
        4'b1010: result = $unsigned(ex_op1) >> ex_op2[4:0];
        // SRA
        4'b1011: result = $signed(ex_op1) >> ex_op2[4:0];
        // OR, ORI
        4'b1100: result = ex_op1 | ex_op2;
        // AND, ANDI
        4'b1110: result = ex_op1 & ex_op2; 
      endcase
      cdb_data = {ex_dest, result};
    end
  end
  
  // check CDB and update RS  
  always_ff @(cdb_data) begin
    if(!valid1[0] && cdb_data[37:32] == operand1[0]) begin
      operand1[0] <= cdb_data[31:0];
      valid1[0] <= 1'b1;
    end
    if(!valid1[1] && cdb_data[37:32] == operand1[1]) begin
      operand1[1] <= cdb_data[31:0];
      valid1[1] <= 1'b1;
    end
    if(!valid1[2] && cdb_data[37:32] == operand1[2]) begin
      operand1[2] <= cdb_data[31:0];
      valid1[0] <= 1'b1;
    end
    if(!valid1[3] && cdb_data[37:32] == operand1[3]) begin
      operand1[3] <= cdb_data[31:0];
      valid1[3] <= 1'b1;
    end
    if(!valid2[0] && cdb_data[37:32] == operand2[0]) begin
      operand2[0] <= cdb_data[31:0];
      valid2[0] <= 1'b1;
    end
    if(!valid2[1] && cdb_data[37:32] == operand2[1]) begin
      operand2[1] <= cdb_data[31:0];
      valid2[1] <= 1'b1;
    end
    if(!valid2[2] && cdb_data[37:32] == operand2[2]) begin
      operand2[2] <= cdb_data[31:0];
      valid2[2] <= 1'b1;
    end
    if(!valid2[3] && cdb_data[37:32] == operand2[3]) begin
      operand2[3] <= cdb_data[31:0];
      valid2[3] <= 1'b1;
    end
  end
endmodule

`default_nettype wire