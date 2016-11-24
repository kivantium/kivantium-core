#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define BUF_SIZE 1024
#define TABLE_SIZE 256
#define REGISTER_SIZE 32
#define MEMORY_SIZE 4096
#define OPCODE_SIZE 20


typedef struct {
    char* name;
    int address;
} symbol;

enum operand_type {
    REGISTER, IMMEDIATE, IMPLUSREG, LABEL
};

enum instructions {
    ADDU, ADDIU, BEQ, J, JAL, JR, LW, 
    ORI, SLT, SLTI, SW, SYSCALL
};


typedef struct {
    enum operand_type type;
    int value;
    int offset;
} operand;

typedef struct {
    enum instructions name;
    int op0, op1, op2;
} instruction;
    
int pc;
FILE *bin_out;
int mem[MEMORY_SIZE];
int reg[REGISTER_SIZE];
char line[BUF_SIZE];
instruction instruction_list[MEMORY_SIZE];
symbol symbol_table[TABLE_SIZE];

char opcode[OPCODE_SIZE][16] = {
    "addu", 
    "addiu", 
    "beq",   
    "j",      
    "jal",    
    "jr",    
    "lw",         
    "ori",   
    "slt",  
    "slti",  
    "sw",    
    "syscall", 
};

int lookup_register(char* arg) {
    if(strcmp("$zero", arg)==0) return 0;
    if(strcmp("$at", arg)==0)   return 1;
    if(strcmp("$v0", arg)==0)   return 2;
    if(strcmp("$v1", arg)==0)   return 3;
    if(strcmp("$a0", arg)==0)   return 4;
    if(strcmp("$a1", arg)==0)   return 5;
    if(strcmp("$a2", arg)==0)   return 6;
    if(strcmp("$a3", arg)==0)   return 7;
    if(strcmp("$t0", arg)==0)   return 8;
    if(strcmp("$t1", arg)==0)   return 9;
    if(strcmp("$t2", arg)==0)   return 10;
    if(strcmp("$t3", arg)==0)   return 11;
    if(strcmp("$t4", arg)==0)   return 12;
    if(strcmp("$t5", arg)==0)   return 13;
    if(strcmp("$t6", arg)==0)   return 14;
    if(strcmp("$t7", arg)==0)   return 15;
    if(strcmp("$s0", arg)==0)   return 16;
    if(strcmp("$s1", arg)==0)   return 17;
    if(strcmp("$s2", arg)==0)   return 18;
    if(strcmp("$s3", arg)==0)   return 19;
    if(strcmp("$s4", arg)==0)   return 20;
    if(strcmp("$s5", arg)==0)   return 21;
    if(strcmp("$s6", arg)==0)   return 22;
    if(strcmp("$s7", arg)==0)   return 23;
    if(strcmp("$t8", arg)==0)   return 24;
    if(strcmp("$t9", arg)==0)   return 25;
    if(strcmp("$k0", arg)==0)   return 26;
    if(strcmp("$k1", arg)==0)   return 27;
    if(strcmp("$gp", arg)==0)   return 28;
    if(strcmp("$sp", arg)==0)   return 29;
    if(strcmp("$fp", arg)==0)   return 30;
    if(strcmp("$ra", arg)==0)   return 31;
    fprintf(stderr, "Unknown register: %s\n", arg);
    exit(EXIT_FAILURE);
}

int isWord(char c) {
    if( (c >= 'A' && c <= 'Z') || (c >= 'a' && c <= 'z') || (c=='$') ) {
        return 1;
    } else {
        return 0;
    }
}
int isWord2(char c) {
    if( isWord(c) || (c >= '0' && c <= '9') ) {
        return 1;
    } else {
        return 0;
    }
}
int isNumber(char c) {
    if(c >= '0' && c <= '9') return 1;
    else return 0;
}

void exit_error(int num, char* line, int p) {
    int i;
    fprintf(stderr, "l%d:%d: Analysis Failed\n", num, p);
    fprintf(stderr, "%s", line);
    for(i=0; i<p; ++i) printf(" ");
    printf("^\n");
    /* free symbol_table */
    for(i=0; i<TABLE_SIZE; i++) {
        if(symbol_table[i].name != NULL) free(symbol_table[i].name);
    }
    exit(EXIT_FAILURE);
}

