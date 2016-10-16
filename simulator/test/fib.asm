    .text
    .globl main
main:
    # スタックフレームの作成
    addiu   $sp, $sp, -32  # スタック領域を下に32 byte伸ばす
    sw      $ra, 20($sp)    # リターン・アドレスを退避
    sw      $fp, 16($sp)    # フレーム・ポインタを退避
    addiu   $fp, $sp, 28    # 新しいフレーム・ポインタを設定
    ori     $s0, $zero, 0
    ori     $s1, $zero, 15
loop:
    beq     $s0, $s1, end
    addu    $a0, $s0, $zero # fibの引数に$s0を設定
    jal     fib             # fibを呼び出す
    addu    $a0, $v0, $zero # fibの結果をa0に移動11101
    ori     $v0, $zero, 1   # syscallでprint_intを呼び出す設定
    syscall                 # print_intでa0(fibの結果が入る)を出力
    ori     $a0, $zero, 10 
    ori     $v0, $zero, 11
    syscall
    addiu   $s0, $s0, 1
    j       loop
end:
    lw      $ra, 20($sp)  # 退避したリターン・アドレスを復元
    lw      $fp, 16($sp)  # 退避したフレーム・ポインタを復元
    addiu   $sp, $sp, 32  # スタック領域を32 byte短くする
    jr      $ra           # 呼び出し元に戻る
# fib関数
fib:
    addiu   $sp, $sp, -32  # スタック領域を下に32 byte伸ばす
    sw      $ra, 20($sp)  # リターン・アドレスを退避
    sw      $fp, 16($sp)  # フレーム・ポインタを退避
    addiu   $fp, $sp, 28  # 新しいフレームポインタを設定
    sw      $a0, 0($fp)   # a0 (引数)を退避
    slti    $t0, $a0, 2   # (次の行と合わせて) a0<2ならば$L2にジャンプ
    beq     $t0, $zero, L2      
    ori     $v0, $zero, 1 # (ここはa0==0のとき実行される) v0(戻り値)に0を入れる
    j       L1           # $L1にジャンプ
# fibの再帰部分
L2:
    lw      $a0, 0($fp)   # 退避しておいたnを$a0に入れる
    addiu   $a0, $a0, -1   # $a0 <- $a0 - 1
    jal     fib           # fib(n-1)の再帰呼出し
    sw      $v0, 4($fp)   # fib(n-1)の戻り値を退避
    lw      $a0, 0($fp)   # 退避しておいたnを$a0に入れる
    addiu   $a0, $a0, -2   # $a0-2を求める
    jal     fib           # fib(n-2)の再帰呼出し
    lw      $v1, 4($fp)   # v1に退避しておいたfib(n-1)の値を入れる
    addu    $v0, $v0, $v1 # v0(fib(n-2)の戻り値)にfib(n-1)の値を足す
# fib関数の終了処理
L1:
    lw      $ra, 20($sp)  # 退避したリターン・アドレスを復元
    lw      $fp, 16($sp)  # 退避したフレーム・ポインタを復元
    addiu   $sp, $sp, 32  # スタック領域を32 byte短くする
    jr      $ra           # 呼び出し元に戻る
