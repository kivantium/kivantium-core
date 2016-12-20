`default_nettype none

module testbench();
  logic clk, reset;
  initial begin
    clk = 0;
    reset = 1'b0; #5; reset = 1'b1; #5; reset = 1'b0; #5;
    
    for(int i=0; i<50; i=i+1) begin
      clk = 0; #5; clk = 1; #5;
    end 
    $finish;
  end
  logic stall_if, stall_dc, stall_dp, stall_ex, stall_cp;
  logic kill_if, kill_dc, kill_dp, kill_ex, kill_cp;
  // Fetch
  logic [31:0] nextpc;
  logic [31:0] instruction0, inst0_pc;
  Fetch fetch(.clk(clk), .reset(reset), .kill(kill_if), .stall(stall_if), .nextpc(nextpc),
            .instruction0(instruction0), .inst0_pc(inst0_pc));         
  // Decode
  logic [63:0] decoded_inst0;
  logic [31:0] decoded_inst0_pc;
  Decode dc(.clk(clk), .reset(reset), .kill(kill_dc), .stall(stall_dc),
            .fetched_inst0(instruction0), .fetched_inst0_pc(inst0_pc),
            .decoded_inst0(decoded_inst0), .decoded_inst0_pc(decoded_inst0_pc));
  // Dispatch
  logic [31:0] dispatched_pc;
  logic [2:0] rs_destination;
  logic [72:0] rs_integer;
  logic [104:0] rs_loadstore;
  logic [105:0] rs_branch;
  logic [4:0] reg_readaddr1, reg_readaddr2;
  logic [31:0] regdata1, regdata2;
  Dispatch dp(.clk(clk), .reset(reset), .kill(kill_dp), .stall(stall_dp),
              .decoded_inst0(decoded_inst0), .decoded_inst0_pc(decoded_inst0_pc),
              .dispatched_pc(dispatched_pc),
              .rs_destination(rs_destination), .rs_integer(rs_integer), .rs_loadstore(rs_loadstore),
              .rs_branch(rs_branch),
              .rs1(reg_readaddr1), .rs2(reg_readaddr2), .regdata1(regdata1), .regdata2(regdata2));
  
  logic [4:0] regwrite_rd, regwrite_addr;
  logic [31:0] regwrite_data;
  logic reg_we;
  
  Register rf(.clk(clk), .reset(reset), .readaddr1(reg_readaddr1), .readaddr2(reg_readaddr2),
              .readdata1(regdata1), .readdata2(regdata2),
              .writeaddr(regwrite_addr), .writedata(regwrite_data), .reg_we(reg_we));
  // Execute
  logic [31:0] memread_addr, memread_data, memwrite_addr, memwrite_data;
  logic memwrite_enable;
  logic [4:0] complete_rd;
  logic [31:0] complete_data;
  
  Execute ex(.clk(clk), .reset(reset), .kill(kill_ex), .stall(stall_ex), .dispatched_pc(dispatched_pc), .nextpc(nextpc),
             .in_rs_destination(rs_destination), .in_rs_integer(rs_integer), .in_rs_loadstore(rs_loadstore),
             .in_rs_branch(rs_branch), .memread_data(memread_data), .memread_addr(memread_addr),
             .memwrite_addr(memwrite_addr), .memwrite_data(memwrite_data), 
             .memwrite_enable(memwrite_enable), .complete_rd(complete_rd), .complete_data(complete_data));

  DataCache dcache(.clk(clk), .readaddr(memread_addr), .readdata(memread_data), 
                   .we(memwrite_enable), .writeaddr(memwrite_addr), .writedata(memwrite_data));
  // Complete
  Complete cp(.clk(clk), .kill(kill_cp), .stall(stall_cp), 
              .complete_data(complete_data), .rd_complete(complete_rd), .complete_we(reg_we),
              .regwrite_data(regwrite_data), .regwrite_addr(regwrite_addr));
  logic [4:0] stalls; 
  Controller ctrl(.clk(clk), .reset(reset), .stalls(stalls));
  assign {stall_if, stall_dc, stall_dp, stall_ex, stall_cp} = stalls;
  assign {kill_if, kill_dc, kill_dp, kill_ex, kill_cp} = 5'b00000;
endmodule
`default_nettype wire