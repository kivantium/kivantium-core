#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <math.h>

#define MAX_MEMORY 1024

uint32_t reg[32], reg_fp[32];
uint32_t imem[MAX_MEMORY];
uint32_t dmem[MAX_MEMORY];
uint32_t fcsr;

union F2I {
    uint32_t int_value;
    float float_value;
};

uint32_t float2int(float f) {
    union F2I t;
    t.float_value = f;
    return t.int_value;
}
float int2float(int i) {
    union F2I t;
    t.int_value = i;
    return t.float_value;
}

uint32_t execute_load(uint32_t instruction, uint32_t pc) {
    uint32_t imm = (((instruction>>31) & 1) ? 0xfffff000 : 0) | (instruction >> 20) & 0xfff;
    uint32_t rs1 = (instruction >> 15) & 0x1f;
    uint32_t rd = (instruction >> 7) & 0x1f;
    uint32_t width = (instruction >> 12) & 0x7;
    // TODO: width
    reg[rd] = dmem[(reg[rs1] + imm)];
    return pc + 4;
}

uint32_t execute_load_fp(uint32_t instruction, uint32_t pc){
    uint32_t imm = (((instruction>>31) & 1) ? 0xfffff000 : 0) | (instruction >> 20) & 0xfff;
    uint32_t rs1 = (instruction >> 15) & 0x1f;
    uint32_t rd = (instruction >> 7) & 0x1f;
    uint32_t width = (instruction >> 12) & 0x7;
    reg_fp[rd] = dmem[(reg[rs1] + imm)];
    return pc + 4;
}

uint32_t execute_op_imm(uint32_t instruction, uint32_t pc){
    uint32_t imm = (((instruction>>31) & 1) ? 0xfffff000 : 0) | (instruction >> 20) & 0xfff;
    uint32_t rs1 = (instruction >> 15) & 0x1f;
    uint32_t rd = (instruction >> 7) & 0x1f;
    uint32_t funct3 = (instruction >> 12) & 0x7;
    switch(funct3) {
        case 0x0: // ADDI
            reg[rd] = reg[rs1] + imm;
            break;
        case 0x2: // SLTI
            reg[rd] = (((int32_t)reg[rs1]) < ((int32_t)imm)) ? 1 : 0;
            break;
        case 0x3: // SLTIU
            reg[rd] = (((uint32_t)rs1) < ((uint32_t)imm)) ? 1 : 0;
            break;
        case 0x4: // XORI
            reg[rd] = reg[rs1] ^ imm;
            break;
        case 0x6: // ORI
            reg[rd] = reg[rs1] | imm;
            break;
        case 0x7: // ANDI
            reg[rd] = reg[rs1] & imm;
            break;
        default:
            fprintf(stderr, "unknown funct. Abort.\n");
            exit(EXIT_FAILURE);
    }
    return pc + 4;
}

uint32_t execute_store(uint32_t instruction, uint32_t pc){
    uint32_t imm = (((instruction>>31) & 1) ? 0xfffff000 : 0) 
                   | (((instruction >> 25) & 0x7f) << 5)| ((instruction >> 7) & 0x1f);
    uint32_t rs1 = (instruction >> 15) & 0x1f;
    uint32_t rs2 = (instruction >> 20) & 0x1f;
    uint32_t width = (instruction >> 12) & 0x7;
    if(reg[rs1] + imm == 0) printf("print_int: %x\n", reg[rs2]);
    dmem[(reg[rs1] + imm)] = reg[rs2];
    return pc + 4;
}

uint32_t execute_store_fp(uint32_t instruction, uint32_t pc){
    uint32_t imm = (((instruction>>31) & 1) ? 0xfffff000 : 0) 
                   | (((instruction >> 25) & 0x7f) << 5)| ((instruction >> 7) & 0x1f);
    uint32_t rs1 = (instruction >> 15) & 0x1f;
    uint32_t rs2 = (instruction >> 20) & 0x1f;
    uint32_t rd = (instruction >> 7) & 0x1f;
    uint32_t width = (instruction >> 12) & 0x7;
    dmem[(reg[rs1] + imm)] = reg_fp[rd];
    return pc + 4;
}

uint32_t execute_op(uint32_t instruction, uint32_t pc){
    uint32_t rs1 = (instruction >> 15) & 0x1f;
    uint32_t rs2 = (instruction >> 20) & 0x1f;
    uint32_t rd = (instruction >> 7) & 0x1f;
    uint32_t funct3  = (instruction >> 12) & 0x7;
    uint32_t funct7  = (instruction >> 25) & 0x7;
    switch(funct3) {
        case 0x0: // ADD, SUB
            if(funct7 == 0x00) reg[rd] = reg[rs1] + reg[rs2];
            else if(funct7 == 0x20) reg[rd] = reg[rs1] - reg[rs2];
            break;
        case 0x1: // SLL
            reg[rd] = reg[rs1] >> rs2;
            break;
        case 0x2: // SLT
            reg[rd] = (((int32_t)reg[rs1]) < ((int32_t)reg[rs2])) ? 1 : 0;
            break;
        case 0x3: // SLTU
            reg[rd] = (((uint32_t)reg[rs1]) < ((uint32_t)reg[rs2])) ? 1 : 0;
            break;
        case 0x4: // XORI
            reg[rd] = reg[rs1] ^ reg[rs2];
            break;
        case 0x6: // ORI
            reg[rd] = reg[rs1] | reg[rs2];
            break;
        case 0x7: // ANDI
            reg[rd] = reg[rs1] & reg[rs2];
            break;
        default:
            fprintf(stderr, "unknown funct. Abort.\n");
            exit(EXIT_FAILURE);
    }
    return pc + 4;
}

