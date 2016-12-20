`include "constants.vh"
`default_nettype none

module Execute(
  input wire clk, reset, kill, stall,
  input wire [31:0] dispatched_pc,
  input wire [2:0] in_rs_destination,
  input wire [72:0] in_rs_integer,
  input wire [104:0] in_rs_loadstore,
  input wire [105:0] in_rs_branch,
  input wire [31:0] memread_data,
  output logic [31:0] nextpc,
  output logic [31:0] memread_addr, memwrite_addr, memwrite_data,
  output logic memwrite_enable,
  output logic [31:0] complete_data,
  output logic [4:0] complete_rd
);

  logic enable_int, enable_branch, enable_loadstore;
  logic [31:0] branch_pc, result_int, result_load;
  logic [1:0] todo_complete;
 
  logic [2:0] rs_destination;
  logic [72:0] rs_integer;
  logic [104:0] rs_loadstore;
  logic [105:0] rs_branch;
  
  logic [4:0] complete_rd_int, complete_rd_ls, complete_rd_branch;
  logic [31:0] complete_data_branch;
  logic [1:0] state;
  
  ExecInteger ei(.clk(clk), .reset(reset), .rs(rs_integer), .enable(enable_int), 
                 .result(result_int), .complete_rd(complete_rd_int));
  ExecLoadStore els(.clk(clk), .reset(reset), .rs(rs_loadstore), .enable(enable_loadstore),
                    .memread_data(memread_data), .memread_addr(memread_addr),
                    .memwrite_addr(memwrite_addr), .complete_data(result_load), 
                    .memwrite_enable(memwrite_enable), .complete_rd(complete_rd_ls), 
                    .memwrite_data(memwrite_data));
  ExecBranch eb(.clk, .reset(reset), .rs(rs_branch), .pc(dispatched_pc), 
                 .enable(enable_branch), .branch_pc(branch_pc), 
                 .rd(complete_rd_branch), .complete_data(complete_data_branch));
  
  always_ff @(posedge clk or posedge reset) begin
    if(reset) begin
      state = 2'b00;
      rs_destination <= 0;
      rs_integer <= 0;
      rs_loadstore <= 0;
      rs_branch <= 0;
    end else if(!stall) begin
      rs_destination <= in_rs_destination;
      rs_integer <= in_rs_integer;
      rs_loadstore <= in_rs_loadstore;
      rs_branch <= in_rs_branch;
      if(state == 2'b00) state <= 2'b01;
    end
    else begin
      if(state == 2'b01) state <= 2'b10;
      else if(state == 2'b10) state <= 2'b11;
      else state <= 2'b00;
    end
  end
  
  always_comb begin
    if(state == 2'b00) begin
      enable_int = 1'b0; enable_branch = 1'b0; enable_loadstore = 1'b0;
      nextpc = 32'bx;
      complete_rd = 5'bx;
      complete_data = 32'bx;
    end else begin
      case(rs_destination)
        `RS_INTEGER: begin
          nextpc = dispatched_pc + 32'd4;
          complete_rd = complete_rd_int;
          complete_data = result_int;
          enable_int = 1'b1; enable_branch = 1'b0; enable_loadstore = 1'b0;
        end
        `RS_BRANCH: begin
          nextpc = branch_pc;
          complete_rd = complete_rd_branch;
          complete_data = complete_data_branch;
          enable_int = 1'b0; enable_branch = 1'b1; enable_loadstore = 1'b0;    
        end
        `RS_LOAD_STORE: begin
          nextpc = dispatched_pc + 32'd4;
          complete_rd = complete_rd_ls;
          complete_data = result_load;
          enable_int = 1'b0; enable_branch = 1'b0; enable_loadstore = 1'b1;
        end
        default: begin
          complete_rd = 5'bxxxxx;
          nextpc = 32'bx;
          complete_data = 32'bx;
          enable_int = 1'b0; enable_branch = 1'b0; enable_loadstore = 1'b0;
        end
      endcase
    end
  end

endmodule
`default_nettype wire