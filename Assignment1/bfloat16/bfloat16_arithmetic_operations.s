.data
# Addition test cases
add_a1:    .word 0x00003F80  # 1.0 in bfloat16
add_b1:    .word 0x00004000  # 2.0 in bfloat16  
add_exp1:  .word 0x00004040  # 3.0 expected (1.0 + 2.0)

add_a2:    .word 0x00003FC0  # 1.5 in bfloat16
add_b2:    .word 0x00003FC0  # 1.5 in bfloat16
add_exp2:  .word 0x00004040  # 3.0 expected (1.5 + 1.5)

add_a3:    .word 0x00003F00  # 0.5 in bfloat16
add_b3:    .word 0x00003F00  # 0.5 in bfloat16
add_exp3:  .word 0x00003F80  # 1.0 expected (0.5 + 0.5)

# Subtraction test cases  
sub_a1:    .word 0x00004040  # 3.0 in bfloat16
sub_b1:    .word 0x00004000  # 2.0 in bfloat16
sub_exp1:  .word 0x00003F80  # 1.0 expected (3.0 - 2.0)

sub_a2:    .word 0x00004000  # 2.0 in bfloat16
sub_b2:    .word 0x00003F80  # 1.0 in bfloat16
sub_exp2:  .word 0x00003F80  # 1.0 expected (2.0 - 1.0)

sub_a3:    .word 0x00004040  # 3.0 in bfloat16
sub_b3:    .word 0x00003FC0  # 1.5 in bfloat16
sub_exp3:  .word 0x00003FC0  # 1.5 expected (3.0 - 1.5)

# Multiplication test cases
mul_a1:    .word 0x00004040  # 3.0 in bfloat16
mul_b1:    .word 0x00004080  # 4.0 in bfloat16
mul_exp1:  .word 0x00004180  # 12.0 expected (3.0 * 4.0)

mul_a2:    .word 0x00004000  # 2.0 in bfloat16
mul_b2:    .word 0x00004020  # 2.5 in bfloat16
mul_exp2:  .word 0x00004140  # 5.0 expected (2.0 * 2.5)

mul_a3:    .word 0x00003FC0  # 1.5 in bfloat16
mul_b3:    .word 0x00004000  # 2.0 in bfloat16
mul_exp3:  .word 0x00004040  # 3.0 expected (1.5 * 2.0)

# Division test cases
div_a1:    .word 0x00004140  # 5.0 in bfloat16
div_b1:    .word 0x00004000  # 2.0 in bfloat16
div_exp1:  .word 0x000040A0  # 2.5 expected (5.0 / 2.0)

div_a2:    .word 0x00004180  # 6.0 in bfloat16
div_b2:    .word 0x00004000  # 2.0 in bfloat16
div_exp2:  .word 0x00004040  # 3.0 expected (6.0 / 2.0)

div_a3:    .word 0x00004040  # 3.0 in bfloat16
div_b3:    .word 0x00004000  # 2.0 in bfloat16
div_exp3:  .word 0x00003FC0  # 1.5 expected (3.0 / 2.0)

# Special values for testing edge cases
test_nan:  .word 0x00007FC0  # NaN value
test_inf:  .word 0x00007F80  # Positive infinity
test_zero: .word 0x00000000  # Zero value

# Result storage for test verification
result:    .word 0x00000000

# tests message ---------------------------------------------
test_start:    .string "bfloat16 Complete Test Suite\n\n"
add_header:    .string "=== Addition Tests ===\n"
sub_header:    .string "\n=== Subtraction Tests ===\n"
mul_header:    .string "\n=== Multiplication Tests ===\n"
div_header:    .string "\n=== Division Tests ===\n"
special_header:.string "\n=== Special Values Tests ===\n"

# Addition test descriptions
add_test1: .string "1.0 + 2.0 = 3.0: "
add_test2: .string "1.5 + 1.5 = 3.0: "
add_test3: .string "0.5 + 0.5 = 1.0: "

# Subtraction test descriptions
sub_test1: .string "3.0 - 2.0 = 1.0: "
sub_test2: .string "2.0 - 1.0 = 1.0: "
sub_test3: .string "3.0 - 1.5 = 1.5: "

# Multiplication test descriptions
mul_test1: .string "3.0 * 4.0 = 12.0: "
mul_test2: .string "2.0 * 2.5 = 5.0: "
mul_test3: .string "1.5 * 2.0 = 3.0: "