uint32_t execute_lui(uint32_t instruction, uint32_t pc){
    uint32_t imm = instruction & 0xfffff000;
    uint32_t rd = (instruction >> 7) & 0x1f;
    reg[rd] = imm;
    return pc + 4;
}

int execute_op_fp(int instruction, uint32_t pc){
    uint32_t rd = (instruction >> 7) & 0x1f;
    uint32_t funct3 = (instruction >> 12) & 0x7;
    uint32_t rs1 = (instruction >> 15) & 0x1f;
    uint32_t rs2 = (instruction >> 20) & 0x1f;
    uint32_t funct7 = (instruction >> 25) & 0x7f;
    float rs1_f = int2float(reg_fp[rs1]);
    float rs2_f = int2float(reg_fp[rs2]);
    switch(funct7) {
        case 0x00: // FADD.S
            reg_fp[rd] = float2int(rs1_f + rs2_f);
            break;
        case 0x04: // FSUB.S
            reg_fp[rd] = float2int(rs1_f - rs2_f);
            break;
        case 0x08: // FMUL.S
            reg_fp[rd] = float2int(rs1_f * rs2_f);
            break;
        case 0x0c: // FDIV.S
            reg_fp[rd] = float2int(rs1_f / rs2_f);
            break;
        case 0x2c: // FSQRT.S
            reg_fp[rd] = float2int(sqrt(rs1_f));
            break;
        case 0x10:
            switch(funct3) {
                case 0x0: // FSGNJ.S
                    reg_fp[rd] = abs(rs1_f) * (rs2_f > 0 ? 1.0 : -1.0);
                    break;
                case 0x1: // FSGNJN.S
                    reg_fp[rd] = abs(rs1_f) * (rs2_f > 0 ? -1.0 : 1.0);
                    break;
                case 0x2: // FSGNJX.S
                    reg_fp[rd] = abs(rs1_f) * (rs1_f > 0 ? -1.0 : 1.0) * (rs2_f > 0 ? -1.0 : 1.0);
                    break;
                default:
                    fprintf(stderr, "unknown funct7\n");
                    exit(EXIT_FAILURE);
            }
            break;
        case 0x14:
            switch(funct3) {
                case 0x0:  // FMIN.S
                    reg_fp[rd] = (rs1_f < rs2_f) ? rs1_f : rs2_f;
                    break;
                case 0x1:  // FMAX.S
                    reg_fp[rd] = (rs1_f > rs2_f) ? rs1_f : rs2_f;
                    break;
                default:
                    fprintf(stderr, "unknown funct7\n");
                    exit(EXIT_FAILURE);
            }
        case 0x60:
            switch(rs2) {
                case 0x0:  // FCVT.W.S
                    reg[rd] = (int32_t)int2float(reg_fp[rs1]);
                    break;
                case 0x1:  // FCVT.WU.S
                    reg[rd] = (uint32_t)int2float(reg_fp[rs1]);
                    break;
                default:
                    fprintf(stderr, "unknown funct7\n");
                    exit(EXIT_FAILURE);
            }
        case 0x70: 
            switch(funct3) {
                case 0x0: // FMV.X.S
                    reg[rd] = reg_fp[rs1];
                    break;
                case 0x1: // FCLASS.S
                    fprintf(stderr, "fclass is not supported!\n");
                    break;
            }
            break;
        case 0x50:
            switch(funct3) {
                case 0x2: // FEQ.S
                    reg[rd] = (rs1_f == rs2_f) ? 1 : 0;
                    break;
                case 0x1: // FLT.S
                    reg[rd] = (rs1_f < rs2_f) ? 1 : 0;
                    break;
                case 0x0: // FLE.S
                    reg[rd] = (rs1_f <= rs2_f) ? 1 : 0;
                    break;
                default:
                    fprintf(stderr, "unknown funct7\n");
                    exit(EXIT_FAILURE);
            }
            break;
        case 0x64:
            switch(rs2) {
                case 0x0:  // FCVT.S.W
                    reg_fp[rd] = float2int((float)((int)reg[rs1]));
                    break;
                case 0x1:  // FCVT.S.WU
                    reg_fp[rd] = float2int((float)((unsigned)reg[rs1]));
                    break;
                default:
                    fprintf(stderr, "unknown funct7\n");
                    exit(EXIT_FAILURE);
            }
            break;
        case 0x78: // FMV.S.X
            reg_fp[rd] = reg[rs1];
            break;
        default:
            fprintf(stderr, "unknown funct7\n");
            exit(EXIT_FAILURE);
    }
    return pc + 4;
}

