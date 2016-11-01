 module Memory #(parameter SIZE = 256)(
  input clk, reset,
  input [31:0] writeaddr, writedata, 
  input writeenable, 
  input [31:0] readaddr, 
  output logic [31:0] readdata
);
  
  logic [31:0] mem [SIZE-1:0];
  
  assign readdata = mem[readaddr[31:2]];
  
  always @(posedge clk) begin
    if(reset == 1) begin
    mem[0] <= 32'h242e00fc;
    mem[1] <= 32'h241d00f8;
    mem[2] <= 32'h27bdffe0;
    mem[3] <= 32'hafbf0014;
    mem[4] <= 32'hafbe0010;
    mem[5] <= 32'h27be001c;
    mem[6] <= 32'h24100000;
    mem[7] <= 32'h24110008;
    mem[8] <= 32'h24120002;
    mem[9] <= 32'h12110005;
    mem[10] <= 32'h02002021;
    mem[11] <= 32'h0c000013;
    mem[12] <= 32'hac020000;
    mem[13] <= 32'h26100001;
    mem[14] <= 32'h08000009;
    mem[15] <= 32'h8fbf0014;
    mem[16] <= 32'h8fbe0010;
    mem[17] <= 32'h27bd0020;
    mem[18] <= 32'h08000012;
    mem[19] <= 32'h27bdffe0;
    mem[20] <= 32'hafbf0014;
    mem[21] <= 32'hafbe0010;
    mem[22] <= 32'h27be001c;
    mem[23] <= 32'hafc40000;
    mem[24] <= 32'h0092402a;
    mem[25] <= 32'h11000002;
    mem[26] <= 32'h24020001;
    mem[27] <= 32'h08000025;
    mem[28] <= 32'h8fc40000;
    mem[29] <= 32'h2484ffff;
    mem[30] <= 32'h0c000013;
    mem[31] <= 32'hafc20004;
    mem[32] <= 32'h8fc40000;
    mem[33] <= 32'h2484fffe;
    mem[34] <= 32'h0c000013;
    mem[35] <= 32'h8fc30004;
    mem[36] <= 32'h00431021;
    mem[37] <= 32'h8fbf0014;
    mem[38] <= 32'h8fbe0010;
    mem[39] <= 32'h27bd0020;
    mem[40] <= 32'h03e00008;
    end
    if(writeenable == 1) mem[writeaddr[31:2]] <= writedata;
  end
endmodule