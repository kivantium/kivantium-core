    .text
    .globl main
main:
    ori     $v0, $zero, 1  # print_intを指定
    ori     $t0, $zero, 1
    addu    $a0, $zero, $t0
    syscall
    addu    $a0, $a0, $t0
    syscall
    addu    $a0, $a0, $t0
    syscall
    addu    $a0, $a0, $t0
    syscall
    addu    $a0, $a0, $t0
    syscall
    jr $ra
