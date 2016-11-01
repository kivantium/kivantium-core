/*
 * convert binary to text
 * Example:
 *   ./convert main.bin > main.txt
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>

#define BAUDRATE B9600
int main(int argc, char *argv[]) {
    int buf;
    int addr = 0;
    FILE *fp;

    if(argc != 2) {
        fprintf(stderr, "Error: argument format is wrong\n");
        fprintf(stderr, "Usage: %s <binary>\n", argv[0]);
        exit(EXIT_FAILURE);
    }

    if((fp = fopen(argv[1],"rb")) < 0) {
        perror(argv[1]);
        exit(EXIT_FAILURE);
    }
    
    
    while(fread(&buf, sizeof(buf), 1, fp) != 0) {
        int i;
        printf("%x: ", addr);
        addr += 4;
        for(i=3; i>=0; i--) {
            uint8_t byte = (buf>>i*8)&0xff;
            printf("%02x", byte);
        }
        printf("\n");
    }
    return 0;
}
