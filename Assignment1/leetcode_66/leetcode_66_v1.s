# Plus One - RISC-V Assembly Implementation
# Implements: digits = digits + 1 for large integers represented as arrays

.data
# Test data arrays
test1:      .word 1, 2, 3          # [1,2,3] -> [1,2,4]
test1_len:  .word 3
test1_exp:  .word 1, 2, 4          # Expected result

test2:      .word 4, 3, 2, 1       # [4,3,2,1] -> [4,3,2,2]
test2_len:  .word 4
test2_exp:  .word 4, 3, 2, 2       # Expected result

test3:      .word 9, 9, 9          # [9,9,9] -> [1,0,0,0]
test3_len:  .word 3
test3_exp:  .word 1, 0, 0, 0       # Expected result (length changes!)

# Output buffer for results
result:     .word 0, 0, 0, 0, 0    # 5 words buffer

# Test messages
test_start_msg:     .string "=== Plus One Automated Test ===\n\n"
test1_msg:          .string "Test 1: [1,2,3] -> [1,2,4] "
test2_msg:          .string "Test 2: [4,3,2,1] -> [4,3,2,2] "
test3_msg:          .string "Test 3: [9,9,9] -> [1,0,0,0] "

pass_msg:           .string "PASS\n"
fail_msg:           .string "FAIL\n"
separator:          .string "\n====================\n"
all_pass_msg:       .string "All tests passed.\n"
some_fail_msg:      .string "Some tests failed.\n"
newline:            .string "\n"

.text
.globl main

main:
    # Print test start message
    la a0, test_start_msg
    li a7, 4
    ecall
    
    # Initialize test counters
    li s0, 0           # s0 = pass count
    li s1, 3           # s1 = total test count
    
    # Test 1: [1,2,3] -> [1,2,4]
    la a0, test1_msg
    li a7, 4
    ecall
    
    la a0, test1       # input array
    lw a1, test1_len   # array length
    jal ra, plus_one
    
    la a1, test1_exp   # expected result
    lw a2, test1_len   # expected length
    jal ra, compare_arrays
    
    beqz a0, test1_fail
    addi s0, s0, 1     # increment pass count
    la a0, pass_msg
    j test1_end
    
test1_fail:
    la a0, fail_msg
    
test1_end:
    li a7, 4
    ecall
    
    # Test 2: [4,3,2,1] -> [4,3,2,2]
    la a0, test2_msg
    li a7, 4
    ecall
    
    la a0, test2       # input array
    lw a1, test2_len   # array length
    jal ra, plus_one
    
    la a1, test2_exp   # expected result
    lw a2, test2_len   # expected length
    jal ra, compare_arrays
    
    beqz a0, test2_fail
    addi s0, s0, 1     # increment pass count
    la a0, pass_msg
    j test2_end
    
test2_fail:
    la a0, fail_msg
    
test2_end:
    li a7, 4
    ecall
    
    # Test 3: [9,9,9] -> [1,0,0,0]
    la a0, test3_msg
    li a7, 4
    ecall
    
    la a0, test3       # input array
    lw a1, test3_len   # array length
    jal ra, plus_one
    
    la a1, test3_exp   # expected result
    li a2, 4           # expected length is 4 (changed due to carry)
    jal ra, compare_arrays
    
    beqz a0, test3_fail
    addi s0, s0, 1     # increment pass count
    la a0, pass_msg
    j test3_end
    
test3_fail:
    la a0, fail_msg
    
test3_end:
    li a7, 4
    ecall
    
    # Print separator
    la a0, separator
    li a7, 4
    ecall
    
    # Print final results
    beq s0, s1, all_passed
    la a0, some_fail_msg
    j print_final
    
all_passed:
    la a0, all_pass_msg
    
print_final:
    li a7, 4
    ecall
    
    # Exit program
    li a7, 10
    ecall

# Plus One function
# Corresponds to: int* plusOne(int* digits, int digitsSize, int* returnSize)
plus_one:
    addi sp, sp, -20
    sw ra, 0(sp)
    sw s0, 4(sp)        # input array address
    sw s1, 8(sp)        # original length
    sw s2, 12(sp)       # result buffer address
    sw s3, 16(sp)       # carry flag
    
    mv s0, a0           # s0 = input array address
    mv s1, a1           # s1 = original length
    la s2, result       # s2 = result buffer address
    
    # Initialize result buffer to zeros
    la t0, result
    li t1, 5            # max possible length
    li t2, 0
