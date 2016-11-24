%{
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <unistd.h>

#define MAX_MEMORY 64

typedef enum Format {Rtype, Itype, Stype, SBtype, Utype, UJtype} Format;

typedef struct instruction{
    uint32_t bin;
    char* label;
    Format format;
} instruction;


typedef struct symbol{
    char* label;
    int addr;
} symbol;

instruction program[MAX_MEMORY];
symbol table[MAX_MEMORY];

int table_size = 0;
int addr = 0;
FILE *outfile;

int get_address(char* label) {
    int i;
    for(i=0; i<=table_size; i++) {
        if(table[i].label == NULL) break;
        if(strcmp(table[i].label, label) == 0) 
            return table[i].addr;
    }
    fprintf(stderr, "unknown label %s\n", label);
    exit(EXIT_FAILURE);
    return -1;
}
void print_bin(uint32_t bin, int pc) {
    int i;
    if(outfile == stdout) {
        printf("%02x: ", pc);
        for(i=31; i>=0; i--) printf("%u", (bin>>i)&1);
        printf("\n");
    } else {
        fwrite(&bin, sizeof(bin), 1, outfile);
    }
}
    
void generate_binary(void) {
    int i;
    for(i=0; i<addr; i+=4) {
        instruction *tmp = &program[i>>2];
        if(tmp->label != NULL) {
            uint32_t dst = get_address(tmp->label);
            if((tmp->bin & 0x7f) == 0x6f) { // JAL
                dst -= i;
                tmp->bin |= ((dst & 0x000ff000) >> 12) << 12; // imm[19:12]
                tmp->bin |= ((dst & 0x00000800) >> 11) << 20; // imm[11]
                tmp->bin |= ((dst & 0x000007fe) >> 1) << 21; // imm[10:1]
                tmp->bin |= ((dst & 0x00100000) >> 20) << 31; // imm[20]
            } 
            if((tmp->bin & 0x7f) == 0x63) { // branch
                dst -= i;
                tmp->bin |= ((dst & 0x00000800) >> 11) << 7; // imm[11]
                tmp->bin |= ((dst & 0x0000001e) >> 1) << 8; // imm[4:1]
                tmp->bin |= ((dst & 0x000003e0) >> 5) << 21; // imm[10:5]
                tmp->bin |= ((dst & 0x00000400) >> 12) << 31; // imm[20]
            }
        }
        print_bin(tmp->bin, i);
    }
}
%}

%union{
    int INT;
    char* STRING;
}

%token CAMMA LPAREN RPAREN COLON RET
%token <INT> REGISTER IMMEDIATE
%token <INT> LUI AUIPC JAL JALR BEQ BNE BLT BGE BLTU BGEU
%token <INT> LB LH LW LBU LHU SB SH SW
%token <INT> ADDI SLTI SLTIU XORI ORI ANDI SLLI SRLI SRAI NOP
%token <INT> ADD SUB SLL SLT SLTU XOR SRL SRA OR AND
%token <INT> FENCE FENCE_I ECALL EBREAK CSRRW CSRRS CSRRC CSRRWI CSRRSI CSRRCI
%token <INT> MUL MULH MULHSU MULHU DIV DIVU REM REMU
%token <INT> FLW FSW FMADD_S FMSUB_S FNMSUB_S FNMADD_S FADD_S FSUB_S FMUL_S FDIV_S FSQRT_S
%token <INT> FSGNJ_S FSGNJN_S FSGNJX_S FMIN_S FMAX_S FCVT_W_S FCVT_WU_S FMV_X_S FEQ_S FLT_S
%token <INT> FLE_S FCLASS_S FCVT_S_W FCVT_S_WU FMV_S_X
%token <STRING> LABEL

%type <INT> op_imm op_reg op_reg2 branch load store
%%


program 
    : 
    | program line
    | program error
    ;

