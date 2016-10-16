    .text
    .globl main
main:
    ori     $v0, $zero, 1  # print_intを指定
    ori     $a0, $zero, 1
    syscall
    ori     $a0, $zero, 2
    syscall
    ori     $a0, $zero, 4
    syscall
    ori     $a0, $zero, 8
    syscall
    ori     $a0, $zero, 16
    syscall
    ori     $a0, $zero, 32
    syscall
    ori     $a0, $zero, 64 
    syscall
    ori     $a0, $zero, -1
    syscall
    ori     $a0, $zero, -2
    syscall
    jr $ra