uint32_t execute_branch(uint32_t instruction, uint32_t pc){
    uint32_t imm = (((instruction>>31) & 1) ? 0xfffff000 : 0) 
                   | (((instruction >> 7) & 0x1) << 11)| (((instruction >> 25) & 0x3f) << 5)
                   | (((instruction >> 8) & 0xf) << 1);
    uint32_t rs1 = (instruction >> 15) & 0x1f;
    uint32_t rs2 = (instruction >> 20) & 0x1f;
    uint32_t funct3  = (instruction >> 12) & 0x7;
    switch(funct3) {
        case 0x0: // BEQ
            if(reg[rs1] == reg[rs2]) return pc + imm;
            else return pc + 4;
            break;
        case 0x1: // BNE
            if(reg[rs1] != reg[rs2]) return pc + imm;
            else return pc + 4;
            break;
        case 0x4: // BLT
            if((int32_t)reg[rs1] < (int32_t)reg[rs2]) return pc + imm;
            else return pc + 4;
            break;
        case 0x5: // BGE 
            if((int32_t)reg[rs1] >= (int32_t)reg[rs2]) return pc + imm;
            else return pc + 4;
            break;
        case 0x6: // BLTU 
            if((uint32_t)reg[rs1] >= (uint32_t)reg[rs2]) return pc + imm;
            else return pc + 4;
            break;
        case 0x7: // BGEU
            if((uint32_t)reg[rs1] >= (uint32_t)reg[rs2]) return pc + imm;
            else return pc + 4;
            break;
        default:
            fprintf(stderr, "unknown funct. Abort.\n");
            exit(EXIT_FAILURE);
    }
}

uint32_t execute_jalr(uint32_t instruction, uint32_t pc){
    uint32_t imm = (instruction >> 20);
    uint32_t rs1 = (instruction >> 15) & 0x1f;
    uint32_t rd = (instruction >> 7) & 0x1f;
    reg[rd] = pc + 4;
    return reg[rs1] + imm;
}

uint32_t execute_jal(uint32_t instruction, uint32_t pc){
    uint32_t rd = (instruction >> 7) & 0x1f;
    uint32_t imm = (((instruction>>31) & 1) ? 0xfff00000 : 0) 
                   | (((instruction >> 12) & 0xff) << 12)
                   | (((instruction >> 20) & 0x1) << 11)
                   | (((instruction >> 21) & 0x3ff) << 1);
    uint32_t jump_addr = pc + imm;
    reg[rd] = pc + 4;
    return pc + imm;
}

int main(int argc, char **argv) {
    FILE *input;

    int pc, addr = 0;
    uint32_t operation;


    if(argc != 2) {
        fprintf(stderr, "Usage: %s <binary file>\n", argv[0]);
        exit(EXIT_FAILURE);
    }
    if((input = fopen(argv[1], "rb")) == NULL) {
        fprintf(stderr, "Failed to open input file: %s\n", argv[1]);
        exit(EXIT_FAILURE);
    }

    addr = 0;
    while(fread(&operation, sizeof(uint32_t), 1, input) != 0) {
        imem[addr] = operation;
        addr++;
    }
    addr;

    pc = 0;
    while(1) {
        int pc_bak = pc;
        int instruction = imem[(pc>>2)];
        int i;
        printf("%2x: ", pc);
        for(i=31; i>=0; i--) printf("%u", (instruction>>i)&1);
        printf("\n");
        int opcode = instruction & 0x7f;
        switch(opcode) {
            case 0x03: // 0000011
                pc = execute_load(instruction, pc);
                break;
            case 0x07: // 0000111
                pc = execute_load_fp(instruction, pc);
                break;
            case 0x13: // 0010011
                pc = execute_op_imm(instruction, pc);
                break;
            case 0x23: // 0100011
                pc = execute_store(instruction, pc);
                break;
            case 0x27: // 0100111
                pc = execute_store_fp(instruction, pc);
                break;
            case 0x33: // 0110011
                pc = execute_op(instruction, pc);
                break;
            case 0x37: // 0110111
                pc = execute_lui(instruction, pc);
                break;
            case 0x53: // 1010011
                pc = execute_op_fp(instruction, pc);
                break;
            case 0x63: // 1100011 
                pc = execute_branch(instruction, pc);
                break;
            case 0x67: // 1100111
                pc = execute_jalr(instruction, pc);
                break;
            case 0x6f: // 1101111
                pc = execute_jal(instruction, pc);
                break;
            default:
                fprintf(stderr, "unknown opcode @ %d!\n", pc);
                exit(EXIT_FAILURE);
        }
        if(pc == pc_bak) {
            fprintf(stderr, "infinite loop. Abort.\n");
            exit(EXIT_FAILURE);
        }
        reg[0] = 0;
    }
}
