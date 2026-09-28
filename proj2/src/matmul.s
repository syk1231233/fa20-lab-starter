.globl matmul

.text
# =======================================================
# FUNCTION: Matrix Multiplication of 2 integer matrices
# 	d = matmul(m0, m1)
# Arguments:
# 	a0 (int*)  is the pointer to the start of m0 
#	a1 (int)   is the # of rows (height) of m0
#	a2 (int)   is the # of columns (width) of m0
#	a3 (int*)  is the pointer to the start of m1
# 	a4 (int)   is the # of rows (height) of m1
#	a5 (int)   is the # of columns (width) of m1
#	a6 (int*)  is the pointer to the the start of d
# Returns:
#	None (void), sets d = matmul(m0, m1)
# Exceptions:
#   Make sure to check in top to bottom order!
#   - If the dimensions of m0 do not make sense,
#     this function terminates the program with exit code 72.
#   - If the dimensions of m1 do not make sense,
#     this function terminates the program with exit code 73.
#   - If the dimensions of m0 and m1 don't match,
#     this function terminates the program with exit code 74.
# =======================================================
matmul:

    # Error checks: if a1 < 1 or a2 < 1, go to error_matrix0
    #              -if a4 < 1 or a5 < 1, go to error_matrix1
    #              -if a2 != a4        , go to error_dismension
    li t0, 1
    blt a1, t0, error_matrix0
    blt a2, t0, error_matrix0
    blt a4, t0, error_matrix1
    blt a5, t0, error_matrix1
    bne a2, a4, error_dismension # if ! a2= a4 terror_dismensionrget
    

    # Prologue: ra, s0, s1, s2, a0, a1, a2, a3, a4
    addi sp, sp, -48
    sw ra, 0(sp)
    sw s0, 4(sp)
    sw s1, 8(sp)
    sw s2, 12(sp)
    sw s3, 16(sp)
    sw s4, 20(sp)
    sw s5, 24(sp)
    sw s6, 28(sp)
    sw s7, 32(sp)

    # Loop set up: s0 - the ith rows in matrix0     s1 - the jth cloumns in matrix1
    #              s2 - current row's base address  s3 - current column's base address
    #              s4 - aim martrix's address
    li s0, 0
    li s1, 0
    mv s2, a0
    mv s3, a3
    mv s4, a6
    j inner_loop_start

outer_loop_start:   # FIX row
    # Upgrade Rows
    addi s0, s0, 1
    li s1, 0
    mv s3, a3
    # Boundary check: if s0 = a1, go to outer_loop_end
    beq s0, a1, outer_loop_end
    # Upgrade row's base address
    slli t0, a2 ,2
    add s2, s2, t0

inner_loop_start:   # Look through columns
    # Boundary check: if s1 = a5, go to outer_loop_start
    beq s1, a5, outer_loop_start
    # Call dot, a0 <- rows base address     a1 <- columns base address
    #           a2 <- a2(matrix0's columns) a3 <- 1
    #           a4 <- a5(matrix1's columns)
    addi sp, sp, -32
    sw a0, 0(sp)
    sw a1, 4(sp)
    sw a2, 8(sp)
    sw a3, 12(sp)
    sw a4, 16(sp)
    sw a5, 20(sp)

    mv a0, s2
    mv a1, s3
    mv a2, a2
    li a3, 1
    mv a4, a5

    jal dot

    mv t0, a0
    lw a0, 0(sp)
    lw a1, 4(sp)
    lw a2, 8(sp)
    lw a3, 12(sp)
    lw a4, 16(sp)
    lw a5, 20(sp)
    addi sp, sp, 32

    # Stroge a0 to according address in memory
    sw t0, 0(s4)

inner_loop_end:
    # Upgrade Columns and aim matrix's address
    addi s1, s1, 1
    addi s3, s3, 4
    addi s4, s4, 4
    j inner_loop_start
outer_loop_end:
    # Epilogue ra, s0, s1, s2
    lw ra, 0(sp)
    lw s0, 4(sp)
    lw s1, 8(sp)
    lw s2, 12(sp)
    lw s3, 16(sp)
    lw s4, 20(sp)
    lw s5, 24(sp)
    lw s6, 28(sp)
    lw s7, 32(sp)
    addi sp, sp, 48

    ret

error_matrix0:
    li a1, 72
    jal exit2  # jump to exit2 and save position to ra

error_matrix1:
    li a1, 73
    jal exit2  # jump to exit2 and save position to ra

error_dismension:
    li a1, 74
    jal exit2  # jump to exit2 and save position to ra
    
    
    