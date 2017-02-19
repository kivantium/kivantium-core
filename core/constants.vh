`timescale 1ns / 1ns

`define LOAD      7'b0000011
`define LOAD_FP   7'b0000111
`define custom_0  7'b0001011
`define MISC_MEM  7'b0001111
`define OP_IMM    7'b0010011
`define AUIPC     7'b0010111
`define OP_IMM_32 7'b0011011

`define STORE     7'b0100011
`define STORE_FP  7'b0100111
`define custom_1  7'b0101011
`define AMO       7'b0101111
`define OP        7'b0110011
`define LUI       7'b0110111
`define OP_32     7'b0111011

`define MADD      7'b1000011
`define MSUB      7'b1000111
`define NMSUB     7'b1001011
`define NMADD     7'b1001111
`define OP_FP     7'b1010011
`define reserved0 7'b1010111
`define custom_2  7'b1011011

`define BRANCH    7'b1100011
`define JALR      7'b1100111
`define reserved1 7'b1101011
`define JAL       7'b1101111
`define SYSTEM    7'b1110011
`define reserved2 7'b1110111
`define custom_3  7'b1111011
`define UNKNOWN   7'b1111111

`define INST_INTEGER 3'b000
`define INST_LOAD_STORE 3'b001
`define INST_BRANCH 3'b010