int get_operand(char* arg, int n, operand* ret) {
    int size = 0; /* the number of operand */
    int i = 0;
    char op[16];
    while(arg[i] != '\0' && size < n) {
        /* skip comment */
        if(arg[i] == '#') {
            break;
        }
        /* skip white space*/
        if(arg[i] <= ' ') {
            while(arg[i] > 0 && arg[i] <= ' ') i++;
            continue;
        }
        /* operand is register */
        if(arg[i] == '$') {
            int j = i+1;
            while(isWord2(arg[j])) j++;
            if(j-i > 7) {
                fprintf(stderr, "Too long operand\n");
                exit_error(0, arg, i);
            }
            strncpy(op, arg+i, j-i);
            op[j-i] = '\0';
            if((ret[size].value = lookup_register(op)) >= 0) {
                ret[size].type = REGISTER;
            } else {
                fprintf(stderr, "Unknown register type\n");
                exit_error(0, arg, i);
            }
            size++;
            i = j+1;
            continue;
        }
        if(isWord(arg[i])) {
            int j = i+1;
            int k;
            while(isWord2(arg[j])) j++;
            strncpy(op, arg+i, j-i);
            op[j-i] = '\0';
            for(k = 0; k < TABLE_SIZE; k++) {
                if(symbol_table[k].name != NULL) {
                    if(strcmp(symbol_table[k].name, op) == 0) {
                        ret[size].type = LABEL;
                        ret[size].value = symbol_table[k].address;
                        size++;
                        break;
                    }
                } else {
                    fprintf(stderr, "Symbol %s could not be resolved (UNEXPECTED BEHAVIOR!!)\n", op);
                    exit(EXIT_FAILURE);
                }
            }
            i = j+1;
            continue;
        }
        if(arg[i] == '-' || isNumber(arg[i])) {
            int isNegative = (arg[i] == '-' ? 1 : 0);
            int n = 0;
            if(isNegative) i++;
            while(isNumber(arg[i])) {
                n = n*10+arg[i]-'0';
                i++;
            }
            if(arg[i] == '(') {
                int j = i;
                while(arg[j] != ')') j++;
                strncpy(op, arg+i+1, j-i-1);
                op[j-i] = '\0';
                if((ret[size].value = lookup_register(op)) >= 0) {
                    ret[size].type = IMPLUSREG;
                    ret[size].offset = (isNegative ? -n : n);
                }
                i = j+1;
                size++;
                continue;
            }

            if(isNegative) n = (n^0xffff) + 1;
            ret[size].type = IMMEDIATE;
            ret[size].value = n;
            size++;
            continue;
        }
        fprintf(stderr, "Unknown character: \"%c\"\n", arg[i]);
        exit_error(0, arg, i);
    }
    return size;
}

int parse_addiu(char* arg, int addr) {
    operand op[3];
    int bin = 9 << 26;
    int flag = 0;
    addr /= 4;
    instruction_list[addr].name = ADDIU;

    if(get_operand(arg, 3, op) == 3) {
        if(op[0].type == REGISTER) {
            bin |= (op[0].value << 16);
            instruction_list[addr].op0 = op[0].value;
        } else flag = 1;
        if(op[1].type == REGISTER) {
            bin |= (op[1].value << 21);
            instruction_list[addr].op1 = op[1].value;
        } else flag = 1;
        if(op[2].type == IMMEDIATE) {
            bin |= op[2].value;
            instruction_list[addr].op2 = op[2].value;
        } else flag = 1;
    } else {
        flag = 1;
    }

    if(flag) {
        fprintf(stderr, "Bad operand: %s\n", arg);
        exit_error(0, arg, 0);
    }
    /* debug display */
#ifdef DEBUG
    printf("%08x: addiu%s", bin, arg);
#endif
    fwrite(&bin, sizeof(int), 1, bin_out);
    return 0;
}
int execute_addiu(instruction inst, int pc) {
    int x;
    if(inst.op2 & (1<<15)) x = -((inst.op2^0xffff) + 1);
    else x = inst.op2;
#ifdef DEBUG
    printf("org: %08x, conv: %08x\n", inst.op2, x);
    printf("%08x: addiu $%d $%d %d\n", pc, inst.op0, inst.op1, x);
#endif
    reg[inst.op0] = reg[inst.op1] + x;
    return pc+4;
}