# Division test descriptions
div_test1: .string "5.0 / 2.0 = 2.5: "
div_test2: .string "6.0 / 2.0 = 3.0: "
div_test3: .string "3.0 / 2.0 = 1.5: "

# Special values test description
special_test: .string "Special values (NaN, Inf, Zero): "

# Test result messages
pass_msg: .string "PASS\n"
fail_msg: .string "FAIL\n"

# Summary and statistics messages
summary:      .string "\n=== Test Summary ===\n"
total_tests:  .string "Total tests: "
passed_tests: .string "Passed: "
failed_tests: .string "Failed: "
all_pass:     .string "\nAll tests passed!\n"
some_fail:    .string "\nSome tests failed.\n"
newline:      .string "\n"

.text
.globl _start

# ==================== main tests ====================
_start:
    la   a0, test_start        # Print test suite header
    addi a7, zero, 4
    ecall
    
    addi s0, zero, 0           # s0 = pass counter
    addi s1, zero, 0           # s1 = total test counter
    
    # ==================== addition tests ====================
    la   a0, add_header
    addi a7, zero, 4
    ecall
    
    # Test 1.1: 1.0 + 2.0 = 3.0
    la   a0, add_test1
    addi a7, zero, 4
    ecall
    
    la   t0, add_a1            # Load test values and perform addition
    lw   a0, 0(t0)
    la   t0, add_b1
    lw   a1, 0(t0)
    jal  bf16_add
    
    la   t0, result            # Store and verify result
    sw   a0, 0(t0)
    la   t0, add_exp1
    lw   a1, 0(t0)
    jal  bf16_eq
    
    jal  check_test_result     # Check and display result
    
    # Test 1.2: 1.5 + 1.5 = 3.0
    la   a0, add_test2
    addi a7, zero, 4
    ecall
    
    la   t0, add_a2
    lw   a0, 0(t0)
    la   t0, add_b2
    lw   a1, 0(t0)
    jal  bf16_add
    
    la   t0, result
    sw   a0, 0(t0)
    la   t0, add_exp2
    lw   a1, 0(t0)
    jal  bf16_eq
    
    jal  check_test_result
    
    # Test 1.3: 0.5 + 0.5 = 1.0
    la   a0, add_test3
    addi a7, zero, 4
    ecall
    
    la   t0, add_a3
    lw   a0, 0(t0)
    la   t0, add_b3
    lw   a1, 0(t0)
    jal  bf16_add
    
    la   t0, result
    sw   a0, 0(t0)
    la   t0, add_exp3
    lw   a1, 0(t0)
    jal  bf16_eq
    
    jal  check_test_result
    
    # ==================== subtraction tests ====================
    la   a0, sub_header
    addi a7, zero, 4
    ecall
    
    # Test 2.1: 3.0 - 2.0 = 1.0
    la   a0, sub_test1
    addi a7, zero, 4
    ecall
    
    la   t0, sub_a1
    lw   a0, 0(t0)
    la   t0, sub_b1
    lw   a1, 0(t0)
    jal  bf16_sub
    
    la   t0, result
    sw   a0, 0(t0)
    la   t0, sub_exp1
    lw   a1, 0(t0)
    jal  bf16_eq
    
    jal  check_test_result
    
    # Test 2.2: 2.0 - 1.0 = 1.0
    la   a0, sub_test2
    addi a7, zero, 4
    ecall
    
    la   t0, sub_a2
    lw   a0, 0(t0)
    la   t0, sub_b2
    lw   a1, 0(t0)
    jal  bf16_sub
    
    la   t0, result
    sw   a0, 0(t0)
    la   t0, sub_exp2
    lw   a1, 0(t0)
    jal  bf16_eq
    
    jal  check_test_result
    
    # Test 2.3: 3.0 - 1.5 = 1.5
    la   a0, sub_test3
    addi a7, zero, 4
    ecall
    
    la   t0, sub_a3
    lw   a0, 0(t0)
    la   t0, sub_b3
    lw   a1, 0(t0)
    jal  bf16_sub
    
    la   t0, result
    sw   a0, 0(t0)
    la   t0, sub_exp3
    lw   a1, 0(t0)
    jal  bf16_eq
    
    jal  check_test_result
    
    # ==================== multiplication tests ====================
    la   a0, mul_header
    addi a7, zero, 4
    ecall
    
    # Test 3.1: 3.0 * 4.0 = 12.0
    la   a0, mul_test1
    addi a7, zero, 4
    ecall
    
    la   t0, mul_a1
    lw   a0, 0(t0)
    la   t0, mul_b1
    lw   a1, 0(t0)
    jal  bf16_mul
    
    la   t0, result
    sw   a0, 0(t0)
    la   t0, mul_exp1
    lw   a1, 0(t0)
    jal  bf16_eq
    
    jal  check_test_result
    
    # Test 3.2: 2.0 * 2.5 = 5.0
    la   a0, mul_test2
    addi a7, zero, 4
    ecall
    
    la   t0, mul_a2
    lw   a0, 0(t0)
    la   t0, mul_b2
    lw   a1, 0(t0)
    jal  bf16_mul
    
    la   t0, result
    sw   a0, 0(t0)
    la   t0, mul_exp2
    lw   a1, 0(t0)
    jal  bf16_eq
    
    jal  check_test_result
    
    # Test 3.3: 1.5 * 2.0 = 3.0
    la   a0, mul_test3
    addi a7, zero, 4
    ecall
    
    la   t0, mul_a3
    lw   a0, 0(t0)
    la   t0, mul_b3
    lw   a1, 0(t0)
    jal  bf16_mul
    
    la   t0, result
    sw   a0, 0(t0)
    la   t0, mul_exp3
    lw   a1, 0(t0)
    jal  bf16_eq
    
    jal  check_test_result
    
    # ==================== division tests ====================
    la   a0, div_header
    addi a7, zero, 4
    ecall
    
    # Test 4.1: 5.0 / 2.0 = 2.5
    la   a0, div_test1
    addi a7, zero, 4
    ecall
    
    la   t0, div_a1
    lw   a0, 0(t0)
    la   t0, div_b1
    lw   a1, 0(t0)
    jal  bf16_div
    
    la   t0, result
    sw   a0, 0(t0)
    la   t0, div_exp1
    lw   a1, 0(t0)
    jal  bf16_eq
    
    jal  check_test_result
    
    # Test 4.2: 6.0 / 2.0 = 3.0
    la   a0, div_test2
    addi a7, zero, 4
    ecall
    
    la   t0, div_a2
    lw   a0, 0(t0)
    la   t0, div_b2
    lw   a1, 0(t0)
    jal  bf16_div
    
    la   t0, result
    sw   a0, 0(t0)
    la   t0, div_exp2
    lw   a1, 0(t0)
    jal  bf16_eq
    
    jal  check_test_result
    
    # Test 4.3: 3.0 / 2.0 = 1.5
    la   a0, div_test3
    addi a7, zero, 4
    ecall
    
    la   t0, div_a3
    lw   a0, 0(t0)
    la   t0, div_b3
    lw   a1, 0(t0)
    jal  bf16_div
    
    la   t0, result
    sw   a0, 0(t0)
    la   t0, div_exp3
    lw   a1, 0(t0)
    jal  bf16_eq
    
    jal  check_test_result
    
    # ==================== special value test ====================
    la   a0, special_header
    addi a7, zero, 4
    ecall
    
    la   a0, special_test
    addi a7, zero, 4
    ecall
    
    # Test NaN detection
    la   t0, test_nan
    lw   a0, 0(t0)
    jal  bf16_isnan
    beq  a0, zero, special_fail
    
    # Test Infinity detection
    la   t0, test_inf
    lw   a0, 0(t0)
    jal  bf16_isinf
    beq  a0, zero, special_fail
    
    # Test zero detection
    la   t0, test_zero
    lw   a0, 0(t0)
    jal  bf16_iszero
    beq  a0, zero, special_fail
    
    # All special value tests passed
    addi s0, s0, 1
    addi s1, s1, 1
    la   a0, pass_msg
    addi a7, zero, 4
    ecall
    j    print_summary

