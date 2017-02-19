main:
    addi   $fp, $zero, 252 # 00
    addi   $sp, $zero, 216 # 04
    sw     $ra, 20($sp)    # 08
    sw     $fp, 16($sp)    # 0c
    addi   $fp, $sp, 28    # 10
    addi   $a0, $zero, 1   # 14
    jal    fib             # 18
    sw     $a0, 0($zero)   # 1c
inf:
    j      inf             # 20
fib:
    slti   $t0, $a0, 2     # 24
    beq    $t0, $zero, rec # 28 
    addi   $a0, $zero, 1   # 2c
    jalr   $zero, 0($ra)   # 30
rec:
    addi   $sp, $sp, -32   # 34
    sw     $ra, 20($sp)    # 38
    sw     $fp, 16($sp)    # 3c
    addi   $fp, $sp, 28    # 40
    sw     $a0, 0($fp)     # 44
    addi   $a0, $a0, -1    # 48
    jal    fib             # 4c
    sw     $a0, 4($fp)     # 50
    lw     $a0, 0($fp)     # 54
    addi   $a0, $a0, -2    # 58
    jal    fib             # 5c
    lw     $a1, 4($fp)     # 60
    add    $a0, $a0, $a1   # 64
    lw     $ra, 20($sp)    # 68
    lw     $fp, 16($sp)    # 6c
    addi   $sp, $sp, 32    # 70
    jalr   $zero, 0($ra)   # 74