int parse_addu(char* arg, int addr) {
    operand op[3];
    int bin = 0x21;
    int flag = 0;
    addr /= 4;
    instruction_list[addr].name = ADDU;

    if(get_operand(arg, 3, op) == 3) {
        if(op[0].type == REGISTER) {
            bin |= (op[0].value << 11);
            instruction_list[addr].op0 = op[0].value;
        } else flag = 1;
        if(op[1].type == REGISTER) {
            bin |= (op[1].value << 21);
            instruction_list[addr].op1 = op[1].value;
        } else flag = 1;
        if(op[2].type == REGISTER) {
            bin |= (op[2].value << 16);
            instruction_list[addr].op2 = op[2].value;
        } else flag = 1;
    } else {
        flag = 1;
    }

    if(flag) {
        fprintf(stderr, "Bad operand: %s\n", arg);
        exit_error(0, arg, 0);
    }
    /* debug display */
#ifdef DEBUG
    printf("%08x: addiu%s", bin, arg);
#endif
    fwrite(&bin, sizeof(int), 1, bin_out);
    return 0;
}
int execute_addu(instruction inst, int pc) {
#ifdef DEBUG
    printf("%08x: addu $%d $%d $%d\n", pc, inst.op0, inst.op1, inst.op2);
#endif
    reg[inst.op0] = reg[inst.op1] + reg[inst.op2];
    return pc+4;
}

int parse_beq(char* arg, int addr) {
    operand op[3];
    int bin = 4 << 26;
    int flag = 0;
    addr /= 4;
    instruction_list[addr].name = BEQ;

    if(get_operand(arg, 3, op) == 3) {
        if(op[0].type == REGISTER) {
            bin |= (op[0].value << 21);
            instruction_list[addr].op0 = op[0].value;
        } else flag = 1;
        if(op[1].type == REGISTER) { 
            bin |= (op[1].value << 16);
            instruction_list[addr].op1 = op[1].value;
        } else flag = 1;
        if(op[2].type == LABEL) {
            bin |= ((op[2].value - addr*4 - 1)>>2);
            instruction_list[addr].op2 = ((op[2].value - addr*4 - 1)>>2);
        } else flag = 1;
    } else {
        flag = 1;
    }

    if(flag) {
        fprintf(stderr, "Bad operand: %s\n", arg);
        exit_error(0, arg, 0);
    }
    /* debug display */
#ifdef DEBUG
    printf("%08x: beq%s", bin, arg);
#endif
    fwrite(&bin, sizeof(int), 1, bin_out);
    return 0;
}
int execute_beq(instruction inst, int pc) {
#ifdef DEBUG
    printf("%08x: beq\n", pc);
#endif
    if(reg[inst.op0]==reg[inst.op1]) {
#ifdef DEBUG
        printf("TRUE; pc <= pc + 0x%02x (result: %08x)\n", inst.op2, pc+inst.op2); 
#endif
        return pc+4+(inst.op2<<2);
    } else {
#ifdef DEBUG
        printf("FALSE; pc <= pc + 4 (result: %08x)\n", pc+4); 
#endif
        return pc+4;
    }
}

int parse_j(char* arg, int addr) {
    operand op[1];
    int bin = 2 << 26;
    int flag = 0;
    addr /= 4;
    instruction_list[addr].name = J;

    if(get_operand(arg, 1, op) == 1) {
        if(op[0].type == LABEL) {
            bin |= (op[0].value >> 2);
            instruction_list[addr].op0 = (op[0].value >> 2);
        } else flag = 1;
    } else {
        flag = 1;
    }

    if(flag) {
        fprintf(stderr, "Bad operand: %s\n", arg);
        exit_error(0, arg, 0);
    }
    /* debug display */
#ifdef DEBUG
    printf("%08x: j%s", bin, arg);
#endif
    fwrite(&bin, sizeof(int), 1, bin_out);
    return 0;
}
int execute_j(instruction inst, int pc) {
#ifdef DEBUG
    printf("%08x: j\n", pc);
#endif
    return (inst.op0<<2);
}

