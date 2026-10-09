# jal / jalr: return address, rd==rs1, back-to-back jumps, kill after jump, negative offsets
jal  ra, f1              # ra = 4
addi t0, x0, 1           # runs after return from f1
jal  x0, skip            # j skip
addi t1, x0, 99          # must never run
f1: addi s0, x0, 5
jalr x0, ra, 0           # ret -> address 4
addi s0, x0, 77          # killed
skip: auipc sp, 0        # sp = address of this insn (0x1c)
addi sp, sp, 16          # sp -> label tgt (0x2c)
jalr sp, sp, 0           # rd == rs1: jump to old sp, sp = 0x28
addi t1, x0, 98          # killed
tgt: jal  a0, j2         # back-to-back jumps
j2:  jal  s1, j3
addi t2, x0, 97          # killed
j3:  addi t2, x0, 3
back: addi t2, t2, -1
blt  x0, t2, back        # loop, then fall through
jal  x0, done
addi t0, x0, 96          # killed
done: addi t0, t0, 10    # t0 = 11
