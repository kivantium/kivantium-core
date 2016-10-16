    .text
    .globl main
main:
    ori     $v0, $zero, 1  # print_intを指定
    slti    $a0, $zero, 1
    syscall
    ori     $t0, $zero, 2
    slti    $a0, $t0, 1
    syscall
    jr $ra
