main:
    addiu   $fp, $zero, 252 # フレームポインタの初期値
    addiu   $sp, $zero, 248 #スタックポインタの初期値
    addiu   $sp, $sp, -32   # スタック領域を下に32 byte伸ばす
    sw      $ra, 20($sp)    # リターン・アドレスを退避
    sw      $fp, 16($sp)    # フレーム・ポインタを退避
    addiu   $fp, $sp, 28    # 新しいフレーム・ポインタを設定
    addiu   $s0, $zero, 0   # ループ変数
    addiu   $s1, $zero, 8   # ループ回数
    addiu   $s2, $zero, 2   # 比較用定数
loop:
    beq     $s0, $s1, end   # ループ終了判定
    addu    $a0, $s0, $zero # fibの引数に$s0を設定
    jal     fib             # fibを呼び出す
    sw      $v0, 0($zero)   # fibの結果をstdoutに出力(MMIO)
    addiu   $s0, $s0, 1     # ループ変数の更新
    j       loop
end:
    lw      $ra, 20($sp)    # 退避したリターン・アドレスを復元
    lw      $fp, 16($sp)    # 退避したフレーム・ポインタを復元
    addiu   $sp, $sp, 32    # スタック領域を32 byte短くする
inf:
    j       inf             # 無限ループ
# fib関数
fib:
    addiu   $sp, $sp, -32   # スタック領域を下に32 byte伸ばす
    sw      $ra, 20($sp)    # リターン・アドレスを退避
    sw      $fp, 16($sp)    # フレーム・ポインタを退避
    addiu   $fp, $sp, 28    # 新しいフレームポインタを設定
    sw      $a0, 0($fp)     # a0 (引数)を退避
    slt     $t0, $a0, $s2   # (次の行と合わせて) a0<2ならば$L2にジャンプ
    beq     $t0, $zero, L2      
    addiu   $v0, $zero, 1   # (ここはa0==0のとき実行される) v0(戻り値)に0を入れる
    j       L1              
# fibの再帰部分
L2:
    lw      $a0, 0($fp)     # 退避しておいたnを$a0に入れる
    addiu   $a0, $a0, -1    # $a0 <- $a0 - 1
    jal     fib             # fib(n-1)の再帰呼出し
    sw      $v0, 4($fp)     # fib(n-1)の戻り値を退避
    lw      $a0, 0($fp)     # 退避しておいたnを$a0に入れる
    addiu   $a0, $a0, -2    # $a0-2を求める
    jal     fib             # fib(n-2)の再帰呼出し
    lw      $v1, 4($fp)     # v1に退避しておいたfib(n-1)の値を入れる
    addu    $v0, $v0, $v1   # v0(fib(n-2)の戻り値)にfib(n-1)の値を足す
# fib関数の終了処理
L1:
    lw      $ra, 20($sp)    # 退避したリターン・アドレスを復元
    lw      $fp, 16($sp)    # 退避したフレーム・ポインタを復元
    addiu   $sp, $sp, 32    # スタック領域を32 byte短くする
    jr      $ra             # 呼び出し元に戻る
