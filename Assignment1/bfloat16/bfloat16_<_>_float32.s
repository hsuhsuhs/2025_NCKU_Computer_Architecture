.data

# Test Case Description Strings ---------------------------------------------
str_t1: .asciz " 1.0f"
str_t_neg_simple: .asciz " -4.0f"
str_t3: .asciz " 3.14159f"
str_t4: .asciz " 0.1f"
str_t_neg_round: .asciz " -2.7f"
str_t5: .asciz " +0.0f"
str_t6: .asciz " -0.0f"
str_t7: .asciz " +Infinity"
str_t8: .asciz " -Infinity"
str_t9: .asciz " NaN"

# Normal Value Tests (with corrected golden values) ------------------------
normal_test_strings:
    .word str_t1, str_t_neg_simple, str_t3, str_t4, str_t_neg_round
normal_test_inputs:
    .word 0x3f800000, 0xc0800000, 0x40490fdb, 0x3dcccccd, 0xc02ccccd
normal_test_golden:
    .word 0x3f80,     0xc080,     0x4049,     0x3dcd,     0xc02d

# Special Value Tests (with corrected golden values) ---------------------------
special_test_strings:
    .word str_t5, str_t6, str_t7, str_t8, str_t9
special_test_inputs:
    .word 0x00000000, 0x80000000, 0x7f800000, 0xff800000, 0x7fc00000
special_test_golden:
    .word 0x0000,     0x8000,     0x7f80,     0xff80,     0x7fc0

# tests message ---------------------------------------------
str_header_normal:  .asciz "\n--- Running Normal Value Test Cases ---\n"
str_header_special: .asciz "\n--- Running Special Value Test Cases (Zero, Inf, NaN) ---\n"
str_testing:        .asciz "Testing"
str_orig_label:     .asciz "\n  Original f32: 0x"
str_bf16_label:     .asciz " -> bf16: 0x"
str_restored_label: .asciz " -> Restored f32: 0x"
str_success:        .asciz "  [PASS]"
str_fail:           .asciz "  [FAIL]"
str_actual:         .asciz " (Actual: 0x"
str_expected:       .asciz ", Expected: 0x"
str_close_paren:    .asciz ")\n"
str_summary:        .asciz "\n\n[Summary: "
str_summary_middle: .asciz " / "
str_summary_end:    .asciz " Tests Passed]\n"
newline:            .asciz "\n"
str_all_pass:       .asciz "\n---  All tests passed!  ---\n"
str_some_fail:      .asciz "\n---  Some tests failed!  ---\n"

.text
.globl main

# ==================== main tests ====================
main:
    # Function Prologue
    addi sp, sp, -8
    sw   ra, 4(sp)
    sw   s0, 0(sp)          # Reserve space on stack for s0 (total failure counter)

    # Initialize overall failure counter
    mv   s0, zero           # s0 = total_failures = 0

    #  ======== Run Normal Tests  ========
    la   a0, str_header_normal
    jal  ra, print_string
    la   a0, normal_test_strings
    la   a1, normal_test_inputs
    la   a2, normal_test_golden
    addi a3, zero, 5
    jal  ra, run_test_suite
    add  s0, s0, a0         # Accumulate failures from this test suite

    #  ======== Run Special Tests  ========
    la   a0, str_header_special
    jal  ra, print_string
    la   a0, special_test_strings
    la   a1, special_test_inputs
    la   a2, special_test_golden
    addi a3, zero, 5
    jal  ra, run_test_suite
    add  s0, s0, a0         # Accumulate failures again

    #  ========  Print Final Overall Summary  ========
    bnez s0, some_tests_failed

all_tests_passed:
    la   a0, str_all_pass
    jal  ra, print_string
    j    exit_program

some_tests_failed:
    la   a0, str_some_fail
    jal  ra, print_string

exit_program:
    # Function Epilogue
    lw   s0, 0(sp)
    lw   ra, 4(sp)
    addi sp, sp, 8
    addi a7, zero, 10       # ecall 10: Exit
    ecall

# =============================================================================
# run_test_suite: Loops through a set of tests, runs them,
#                 and returns the number of failures.
# Return Value: a0 = Number of failures in this suite.
#==============================================================================
run_test_suite:
    # Function Prologue: Allocate 28 bytes (1 ra + 6 s-regs)
    addi sp, sp, -28
    sw   ra, 24(sp)
    sw   s0, 20(sp)
    sw   s1, 16(sp)
    sw   s2, 12(sp)
    sw   s3, 8(sp)
    sw   s4, 4(sp)
    sw   s5, 0(sp)

    mv   s0, a0             # s0 = string array
    mv   s1, a1             # s1 = input array
    mv   s2, a2             # s2 = golden value array
    mv   s3, a3             # s3 = Loop counter
    mv   s4, zero           # s4 = Success counter
    mv   s5, zero           # s5 = Failure counter
    mv   t5, a3             # t5 = Backup of total test count for summary

test_loop:
    # Pass pointers to the single test runner
    mv   a0, s0
    mv   a1, s1
    mv   a2, s2
    jal  ra, run_single_test
    # run_single_test returns 1 in a0 if it failed, 0 if success
    add  s5, s5, a0         # Accumulate failure count

    # Advance all array pointers to the next test case
    addi s0, s0, 4
    addi s1, s1, 4
    addi s2, s2, 4
    addi s3, s3, -1
    bnez s3, test_loop      # Continue if tests remain

    # =========  Print Suite Summary  ===========
    sub  s4, t5, s5         # Success count is total - failures
    la   a0, str_summary
    jal  ra, print_string
    mv   a0, s4
    jal  ra, print_int
    la   a0, str_summary_middle
    jal  ra, print_string
    mv   a0, t5
    jal  ra, print_int
    la   a0, str_summary_end
    jal  ra, print_string

    # Function Epilogue
    mv   a0, s5             # Set return value to the failure count
    lw   s5, 0(sp)
    lw   s4, 4(sp)
    lw   s3, 8(sp)
    lw   s2, 12(sp)
    lw   s1, 16(sp)
    lw   s0, 20(sp)
    lw   ra, 24(sp)
    addi sp, sp, 28
    ret