line    
    : LABEL COLON RET {
        table[table_size].label = strdup($1);
        table[table_size].addr = addr;
        table_size++; }
    | instruction RET
    | RET
    ;

instruction 
    : op_imm REGISTER CAMMA REGISTER CAMMA IMMEDIATE {
        // ADDI, SLTI[U], ANDI, ORI, XORI
        instruction *tmp = &program[addr>>2];
        tmp->format = Itype;
        tmp->bin |= 0x13; // opcode 0010011
        tmp->bin |= ($2 << 7); // rd
        tmp->bin |= ($1 << 12); // funct3
        tmp->bin |= ($4 << 15); // rs1
        tmp->bin |= ($6 << 20); // imm[11:0] TODO: error handling
        addr += 4;}
    | NOP {
        // NOP
        instruction *tmp = &program[addr>>2];
        tmp->format = Itype;
        tmp->bin |= 0x13; // opcode 0010011
        tmp->bin |= ($1 << 12); // funct3
        addr += 4;}
    | SRAI REGISTER CAMMA REGISTER CAMMA IMMEDIATE {
        // SLLI, SRLI, SRAI
        instruction *tmp = &program[addr>>2];
        tmp->format = Itype;
        tmp->bin |= 0x13;       // opcode 0010011
        tmp->bin |= ($2 << 7);  // rd
        tmp->bin |= ($1 << 12); // funct3
        tmp->bin |= ($4 << 15); // rs1
        tmp->bin |= ($6 << 20); // imm[4:0]
        tmp->bin |= (0x20 << 25); // imm[11:5]
        addr += 4;}
    | LUI REGISTER CAMMA IMMEDIATE {
        // LUI
        instruction *tmp = &program[addr>>2];
        tmp->format = Utype;
        tmp->bin |= 0x37;        // opcode 0110111
        tmp->bin |= ($2 << 7);  // rd
        tmp->bin |= ($4 << 12); // imm[31:12]
        addr += 4;}
    | AUIPC REGISTER CAMMA IMMEDIATE {
        // AUIPC
        instruction *tmp = &program[addr>>2];
        tmp->format = Utype;
        tmp->bin |= 0x17;       // opcode 0010111
        tmp->bin |= ($2 << 7);  // rd
        tmp->bin |= ($4 << 12); // imm[31:12]
        addr += 4;}
    | op_reg REGISTER CAMMA REGISTER CAMMA REGISTER {
        // ADD, SLT, SLTU, AND, OR, XOR, SLL, SRL
        instruction *tmp = &program[addr>>2];
        tmp->format = Rtype;
        tmp->bin |= 0x33;       // opcode 0110011
        tmp->bin |= ($2 << 7);  // rd
        tmp->bin |= ($1 << 12); // funct3
        tmp->bin |= ($4 << 15); // rs1
        tmp->bin |= ($6 << 20); // rs2
        addr += 4;}
    | op_reg2 REGISTER CAMMA REGISTER CAMMA REGISTER {
        // SUB, SRA
        instruction *tmp = &program[addr>>2];
        tmp->format = Rtype;
        tmp->bin |= 0x33;       // opcode 0110011
        tmp->bin |= ($2 << 7);  // rd
        tmp->bin |= ($1 << 12); // funct3
        tmp->bin |= ($4 << 15); // rs1
        tmp->bin |= ($6 << 20); // rs2
        tmp->bin |= (0x20 << 25); // funct7
        addr += 4;}
    | JAL LABEL {
        instruction *tmp = &program[addr>>2];
        tmp->format = UJtype;
        tmp->bin |= 0x6f;       // opcode 1101111
        tmp->bin |= (0x1 << 7); // save pc to $ra
        tmp->label = strdup($2);
        addr += 4;}
    | JAL REGISTER LABEL {
        instruction *tmp = &program[addr>>2];
        tmp->format = UJtype;
        tmp->bin |= 0x6f;       // opcode 1101111
        tmp->bin |= ($2 << 7); // save pc to $ra
        tmp->label = strdup($3);
        addr += 4;}
    | JALR REGISTER CAMMA IMMEDIATE LPAREN REGISTER RPAREN {
        instruction *tmp = &program[addr>>2];
        tmp->format = Itype;
        tmp->bin |= 0x67;       // opcode 1100111
        tmp->bin |= ($2 << 7);  // rd
        tmp->bin |= (0 << 12); // funct3
        tmp->bin |= ($6 << 15); // rs1
        tmp->bin |= ($4 << 20); // imm[11:0]
        addr += 4;}
    | branch REGISTER CAMMA REGISTER CAMMA LABEL {
        instruction *tmp = &program[addr>>2];
        tmp->format = SBtype;
        tmp->bin |= 0x63;       // opcode 1100011
        tmp->bin |= ($1 << 12); // funct3
        tmp->bin |= ($2 << 15); // rs1
        tmp->bin |= ($4 << 20); // rs2
        tmp->label = strdup($6);
        addr += 4;}
    | load REGISTER CAMMA IMMEDIATE LPAREN REGISTER RPAREN {
        instruction *tmp = &program[addr>>2];
        tmp->format = Itype;
        tmp->bin |= 0x03;       // opcode 0000011
        tmp->bin |= ($2 << 7);  // rd
        tmp->bin |= ($1 << 12); // funct3
        tmp->bin |= ($6 << 15); // rs1
        tmp->bin |= ($4 << 20); // imm[11:0]
        addr += 4;}
    | store REGISTER CAMMA IMMEDIATE LPAREN REGISTER RPAREN {
        instruction *tmp = &program[addr>>2];
        tmp->format = Stype;
        tmp->bin |= 0x23;       // opcode 0100011
        tmp->bin |= ($2 << 20);  // rs2
        tmp->bin |= ($1 << 12); // funct3
        tmp->bin |= ($6 << 15); // rs1
        tmp->bin |= ((($4 & 0x01f) >> 0) << 7); // imm[4:0]
        tmp->bin |= ((($4 & 0xfe0) >> 5) << 25); // imm[11:5]
        addr += 4;}
    ;

