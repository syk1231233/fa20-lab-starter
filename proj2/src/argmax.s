.globl argmax

.text
# =================================================================
# FUNCTION: Given a int vector, return the index of the largest
#	element. If there are multiple, return the one
#	with the smallest index.
# Arguments:
# 	a0 (int*) is the pointer to the start of the vector
#	a1 (int)  is the # of elements in the vector
# Returns:
#	a0 (int)  is the first index of the largest element
# Exceptions:
# - If the length of the vector is less than 1,
#   this function terminates the program with error code 77.
# =================================================================
argmax:

    # Error Check: if a1 < 1, exit with code 77
    li t0, 1
    blt a1, t0, error
    # loop set up: t0 - index of element t1 - address of according element 
    #              t2 - element          t3 - max element's index
    #              t4 - max element
    mv t0, zero
    mv t1, a0
    mv t3, t1
    lw t4, 0(t1)
loop_start:
    # Boundary Check: if t0 == a1, loop end
    beq t0, a1, loop_end
    # Load element from memory to register
    lw t2, 0(t1)
    # Logic Tackle: if t2 > t4, t4 = t2, t3 = t0
    ble t2, t4, loop_continue
    mv t3, t0
    mv t4, t2
    
loop_continue:
    # Upgrade index to next
    addi t0, t0, 1
    # Upgrade address to next
    addi t1, t1, 4
    # Next loop: back to loop_start
    j loop_start

loop_end:
    # Set a0: a0 = t3
    mv a0, t3
    ret

error:
    li a1, 77
    jal exit2