special_fail:
    # Special value test failed
    addi s1, s1, 1
    la   a0, fail_msg
    addi a7, zero, 4
    ecall

# ==================== test summary ====================
print_summary:
    la   a0, summary           # Print test summary header
    addi a7, zero, 4
    ecall
    
    sub  s2, s1, s0            # s2 = failed tests = total - passed
    
    # Print total tests count
    la   a0, total_tests
    addi a7, zero, 4
    ecall
    add  a0, zero, s1
    addi a7, zero, 1
    ecall
    la   a0, newline
    addi a7, zero, 4
    ecall
    
    # Print passed tests count
    la   a0, passed_tests
    addi a7, zero, 4
    ecall
    add  a0, zero, s0
    addi a7, zero, 1
    ecall
    la   a0, newline
    addi a7, zero, 4
    ecall
    
    # Print failed tests count
    la   a0, failed_tests
    addi a7, zero, 4
    ecall
    add  a0, zero, s2
    addi a7, zero, 1
    ecall
    la   a0, newline
    addi a7, zero, 4
    ecall
    
    # Print final result message
    beq  s2, zero, all_passed_msg
    la   a0, some_fail
    j    exit

all_passed_msg:
    la   a0, all_pass

exit:
    addi a7, zero, 4
    ecall
    addi a7, zero, 10         # Exit system call
    ecall

