.globl dot

.text
# =======================================================
# FUNCTION: Dot product of 2 int vectors
# Arguments:
#   a0 (int*) is the pointer to the start of v0
#   a1 (int*) is the pointer to the start of v1
#   a2 (int)  is the length of the vectors
#   a3 (int)  is the stride of v0
#   a4 (int)  is the stride of v1
# Returns:
#   a0 (int)  is the dot product of v0 and v1
# Exceptions:
# - If the length of the vector is less than 1,
#   this function terminates the program with error code 75.
# - If the stride of either vector is less than 1,
#   this function terminates the program with error code 76.
# =======================================================
dot:
    # Error Check: if a2 < 1, exit with code 75(error1)
    #           —  if a3 < 1 or a4 < 1. exit with code 76(error2)
    li t0, 1
    blt a2, t0, error1
    blt a3, t0, error2
    blt a4, t0, error2

    # Loop set up:
    #       Vector 0: t0 - element address t1 - element a3 - stride offset
    #       Vector 1: t2 - element address t3 - element a4 - stride offset
    #                 t4 - temporary stroge the multiple result
    #                 t5 - the sum of multiple
    mv t0, a0
    mv t2, a1
    li t5, 0
    slli a3, a3, 2
    slli a4, a4, 2

loop_start:
    # Boundary Check: if a2 = 0, loop end
    beq a2, zero, loop_end
    # Load data:    t1 <- memory(t0)
    #               t3 <- memory(t2)
    lw t1, 0(t0)
    lw t3, 0(t2)
    # Logic tackle: 1. t4 = t1 * t3
    #               2. t5 = t5 + t4
    mul t4, t1, t3
    add t5, t5, t4

loop_continue:
    # Upgrade address:
    add t0, t0, a3
    add t2, t2, a4
    # Upgrade a2
    addi a2, a2, -1
    # Back to loop_start
    j loop_start

loop_end:
    # Return t5: a0 = t5
    mv a0, t5
    ret

error1:
    li a1, 75
    jal exit2

error2:
    li a1, 76
    jal exit2