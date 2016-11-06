%{
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>

#define MAX_MEMORY 64
typedef enum Type {Rformat, Iformat, Jformat} Type;
typedef struct instruction{
    Type type;
    int op, rs, rt, rd, shamt, funct, imm;
    char* label;
} instruction;

typedef struct symbol{
    char* label;
    int addr;
} symbol;

instruction program[MAX_MEMORY];
symbol table[MAX_MEMORY];
int table_size = 0;
int addr = 0;
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
void print_bin(uint32_t bin) {
    int i;
    for(i=31; i>=0; i--)  printf("%u", (bin>>i)&1);
    printf("\n");
}
    
void generate_binary(void) {
    int i;
    for(i=0; i<addr; i+=4) {
        instruction *tmp = &program[i>>2];
        uint32_t bin = 0;
        switch(tmp->type) {
            case Rformat:
                bin |= ((tmp->rs) << 21);
                bin |= ((tmp->rt) << 16);
                bin |= ((tmp->rd) << 11);
                bin |= ((tmp->shamt) << 6);
                bin |= (tmp->funct);
                break;
            case Iformat:
                bin |= ((tmp->op) << 26);
                bin |= ((tmp->rs) << 21);
                bin |= ((tmp->rt) << 16);
                if(tmp->label == NULL) {
                    bin |= (tmp->imm) & 0xffff;
                } else {
                    bin |= ((get_address(tmp->label)-(i+4))>>2)&0xffff;
                }
                break;
            case Jformat:
                bin |= ((tmp->op) << 26);
                bin |= get_address(tmp->label)>>2;
                break;
            default:
                fprintf(stderr, "unknown format\n");
                exit(EXIT_FAILURE);
                break;
        }
        //print_bin(bin);
        printf("%08x\n", bin);
    }
}
%}

%union{
    int INT;
    char* STRING;
}

%token CAMMA LPAREN RPAREN COLON RET
%token <INT> REGISTER IMMEDIATE
%token <INT> ADDU AND JR NOR OR SLL SRL SLT SUBU
%token <INT> ADDIU BEQ BNE LW SW J JAL
%token <STRING> LABEL

%type <INT> special branch shift loadstore jump
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
    : special REGISTER CAMMA REGISTER CAMMA REGISTER {
        instruction *tmp = &program[addr>>2];
        tmp->type = Rformat;
        tmp->op = 0;
        tmp->rs = $4;
        tmp->rt = $6;
        tmp->rd = $2;
        tmp->shamt = 0;
        tmp->funct = $1;
        addr += 4; }
    | JR REGISTER {
        instruction *tmp = &program[addr>>2];
        tmp->type = Rformat;
        tmp->op = 0;
        tmp->rs = $2;
        tmp->rt = 0;
        tmp->rd = 0;
        tmp->shamt = 0;
        tmp->funct = $1; 
        addr += 4;}
    | shift REGISTER CAMMA REGISTER CAMMA IMMEDIATE {
        instruction *tmp = &program[addr>>2];
        tmp->type = Rformat;
        tmp->op = 0;
        tmp->rs = 0;
        tmp->rt = $4;
        tmp->rd = $2;
        tmp->shamt = $6;
        tmp->funct = $1; 
        addr += 4;}
    | ADDIU REGISTER CAMMA REGISTER CAMMA IMMEDIATE {
        instruction *tmp = &program[addr>>2];
        tmp->type = Iformat;
        tmp->op = $1;
        tmp->rs = $4;
        tmp->rt = $2;
        tmp->imm = $6;
        addr += 4;}
    | branch REGISTER CAMMA REGISTER CAMMA LABEL {
        instruction *tmp = &program[addr>>2];
        tmp->type = Iformat;
        tmp->op = $1;
        tmp->rs = $2;
        tmp->rt = $4;
        tmp->label = strdup($6);
        addr += 4;}
    | loadstore REGISTER CAMMA IMMEDIATE LPAREN REGISTER RPAREN {
        instruction *tmp = &program[addr>>2];
        tmp->type = Iformat;
        tmp->op = $1;
        tmp->rs = $6;
        tmp->rt = $2;
        tmp->imm = $4;
        tmp->label = NULL;
        addr += 4;}
    | jump LABEL {
        instruction *tmp = &program[addr>>2];
        tmp->type = Jformat;
        tmp->op = $1;
        tmp->label = strdup($2);
        addr += 4;}
    ;

special
    : ADDU
    | AND
    | NOR
    | OR
    | SLT
    | SUBU
    ;

branch
    : BEQ
    | BNE
    ;

shift
    : SLL
    | SRL
    ;

loadstore
    : SW
    | LW
    ;

jump
    : J
    | JAL
    ;

%%

main() {
    yyparse();
    generate_binary();
}

yyerror(char *msg) {
    extern int yylineno;
    fprintf(stderr,"At line %d %s\n",yylineno, msg);
}