# ==================== TEST RESULT CHECKER SUBROUTINE ====================
check_test_result:
    addi sp, sp, -4
    sw   ra, 0(sp)
    
    addi s1, s1, 1            # Increment total test counter
    
    beq  a0, zero, test_failed
    addi s0, s0, 1            # Increment pass counter
    la   a0, pass_msg
    j    test_end

test_failed:
    la   a0, fail_msg

test_end:
    addi a7, zero, 4
    ecall
    
    lw   ra, 0(sp)
    addi sp, sp, 4
    ret

# ==================== BF16 Subtraction Function ====================
# Implements: a - b = a + (-b)
# Input: a0 = bf16 a, a1 = bf16 b
# Output: a0 = a - b in bf16 format
bf16_sub:
    addi sp, sp, -8
    sw   ra, 0(sp)
    sw   s0, 4(sp)
    
    mv   s0, a1               # Save b
    
    # Flip the sign bit of b (b ^= BF16_SIGN_MASK)
    li   t0, 0x8000           # BF16_SIGN_MASK
    xor  a1, s0, t0           # b.bits ^= BF16_SIGN_MASK
    
    # Call bf16_add(a, -b)
    jal  bf16_add
    
    lw   ra, 0(sp)
    lw   s0, 4(sp)
    addi sp, sp, 8
    ret

# ==================== BF16 Addition Function ====================
bf16_add:
    addi sp, sp, -16
    sw   ra, 0(sp)
    sw   s0, 4(sp)
    sw   s1, 8(sp)
    sw   s2, 12(sp)
    
    add  s0, zero, a0          # Save input values
    add  s1, zero, a1
    
    # Extract sign, exponent, mantissa from a
    srli t0, s0, 15           # Extract sign bit (bit 15)
    andi t0, t0, 1            # Keep only the sign bit
    srli t1, s0, 7            # Extract exponent (bits 7-14)
    andi t1, t1, 255          # Keep only 8 exponent bits
    andi t2, s0, 127          # Extract mantissa (bits 0-6)
    
    # Extract sign, exponent, mantissa from b
    srli t3, s1, 15
    andi t3, t3, 1
    srli t4, s1, 7
    andi t4, t4, 255
    andi t5, s1, 127
    
    # Add implicit 1 to mantissas for normalized numbers
    beq  t1, zero, skip_impl_a
    ori  t2, t2, 128          # Add implicit 1 (bit 7)
skip_impl_a:
    beq  t4, zero, skip_impl_b
    ori  t5, t5, 128
skip_impl_b:
    
    # Align exponents by shifting smaller exponent's mantissa
    sub  t6, t1, t4           # Calculate exponent difference
    bge  t6, zero, a_greater_exp
    
    # b has larger exponent, shift a's mantissa
    sub  t6, t4, t1           # Get shift amount
    srl  t2, t2, t6           # Shift a's mantissa right
    add  t1, zero, t4         # Use b's exponent
    j    exponents_aligned
    
a_greater_exp:
    # a has larger exponent, shift b's mantissa
    srl  t5, t5, t6
    
exponents_aligned:
    # Perform addition or subtraction based on signs
    bne  t0, t3, subtract
    
    # Same sign - add mantissas
    add  t2, t2, t5
    add  s2, zero, t0          # Save result sign
    j    normalize
    