# =============================================================================
# run_single_test: Performs a round-trip conversion and checks the result.
# Arguments: a0=str_ptr, a1=input_ptr, a2=golden_ptr
# Return Value: a0 = 1 if fail, 0 if success.
#==============================================================================
run_single_test:
    # Function Prologue
    addi sp, sp, -20
    sw   ra, 16(sp)
    sw   s0, 12(sp)
    sw   s1, 8(sp)
    sw   s2, 4(sp)
    sw   s3, 0(sp)
    
    # Load test data into saved registers
    lw   s0, 0(a0)            # s0 = address of description string
    lw   s1, 0(a1)            # s1 = original f32 input value
    lw   s2, 0(a2)            # s2 = expected bf16 golden value

    # Perform Conversions 
    mv   a0, s1               # Set argument for f32_to_bf16
    jal  ra, f32_to_bf16
    mv   s3, a0               # s3 = actual_bf16_result
    jal  ra, bf16_to_f32
    mv   t0, a0               # t0 = restored_f32_result

    #  Calculate Golden Restored Value 
    slli t1, s2, 16           # t1 = golden_restored_f32

    # ===== Print Results on a Single Line ==========
    la   a0, str_testing
    jal  ra, print_string     # Print "Testing"
    mv   a0, s0
    jal  ra, print_string     # Print " 1.0f"
    la   a0, str_orig_label
    jal  ra, print_string     # Print "\n  Original f32: 0x"
    mv   a0, s1
    jal  ra, print_hex32      # Print original value
    la   a0, str_bf16_label
    jal  ra, print_string     # Print " -> bf16: 0x"
    mv   a0, s3
    jal  ra, print_hex32      # Print bf16 value
    la   a0, str_restored_label
    jal  ra, print_string     # Print " -> Restored f32: 0x"
    mv   a0, t0
    jal  ra, print_hex32      # Print restored value

    # Compare restored_f32 (t0) with golden_restored_f32 (t1)
    beq  t0, t1, test_success
    
test_fail:
    la   a0, str_fail
    jal  ra, print_string
    la   a0, str_actual
    jal  ra, print_string
    mv   a0, t0
    jal  ra, print_hex32
    la   a0, str_expected
    jal  ra, print_string
    mv   a0, t1
    jal  ra, print_hex32
    la   a0, str_close_paren
    jal  ra, print_string
    addi a0, zero, 1          # Return 1 for failure
    j    end_single_test

test_success:
    la   a0, str_success
    jal  ra, print_string
    la   a0, newline
    jal  ra, print_string
    addi a0, zero, 0          # Return 0 for success

end_single_test:
    # Function Epilogue
    lw   s3, 0(sp)
    lw   s2, 4(sp)
    lw   s1, 8(sp)
    lw   s0, 12(sp)
    lw   ra, 16(sp)
    addi sp, sp, 20
    ret

# ====================  bf16_t f32_to_bf16(float val)  ========================
f32_to_bf16:
    # Check if the number is NaN or Infinity by inspecting the exponent.
    srli t0, a0, 23         # Isolate exponent and sign.
    andi t0, t0, 0xFF       # Mask to get only the 8 exponent bits.
    addi t1, zero, 0xFF     # Load 0xFF for comparison.
    beq  t0, t1, is_nan_or_inf # If exponent is all 1s, jump to special handling.

    # ====== Normal Number Rounding Path ======
    lui  t0, 0x80000        # Load upper bits of the sign mask (0x80000000).
    and  t1, a0, t0         # t1 = sign bit (0x80000000 or 0).
    not  t0, t0             # sign mask = 0x7FFFFFFF.
    and  t2, a0, t0         # t2 = magnitude.
    srli t3, t2, 16         # Shift magnitude to get the tie-breaking bit's position.
    andi t3, t3, 1          # Isolate the tie-breaking bit (0 or 1).
    lui  t4, 0x8            # Load upper bits of 0x8000.
    addi t4, t4, -1         # Create the main rounding constant 0x7FFF.
    add  t3, t3, t4         # t3 = final addend (0x7FFF or 0x8000).
    add  t2, t2, t3         
    srli t2, t2, 16         # Truncate the rounded magnitude to 16 bits.
    srli t1, t1, 16         # Shift the original sign bit to its bf16 position (bit 15).
    or   a0, t2, t1         
    ret                     
is_nan_or_inf:
    # For NaN, Infinity, and Zero, the correct behavior is simple truncation.
    srli a0, a0, 16         # Shift right by 16 bits.
    ret                     

# ================  float bf16_to_f32(bf16_t val) ======================
bf16_to_f32:
    slli a0, a0, 16         # Shift left by 16, padding lower bits with zeros.
    ret                     


# ===========  Helper Print Functions  ==========
print_string:
    addi a7, zero, 4        # Set ecall code for Print String.
    ecall                   
    ret                     
print_hex32:
    addi a7, zero, 34       # Set ecall code for Print Hex.
    ecall                
    ret                  
print_int:
    addi a7, zero, 1        # Set ecall code for Print Integer.
    ecall                   
    ret    