# I-type arithmetic: addi slli slti xori srli srai ori andi
addi t0, x0, -1        # t0 = 0xffffffff (negative imm, inst[30]=1 must still be addi)
addi t1, x0, 2047      # t1 = 0x7ff (max positive imm)
addi t2, x0, -2048     # t2 = 0xfffff800 (min negative imm)
slli s0, t1, 20        # s0 = 0x7ff00000
slli s1, t0, 31        # s1 = 0x80000000
srli a0, s1, 4         # a0 = 0x08000000 (logical: zero fill)
srai ra, s1, 4         # ra = 0xf8000000 (arithmetic: sign fill)
srai sp, t1, 3         # sp = 0xff (positive srai)
slti t0, t2, 0         # 1 (-2048 < 0)
slti t1, t1, -5        # 0 (2047 < -5 false)
slti s0, a0, 0x7ff     # 0 (equal-ish check: 0x08000000 < 2047 false)
xori s1, t2, -1        # s1 = ~0xfffff800 = 0x7ff
xori a0, a0, 0x555     # a0 = 0x08000555
ori  ra, ra, 0x0f0     # ra = 0xf80000f0
ori  sp, sp, -256      # sp = 0xffffffff
andi t2, t2, 0x7f0     # t2 = 0x800
andi s0, ra, -16       # s0 = 0xf80000f0
slti t1, t0, 1         # t1 = 0 (1 < 1 false: equal case)