subtract:
    # Different signs - subtract smaller from larger
    bgeu t2, t5, a_greater_mant
    sub  t2, t5, t2           # b - a
    add  s2, zero, t3         # Use b's sign
    j    normalize
    
a_greater_mant:
    sub  t2, t2, t5           # a - b
    add  s2, zero, t0         # Use a's sign
    
normalize:
    beq  t2, zero, zero_result # Result is zero
    
    # Normalize mantissa to range [128, 255] (1.0 to 1.99)
    addi t3, zero, 1
    slli t3, t3, 8            # t3 = 256 (threshold)
    
normalize_loop:
    bgeu t2, t3, shift_right
    slli t2, t2, 1            # Shift left until normalized
    addi t1, t1, -1           # Decrement exponent
    bne  t1, zero, normalize_loop
    j    underflow            # Exponent underflow
    
shift_right:
    srli t2, t2, 1            # Shift right if mantissa too large
    addi t1, t1, 1            # Increment exponent
    bgeu t2, t3, shift_right
    
    addi t3, zero, 255        # Check for exponent overflow/underflow
    bge  t1, t3, overflow
    bne  t1, zero, pack_result
    
underflow:
    add  a0, zero, zero       # Exponent underflow - return zero
    j    done
    
overflow:
    # Exponent overflow - return infinity
    addi a0, zero, 127        # Construct 0x7F80 (+inf)
    slli a0, a0, 8
    ori  a0, a0, 128
    beq  s2, zero, done
    addi a0, zero, 255        # Construct 0xFF80 (-inf)
    slli a0, a0, 8
    ori  a0, a0, 128
    j    done
    
zero_result:
    add  a0, zero, zero
    j    done
    
pack_result:
    andi t2, t2, 127          # Remove implicit bit (keep bits 0-6)
    slli a0, s2, 15           # Set sign bit (bit 15)
    slli t1, t1, 7            # Shift exponent to bits 7-14
    or   a0, a0, t1           # Combine sign and exponent
    or   a0, a0, t2           # Combine with mantissa
    
done:
    lw   ra, 0(sp)
    lw   s0, 4(sp)
    lw   s1, 8(sp)
    lw   s2, 12(sp)
    addi sp, sp, 16
    ret

# ==================== BF16 Multiplication Function (Fixed) ==================== 
bf16_mul:
    addi sp, sp, -24
    sw ra, 0(sp)
    sw s0, 4(sp)
    sw s1, 8(sp)
    sw s2, 12(sp)
    sw s3, 16(sp)
    sw s4, 20(sp)
    
    mv s0, a0  # a
    mv s1, a1  # b
    
    # Extract sign bits
    srli s2, s0, 15
    andi s2, s2, 1    # sign_a
    srli t0, s1, 15
    andi t0, t0, 1    # sign_b
    xor s2, s2, t0    # result_sign = sign_a ^ sign_b
    
    # Extract exponents
    srli s3, s0, 7
    andi s3, s3, 0xFF # exp_a
    srli t0, s1, 7
    andi t0, t0, 0xFF # exp_b
    
    # Extract mantissas and add implicit bit
    andi s4, s0, 0x7F # mant_a
    andi t1, s1, 0x7F # mant_b
    
    # Check for special cases
    beq s3, zero, mul_zero_a
    li t2, 0xFF
    beq s3, t2, mul_inf_nan_a
    
mul_check_b:
    beq t0, zero, mul_zero_b
    li t2, 0xFF
    beq t0, t2, mul_inf_nan_b
    
    # Add implicit 1 to mantissas for normalized numbers
    ori s4, s4, 0x80
    ori t1, t1, 0x80
    
    # Multiply mantissas (16-bit result)
    mul t2, s4, t1        # mantissa product (16 bits)
    
    # Calculate result exponent
    add s3, s3, t0        # exp_a + exp_b
    addi s3, s3, -127     # subtract bias
    
    # Normalize mantissa
    li t3, 0x4000         # 0x4000 = 1<<14 (check if product >= 0x4000)
    bgeu t2, t3, mul_normalize_shift_right
    
    # Need to shift left
    slli t2, t2, 1
    addi s3, s3, -1
    j mul_check_exp
    
mul_normalize_shift_right:
    # Product is too large, shift right
    srli t2, t2, 7        # shift to get 7-bit mantissa
    andi t2, t2, 0x7F     # keep only 7 bits
    j mul_pack_result
    