op_imm 
    : ADDI
    | SLTI
    | SLTIU
    | ANDI
    | ORI
    | XORI
    | SLLI
    | SRLI
    ;
op_reg
    : ADD
    | SLT
    | SLTU
    | AND
    | OR
    | XOR
    | SLL
    | SRL
    ;
op_reg2
    : SUB
    | SRA
    ;
branch
    : BEQ
    | BNE
    | BLT
    | BLTU
    | BGE
    | BGEU
    ;
load
    : LW
    | LH
    | LHU
    | LB
    | LBU
    ;
store
    : SW
    | SH
    | SB
    ;
%%

void main(int argc, char **argv) {
    extern FILE* yyin;
    int ch;
    extern char *optarg;
    extern int optind, opterr;
    outfile = stdout;
    while ((ch = getopt(argc, argv, "o:")) != -1){
        switch (ch){
            case 'o':
                if((outfile = fopen(optarg, "wb")) == NULL) {
                    fprintf(stderr, "failed to open output file\n");
                    exit(EXIT_FAILURE);
                }
              break;
        }
    }
  argc -= optind;
  argv += optind;
    if(argc != 1) {
        fprintf(stderr, "input file not specified\n");
        fprintf(stderr, "Usage: ./shino <assembly file> <option>\n");
        exit(EXIT_FAILURE);
    }
    if((yyin = fopen(argv[0], "r")) == NULL) {
        fprintf(stderr, "input file not found\n");
        exit(EXIT_FAILURE);
    }
    
    yyparse();
    generate_binary();
}

yyerror(char *msg) {
    extern int yylineno;
    fprintf(stderr,"l%d: %s\n",yylineno, msg);
}
