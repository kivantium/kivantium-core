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

"addu"      {yylval.INT = 0x21; return ADDU;}
"and"       {yylval.INT = 0x24; return AND;}
"jr"        {yylval.INT = 0x08; return JR;}
"nor"       {yylval.INT = 0x27; return NOR;}
"or"        {yylval.INT = 0x25; return OR;}
"sll"       {yylval.INT = 0x00; return SLL;}
"srl"       {yylval.INT = 0x02; return SRL;}
"slt"       {yylval.INT = 0x2a; return SLT;}
"subu"      {yylval.INT = 0x23; return SUBU;}

"addiu"     {yylval.INT = 0x09; return ADDIU;}
"beq"       {yylval.INT = 0x04; return BEQ;}
"bne"       {yylval.INT = 0x05; return BNE;}
"lw"        {yylval.INT = 0x23; return LW;}
"sw"        {yylval.INT = 0x2b; return SW;}

"j"         {yylval.INT = 0x02; return J;}
"jal"       {yylval.INT = 0x03; return JAL;}

"$zero"     {yylval.INT = 0;  return(REGISTER); }
"$at"       {yylval.INT = 1;  return(REGISTER); }
"$v0"       {yylval.INT = 2;  return(REGISTER); }
"$v1"       {yylval.INT = 3;  return(REGISTER); }
"$a0"       {yylval.INT = 4;  return(REGISTER); }
"$a1"       {yylval.INT = 5;  return(REGISTER); }
"$a2"       {yylval.INT = 6;  return(REGISTER); }
"$a3"       {yylval.INT = 7;  return(REGISTER); }
"$t0"       {yylval.INT = 8;  return(REGISTER); }
"$t1"       {yylval.INT = 9;  return(REGISTER); }
"$t2"       {yylval.INT = 10; return(REGISTER); }
"$t3"       {yylval.INT = 11; return(REGISTER); }
"$t4"       {yylval.INT = 12; return(REGISTER); }
"$t5"       {yylval.INT = 13; return(REGISTER); }
"$t6"       {yylval.INT = 14; return(REGISTER); }
"$t7"       {yylval.INT = 15; return(REGISTER); }
"$s0"       {yylval.INT = 16; return(REGISTER); }
"$s1"       {yylval.INT = 17; return(REGISTER); }
"$s2"       {yylval.INT = 18; return(REGISTER); }
"$s3"       {yylval.INT = 19; return(REGISTER); }
"$s4"       {yylval.INT = 20; return(REGISTER); }
"$s5"       {yylval.INT = 21; return(REGISTER); }
"$s6"       {yylval.INT = 22; return(REGISTER); }
"$s7"       {yylval.INT = 23; return(REGISTER); }
"$t8"       {yylval.INT = 24; return(REGISTER); }
"$t9"       {yylval.INT = 25; return(REGISTER); }
"$k0"       {yylval.INT = 26; return(REGISTER); }
"$k1"       {yylval.INT = 27; return(REGISTER); }
"$gp"       {yylval.INT = 28; return(REGISTER); }
"$sp"       {yylval.INT = 29; return(REGISTER); }
"$fp"       {yylval.INT = 30; return(REGISTER); }
"$ra"       {yylval.INT = 31; return(REGISTER); }

{id}        {yylval.STRING = strdup(yytext); return LABEL;}
{other}     {fprintf(stderr, "illegal char '%c' ignored\n", yytext[0]);}