mul_check_exp:
    # Check if we need to normalize more
    li t3, 0x4000
    bgeu t2, t3, mul_normalize_shift_right
    
    # Get final 7-bit mantissa
    srli t2, t2, 7
    andi t2, t2, 0x7F
    
mul_pack_result:
    # Check exponent bounds
    ble s3, zero, mul_underflow
    li t3, 0xFF
    bge s3, t3, mul_overflow
    
    # Pack result
    slli a0, s2, 15       # sign
    slli t3, s3, 7        # exponent
    or a0, a0, t3
    or a0, a0, t2         # mantissa
    j mul_done

mul_zero_a:
    # a is zero
    beq t0, zero, mul_zero_result    # 0 * 0 = 0
    li t2, 0xFF
    beq t0, t2, mul_nan_result       # 0 * inf = NaN
    j mul_zero_result

mul_zero_b:
    # b is zero
    li t2, 0xFF
    beq s3, t2, mul_nan_result       # inf * 0 = NaN
    j mul_zero_result

mul_inf_nan_a:
    # a is inf or NaN
    beq s4, zero, mul_a_inf          # a is infinity
    j mul_nan_result                 # a is NaN

mul_inf_nan_b:
    # b is inf or NaN
    beq t1, zero, mul_b_inf          # b is infinity
    j mul_nan_result                 # b is NaN

mul_a_inf:
    beq t0, zero, mul_nan_result     # inf * 0 = NaN
    j mul_inf_result

mul_b_inf:
    beq s3, zero, mul_nan_result     # 0 * inf = NaN
    j mul_inf_result

mul_zero_result:
    li a0, 0
    j mul_done

mul_inf_result:
    li a0, 0x7F80        # +inf
    beq s2, zero, mul_done
    li a0, 0xFF80        # -inf
    j mul_done

mul_nan_result:
    li a0, 0x7FC0        # NaN
    j mul_done

mul_underflow:
    li a0, 0             # flush to zero
    j mul_done

mul_overflow:
    li a0, 0x7F80        # +inf
    beq s2, zero, mul_done
    li a0, 0xFF80        # -inf

mul_done:
    lw ra, 0(sp)
    lw s0, 4(sp)
    lw s1, 8(sp)
    lw s2, 12(sp)
    lw s3, 16(sp)
    lw s4, 20(sp)
    addi sp, sp, 24
    ret

# ==================== BF16 Division Function (Fixed) ==================== 
bf16_div:
    addi sp, sp, -24
    sw ra, 0(sp)
    sw s0, 4(sp)
    sw s1, 8(sp)
    sw s2, 12(sp)
    sw s3, 16(sp)
    sw s4, 20(sp)
    
    mv s0, a0  # a (dividend)
    mv s1, a1  # b (divisor)
    
    # Extract sign bits
    srli s2, s0, 15
    andi s2, s2, 1    # sign_a
    srli t0, s1, 15
    andi t0, t0, 1    # sign_b
    xor s2, s2, t0    # result_sign = sign_a ^ sign_b
    
    # Extract exponents
    srli s3, s0, 7
    andi s3, s3, 0xFF # exp_a
    srli t0, s1, 7
    andi t0, t0, 0xFF # exp_b
    
    # Extract mantissas
    andi s4, s0, 0x7F # mant_a
    andi t1, s1, 0x7F # mant_b
    
    # Check for special cases
    # Division by zero
    beq t0, zero, div_by_zero_check
    
    # Check for NaN/infinity
    li t2, 0xFF
    beq s3, t2, div_inf_nan_a
    beq t0, t2, div_inf_nan_b
    
    # Check for zero dividend
    beq s3, zero, div_zero_dividend
    
    # Add implicit 1 to mantissas
    ori s4, s4, 0x80
    ori t1, t1, 0x80
    
    # Perform division using restoring division algorithm
    li t2, 0           # quotient
    li t3, 8           # counter
    mv t4, s4          # remainder (start with dividend mantissa)
    
div_loop:
    slli t2, t2, 1     # shift quotient left
    slli t4, t4, 1     # shift remainder left
    
    # Compare remainder with divisor
    bltu t4, t1, div_skip_sub
    sub t4, t4, t1     # subtract divisor
    ori t2, t2, 1      # set quotient bit
    
