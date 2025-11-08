    .section .text
    .globl qz3_C_main
    .globl fast_rsqrt
    .globl fast_distance_3d

// clz
clz:
    beqz a0, 1f
    li   t0, 0                  /* n = 0 */
    li   t1, 0x80000000         /* mask = 1<<31 */
0:  and  t2, a0, t1
    bnez t2, 2f                 /* while ((x & 0x8000_0000)==0) break when set */
    addi t0, t0, 1              /* n++ */
    slli a0, a0, 1              /* x <<= 1 */
    j    0b
2:  mv   a0, t0
    ret
1:  li   a0, 32
    ret


.macro MUL16 dest, areg, breg, tmp
    /* tmp holds running a, t3 is loop cnt, t4 scratch, t5 scratch */
    mv   \dest, x0
    mv   \tmp,  \areg
    li   t3, 16
1:
    andi t4, \breg, 1
    beqz t4, 2f
    add  \dest, \dest, \tmp
2:
    srli \breg, \breg, 1
    slli \tmp,  \tmp,  1
    addi t3, t3, -1
    bnez t3, 1b
.endm

mul_q16:
    srli t0, a0, 16                 /* a_hi */
    slli t1, a0, 16
    srli t1, t1, 16                 /* a_lo */

    /* b_hi / b_lo */
    srli t2, a1, 16                 /* b_hi */
    slli t3, a1, 16
    srli t3, t3, 16                 /* b_lo */

    /* hi  = a_hi*b_hi */
    MUL16 t4, t0, t2, t5

    /* mid = a_hi*b_lo + a_lo*b_hi */
    MUL16 s0, t0, t3, t5
    MUL16 s1, t1, t2, t5
    add  s0, s0, s1                 /* mid */

    /* lo  = a_lo*b_lo */
    MUL16 s2, t1, t3, t5

    /* result = (hi<<16) + mid + (lo>>16) */
    slli t4, t4, 16
    srli s2, s2, 16
    add  t4, t4, s0
    add  a0, t4, s2
    ret

/* ============================================================
 // newton_step(y,x): y = y*(1.5 - 0.5*x*y^2)  (Q16)
 
newton_step:
    addi sp, sp, -16
    sw   a0, 0(sp)          /* y */
    sw   a1, 4(sp)          /* x */

    /* y2 = mul_q16(y,y) */
    mv   a1, a0
    jal  mul_q16
    mv   t0, a0             /* y2 */

    /* xy2 = mul_q16(x, y2) */
    lw   a0, 4(sp)
    mv   a1, t0
    jal  mul_q16
    mv   t1, a0             /* xy2 */

    /* half_xy2 = xy2 >> 1 */
    srli t1, t1, 1

    /* term = 1.5(Q16) = 3<<15 = 0x00018000 */
    li   t2, 0x00018000
    sub  t3, t2, t1         /* diff = term - half_xy2 */
    bltz t3, 0f
    mv   s0, t3
    j    1f
0:  mv   s0, x0
1:
    /* y * diff */
    lw   a0, 0(sp)
    mv   a1, s0
    jal  mul_q16

    addi sp, sp, 16
    ret


    .section .rodata
rsqrt_table:
    .word 65536,46341,32768,23170,16384,11585,8192,5793
    .word 4096,2896,2048,1448,1024,724,512,362
    .word 256,181,128,90,64,45,32,23
    .word 16,11,8,6,4,3,2,1

    .section .text


fast_rsqrt:
    beqz a0, 9f

    /* exp = 31 - clz(x) */
    addi sp, sp, -16
    sw   a0, 0(sp)                /* save x */
    jal  clz
    li   t0, 31
    sub  s0, t0, a0               /* s0 = exp */

    /* y = table[exp] */
    la   t1, rsqrt_table
    slli t2, s0, 2
    add  t1, t1, t2
    lw   s1, 0(t1)                /* y */

    /* y_next = table[exp+1] */
    addi t2, t2, 4
    la   t3, rsqrt_table
    add  t3, t3, t2
    lw   s2, 0(t3)
    sub  s3, s1, s2               /* delta = y - y_next */

    /* base = 1<<exp */
    li   t4, 1
    sll  t4, t4, s0               /* base */
    lw   t5, 0(sp)                /* x */
    sub  s4, t5, t4               /* diff = x - base */

    /* frac = (((x - 2^exp) << 16) >> exp) */
    li   t6, 16
    /* if (exp <= 16) frac = diff << (16-exp); else frac = diff >> (exp-16) */
    slt  t0, s0, t6               /* t0 = exp < 16 ?1:0 */
    beqz t0, 3f                   /* if not (exp<16) -> exp>=16 */
    /* exp < 16 */
    sub  t1, t6, s0               /* 16-exp */
    sll  s5, s4, t1               /* frac */
    j    4f
