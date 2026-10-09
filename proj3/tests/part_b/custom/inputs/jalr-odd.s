# jalr target must clear bit 0: (rs1 + imm) & ~1
auipc t0, 0            # t0 = 0
addi  t0, t0, 17       # t0 = 17 (odd); 17 & ~1 = 16 -> label tgt
jalr  ra, t0, 0        # ra = 12, jump to 16
addi  t1, x0, 99       # killed
tgt: addi t2, x0, 7    # address 16
addi  s0, x0, 1
