.globl relu

.text
# ==============================================================================
# FUNCTION: Performs an inplace element-wise ReLU on an array of ints
# Arguments:
# 	a0 (int*) is the pointer to the array
#	a1 (int)  is the # of elements in the array
# Returns:
#	None
# Exceptions:
# - If the length of the vector is less than 1,
#   this function terminates the program with error code 78.
# ==============================================================================
relu:
    # Error Check: if a1 < 1, exit with code 78
    li t0, 1
    blt a1, t0, error

    # loop set up:
    li t0, 0
    mv t1, a0

    # t0-index of element t1-address of element t2-element
loop_start:
    # Boundary Check: if index = length, loop end
    beq t0, a1, loop_end
    # Load element from memory
    lw t2, 0(t1)
    # Logic tackle: if element < 0, store zero back to memory
    bge t2, zero, loop_continue
    sw  zero, 0(t1)

loop_continue:
    addi t0, t0, 1
    addi t1, t1, 4
    j loop_start

loop_end:
    ret
    
error:
    li a1, 78
    jal exit2
