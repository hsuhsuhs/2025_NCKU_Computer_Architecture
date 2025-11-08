.text
  
    .extern print_hanoi_move  

    .globl  qz2_A_main
qz2_A_main:
    # --- Function Prologue ---
    addi    sp, sp, -64
    sw      ra, 60(sp)
    sw      s0, 56(sp)      # s0 (i)
    sw      s1, 52(sp)      # s1 (disk_num)
    sw      s2, 48(sp)      # s2 (from_peg)
    sw      s3, 44(sp)      # s3 (to_peg)
    sw      s4, 40(sp)      # s4 (obdata_base)
    sw      s5, 36(sp)      # s5 = pos[0]
    sw      s6, 32(sp)      # s6 = pos[1]
    sw      s7, 28(sp)      # s7 = pos[2]
    sw      s8, 24(sp)      # s8 = from_char (decoded)
    sw      s9, 20(sp)      # s9 = to_char (decoded)

    # Initialize pos[] array in registers
    mv      s5, x0
    mv      s6, x0
    mv      s7, x0

    addi    s0, x0, 1
game_loop:
    #  Gray code
    li      x5, 8
    beq     s0, x5, finish_game
    srli    x5, s0, 1
    xor     x6, s0, x5
    addi    x7, s0, -1
    srli    x28, x7, 1
    xor     x7, x7, x28
    xor     x5, x6, x7
    addi    s1, x0, 0
    andi    x6, x5, 1
    bne     x6, x0, disk_found
    addi    s1, x0, 1
    andi    x6, x5, 2
    bne     x6, x0, disk_found
    addi    s1, x0, 2
disk_found:
    andi    x30, x5, 5
    li      x31, 5
    beq     x30, x31, continue_move
continue_move:

    # (Get 'from_peg' (s2) ...
    beq     s1, x0, get_pos0
    li      x5, 1
    beq     s1, x5, get_pos1
    mv      s2, s7
    j       after_get_pos
get_pos0:
    mv      s2, s5
    j       after_get_pos
get_pos1:
    mv      s2, s6
after_get_pos:

    bne     s1, x0, handle_large
    addi    s3, s2, 2
    li      x6, 3
    blt     s3, x6, display_move
    sub     s3, s3, x6
    j       display_move
handle_large:
    mv      x6, s5
    li      x19, 3
    sub     s3, x19, s2
    sub     s3, s3, x6
    li      x7, 3
check_modulo:
    blt     s3, x0, add_three
    bge     s3, x7, sub_three
    j       display_move
add_three:
    addi    s3, s3, 3
    j       check_modulo
sub_three:
    sub     s3, s3, x7
    j       check_modulo

display_move:
    # --- Decode Chars (沒變) ---
    la      s4, obdata
    add     x5, s4, s2
    lbu     s8, 0(x5)       # s8 = from_char (obfuscated)
    li      x6, 0x6F
    xor     s8, s8, x6
    addi    s8, s8, -0x12   # s8 = from_char (decoded)

    add     x7, s4, s3
    lbu     s9, 0(x7)       # s9 = to_char (obfuscated)
    xor     s9, s9, x6
    addi    s9, s9, -0x12   # s9 = to_char (decoded)

    # --- [NEW] 最佳化的 print ---
    # 我們只呼叫 1 次！
    
    addi    a0, s1, 1       # a0 = disk + 1
    mv      a1, s8          # a1 = from_char
    mv      a2, s9          # a2 = to_char
    jal     ra, print_hanoi_move # JAL 
    
    # --- [End of print logic] ---

    # (Update pos[disk] ... 
    beq     s1, x0, set_pos0
    li      x5, 1
    beq     s1, x5, set_pos1
    mv      s7, s3
    j       after_set_pos
set_pos0:
    mv      s5, s3
    j       after_set_pos
set_pos1:
    mv      s6, s3
after_set_pos:

    addi    s0, s0, 1
    jal     x0, game_loop

finish_game:
    # --- Function Epilogue ---
    lw      ra, 60(sp)
    lw      s0, 56(sp)
    lw      s1, 52(sp)
    lw      s2, 48(sp)
    lw      s3, 44(sp)
    lw      s4, 40(sp)
    lw      s5, 36(sp)
    lw      s6, 32(sp)
    lw      s7, 28(sp)
    lw      s8, 24(sp)
    lw      s9, 20(sp)
    addi    sp, sp, 64
    ret # Return to C caller (main.c)

    .data
obdata:
    .byte   0x3c, 0x3b, 0x3a  # 'A', 'B', 'C' obfuscated