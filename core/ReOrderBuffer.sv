`default_nettype none
`include "constants.vh"

module ReOrderBuffer(
  input wire clk, reset, stall_dp, dp_to_rob,
  input wire [5:0] read_entry1, read_entry2, dp_rob_dest,
  input wire [40:0] dp_rob_data,
  input wire [37:0] cdb_integer,
  output logic rob_is_full,
  output logic [5:0] rob_free_entry,
  output logic rob_valid1, rob_valid2,
  output logic [31:0] rob_read_data1, rob_read_data2,
  output logic arf_write_enable,
  output logic [4:0] arf_write_reg, dp_arf_dest,
  output logic [31:0] arf_write_data
);

  parameter ROB_SIZE = 64;
  
  // head and tail pointer
  logic [6:0] head, tail;
  assign rob_is_full = (head[6] != tail[6]) && (head[5:0] == tail[5:0]);
  assign rob_free_entry = tail[5:0];
  
  logic [2:0] dp_inst_type;
  logic [31:0] dp_inst_pc;
  logic dp_pred_taken;
  assign {dp_inst_type, dp_inst_pc, dp_arf_dest, dp_pred_taken} =  dp_rob_data;
  
  logic [31:0] data[ROB_SIZE-1];
  logic [0:0] valid[ROB_SIZE-1];
  logic [0:0] pred_taken[ROB_SIZE-1];
  logic [2:0] inst_type[ROB_SIZE-1];
  logic [31:0] inst_pc[ROB_SIZE-1];
  logic [4:0] arf_dest[ROB_SIZE-1];

  always_ff @(posedge clk or posedge reset) begin
    if(reset) begin
      for(int i=0; i<ROB_SIZE; i=i+1) valid[i] <= 1'b0;
    end else begin
      if(dp_to_rob) begin
        inst_type[dp_rob_dest] <= dp_inst_type;
        inst_pc[dp_rob_dest] <= dp_inst_pc;
        pred_taken[dp_rob_dest] <= dp_pred_taken;
        arf_dest[dp_rob_dest] <= dp_arf_dest;
      end
    end
  end
  
  assign rob_read_data1 = data[read_entry1];
  assign rob_read_data2 = data[read_entry2];
  assign rob_valid1 = valid[read_entry1];
  assign rob_valid2 = valid[read_entry2];
  
  // complete
  always_comb begin
    if(valid[head] == 1'b1) begin
      case(inst_type[head])
        `INST_INTEGER: begin
          arf_write_enable = 1'b1;
          arf_write_reg = arf_dest[head];
          arf_write_data = data[head];
        end
        default: begin
        end
      endcase
    end
  end
  
  // check common data bus
  logic [5:0] cdb_integer_entry;
  logic [31:0] cdb_integer_data;
  assign {cdb_integer_entry, cdb_integer_data} = cdb_integer;
  
  always_ff @(cdb_integer_entry) begin
    if(cdb_integer_entry != 6'b000000) begin
      data[cdb_integer_entry] <= cdb_integer_data;
      valid[cdb_integer_entry] <= 1'b1;      
    end
  end
  
  always_ff @(posedge clk or posedge reset) begin
    if(reset) begin
      head <= 7'b000001;
      tail <= 7'b000001;
    end else begin
      if(dp_to_rob) begin
        if(tail == 7'b0111111) tail <= 7'b1000001;
        else if(tail == 7'b1111111) tail <= 7'b0000001;
        tail <= tail + 7'b1;
      end
      if(valid[head] == 1'b1) begin
        case(inst_type[head])
          `INST_INTEGER: begin
            head <= head + 1;
          end
        endcase
      end
    end
  end
endmodule
`default_nettype wire