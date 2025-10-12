.data
# Test data
test1:     .word 15         # small value
test2:     .word 108        # medium value  
test3:     .word 1000000    # large value

# Test messages
test_start_msg:     .string "=== UF8 Automated Test ===\n\n"
test1_msg:          .string "Test 1 (small): "
test2_msg:          .string "Test 2 (medium): "
test3_msg:          .string "Test 3 (large): "
arrow_msg:          .string " -> Encoded: "
decode_result_msg:  .string ", Decoded: "
pass_msg:           .string " PASS\n"
fail_msg:           .string " FAIL\n"
separator:          .string "\n====================\n"
all_pass_msg:       .string "All tests passed.\n"
some_fail_msg:      .string "Some tests failed.\n"
newline:            .string "\n"

.text
.globl _start

_start:
    jal main
    li a7, 10
    ecall

print_string:
    li a7, 4              
    ecall
    jr ra

print_int:
    li a7, 1           
    ecall
    jr ra

print_char:
    li a7, 11         
    ecall
    jr ra

# clz function (count leading zeros)
clz:
    li t0, 32             # n = 32
    li t1, 16             # c = 16
clz_loop:
    srl t2, a0, t1        # y = x >> c
    beqz t2, clz_skip     # if (y == 0) skip
    sub t0, t0, t1        # n -= c
    mv a0, t2             # x = y
clz_skip:
    srli t1, t1, 1        # c >>= 1
    bnez t1, clz_loop     # while (c != 0)
    sub a0, t0, a0        # return n - x
    jr ra

# UF8 decoding function
uf8_decode:
    andi t0, a0, 0x0F     # mantissa = fl & 0x0F
    srli t1, a0, 4        # exponent = fl >> 4
    
    # offset = (0x7FFF >> (15 - exponent)) << 4
    li t2, 0x7FFF
    li t3, 15
    sub t3, t3, t1        # 15 - exponent
    srl t2, t2, t3        # 0x7FFF >> (15 - exponent)
    slli t2, t2, 4        # << 4
    
    sll t0, t0, t1        # mantissa << exponent
    add a0, t0, t2        # return value
    jr ra

# UF8 encoding function
uf8_encode:
    # Special case: value < 16
    li t0, 16
    blt a0, t0, encode_small
    
    addi sp, sp, -20
    sw ra, 16(sp)
    sw s0, 12(sp)         # value
    sw s1, 8(sp)          # exponent
    sw s2, 4(sp)          # overflow
    sw s3, 0(sp)          # temporary variable
    
    mv s0, a0             # s0 = value
    li s1, 0              # exponent = 0
    li s2, 0              # overflow = 0
    
    # Estimate using CLZ
    mv a0, s0
    jal clz
    li t0, 31
    sub t0, t0, a0        # msb = 31 - clz(value)
    
    # If msb >= 5, estimate exponent
    li t1, 5
    blt t0, t1, upscan_init
    
    # Estimate exponent = msb - 4
    addi s1, t0, -4       # exponent = msb - 4
    li t1, 15
    ble s1, t1, calc_overflow
    li s1, 15             # clamp to max = 15
    
calc_overflow:
    # overflow = 16 * (2^exponent - 1)
    beqz s1, upscan_init  # if exponent == 0 → overflow = 0
    
    li t2, 0              # loop counter
    li s2, 0              # overflow = 0
build_loop:
    slli s2, s2, 1        # overflow << 1
    addi s2, s2, 16       # overflow + 16
    addi t2, t2, 1
    blt t2, s1, build_loop
    
    j check_adjust

check_adjust:
    beqz s1, upscan_init  # if exponent == 0 → skip
    
    # If value < overflow, adjust downward
    bgeu s0, s2, upscan_init
    
    addi s2, s2, -16      # overflow - 16
    srli s2, s2, 1        # (overflow - 16) >> 1
    addi s1, s1, -1       # exponent--
    
    j upscan_init          # continue (only adjust once)

upscan_init:
    # Start upward adjustment
    li s3, 15             # max_exponent = 15

upscan_loop:
    bge s1, s3, upscan_done
    
    # next_overflow = (overflow << 1) + 16
    slli t0, s2, 1
    addi t0, t0, 16
    
    # Stop if value < next_overflow
    blt s0, t0, upscan_done
    
    # Move to next range
    mv s2, t0             # overflow = next_overflow
    addi s1, s1, 1        # exponent++
    j upscan_loop

upscan_done:
    # mantissa = (value - overflow) >> exponent
    sub t0, s0, s2
    srl t0, t0, s1
    
    # Limit mantissa to 15
    li t1, 15
    ble t0, t1, encode_pack
    li t0, 15

encode_pack:
    # Combine: (exponent << 4) | mantissa
    slli s1, s1, 4
    or a0, s1, t0
    
    lw ra, 16(sp)
    lw s0, 12(sp)
    lw s1, 8(sp)
    lw s2, 4(sp)
    lw s3, 0(sp)
    addi sp, sp, 20
    jr ra

encode_small:
    # For value < 16, return directly
    jr ra

# Automated test function – test one value (returns 0=pass, 1=fail)
test_single_value:
    # a0 = test value
    addi sp, sp, -16
    sw ra, 12(sp)
    sw s0, 8(sp)          # original value
    sw s1, 4(sp)          # encoded
    sw s2, 0(sp)          # decoded
    
    mv s0, a0             # save original
    
    # Show test info
    mv a0, s0
    jal print_int
    la a0, arrow_msg
    jal print_string
    
    # Encode
    mv a0, s0
    jal uf8_encode
    mv s1, a0             # save encoded result
    
    # Print encoded value
    mv a0, s1
    jal print_int
    
    # Decode
    mv a0, s1
    jal uf8_decode
    mv s2, a0             # save decoded result
    
    # Print decoded result
    la a0, decode_result_msg
    jal print_string
    mv a0, s2
    jal print_int
    
    # Check decoded == original
    bne s2, s0, test_fail
    
    # Pass
    la a0, pass_msg
    jal print_string
    li a0, 0
    j test_done

test_fail:
    # Fail
    la a0, fail_msg
    jal print_string
    li a0, 1

test_done:
    lw ra, 12(sp)
    lw s0, 8(sp)
    lw s1, 4(sp)
    lw s2, 0(sp)
    addi sp, sp, 16
    jr ra

# Main – automated tests for three values
main:
    addi sp, sp, -8
    sw ra, 4(sp)
    sw s0, 0(sp)          # test summary (0 = all passed)
    
    li s0, 0              # assume all pass
    
    la a0, test_start_msg
    jal print_string
    
    # Test 1: small value
    la a0, test1_msg
    jal print_string
    lw a0, test1
    jal test_single_value
    or s0, s0, a0         # merge result
    
    # Test 2: medium value
    la a0, test2_msg
    jal print_string
    lw a0, test2
    jal test_single_value
    or s0, s0, a0
    
    # Test 3: large value
    la a0, test3_msg
    jal print_string
    lw a0, test3
    jal test_single_value
    or s0, s0, a0
    
    # Print summary
    la a0, separator
    jal print_string
    
    bnez s0, tests_failed
    
    # All passed
    la a0, all_pass_msg
    jal print_string
    j main_done

tests_failed:
    # Some tests failed
    la a0, some_fail_msg
    jal print_string

main_done:
    lw ra, 4(sp)
    lw s0, 0(sp)
    addi sp, sp, 8
    jr ra
