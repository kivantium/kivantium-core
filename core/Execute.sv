`include "constants.vh"
`default_nettype none

module Execute(
  input wire clk, reset, kill, stall,
  input wire [31:0] dispatched_pc,
  input wire [2:0] rs_destination,
  input wire [75:0] rs_integer,
  input wire [103:0] rs_loadstore,
  input wire [105:0] rs_branch,
  input wire [31:0] memread_data,
  output logic [31:0] nextpc,
  output logic finish_ex,
  output logic [31:0] memread_addr, memwrite_addr, complete_data,
  output logic memwrite_enable,
  output logic [4:0] complete_rd
);

  logic start_int, start_ls, start_br;
  logic finish_int, finish_ls, finish_br;
  logic [31:0] branch_pc, result_int, result_load;
  logic [1:0] todo_complete;
  
  ExecInteger ei(.clk(clk), .reset(reset), .rs(rs_integer), .start(start_int), .finish(finish_int), 
                 .ex_result(result_int), .complete_rd(complete_rd));
  ExecLoadStore els(.clk(clk), .reset(reset), .rs(rs_loadstore), .start(start_ls), .finish(finish_ls),
                    .memread_data(memread_data), .memread_addr(memread_addr),
                    .memwrite_addr(memwrite_addr), .load_data(result_load), 
                    .memwrite_enable(memwrite_enable), .complete_rd(complete_rd));
  ExecBranch eb(.clk, .reset(reset), .rs(rs_branch), .pc(dispatched_pc), 
                 .start(start_br), .finish(finish_br), .branch_pc(branch_pc));
  
  always_ff @(posedge clk) begin
    case(rs_destination)
      `RS_INTEGER: begin
        start_int <= 1'b1; start_ls <= 1'b0; start_br <= 1'b0;
      end
      `RS_LOAD_STORE: begin
        start_int <= 1'b0; start_ls <= 1'b1; start_br <= 1'b0;
      end
      `RS_BRANCH: begin
        start_int <= 1'b0; start_ls <= 1'b0; start_br <= 1'b1;
      end
    endcase
  end
  
  always_ff @(posedge clk or negedge reset) begin
    if(reset == 1'b0) begin
      finish_ex <= 1'b0;
      nextpc <= 32'b0;
    end else if(finish_int) begin
      finish_ex <= 1'b1;
      nextpc <= dispatched_pc + 32'd4;
      todo_complete <= 2'b00;
      complete_data <= result_int;
    end else if(finish_ls) begin
      finish_ex <= 1'b1;
      nextpc <= dispatched_pc + 32'd4;
      todo_complete <= 2'b01;
      complete_data <= result_load;
    end else if(finish_br) begin
      finish_ex <= 1'b1;
      nextpc <= branch_pc;
      todo_complete <= 2'b10;
    end
  end
endmodule
`default_nettype wire