div_skip_sub:
    addi t3, t3, -1
    bnez t3, div_loop
    
    # t2 now contains the quotient mantissa (8 bits)
    
    # Calculate result exponent
    sub s3, s3, t0     # exp_a - exp_b
    addi s3, s3, 127   # add bias
    
    # Normalize quotient if needed
    andi t3, t2, 0x80  # check if implicit bit is set
    bnez t3, div_normalized
    
    # Need to normalize - shift left and adjust exponent
    slli t2, t2, 1
    andi t2, t2, 0xFF  # keep 8 bits
    addi s3, s3, -1
    
div_normalized:
    # Get final 7-bit mantissa (remove implicit bit)
    andi t2, t2, 0x7F
    
    # Check exponent bounds
    ble s3, zero, div_underflow
    li t3, 0xFF
    bge s3, t3, div_overflow
    
    # Pack result
    slli a0, s2, 15    # sign
    slli t3, s3, 7     # exponent
    or a0, a0, t3
    or a0, a0, t2      # mantissa
    j div_done

div_by_zero_check:
    # Division by zero
    beq s3, zero, div_zero_by_zero  # 0/0 = NaN
    li a0, 0x7F80        # +inf
    beq s2, zero, div_done
    li a0, 0xFF80        # -inf
    j div_done

div_zero_by_zero:
    li a0, 0x7FC0        # NaN
    j div_done

div_zero_dividend:
    # 0 / non-zero = 0
    li a0, 0
    j div_done

div_inf_nan_a:
    # a is inf or NaN
    beq s4, zero, div_a_inf    # a is infinity
    j div_nan_result           # a is NaN

div_inf_nan_b:
    # b is inf or NaN  
    beq t1, zero, div_b_inf    # b is infinity
    j div_nan_result           # b is NaN

div_a_inf:
    beq t0, zero, div_nan_result  # inf / 0 = NaN
    li t2, 0xFF
    beq t0, t2, div_nan_result    # inf / inf = NaN
    j div_inf_result

div_b_inf:
    beq s3, zero, div_zero_result # 0 / inf = 0
    j div_zero_result             # finite / inf = 0

div_inf_result:
    li a0, 0x7F80        # +inf
    beq s2, zero, div_done
    li a0, 0xFF80        # -inf
    j div_done

div_zero_result:
    li a0, 0
    j div_done

div_nan_result:
    li a0, 0x7FC0        # NaN
    j div_done

div_underflow:
    li a0, 0             # flush to zero
    j div_done

div_overflow:
    li a0, 0x7F80        # +inf
    beq s2, zero, div_done
    li a0, 0xFF80        # -inf

div_done:
    lw ra, 0(sp)
    lw s0, 4(sp)
    lw s1, 8(sp)
    lw s2, 12(sp)
    lw s3, 16(sp)
    lw s4, 20(sp)
    addi sp, sp, 24
    ret

# ==================== utility functions ====================
# Check if bfloat16 value is NaN
bf16_isnan:
    srli t0, a0, 7
    andi t0, t0, 255
    addi t1, zero, 255
    bne  t0, t1, not_nan_ret
    
    andi t0, a0, 127          # Exponent is all 1s, check if mantissa is non-zero
    beq  t0, zero, not_nan_ret  # Infinity, not NaN
    
    addi a0, zero, 1
    ret
    
not_nan_ret:
    add  a0, zero, zero
    ret

# Check if bfloat16 value is Infinity
bf16_isinf:
    srli t0, a0, 7
    andi t0, t0, 255
    addi t1, zero, 255
    bne  t0, t1, not_inf_ret
    
    andi t0, a0, 127          # Exponent is all 1s, check if mantissa is zero
    bne  t0, zero, not_inf_ret  # NaN, not Infinity
    
    addi a0, zero, 1
    ret
    
not_inf_ret:
    add  a0, zero, zero
    ret

# Check if bfloat16 value is zero
bf16_iszero:
    andi t0, a0, 255          # Check lower 8 bits
    srli t1, a0, 8            # Check next 7 bits
    andi t1, t1, 127
    or   t0, t0, t1           # Combine results
    bne  t0, zero, not_zero_ret
    addi a0, zero, 1
    ret
    
not_zero_ret:
    add  a0, zero, zero
    ret

# Check if two bfloat16 values are equal
bf16_eq:
    beq  a0, a1, equal_ret
    add  a0, zero, zero
    ret
    
equal_ret:
    addi a0, zero, 1
    ret