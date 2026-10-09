# lb lh lw sb sh sw: every byte offset, sign extension, neighbours preserved
addi t0, x0, 256       # base address 0x100
lui  t1, 0x80f07       # t1 = 0x80f07000
addi t1, t1, 0x7f1     # t1 = 0x80f077f1  bytes: [3]=80 [2]=f0 [1]=77 [0]=f1
sw   t1, 0(t0)
lb   t2, 0(t0)         # 0xfffffff1 (negative byte)
lb   s0, 1(t0)         # 0x00000077 (positive byte)
lb   s1, 2(t0)         # 0xfffffff0
lb   a0, 3(t0)         # 0xffffff80
lh   ra, 0(t0)         # 0x000077f1 (positive half)
lh   sp, 2(t0)         # 0xffff80f0 (negative half)
addi t2, x0, 0x0ab     # t2 = 0xab
sb   t2, 0(t0)         # word -> 0x80f077ab
sb   t2, 1(t0)         # word -> 0x80f0abab
sb   t2, 2(t0)         # word -> 0x80ababab
sb   t2, 3(t0)         # word -> 0xabababab
lw   s0, 0(t0)         # 0xabababab
addi s1, x0, -2        # s1 = 0xfffffffe
sh   s1, 0(t0)         # word -> 0xababfffe
lw   a0, 0(t0)
sh   s1, 2(t0)         # word -> 0xfffefffe
lw   ra, 0(t0)
sw   t1, 4(t0)         # second word, neighbour check
sb   x0, 5(t0)         # 0x80f000f1
lw   sp, 4(t0)