int parse_jal(char* arg, int addr) {
    operand op[1];
    int bin = 3 << 26;
    int flag = 0;
    addr /= 4;
    instruction_list[addr].name = JAL;

    if(get_operand(arg, 1, op) == 1) {
        if(op[0].type == LABEL) {
            bin |= (op[0].value>>2);
            instruction_list[addr].op0 = (op[0].value>>2);
        } else flag = 1;
    } else {
        flag = 1;
    }

    if(flag) {
        fprintf(stderr, "Bad operand: %s\n", arg);
        exit_error(0, arg, 0);
    }
    /* debug display */
#ifdef DEBUG
    printf("%08x: jal%s", bin, arg);
#endif
    fwrite(&bin, sizeof(int), 1, bin_out);
    return 0;
}
int execute_jal(instruction inst, int pc) {
#ifdef DEBUG
    printf("%08x: jal\n", pc);
    printf("$ra <= %08x\n", pc+4);
#endif
    reg[31] = pc+4;
    return (inst.op0<<2);
}

int parse_jr(char* arg, int addr) {
    operand op[1];
    int bin = 8;
    int flag = 0;
    addr /= 4;;
    instruction_list[addr].name = JR;

    if(get_operand(arg, 1, op) == 1) {
        if(op[0].type == REGISTER) {
            bin |= (op[0].value << 21);
            instruction_list[addr].op0 = op[0].value;
        } else flag = 1;
    } else {
        flag = 1;
    }

    if(flag) {
        fprintf(stderr, "Bad operand: %s\n", arg);
        exit_error(0, arg, 0);
    }
    /* debug display */
#ifdef DEBUG
    printf("%08x: jr%s", bin, arg);
#endif
    fwrite(&bin, sizeof(int), 1, bin_out);
    return 0;
}
int execute_jr(instruction inst, int pc) {
#ifdef DEBUG
    printf("%08x: jr\n", pc);
    printf("register: %d, address: %08x\n", inst.op0, reg[inst.op0]);
#endif
    fflush(stdout);
    return reg[inst.op0];
}

int parse_lw(char* arg, int addr) {
    operand op[3];
    int bin = 0x23 << 26;
    int flag = 0;
    addr /= 4;
    instruction_list[addr].name = LW;

    if(get_operand(arg, 2, op) == 2) {
        if(op[0].type == REGISTER) {
            bin |= (op[0].value << 16);
            instruction_list[addr].op0 = op[0].value;
        } else flag = 1;
        if(op[1].type == IMPLUSREG) {
            bin |= (op[1].value << 21);
            bin |= (op[1].offset & 0xffff);
            instruction_list[addr].op1 = op[1].value;
            instruction_list[addr].op2 = op[1].offset;
        } else flag = 1;
    } else {
        flag = 1;
    }

    if(flag) {
        fprintf(stderr, "Bad operand: %s\n", arg);
        exit_error(0, arg, 0);
    }
    /* debug display */
#ifdef DEBUG
    printf("%08x: lw%s", bin, arg);
#endif
    fwrite(&bin, sizeof(int), 1, bin_out);
    return 0;
}

int execute_lw(instruction inst, int pc) {
    int x;
#ifdef DEBUG
    printf("%08x: lw\n", pc);
#endif

    if(inst.op2 & (1<<15)) x = (inst.op2^0xffffff) + 1;
    else x = inst.op2;

#ifdef DEBUG
    printf("$%d <= $mem[%d](content:%d)\n", inst.op0, (reg[inst.op1]+x)/4, mem[(reg[inst.op1]+x)/4]);
#endif

    reg[inst.op0] = mem[(reg[inst.op1]+x)/4];
    return pc+4;
}

int parse_ori(char* arg, int addr) {
    operand op[3];
    int bin = 0xd << 26;
    int flag = 0;
    addr /= 4;
    instruction_list[addr].name = ORI;

    if(get_operand(arg, 3, op) == 3) {
        if(op[0].type == REGISTER) {
            bin |= (op[0].value << 16);
            instruction_list[addr].op0 = op[0].value;
        } else flag = 1;
        if(op[1].type == REGISTER) {
            bin |= (op[1].value << 21);
            instruction_list[addr].op1 = op[1].value;
        } else flag = 1;
        if(op[2].type == IMMEDIATE) {
            bin |= op[2].value;
            instruction_list[addr].op2 = op[2].value;
        } else flag = 1;
    } else {
        flag = 1;
    }

    if(flag) {
        fprintf(stderr, "Bad operand: %s\n", arg);
        exit_error(0, arg, 0);
    }
    /* debug display */
#ifdef DEBUG
    printf("%08x: ori%s", bin, arg);
#endif
    fwrite(&bin, sizeof(int), 1, bin_out);
    return 0;
}
int execute_ori(instruction inst, int pc) {
#ifdef DEBUG
    printf("%08x: ori\n", pc);
#endif

    reg[inst.op0] = reg[inst.op1] | inst.op2;
    return pc+4;
}

