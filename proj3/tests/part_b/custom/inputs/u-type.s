# lui / auipc
lui   t0, 0x12345      # 0x12345000
lui   t1, 0xfffff      # 0xfffff000
addi  t1, t1, -1       # 0xffffefff
auipc t2, 0            # PC of this insn = 0xc
auipc s0, 1            # 0x10 + 0x1000 = 0x1010
auipc s1, 0xfffff      # 0x14 + 0xfffff000 = 0xfffff014
lui   a0, 0x80000      # 0x80000000
addi  a0, a0, 0x7ff    # 0x800007ff
