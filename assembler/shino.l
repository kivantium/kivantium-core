%{
#include "y.tab.h"
%}

ws  [ \t]
digit [0-9]
letter [a-zA-Z_]
newline [\r\n]
id  {letter}({letter}|{digit})*
other .

%%

{ws}+
{newline}   { return RET; }
"#"{other}+
"("         { return LPAREN; }
")"         { return RPAREN; }
","         { return CAMMA; }
":"         { return COLON; }

-{digit}+   {yylval.INT = atoi(yytext); return IMMEDIATE;}
{digit}+    {yylval.INT = atoi(yytext);  return IMMEDIATE;}

"addi"      {yylval.INT = 0x0; return ADDI;}
"slti"      {yylval.INT = 0x2; return SLTI;}
"sltiu"     {yylval.INT = 0x3; return SLTIU;}
"andi"      {yylval.INT = 0x7; return ANDI;}
"ori"       {yylval.INT = 0x6; return ORI;}
"xori"      {yylval.INT = 0x4; return XORI;}
"slli"      {yylval.INT = 0x1; return SLLI;}
"srli"      {yylval.INT = 0x5; return SRLI;}
"srai"      {yylval.INT = 0x5; return SRAI;}
"lui"       {return LUI;}
"auipc"     {return AUIPC;}
"add"       {yylval.INT = 0x0; return ADD;}
"slt"       {yylval.INT = 0x2; return SLT;}
"sltu"      {yylval.INT = 0x3; return SLTU;}
"and"       {yylval.INT = 0x7; return AND;}
"or"        {yylval.INT = 0x6; return OR;}
"xor"       {yylval.INT = 0x4; return XOR;}
"sll"       {yylval.INT = 0x1; return SLL;}
"srl"       {yylval.INT = 0x5; return SRL;}
"sub"       {yylval.INT = 0x0; return SUB;}
"sra"       {yylval.INT = 0x5; return SRA;}
"nop"       {yylval.INT = 0x0; return NOP;}
"jalr"      {return JALR;}
"jal"       {return JAL;}
"j"         {return J;}
"beq"       {yylval.INT = 0x0; return BEQ;}
"bne"       {yylval.INT = 0x1; return BNE;}
"blt"       {yylval.INT = 0x4; return BLT;}
"bltu"      {yylval.INT = 0x6; return BLTU;}
"bge"       {yylval.INT = 0x5; return BGE;}
"bgeu"      {yylval.INT = 0x7; return BGEU;}
"lw"        {yylval.INT = 0x2; return LW;}
"lh"        {yylval.INT = 0x1; return LH;}
"lhu"       {yylval.INT = 0x5; return LHU;}
"lb"        {yylval.INT = 0x0; return LB;}
"lbu"       {yylval.INT = 0x4; return LBU;}
"sw"        {yylval.INT = 0x2; return SW;}
"sh"        {yylval.INT = 0x1; return SH;}
"sb"        {yylval.INT = 0x0; return SB;}

"$zero"     {yylval.INT = 0;  return(REGISTER); }
"$ra"       {yylval.INT = 1;  return(REGISTER); }
"$sp"       {yylval.INT = 2;  return(REGISTER); }
"$gp"       {yylval.INT = 3;  return(REGISTER); }
"$tp"       {yylval.INT = 4;  return(REGISTER); }
"$t0"       {yylval.INT = 5;  return(REGISTER); }
"$t1"       {yylval.INT = 6;  return(REGISTER); }
"$t2"       {yylval.INT = 7;  return(REGISTER); }
"$fp"       {yylval.INT = 8;  return(REGISTER); }
"$s0"       {yylval.INT = 8;  return(REGISTER); }
"$s1"       {yylval.INT = 9;  return(REGISTER); }
"$a0"       {yylval.INT = 10; return(REGISTER); }
"$a1"       {yylval.INT = 11; return(REGISTER); }
"$a2"       {yylval.INT = 12; return(REGISTER); }
"$a3"       {yylval.INT = 13; return(REGISTER); }
"$a4"       {yylval.INT = 14; return(REGISTER); }
"$a5"       {yylval.INT = 15; return(REGISTER); }
"$a6"       {yylval.INT = 16; return(REGISTER); }
"$a7"       {yylval.INT = 17; return(REGISTER); }
"$s2"       {yylval.INT = 18; return(REGISTER); }
"$s3"       {yylval.INT = 19; return(REGISTER); }
"$s4"       {yylval.INT = 20; return(REGISTER); }
"$s5"       {yylval.INT = 21; return(REGISTER); }
"$s6"       {yylval.INT = 22; return(REGISTER); }
"$s7"       {yylval.INT = 23; return(REGISTER); }
"$s8"       {yylval.INT = 24; return(REGISTER); }
"$s9"       {yylval.INT = 25; return(REGISTER); }
"$s10"      {yylval.INT = 26; return(REGISTER); }
"$s11"      {yylval.INT = 27; return(REGISTER); }
"$t3"       {yylval.INT = 28; return(REGISTER); }
"$t4"       {yylval.INT = 29; return(REGISTER); }
"$t5"       {yylval.INT = 30; return(REGISTER); }
"$t6"       {yylval.INT = 31; return(REGISTER); }
"$x0"        {yylval.INT = 0;  return(REGISTER); }
"$x1"        {yylval.INT = 1;  return(REGISTER); }
"$x2"        {yylval.INT = 2;  return(REGISTER); }
"$x3"        {yylval.INT = 3;  return(REGISTER); }
"$x4"        {yylval.INT = 4;  return(REGISTER); }
"$x5"        {yylval.INT = 5;  return(REGISTER); }
"$x6"        {yylval.INT = 6;  return(REGISTER); }
"$x7"        {yylval.INT = 7;  return(REGISTER); }
"$x8"        {yylval.INT = 8;  return(REGISTER); }
"$x9"        {yylval.INT = 9;  return(REGISTER); }
"$x10"       {yylval.INT = 10; return(REGISTER); }
"$x11"       {yylval.INT = 11; return(REGISTER); }
"$x12"       {yylval.INT = 12; return(REGISTER); }
"$x13"       {yylval.INT = 13; return(REGISTER); }
"$x14"       {yylval.INT = 14; return(REGISTER); }
"$x15"       {yylval.INT = 15; return(REGISTER); }
"$x16"       {yylval.INT = 16; return(REGISTER); }
"$x17"       {yylval.INT = 17; return(REGISTER); }
"$x18"       {yylval.INT = 18; return(REGISTER); }
"$x19"       {yylval.INT = 19; return(REGISTER); }
"$x20"       {yylval.INT = 20; return(REGISTER); }
"$x21"       {yylval.INT = 21; return(REGISTER); }
"$x22"       {yylval.INT = 22; return(REGISTER); }
"$x23"       {yylval.INT = 23; return(REGISTER); }
"$x24"       {yylval.INT = 24; return(REGISTER); }
"$x25"       {yylval.INT = 25; return(REGISTER); }
"$x26"       {yylval.INT = 26; return(REGISTER); }
"$x27"       {yylval.INT = 27; return(REGISTER); }
"$x28"       {yylval.INT = 28; return(REGISTER); }
"$x29"       {yylval.INT = 29; return(REGISTER); }
"$x30"       {yylval.INT = 30; return(REGISTER); }
"$x31"       {yylval.INT = 31; return(REGISTER); }

{id}        {yylval.STRING = strdup(yytext); return LABEL;}
{other}     {fprintf(stderr, "illegal char '%c' ignored\n", yytext[0]);}