int parse_slt(char* arg, int addr) {
    operand op[3];
    int bin = 0x2A;
    int flag = 0;
    addr /= 4;
    instruction_list[addr].name = SLT;

    if(get_operand(arg, 3, op) == 3) {
        if(op[0].type == REGISTER) {
            bin |= (op[0].value << 11);
            instruction_list[addr].op0 = op[0].value;
        } else flag = 1;
        if(op[1].type == REGISTER) {
            bin |= (op[1].value << 21);
            instruction_list[addr].op1 = op[1].value;
        } else flag = 1;
        if(op[2].type == REGISTER) {
            bin |= (op[2].value << 16);
            instruction_list[addr].op2 = op[2].value;
        } else flag = 1;
    } else {
        flag = 1;
    }

    if(flag) {
        fprintf(stderr, "Bad operand: %s\n", arg);
        exit_error(0, arg, 0);
    }
    /* debug display */
#ifdef DEBUG
    printf("%08x: slt%s", bin, arg);
#endif
    fwrite(&bin, sizeof(int), 1, bin_out);
    return 0;
}
int execute_slt(instruction inst, int pc) {
#ifdef DEBUG
    printf("%08x: slt $%d $%d $%d\n", pc, inst.op0, inst.op1, inst.op2);
#endif
    reg[inst.op0] = (reg[inst.op1] < reg[inst.op2]);
    return pc+4;
}
int parse_slti(char* arg, int addr) {
    operand op[3];
    int bin = 0xa << 26;
    int flag = 0;
    addr /= 4;
    instruction_list[addr].name = SLTI;

    if(get_operand(arg, 3, op) == 3) {
        if(op[0].type == REGISTER) {
            bin |= (op[0].value << 16);
            instruction_list[addr].op0 = op[0].value;
        } else flag = 1;
        if(op[1].type == REGISTER) {
            bin |= (op[1].value << 21);
            instruction_list[addr].op1 = op[1].value;
        } else flag = 1;
        if(op[2].type == IMMEDIATE) {
            bin |= op[2].value;
            instruction_list[addr].op2 = op[2].value;
        } else flag = 1;
    } else {
        flag = 1;
    }

    if(flag) {
        fprintf(stderr, "Bad operand: %s\n", arg);
        exit_error(0, arg, 0);
    }
    /* debug display */
#ifdef DEBUG
    printf("%08x: slti%s", bin, arg);
#endif
    fwrite(&bin, sizeof(int), 1, bin_out);
    return 0;
}
int execute_slti(instruction inst, int pc) {
    int x;
#ifdef DEBUG
    printf("%08x: slti\n", pc);
#endif
    if(inst.op2 & (1<<16)) x = inst.op2^0xffffff + 1;
    else x = inst.op2;

    if(reg[inst.op1] < x) reg[inst.op0] = 1;
    else reg[inst.op0] = 0;
    return pc+4;
}

