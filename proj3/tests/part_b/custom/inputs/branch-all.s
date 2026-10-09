# all 6 branches, taken and not taken, signed vs unsigned, backward branch, kill check
addi t0, x0, -1          # t0 = -1 (0xffffffff, huge unsigned)
addi t1, x0, 1           # t1 = 1
addi a0, x0, 0           # a0 counts correct paths
beq  t0, t1, bad         # not taken
addi a0, a0, 1
bne  t0, t1, l1          # taken
addi ra, x0, 99          # must be killed
l1: blt  t0, t1, l2      # taken (signed -1 < 1)
addi ra, x0, 98          # must be killed
l2: bltu t0, t1, bad     # not taken (unsigned 0xffffffff > 1)
addi a0, a0, 1
bge  t1, t0, l3          # taken (signed 1 >= -1)
addi sp, x0, 97          # must be killed
l3: bgeu t1, t0, bad     # not taken (unsigned 1 < 0xffffffff)
addi a0, a0, 1
bge  t1, t1, l4          # taken (equal)
addi sp, x0, 96
l4: bgeu t0, t0, l5      # taken (equal)
addi s0, x0, 95
l5: addi s1, x0, 3       # backward loop: s1 = 3 -> 0, t2 counts iterations
loop: addi t2, t2, 1
addi s1, s1, -1
bne  s1, x0, loop        # backward branch, taken twice
beq  x0, x0, end         # taken
bad: addi a0, x0, -1     # reached only on error
end: addi a0, a0, 10     # a0 = 13 if all correct