3:  beq  s0, t6, 5f               /* exp == 16 ? */
    sub  t1, s0, t6               /* exp-16 */
    srl  s5, s4, t1               /* frac */
    j    4f
5:  mv   s5, s4                   /* exp==16: frac=diff */
4:
    /* y -= (delta * frac) >> 16 */
    mv   a0, s3
    mv   a1, s5
    jal  mul_q16
    sub  s1, s1, a0               /* y -= correction */

    /* Newton two steps */
    mv   a0, s1
    mv   a1, t5                   /* x */
    jal  newton_step
    mv   s1, a0

    mv   a0, s1
    mv   a1, t5
    jal  newton_step
    mv   a0, a0

    addi sp, sp, 16
    ret

9:  li   a0, -1
    ret

// fast_distance_3d(dx,dy,dz) ≈ sqrt(dx^2+dy^2+dz^2)

fast_distance_3d:
    addi sp, sp, -16
    sw   a0, 0(sp)
    sw   a1, 4(sp)
    sw   a2, 8(sp)

    // d1 = dx*dx 
    lw   a0, 0(sp)
    mv   a1, a0
    jal  mul_q16
    mv   s0, a0

    /* d2 */
    lw   a0, 4(sp)
    mv   a1, a0
    jal  mul_q16
    mv   s1, a0

    /* d3 */
    lw   a0, 8(sp)
    mv   a1, a0
    jal  mul_q16
    mv   s2, a0

    add  s3, s0, s1
    add  s3, s3, s2                /* dist_sq (Q16-ish) */

    beqz s3, 0f
    mv   a0, s3
    jal  fast_rsqrt                /* inv = 1/sqrt(dist_sq) (Q16) */
    mv   s4, a0
    /* dist ≈ dist_sq * inv >> 16 */
    mv   a0, s3
    mv   a1, s4
    jal  mul_q16
    addi sp, sp, 16
    ret
0:
    mv   a0, x0
    addi sp, sp, 16
    ret

/* ============================================================
 * check_result
 * ============================================================ */
    .extern printf
    .extern print_int

check_result:
    addi sp, sp, -16
    sw   a1, 0(sp)
    sw   a2, 4(sp)

    la   a0, str_got
    jal  printf
    la   a0, str_expect
    jal  printf

    lw   a0, 4(sp)                /* expect */
    jal  print_int

    lw   t0, 0(sp)                /* got */
    lw   t1, 4(sp)                /* expect */
    addi t2, t1, -2
    addi t3, t1,  2
    blt  t0, t2, 1f
    bgt  t0, t3, 1f
    la   a0, str_wrong
    jal  printf
    j    2f
1:  la   a0, str_correct
    jal  printf
2:  addi sp, sp, 16
    ret

/* ============================================================
 * qz3_C_main
 * ============================================================ */
qz3_C_main:
    la a0, str_rsqrt
    jal printf

    li a0, 1
    jal fast_rsqrt
    li a2, 65536
    mv a1, a0
    la a0, str_rs1
    jal check_result

    li a0, 16
    jal fast_rsqrt
    li a2, 16384
    mv a1, a0
    la a0, str_rs16
    jal check_result

    li a0, 1024
    jal fast_rsqrt
    li a2, 2048
    mv a1, a0
    la a0, str_rs1024
    jal check_result

    la a0, str_dist
    jal printf

    li a0, 3
    li a1, 4
    li a2, 0
    jal fast_distance_3d
    li a2, 5
    mv a1, a0
    la a0, str_d340
    jal check_result

    li a0, 10
    li a1, 0
    li a2, 0
    jal fast_distance_3d
    li a2, 10
    mv a1, a0
    la a0, str_d100
    jal check_result

    li a0, 10
    li a1, 10
    li a2, 10
    jal fast_distance_3d
    li a2, 17
    mv a1, a0
    la a0, str_d101010
    jal check_result

    la a0, str_done
    jal printf
    ret

/* ============================================================
 * String literals
 * ============================================================ */
    .section .rodata
str_got:       .asciz " got ~ "
str_expect:    .asciz " expect="
str_wrong:     .asciz " wrong \n"
str_correct:   .asciz " correct \n"
str_rsqrt:     .asciz "--- Test fast_rsqrt(x) ---\n"
str_rs1:       .asciz "rsqrt(1)"
str_rs16:      .asciz "rsqrt(16)"
str_rs1024:    .asciz "rsqrt(1024)"
str_dist:      .asciz "\n--- Test fast_distance_3d() ---\n"
str_d340:      .asciz "dist(3,4,0)"
str_d100:      .asciz "dist(10,0,0)"
str_d101010:   .asciz "dist(10,10,10)"
str_done:      .asciz "\n=== All tests passed ===\n"