int parse_sw(char* arg, int addr) {
    operand op[3];
    int bin = 0x2b << 26;
    int flag = 0;
    addr /= 4;
    instruction_list[addr].name = SW;

    if(get_operand(arg, 2, op) == 2) {
        if(op[0].type == REGISTER) {
            bin |= (op[0].value << 16);
            instruction_list[addr].op0 = op[0].value;
        } else flag = 1;
        if(op[1].type == IMPLUSREG) {
            bin |= (op[1].value << 21);
            bin |= (op[1].offset & 0xffff);
            instruction_list[addr].op1 = op[1].value;
            instruction_list[addr].op2 = op[1].offset;
        } else flag = 1;
    } else {
        flag = 1;
    }

    if(flag) {
        fprintf(stderr, "Bad operand: %s\n", arg);
        exit_error(0, arg, 0);
    }
    /* debug display */
#ifdef DEBUG
    printf("%08x: sw%s", bin, arg);
#endif
    fwrite(&bin, sizeof(int), 1, bin_out);
    return 0;
}
int execute_sw(instruction inst, int pc) {
    int x;
#ifdef DEBUG
    printf("%08x: sw\n", pc);
#endif
    if(inst.op2 & (1<<15)) x = (inst.op2^0xffffff) + 1;
    else x = inst.op2;
#ifdef DEBUG
    printf("mem[%d] <= $%d(content:%d)\n", (reg[inst.op1]+inst.op2)/4, inst.op0, reg[inst.op0]);
#endif

    mem[(reg[inst.op1]+inst.op2)/4] = reg[inst.op0];
    if((reg[inst.op1]+inst.op2)/4  == 0) fprintf(stderr, "%x\n", reg[inst.op0]);
    return pc+4;
}
int parse_syscall(char* arg, int addr) {
    int bin = 0xc;
    addr /= 4;
    instruction_list[addr].name = SYSCALL;
    /* debug display */
#ifdef DEBUG
    printf("%08x: syscall%s", bin, arg);
#endif
    fwrite(&bin, sizeof(int), 1, bin_out);
    return 0;
}
int execute_syscall(instruction inst, int pc) {
#ifdef DEBUG
    printf("%08x: syscall\n", pc);
#endif

    if(reg[2] == 1) {
        fprintf(stderr, "%d", reg[4]);
    }
    if(reg[2] == 11) {
        fprintf(stderr, "%c", (char)reg[4]);
    }
    return pc+4;
}
int execute(int pc) {
    instruction inst = instruction_list[pc/4];
    switch(inst.name) {
        case ADDIU:
            return execute_addiu(inst, pc);
        case ADDU:
            return execute_addu(inst, pc);
        case BEQ:
            return execute_beq(inst, pc);
        case J:
            return execute_j(inst, pc);
        case JAL:
            return execute_jal(inst, pc);
        case JR:
            return execute_jr(inst, pc);
        case LW:
            return execute_lw(inst, pc);
        case ORI:
            return execute_ori(inst, pc);
        case SLT:
            return execute_slt(inst, pc);
        case SLTI:
            return execute_slti(inst, pc);
        case SW:
            return execute_sw(inst, pc);
        case SYSCALL:
            return execute_syscall(inst, pc);
        default:
            fprintf(stderr, "Unknown instruction. Abort.\n");
            exit(EXIT_FAILURE);
    }
}

