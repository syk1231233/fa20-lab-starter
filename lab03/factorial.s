.globl factorial

.data
n: .word 7

.text
main:
    la t0, n
    lw a0, 0(t0)
    jal ra, factorial

    addi a1, a0, 0
    addi a0, x0, 1
    ecall # Print Result

    addi a1, x0, '\n'
    addi a0, x0, 11
    ecall # Print newline

    addi a0, x0, 10
    ecall # Exit

factorial:
    # a0 - n!
    # loop set up: t0 - result
    li t0, 1
loop_start:
    beq a0, zero, loop_end
    mul t0, t0, a0
loop_continue:
    addi a0, a0, -1
    j loop_start
loop_end:
    mv a0, t0
    ret