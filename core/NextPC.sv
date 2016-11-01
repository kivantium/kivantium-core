module NextPC (
  input [31:0] pcplus4, 
  input [25:0] jumpsrc,
  input [31:0] signextimm,
  input [31:0] jrsrc,
  input brancheq, branchne, iszero, jump, jumpandlink, jumpregister,
  output logic [31:0] nextpc
);
  always_comb begin
    if((brancheq & iszero) | (branchne & !iszero)) begin
      nextpc = (signextimm << 2) + pcplus4;
    end else if(jump | jumpandlink) begin
      nextpc = {pcplus4[31:28], jumpsrc, 2'b00};
    end else if(jumpregister) begin
      nextpc = jrsrc;
    end else begin
      nextpc = pcplus4;
    end
  end      
endmodule