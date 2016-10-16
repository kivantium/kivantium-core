    .text
    .globl main
main:
    ori     $v0, $zero, 1  # print_intを指定
    ori     $t0, $zero, 1
    addiu    $a0, $zero, 1
    syscall
    addiu    $a0, $a0, 1
    syscall
    addiu    $a0, $a0, 1
    syscall
    addiu    $a0, $a0, 1
    syscall
    addiu    $a0, $a0, 1
    syscall
    jr $ra
