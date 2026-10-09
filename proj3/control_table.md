# 控制信号表（自推验收）

填写说明：
- 写**具体表现**（选 rs1 / 选 imm / 写回 ALU 结果 ……），不写 0/1。
- 无关项写“无关”，并在括号里说明原因。
- 随 funct3 / funct7 变化的信号写“见规则 X”，然后在文末对应的规则里写清楚。

---

## R 型（add sub sll slt xor srl sra or and mul mulh mulhu）
- PCSel：   pc + 4
- ImmSel：  未定义, 不使用立即数
- RegWEn：  1, 写回
- BrUn：    未定义, 不是分支指令
- ASel：    选中rs1
- BSel：    选中rs2
- ALU 运算： 对应运算模式
- 写内存 / 掩码：  未定义, 不写内存
- WBSel：   选中alu_result
- CSRWen：  未定义, 不与csr寄存器交互
- CSRSel：  未定义, 不与csr寄存器交互
- Kill：    不杀

## I 型算术（addi slli slti xori srli srai ori andi）
- PCSel：   pc+4
- ImmSel：  i型立即数生成
- RegWEn：  1, 写回rd
- BrUn：     未定义, 不是分支指令
- ASel：    rs1
- BSel：    imm
- ALU 运算： 对应运算类型
- 写内存 / 掩码：不写内存
- WBSel：   alu_result
- CSRWen：  未定义, 不与csr寄存器交互
- CSRSel：  未定义, 不与csr寄存器交互
- Kill：    不杀

## lui 加载无符号立即数
- PCSel：   pc + 4
- ImmSel：  u型立即数生成
- RegWEn：  1, 写回rd寄存器
- BrUn：    未定义, 不是分支指令
- ASel：    rs1
- BSel：    imm
- ALU 运算： 对应运算类型
- 写内存 / 掩码： 不进行写内存
- WBSel：   1, 写回rd寄存器
- CSRWen：  未定义, 不与csr寄存器交互
- CSRSel：  除了最后的csrw都是未定义, 不与csr寄存器交互
- Kill：    不杀

## auipc    
- PCSel：   pc + 4
- ImmSel：  u型立即数生成
- RegWEn：  1, 写回rd寄存器
- BrUn：    未定义, 不是分支指令, b型指令之外都是这个
- ASel：    ex_pc
- BSel：    imm
- ALU 运算： u型低20位加法   
- 写内存 / 掩码：不写内存
- WBSel：   1, 写回rd寄存器
- CSRWen：  
- CSRSel：
- Kill：    不杀

## load（lb lh lw）
- PCSel：   pc + 4
- ImmSel：  l型加载立即数
- RegWEn：  1, 写回rd寄存器
- BrUn：    
- ASel：    rs1
- BSel：    imm
- ALU 运算： 加法, 算出内存地址送入内存
- 写内存 / 掩码： 不进行写内存
- WBSel：   不写回内存
- CSRWen：  
- CSRSel：
- Kill：    不杀

## store（sb sh sw）
- PCSel：   pc + 4
- ImmSel：  s 型加载立即数
- RegWEn：  1, 写回rd
- BrUn：    
- ASel：    rs1
- BSel：    imm
- ALU 运算： 加法, 算出内存地址
- 写内存 / 掩码：根据func3变化, func7类型说明取几个字
- WBSel：   0, 选通经过掩码取出的alu_result
- CSRWen：
- CSRSel：
- Kill：    不杀

## branch（beq bne blt bge bltu bgeu）
- PCSel： 根据branchcomp结果进行, 如果条件成立, pc = pc + imm, 如果不成立, pc = pc +4 
- ImmSel：b 型立即数生成
- RegWEn：不写回
- BrUn： 看比较类型有没有u, 这个信号决定是有符号数比较还是无符号
- ASel： ex_pc
- BSel： imm
- ALU 运算：加法, ex_pc + imm
- 写内存 / 掩码：   不写
- WBSel：   不写
- CSRWen：  
- CSRSel：
- Kill：    如果条件成立, 就把取指流水线寄存器中载入nop指令杀死对应指令, 如果不成立, 就不杀

## jal
- PCSel：pc = pc + imm
- ImmSel：j型立即数生成
- RegWEn：不写回
- BrUn： 未定义, 不进行比较
- ASel： ex_pc
- BSel： imm
- ALU 运算：    加法, 算出新的pc
- 写内存 / 掩码：   不写
- WBSel：不写
- CSRWen：
- CSRSel：
- Kill： 立即杀, 取值流水线寄存器塞入nop

## jalr
- PCSel：pc = pc + imm
- ImmSel： j型立即数生成
- RegWEn： 1, 将取值阶段的pc(刚好是ex_pc + 4, 跳转指令的下一条指令)塞入ra
- BrUn：未定义, 不进行比较
- ASel：ex_pc
- BSel：imm
- ALU 运算：    加法
- 写内存 / 掩码： 不写
- WBSel：不写
- CSRWen：
- CSRSel：
- Kill： 立即杀, 取值流水线寄存器塞入nop

## csrw
- PCSel pc +4
- ImmSel：未定义
- RegWEn：0, 不写回
- BrUn：
- ASel：未定义, 不进行alu运算
- BSel：未定义, 不进行alu运算
- ALU 运算： 未定义
- 写内存 / 掩码：未定义
- WBSel：未定义
- CSRWen：1, 立即写回(除了csrw其他都是0, 不许写回)
- CSRSel：0, 选用寄存器
- Kill： 不杀

## csrwi
- PCSel：pc + 4
- ImmSel：未定义, 
- RegWEn：
- BrUn：
- ASel：
- BSel：
- ALU 运算：
- 写内存 / 掩码：
- WBSel：
- CSRWen：1, 立即写回
- CSRSel：1, 选用立即数
- Kill：不杀

---

## 规则 A：ALU 运算（R 型 / I 型）
用到哪些位来区分： func3 func7
- add：
- sub：
- sll / slli：
- slt / slti：
- xor / xori：
- srl / srli：
- sra / srai：
- or / ori：
- and / andi：
- mul：
- mulh：
- mulhu：
- I 型为什么不能看 inst[30]（除了……）和 inst[25]：

## 规则 B：分支成立条件（PCSel）
- beq：
- bne：
- blt：
- bge：
- bltu：
- bgeu：
- BrUn 由什么决定：指令类型, 是不是无符号比较

## 规则 C：load 提取
- 移位量：addi[1:0] * 8, 
- lb：
- lh：
- lw：

## 规则 D：store 对齐与写掩码
- WRITE_DATA 怎么得到：将alu_result移位, addi[1:0] * 8,
- sb 掩码： 0001
- sh 掩码： 0011
- sw 掩码： 1111
- 非 store 指令的掩码： 0000

## 规则 E：CSR
- CSR 地址从哪来：指令直接提取出来的
- csrw 写入的数据： rs1
- csrwi 写入的数据：指令中立即数扩展
- 写使能条件（csr.circ 内部）：地址一样并且有写使能信号, 因为我们的cpu只有一个控制状态寄存器

## 规则 F：Kill 与下一个 PC
- Kill 等于什么： nop指令塞取值流水线寄存器
- 被 kill 的那一拍，IF 取的是哪条指令：pc + 4
- jal/jalr 的返回地址从哪来（方案 B 的理由）：if 阶段的pc, 省一个加法器, 刚好是执行阶段pc的下一条指令地址
