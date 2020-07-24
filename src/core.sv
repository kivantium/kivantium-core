`default_nettype none

module core(clk, reset, led, seg_data);
  input wire clk, reset;
  output logic [15:0] led;
  output logic [15:0] seg_data;
  
  logic [31:0] pc;
  assign led = pc[15:0];
  
  logic [31:0] imem_addr, imem_data; // instruction memory address and data
  logic [4:0] dc_rs1, dc_rs2; // register number from decoder
  logic [31:0] dc_imm;
  logic [2:0] dc_funct3;
  logic [6:0] dc_funct7;
  logic [4:0] dc_rd; // destination register from decoder
  logic dc_inst_op, dc_inst_op_imm, dc_inst_store, dc_inst_load, dc_inst_branch,
        dc_inst_jal, dc_inst_jalr, dc_inst_lui, dc_inst_auipc;
  
  logic [31:0] rf_data1, rf_data2; // data from register file
  logic [31:0] alu_result;
  logic [31:0] rf_write_data;
  
  logic status_idle, status_if, status_de, status_ex, status_ma, status_wb, status_wait;

  // State control
  always @(posedge clk) begin
    if(reset) begin
      {status_idle, status_if, status_de, status_ex, status_ma, status_wb, status_wait} <= 7'b1000000;
    end
    else begin
      if(status_idle) begin
        status_idle <= 1'b0;
        status_if <= 1'b1;
      end
      else if(status_if) begin
        status_if <= 1'b0;
        status_de <= 1'b1;
      end
      else if(status_de) begin
        status_de <= 1'b0;
        status_ex <= 1'b1;
      end
      else if(status_ex) begin
        status_ex <= 1'b0;
        status_ma <= 1'b1;
      end
      else if(status_ma) begin
        status_ma <= 1'b0;
        status_wb <= 1'b1;
      end
      else begin
        status_wb <= 1'b0;
        status_if <= 1'b1;
      end
    end
  end
  
  // Stage 1: Instruction Fetch
  assign imem_addr = pc; 
  instructionMemory imem(
    .clk(clk),
    .reset(reset),
    .addr(imem_addr),
    .inst(imem_data)
  );
  
  // Stage 2: Instruction Decode
  instructionDecoder decoder(
    .instruction(imem_data),
    .rs1_num(dc_rs1),
    .rs2_num(dc_rs2),
    .rd_num(dc_rd),
    .imm(dc_imm),
    .funct3(dc_funct3),
    .funct7(dc_funct7),
    .inst_op(dc_inst_op),
    .inst_op_imm(dc_inst_op_imm), 
    .inst_store(dc_inst_store),
    .inst_load(dc_inst_load),
    .inst_branch(dc_inst_branch),
    .inst_jal(dc_inst_jal),
    .inst_jalr(dc_inst_jalr),
    .inst_lui(dc_inst_lui),
    .inst_auipc(dc_inst_auipc) 
  );
  
  registerFile rf(
    .clk(clk),
    .reset(reset),
    .read_reg1(dc_rs1),
    .read_reg2(dc_rs2),
    .read_data1(rf_data1),
    .read_data2(rf_data2),
    .write_reg(dc_rd),
    .write_data(rf_write_data),
    .write_enable(status_wb),
    .register1(seg_data)
  );
  
  // Stage 3: Execution
  executeInteger alu(
    .rs1_data(rf_data1),
    .rs2_data(rf_data2),
    .imm_data(dc_imm),
    .funct3(dc_funct3),
    .funct7(dc_funct7),
    .result(alu_result),
    .inst_op(dc_inst_op),
    .inst_op_imm(dc_inst_op_imm),
    .inst_store(dc_inst_store),
    .inst_load(dc_inst_load),
    .inst_branch(dc_inst_branch)
  );
  
  logic [31:0] dmem_read_addr, dmem_read_data, dmem_write_addr, dmem_write_data;
  logic dmem_write_enable;
  
  // Stage 4: Memory Access
  dataMemory dmem(
    .clk(clk),
    .reset(reset),
    .read_addr(dmem_read_addr),
    .read_data(dmem_read_data),
    .write_addr(dmem_write_addr),
    .write_data(dmem_write_data),
    .write_enable(dmem_write_enable)
  );
 
  assign dmem_read_addr = alu_result;
  assign dmem_write_addr = alu_result;
  assign dmem_write_data = (dc_funct3 == 3'b000) ? rf_data2[7:0]:
                           (dc_funct3 == 3'b001) ? rf_data2[15:0] : rf_data2;
  assign dmem_write_enable = status_ma && dc_inst_store;
  
  // Stage 5: Write back
  always_comb begin
    if(dc_inst_jal || dc_inst_jalr) rf_write_data = pc + 32'd4;
    else if(dc_inst_load) rf_write_data = dmem_read_data;
    else if(dc_inst_lui) rf_write_data = dc_imm;
    else if(dc_inst_auipc) rf_write_data = pc + dc_imm;
    else rf_write_data = alu_result;    
  end
  
  always_ff @(posedge clk) begin
    if(reset) begin
      pc <= 32'd0;
    end
    else begin
      if(status_wb) begin
        if(dc_inst_branch) begin
          if(alu_result) pc <= pc + dc_imm;
          else pc <= pc + 32'd4;
        end
        else if(dc_inst_jal) begin
          pc <= pc + dc_imm;
        end
        else if(dc_inst_jalr) begin
          pc <= rf_data1 + dc_imm;
        end
        else if(dc_inst_lui) begin
          pc <= pc + 32'd4;
        end
        else if(dc_inst_auipc) begin
          pc <= pc + 32'd4;
        end
        else begin
          pc <= pc + 32'd4;
        end
      end
    end
  end
endmodule
`default_nettype wire