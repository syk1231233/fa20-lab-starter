# R-type: add sub sll slt xor srl sra or and mul mulh mulhu
addi t0, x0, -7        # t0 = -7
addi t1, x0, 3         # t1 = 3
add  t2, t0, t1        # -4
sub  s0, t1, t0        # 10
sub  s1, t0, t0        # 0
sll  a0, t1, t1        # 3 << 3 = 24
addi ra, x0, 33        # shift amount 33 -> only low 5 bits (1) used
sll  sp, t1, ra        # 3 << 1 = 6
slt  t2, t0, t1        # 1 (-7 < 3)
slt  s0, t1, t0        # 0
slt  s1, t1, t1        # 0 (equal)
xor  a0, t0, t1        # 0xfffffffa
srl  ra, t0, t1        # 0x1fffffff
sra  sp, t0, t1        # -1
or   t2, t0, t1        # 0xfffffffb
and  s0, t0, t1        # 1
mul  s1, t0, t1        # -21
mulh a0, t0, t1        # high of -21 = 0xffffffff
mulhu ra, t0, t1       # high of 0xfffffff9*3 = 2
mul  sp, t0, t0        # 49
mulh t2, t0, t0        # 0