init_loop:
    beqz t1, init_done
    sw t2, 0(t0)
    addi t0, t0, 4
    addi t1, t1, -1
    j init_loop
init_done:
    
    # Copy input to result (similar to malloc + initialization in C)
    mv t0, s0           # source = input array
    mv t1, s2           # destination = result buffer
    mv t2, s1           # counter = length
copy_loop:
    beqz t2, copy_done
    lw t3, 0(t0)
    sw t3, 0(t1)
    addi t0, t0, 4
    addi t1, t1, 4
    addi t2, t2, -1
    j copy_loop
copy_done:
    
    # Start from least significant digit with carry = 1
    li s3, 1            # carry flag = true (initially adding 1)
    
    # Calculate pointer to last element
    la t0, result       # result array
    addi t1, s1, -1     # index of last element
    slli t1, t1, 2      # convert to byte offset
    add t0, t0, t1      # point to last element
    
    mv t2, s1           # counter = length
process_digits:
    beqz t2, check_final_carry
    
    # Check if we need to add (last digit or carry is set)
    beqz s3, no_addition
    
    # Add 1 to current digit
    lw t3, 0(t0)        # load current digit
    addi t3, t3, 1      # add 1
    
    # Check for carry
    li t4, 10
    blt t3, t4, no_overflow
    
    # Handle overflow: set digit to 0, keep carry flag
    li t3, 0
    li s3, 1            # carry remains true
    j store_digit
    
no_overflow:
    # No overflow, clear carry flag
    li s3, 0
    
store_digit:
    sw t3, 0(t0)
    
no_addition:
    # Move to next digit (more significant)
    addi t0, t0, -4
    addi t2, t2, -1
    j process_digits

check_final_carry:
    # If we still have carry after processing all digits
    beqz s3, plus_one_done
    
    # Need to expand array: shift right and add 1 at front
    # Calculate new length
    addi s1, s1, 1
    
    # Shift all elements right by one position
    la t0, result
    addi t1, s1, -2     # index of second last element in new array
    slli t1, t1, 2
    add t2, t0, t1      # source pointer (starts at original last element)
    addi t3, t2, 4      # destination pointer (one position right)
    
    mv t4, s1           # counter = new length - 1
    addi t4, t4, -1
shift_loop:
    beqz t4, shift_done
    lw t5, 0(t2)
    sw t5, 0(t3)
    addi t2, t2, -4
    addi t3, t3, -4
    addi t4, t4, -1
    j shift_loop

shift_done:
    # Add 1 as the new most significant digit
    li t0, 1
    la t1, result
    sw t0, 0(t1)

plus_one_done:
    mv a0, s1           # return new length
    
    lw ra, 0(sp)
    lw s0, 4(sp)
    lw s1, 8(sp)
    lw s2, 12(sp)
    lw s3, 16(sp)
    addi sp, sp, 20
    ret

# Compare arrays function
# Input: a0 = actual length, a1 = expected array address, a2 = expected length  
# Output: a0 = 1 if arrays match, 0 otherwise
compare_arrays:
    addi sp, sp, -12
    sw ra, 0(sp)
    sw s0, 4(sp)
    sw s1, 8(sp)
    
    mv s0, a1           # s0 = expected array
    mv s1, a2           # s1 = expected length
    
    # First check if lengths match
    bne a0, s1, compare_fail
    
    # Now compare each element
    la t0, result       # actual result array
    mv t1, s0           # expected array
    mv t2, s1           # counter
    
compare_loop:
    beqz t2, compare_success
    lw t3, 0(t0)        # actual value
    lw t4, 0(t1)        # expected value
    bne t3, t4, compare_fail
    addi t0, t0, 4
    addi t1, t1, 4
    addi t2, t2, -1
    j compare_loop

compare_success:
    li a0, 1
    j compare_done

compare_fail:
    li a0, 0

compare_done:
    lw ra, 0(sp)
    lw s0, 4(sp)
    lw s1, 8(sp)
    addi sp, sp, 12
    ret