int main(int argc, char** argv) {
    FILE *fp;
    int loop;
    int current_table_size = 0;
    int current_line = 0;
    int instruction_address = 0;
    int nextpc = 0;

    bin_out = fopen("out.bin", "wb");
    if(bin_out == NULL){
        fprintf(stderr, "Could not open out.bin\n");
        exit(EXIT_FAILURE);
    }
    /* initialize symbol_table */
    for(loop=0; loop<TABLE_SIZE; loop++) {
        symbol_table[loop].name = NULL;
        symbol_table[loop].address = -1;
    }

    /* check if there are two arguments */
    if(argc != 2) {
        fprintf(stderr, "Usage: %s <filename>\n", argv[0]);
        exit(EXIT_FAILURE);
    }

    /* check if input file exists */
    if((fp = fopen(argv[1], "r")) == NULL) {
        fprintf(stderr, "File not found\n");
        exit(EXIT_FAILURE);
    }

    /* get symbol addresses */
    while(fgets(line, BUF_SIZE, fp) != NULL) {
        current_line++;
        int i = 0;
        char *token = NULL;

        while(line[i] != '\0') {
            /* skip comment */
            if(line[i] == '#') {
                break;
            }

            /* skip white space*/
            if(line[i] <= ' ') {
                while(line[i] > 0 && line[i] <= ' ') i++;
                continue;
            }

            /* skip assembler directive (for now) */
            if(line[i] == '.') {
                break;
            }

            /* get token */
            if(isWord(line[i])) {
                int j = i+1;
                while(isWord2(line[j])) j++;
                /* if token is given and not symbol */
                if(line[j] == ':') {
                    token = (char*) malloc(sizeof(char)*(j-i));
                    strncpy(token, line+i, j-i);
                    token[j-i] = '\0';
                    symbol_table[current_table_size].name = token;
                    symbol_table[current_table_size].address = instruction_address;
                    current_table_size++;
#ifdef DEBUG
                    printf("symbol %s: %08x\n", token, instruction_address);
#endif
                    if(current_table_size >= TABLE_SIZE) {
                        fprintf(stderr, "Too many tokens\n");
                        exit_error(current_line, line, i);
                    }
                } else {
                    int flag = 0;
                    for(loop=0; loop<OPCODE_SIZE; ++loop) {
                        if(strncmp(line+i, opcode[loop], j-i-1) == 0) {
                            flag = 1;
                            break;
                        }
                    }
                    if(flag == 0) {
                        fprintf(stderr, "Unknown opcode\n");
                        exit_error(current_line, line, i);
                    }
#ifdef DEBUG
                    printf("%08x: %s\n", instruction_address, opcode[loop]);
#endif
                    instruction_address += 4;
                }
                break;
            }
            fprintf(stderr, "Unknown character: \"%c\"\n", line[i]);
            exit_error(current_line, line, i);
        }
    }
    for(loop = 0; loop < current_table_size; loop++) {
#ifdef DEBUG
        printf("%s: %x\n", symbol_table[loop].name, symbol_table[loop].address);
#endif
        if(symbol_table[loop].address < 0) {
            fprintf(stderr, "Error definition not found: %s\n", symbol_table[loop].name);
            exit(EXIT_FAILURE);
        }
    }

    /* convert to binary */
    rewind(fp);
    current_line = 0;
    instruction_address = 0;
    while(fgets(line, BUF_SIZE, fp) != NULL) {
        current_line++;
        int i = 0;
        char *token = NULL;

        while(line[i] != '\0') {
            /* skip comment */
            if(line[i] == '#') {
                break;
            }

            /* skip white space*/
            if(line[i] <= ' ') {
                while(line[i] > 0 && line[i] <= ' ') i++;
                continue;
            }

            /* skip assembler directive (for now) */
            if(line[i] == '.') {
                break;
            }

            /* get token */
            if(isWord(line[i])) {
                int j = i+1;
                while(isWord2(line[j])) j++;
                /* instruction */
                if(line[j] != ':') {
                    token = (char*) malloc(sizeof(char)*(j-i+1));
                    strncpy(token, line+i, j-i);
                    token[j-i] = '\0';
                    if(strcmp("addiu", token) == 0)   parse_addiu(line+j, instruction_address);
                    else if(strcmp("addu", token) == 0)       parse_addu(line+j, instruction_address);
                    else if(strcmp("beq", token) == 0)     
                        parse_beq(line+j, instruction_address);
                    else if(strcmp("j", token) == 0)       parse_j(line+j, instruction_address);
                    else if(strcmp("jal", token) == 0)     parse_jal(line+j, instruction_address);
                    else if(strcmp("jr", token) == 0)      parse_jr(line+j, instruction_address);
                    else if(strcmp("lw", token) == 0)      parse_lw(line+j, instruction_address);
                    else if(strcmp("ori", token) == 0)     parse_ori(line+j, instruction_address);
                    else if(strcmp("slt", token) == 0)    parse_slt(line+j, instruction_address);
                    else if(strcmp("slti", token) == 0)    parse_slti(line+j, instruction_address);
                    else if(strcmp("sw", token) == 0)      parse_sw(line+j, instruction_address);
                    else if(strcmp("syscall", token) == 0) parse_syscall(line+j, instruction_address);
                    else {
                        fprintf(stderr, "Unimplemented operation: %s\n", token);
                        exit(EXIT_FAILURE);
                    }
                    free(token);
                    instruction_address += 4;
                    break;
                }
                break;
            }
            fprintf(stderr, "Unknown character: \"%c\"\n", line[i]);
            exit_error(current_line, line, i);
        }
    }
    fclose(bin_out);
    for(loop = 0; loop < instruction_address; loop += 4) {
        printf("%08x: %s %d %d %d\n", loop, opcode[(int)instruction_list[loop/4].name]
        , instruction_list[loop/4].op0, instruction_list[loop/4].op1, instruction_list[loop/4].op2);
    }

    reg[29] = MEMORY_SIZE*4-8; /* set initial $sp */
    reg[30] = MEMORY_SIZE*4-4; /* set initial $fp */
    reg[31] = -1;            /* set initial $ra */
    printf("\nEXECUTE\n");
    while(nextpc != -1) {
        int t;
        /* printf("$sp: %d, $fp: %d, $ra: %08x\n", reg[29], reg[30], reg[31]);*/
        t = execute(nextpc);
        if(t == nextpc) {
            fprintf(stderr, "break\n");
            break;
        }
        else nextpc = t;
        reg[0] = 0;
        fflush(stdout);
    }

    return 0;
}
