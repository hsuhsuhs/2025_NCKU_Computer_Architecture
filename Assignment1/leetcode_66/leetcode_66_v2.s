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

# Optimized plus_one function
plus_one:
    addi sp, sp, -12
    sw ra, 0(sp)
    sw s0, 4(sp)        # result buffer address
    sw s1, 8(sp)        # original length
    
    la s0, result       # s0 = result buffer address
    mv s1, a1           # s1 = original length
    
    # Copy input to result
    mv t0, a0           # source
    mv t1, s0           # destination  
    mv t2, a1           # counter
copy_loop:
    beqz t2, copy_done
    lw t3, 0(t0)
    sw t3, 0(t1)
    addi t0, t0, 4
    addi t1, t1, 4
    addi t2, t2, -1
    j copy_loop
copy_done:
    
    # Add 1 starting from the last digit
    addi t0, s1, -1     # index of last element
    slli t0, t0, 2      # convert to byte offset
    add t0, s0, t0      # pointer to last element
    
    li t1, 1            # carry = 1 (we're adding 1)
    
add_loop:
    # Load current digit
    lw t2, 0(t0)
    
    # Add carry
    add t2, t2, t1
    li t1, 0            # reset carry
    
    # Check if digit >= 10
    li t3, 10
    blt t2, t3, no_carry
    
    # Handle carry: set digit to 0, set carry to 1
    li t2, 0
    li t1, 1
    
no_carry:
    # Store updated digit
    sw t2, 0(t0)
    
    # Check if we need to continue
    beqz t1, add_done    # no carry, we're done
    
    # Move to previous digit
    addi t0, t0, -4
    
    # Check if we've reached the beginning
    blt t0, s0, expand_array
    j add_loop

add_done:
    mv a0, s1           # return original length
    j plus_one_exit

expand_array:
    # All digits were 9, need to expand array
    # Shift all digits right by one position
    addi t0, s1, -1     # start from last index
shift_loop:
    bltz t0, shift_done
    slli t1, t0, 2      # byte offset
    add t1, s0, t1      # source address
    lw t2, 0(t1)        # load value
    addi t3, t1, 4      # destination address (one position right)
    sw t2, 0(t3)        # store value
    addi t0, t0, -1     # move to previous index
    j shift_loop

shift_done:
    # Set first digit to 1
    li t0, 1
    sw t0, 0(s0)
    addi a0, s1, 1      # return new length

plus_one_exit:
    lw ra, 0(sp)
    lw s0, 4(sp)
    lw s1, 8(sp)
    addi sp, sp, 12
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