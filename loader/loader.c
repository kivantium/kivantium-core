/*
 * loading binary to CPU
 * Example:
 *   ./loader /dev/ttyUSB1 main.bin 
 */

#include <sys/types.h>
#include <sys/stat.h>
#include <sys/ioctl.h>
#include <fcntl.h>
#include <termios.h>
#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>

#define BAUDRATE B9600
int main(int argc, char *argv[]) {
    int fd, len;
    int buf;
    FILE *fp;

    struct termios oldtio, newtio;
    if(argc != 3) {
        fprintf(stderr, "Error: argument format is wrong\n");
        fprintf(stderr, "Usage: %s <device> <binary>\n", argv[0]);
        exit(EXIT_FAILURE);
    }

    if((fd=open(argv[1], O_RDWR)) < 0) {
        perror(argv[1]);
        exit(EXIT_FAILURE);
    }

    if((fp = fopen(argv[2],"rb")) < 0) {
        perror(argv[2]);
        exit(EXIT_FAILURE);
    }
    
    ioctl(fd, TCGETS, &oldtio);
    newtio = oldtio;
    newtio.c_cflag = BAUDRATE | CS8 | CLOCAL | CREAD;
    ioctl(fd, TCSETS, &newtio);
    
    while(fread(&buf, sizeof(buf), 1, fp) != 0) {
        int i;
        for(i=0; i<4; i++) {
            uint8_t byte = (buf>>i*8)&0xff;
            printf("%02x ", byte);
            write(fd, &byte, 1);
        }
        printf("\n");
    }
    
    ioctl(fd, TCSETS, &oldtio);
    close(fd);

    return 0;
}
