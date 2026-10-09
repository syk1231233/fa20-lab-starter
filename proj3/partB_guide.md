# Proj3 Part B 指南（官方文档要点 + 学习引导）

> 官方事实用普通文字写出；🤔 标记的是需要你自己想清楚的问题，答案不给出。

---

## 0. 硬性规则（违反会直接挂测试）

- **不要移动、增删 cpu.circ 的输入/输出引脚**，否则子电路外形变化，测试框架接不上。
- **不要把 mem.circ 放进 CPU**，内存已经在 test_harness.circ 里接到了 CPU 的输出上。
- **不要新建 .circ 文件**。评分只用 `branch_comp.circ`、`control_logic.circ`、`cpu.circ`、`imm_gen.circ`、`csr.circ`；你的 `alu.circ` 和 `regfile.circ` 会被替换成官方答案，所以 CPU 里别用你在这两个文件里自建的子电路。
- 子电路要改就去改各自的 .circ 文件，不要改 cpu.circ 里的副本；改完后要关掉 cpu.circ 再重新打开，才会加载新版本。
- control_logic 可以加端口，但**不能改或删现有端口**（加端口有可能弄乱外形，官方不推荐；需要额外逻辑时，建议在 cpu.circ 里建子电路）。
- **允许使用的库**：
  - Wiring（但晶体管、传输门、POR、上拉电阻、Power、Ground、Do not connect 不能用）
  - Gates
  - Plexers
  - Arithmetic（不能用 Divider）
  - Memory（不能用 RAM、Random Generator；**ROM 可以用**）
- **Splitter 不能有映射到 0 个位的输出端**，否则 autograder 会运行失败。
- **只实现对齐访存**，不要实现非对齐访问（那需要 stall，会导致输出和参考对不上）。
- **不要在 IF 阶段计算分支目标**。测试每拍都会和参考对比，参考在这个时刻输出的是 nop。

---

## 1. 必须支持的指令

### R 型（opcode = 0x33）
| 指令 | funct3 | funct7 | 操作 |
|---|---|---|---|
| add | 0x0 | 0x00 | rd = rs1 + rs2 |
| mul | 0x0 | 0x01 | rd = (rs1 * rs2)[31:0] |
| sub | 0x0 | 0x20 | rd = rs1 - rs2 |
| sll | 0x1 | 0x00 | rd = rs1 << rs2 |
| mulh | 0x1 | 0x01 | rd = (rs1 * rs2)[63:32]（有符号） |
| mulhu | 0x3 | 0x01 | rd = (rs1 * rs2)[63:32]（无符号） |
| slt | 0x2 | 0x00 | rd = (rs1 < rs2) ? 1 : 0（有符号） |
| xor | 0x4 | 0x00 | rd = rs1 ^ rs2 |
| srl | 0x5 | 0x00 | rd = rs1 >> rs2（逻辑） |
| sra | 0x5 | 0x20 | rd = rs1 >> rs2（算术） |
| or | 0x6 | 0x00 | rd = rs1 \| rs2 |
| and | 0x7 | 0x00 | rd = rs1 & rs2 |

### I 型 load（opcode = 0x03）
| 指令 | funct3 | 操作 |
|---|---|---|
| lb | 0x0 | rd = SignExt(Mem[rs1+offset] 的 1 字节) |
| lh | 0x1 | rd = SignExt(Mem[rs1+offset] 的半字) |
| lw | 0x2 | rd = Mem[rs1+offset] 的一个字 |

### I 型算术（opcode = 0x13）
| 指令 | funct3 | imm[11:5] | 操作 |
|---|---|---|---|
| addi | 0x0 | | rd = rs1 + imm |
| slli | 0x1 | 0x00 | rd = rs1 << imm |
| slti | 0x2 | | rd = (rs1 < imm) ? 1 : 0 |
| xori | 0x4 | | rd = rs1 ^ imm |
| srli | 0x5 | 0x00 | rd = rs1 >> imm（逻辑） |
| srai | 0x5 | 0x20 | rd = rs1 >> imm（算术） |
| ori | 0x6 | | rd = rs1 \| imm |
| andi | 0x7 | | rd = rs1 & imm |

### S 型 store（opcode = 0x23）
| 指令 | funct3 | 操作 |
|---|---|---|
| sb | 0x0 | Mem[rs1+offset] = rs2[7:0] |
| sh | 0x1 | Mem[rs1+offset] = rs2[15:0] |
| sw | 0x2 | Mem[rs1+offset] = rs2 |

### SB 型分支（opcode = 0x63）：条件成立时 PC = PC + {offset, 1'b0}
| 指令 | funct3 | 条件 |
|---|---|---|
| beq | 0x0 | rs1 == rs2 |
| bne | 0x1 | rs1 != rs2 |
| blt | 0x4 | rs1 < rs2（有符号） |
| bge | 0x5 | rs1 >= rs2（有符号） |
| bltu | 0x6 | rs1 < rs2（无符号） |
| bgeu | 0x7 | rs1 >= rs2（无符号） |

### U / UJ / jalr
| 指令 | 类型 | opcode | funct3 | 操作 |
|---|---|---|---|---|
| auipc | U | 0x17 | | rd = PC + {offset, 12'b0} |
| lui | U | 0x37 | | rd = {offset, 12'b0} |
| jal | UJ | 0x6f | | rd = PC + 4；PC = PC + {imm, 1'b0} |
| jalr | I | 0x67 | 0x0 | rd = PC + 4；PC = rs1 + imm |

### CSR（opcode = 0x73）
| 指令 | funct3 | 操作 |
|---|---|---|
| csrw csr, rs1（即 csrrw x0, csr, rs1） | 0x1 | CSR[csr] = rs1 |
| csrwi csr, uimm（即 csrrwi x0, csr, uimm） | 0x5 | CSR[csr] = {27'b0, uimm} |

- 只会用到一个 CSR：**tohost = 0x51E**。
- uimm 是 5 位零扩展立即数，编码在 **rs1 字段**里。
- Venus 不支持 CSR，所以没法为这两条指令生成自定义测试，只能靠 `part_b pipelined` 里的 csrw/csrwi 测试。

---

## 2. 指令格式和立即数

### 字段位置
```
         31        25 24   20 19   15 14  12 11       7 6      0
R 型   [  funct7    |  rs2  |  rs1  | f3   |    rd     | opcode ]
I 型   [      imm[11:0]     |  rs1  | f3   |    rd     | opcode ]
S 型   [  imm[11:5] |  rs2  |  rs1  | f3   | imm[4:0]  | opcode ]
B 型   [imm[12|10:5]|  rs2  |  rs1  | f3   |imm[4:1|11]| opcode ]
U 型   [           imm[31:12]              |    rd     | opcode ]
J 型   [     imm[20|10:1|11|19:12]         |    rd     | opcode ]
CSR    [   csr[11:0]        |rs1/uimm| f3  |    rd     | opcode ]
```

### 立即数拼接（从 imm_gen 输出的都是 32 位，并且做符号扩展）
| 类型 | imm 各位来自 inst 的哪些位 |
|---|---|
| I | imm[31:11] = inst[31]（符号扩展）；imm[10:0] = inst[30:20] |
| S | imm[31:11] = inst[31]；imm[10:5] = inst[30:25]；imm[4:0] = inst[11:7] |
| B | imm[31:12] = inst[31]；imm[11] = inst[7]；imm[10:5] = inst[30:25]；imm[4:1] = inst[11:8]；imm[0] = 0 |
| U | imm[31:12] = inst[31:12]；imm[11:0] = 0 |
| J | imm[31:20] = inst[31]；imm[19:12] = inst[19:12]；imm[11] = inst[20]；imm[10:1] = inst[30:21]；imm[0] = 0 |

imm_gen 接口：输入 `inst`（32 位）、`ImmSel`（3 位）；输出 `imm`（32 位）。ImmSel 的编码由你自己定。

🤔 哪些位在多种格式里都来自同一个 inst 位？利用这一点可以减少 mux 的数量（设计竞赛加分）。
🤔 B 型和 J 型的 imm[0] = 0，在电路里怎么产生这个 0？（提示：不需要任何门）

---

## 3. ALUSel 编码（根据你 alu.circ 里的 tunnel 名推出）

| ALUSel | 操作 | ALUSel | 操作 |
|---|---|---|---|
| 0 | add | 7 | slt |
| 1 | and | 10 | mul |
| 2 | or | 11 | mulhu |
| 3 | xor | 12 | sub |
| 4 | srl | 13 | **bsel**（直接输出 B） |
| 5 | sra | 14 | mulh |
| 6 | sll | | |

🤔 lui 要怎么用上 bsel？
🤔 R 型的 funct3 和这张表的编码，有没有直接对应的关系？（对比 add、sll、slt、xor、srl、or、and 的 funct3 看看）

---

## 4. 各子电路的接口

### 内存（已实现，在 test harness 里，**不要放进 CPU**）
| 信号 | CPU 侧引脚 | 方向 | 位宽 | 说明 |
|---|---|---|---|---|
| WriteAddr | `WRITE_ADDRESS`（输出） | 输入到内存 | 32 | 读和写共用这个地址 |
| WriteData | `WRITE_DATA`（输出） | 输入到内存 | 32 | 要写入的数据 |
| Write_En | `WRITE_ENABLE`（输出） | 输入到内存 | 4 | **字节写掩码**；不写内存的指令必须是 0 |
| ReadData | `READ_DATA`（输入） | 内存输出 | 32 | 地址对应的整个字，与 Write_En 无关 |

- 你给的是**字节地址**，但内存会**忽略最低 2 位**，按字地址处理。例如给 `0x1007`，读到的是 `0x1004`~`0x1007` 这 4 个字节。
- 例：Write_En = `4'b1000` 时，只覆盖该字的最高字节。

🤔 lb 读地址 `0x1003` 时，你要的字节在 READ_DATA 的哪 8 位？addr[1:0] 分别等于 0、1、2、3 时呢？lh 的情况呢？
🤔 sb 写地址 `0x1002` 时，Write_En 应该是多少？rs2[7:0] 要放到 WRITE_DATA 的哪个字节上？
🤔 “移 addr[1:0] × 8 位”可以用拆分器拼出移位量，不需要乘法器。

### Branch Comparator（branch_comp.circ，你来实现）
| 信号 | 方向 | 位宽 | 说明 |
|---|---|---|---|
| rs1 | 输入 | 32 | |
| rs2 | 输入 | 32 | |
| BrUn | 输入 | 1 | 1 表示无符号比较，0 表示有符号比较 |
| BrEq | 输出 | 1 | rs1 == rs2 |
| BrLt | 输出 | 1 | rs1 < rs2 |

### CSR（csr.circ，你来实现 tohost 寄存器和写逻辑；**不要动已有的连接**）
| 信号 | 方向 | 位宽 | 说明 |
|---|---|---|---|
| CSR_address | 输入 | 12 | CSR 地址 |
| CSR_din | 输入 | 32 | 要写入的值 |
| CSR_WE | 输入 | 1 | 写使能 |
| clk | 输入 | 1 | |
| tohost | 输出 | 32 | tohost 寄存器的值 |

### Control Logic（control_logic.circ）
- 输入：`inst`、`BrEq`、`BrLt`
- 输出：`PCSel`、`RegWEn`、`ImmSel`(3)、`BrUn`、`ASel`、`BSel`、`ALUSel`(4)、`MemRW`、`WBSel`(2)、`CSRSel`、`CSRWen`

端口不必全部用上，也可以添加端口，但**不能改或删已有端口**。

两种实现方式：
- **硬连线**（官方推荐）：用与、或、非门以及 mux/demux，直接从指令算出各控制信号。
- **ROM**：先把指令映射成一个地址，再从 ROM 的这个地址读出控制字。

---

## 5. 流水线与 Kill（控制冒险）

- 两级流水线：**IF**（取指）和 **EX**（译码、执行、访存、写回）。所有控制都在 EX 里完成。
- 分支要到 EX 才判断出来，这时 IF 已经取出了下一条指令（可能是错的）。
- **规则**：
  - EX 里是**任何跳转**（jal/jalr）或**成立的分支**时，要 kill 正在取的那条指令。
  - 分支不成立时**不要** kill。
- **kill 必须这样实现**：用 mux 往指令流里塞一个 nop，送进 EX 阶段，代替取到的那条指令。nop 可以用 `0x00000013`（addi x0, x0, 0），其他 nop 也行。
- 复位时 Logisim 把寄存器清零，所以第一拍指令寄存器里是 0，可以把它当 nop 用。复位方法：Simulate → Reset Simulation（Ctrl/Cmd+R）。

官方让你思考的问题：
1. 🤔 IF 和 EX 的 PC 值一样吗？
2. 🤔 需要在两级之间存 PC 吗？哪些指令会用到 EX 阶段的 PC？
3. 🤔 塞 nop 的 mux 放在指令寄存器**之前**还是**之后**？
4. 🤔 EX 在执行一条被注入的 nop 时，下一个应该请求哪个地址？和平时有区别吗？

---

## 6. 任务路线（按指令驱动，一次加一类）

**核心原则：** 每个任务只加“这一类指令需要的”数据通路和控制信号。做完一个任务就跑测试，测试通过了再进入下一个。
control_logic 也是逐步长出来的：每个任务只往里加一种 opcode 的处理。还没加到的 opcode 先输出全 0，也就是不写寄存器、不写内存、不跳转。

当前进度：二级流水线 ✅、branch_comp ✅、imm_gen ✅（ImmSel 编码：I=0、S=1、B=2、U=3、J=4）、**control_logic ✅（全部指令，已用 628 组测试向量验证）**

> control_logic 已经一次性实现完毕，后面每个任务的“控制”部分**只需要对照理解，不用再动手**，只搭数据通路即可。
> 实现方式是 ROM 控制，共 3 个 ROM：
> - 主译码 ROM：地址 {funct3, opcode[6:2]}，输出一个控制字；
> - ALUSel ROM：地址 {aluMode, inst[25], inst[30], funct3}；
> - PCSel ROM：地址 {isJump, isBranch, BrLt, BrEq, funct3}。
>
> 搭数据通路时，mux 的输入顺序必须符合下面的约定：
>
> | 信号 | 0 | 1 | 2 |
> |---|---|---|---|
> | PCSel | PC_IF+4 | ALU 结果 | |
> | ASel | rs1 | EX_PC | |
> | BSel | rs2 | imm | |
> | WBSel | 内存（load 提取后） | ALU 结果 | EX_PC+4 |
> | CSRSel | rs1 | uimm（inst[19:15] 零扩展） | |
> | MemRW | 不写 | store（写掩码由数据通路按 funct3 和地址生成） | |
> | BrUn | 有符号 | 无符号（= funct3[1]） | |
>
> kill 直接用 PCSel。CSRWen 只在 csrw/csrwi 时为 1。

每个任务都按同一套流程走：
1. 用这类指令在数据通路上走一遍，看缺什么（mux？连线？），补上。
2. 在 control_logic 里加上这类指令的译码，把控制信号表里对应的那一行填好。
3. 在 `tests/part_b/custom/inputs/<名字>.s` 写一个自定义测试，再跑相关的 sanity 测试。

---

### 6.0 控制逻辑的搭法（先读这一节）

不要把整条指令都当作真值表的输入去映射。推荐**两级译码**，也就是课上讲的硬连线控制：

**第一级：opcode → one-hot 指令类型线**

- RV32I 里所有 opcode 的最低两位都是 `11`，所以只看 **opcode[6:2]** 这 5 位就够了。
- 把它接到 Plexers 库里的 **Decoder**（选择位宽设为 5），会得到 32 根输出线。在任一时刻，**只有一根是 1**。
- 只取你需要的那几根，给它们起名接 tunnel：

| 类型线 | opcode | opcode[6:2] |
|---|---|---|
| isR | 0110011 | 01100 = 12 |
| isI（算术） | 0010011 | 00100 = 4 |
| isLoad | 0000011 | 00000 = 0 |
| isStore | 0100011 | 01000 = 8 |
| isBranch | 1100011 | 11000 = 24 |
| isJal | 1101111 | 11011 = 27 |
| isJalr | 1100111 | 11001 = 25 |
| isLui | 0110111 | 01101 = 13 |
| isAuipc | 0010111 | 00101 = 5 |
| isCSR | 1110011 | 11100 = 28 |

> nop（0x13）会落在 isI 上，执行的是 addi x0, x0, 0，结果无害。复位时的 0x00000000 会落在 isLoad 上，变成 lb x0, 0(x0)：它会读内存，但写的是 x0，所以也无害。

**第二级：每个控制信号 = 若干类型线的组合**

1 位的信号直接用一个 **OR 门**，把“这个信号要为 1 的那些类型”或起来。例如：
```
RegWEn = isR | isI | isLoad | isLui | isAuipc | isJal | isJalr
```
每做完一个任务，就往相应的 OR 门上多接一根线，正好符合逐步推进的节奏。

多位的信号：
- **ImmSel / WBSel**：用 OR 门把类型线编码成二进制，每一位单独一个 OR 门。也可以用 Plexers 库里的 **Priority Encoder**。
- **ALUSel**：只有 R 型和 I 型算术需要看 funct3/funct7。其他类型都是固定值：大多数是 add，lui 是 bsel。可以这样做：
  - 先用一个小 **ROM**：地址取 `{inst[25], inst[30], funct3}`，一共 5 位、32 项，数据就是 ALUSel。
  - 再用 mux 选择：(isR | isI) 时用 ROM 的输出，isLui 时用 13，其余用 0。
  - 🤔 I 型算术里，只有 funct3=101 时才应该看 inst[30]，而且 I 型永远不能看 inst[25]。你怎么在送进 ROM 之前把这两位“屏蔽”掉？
- **PCSel**：做一个 8 选 1 mux，选择端接 funct3，8 个输入分别是 BrEq、!BrEq、BrLt、!BrLt 这些。mux 的输出再和 isBranch 相与，最后或上 isJal | isJalr。

**还有两种可选的做法：**
- **ROM 控制**：先把指令压缩成一个小地址，比如 opcode[6:2] 加 funct3，一共 8 位。然后用 Python 脚本生成整张控制字表，导入 ROM（右键 ROM → Load Image，文件格式是 `v3.0 hex words plain`）。好处是改一个信号只要重新生成表；缺点是设计竞赛里门数比较多。
- **Logisim 自动生成**：菜单 Project → Analyze Circuit（组合逻辑分析），定义输入输出、填真值表或者写表达式，然后点 Build Circuit，Logisim 会自动搭出门电路。适合输入少于 8 位的小信号，比如 PCSel、BrUn。生成的电路要放在 control_logic.circ 里面，不要新建 .circ 文件。

---

### 任务 0：修好 addi（回归测试）✅
- **数据通路**：EX 阶段的译码 splitter、imm_gen、control_logic 都改成读 `EX_INSTRUCTION`。
- **控制**：搭好上面说的第一级 Decoder，先只用 isI 这一根线：RegWEn = isI，ImmSel = I，ALUSel = add。
- **验收**：`python3 test_runner.py part_b pipelined` 中 **addi** 通过。

---

### 任务 1：I 型算术（opcode = `0010011` = 0x13）

**格式**
```
 31                 20 19   15 14  12 11    7 6       0
[     imm[11:0]       |  rs1  |funct3|  rd   | 0010011 ]
```
移位类指令（slli/srli/srai）的 imm 字段要拆开看：
```
 31     25 24   20
[ funct7  | shamt ]     shamt = 移位量，只用低 5 位
```

**指令和效果**
| 指令 | funct3 | inst[31:25] | 效果 | ALU 操作 |
|---|---|---|---|---|
| addi rd, rs1, imm | 000 | — | rd = rs1 + imm | add |
| slli rd, rs1, sh | 001 | 0000000 | rd = rs1 << sh | sll |
| slti rd, rs1, imm | 010 | — | rd = (rs1 < imm) ? 1 : 0（有符号） | slt |
| xori rd, rs1, imm | 100 | — | rd = rs1 ^ imm | xor |
| srli rd, rs1, sh | 101 | 0000000 | rd = rs1 >> sh（逻辑右移，高位补 0） | srl |
| srai rd, rs1, sh | 101 | **0100000** | rd = rs1 >> sh（算术右移，高位补符号位） | sra |
| ori rd, rs1, imm | 110 | — | rd = rs1 \| imm | or |
| andi rd, rs1, imm | 111 | — | rd = rs1 & imm | and |

例子：`addi t0, x0, -1` 编码为 `0xfff00293`，执行后 t0 = 0xffffffff。

- **数据通路**：不用改。A 接 rs1，B 接 imm（I 型立即数，符号扩展），结果写回 rd。
- **控制**：
  - ALUSel 由 funct3 决定。去对比 funct3 和第 3 节的 ALUSel 编码表，看看两者是什么关系，适合用 ROM 还是用 mux。
  - 🤔 funct3=001 和 101 时 inst[30] 有意义。其他 funct3 时，inst[30] 是立即数的一部分，为什么**不能**看它？例如 `addi t0, x0, -1` 的 inst[30]=1。
- **验收**：自定义测试 `i-type.s`。每条指令都要测，包括 imm 为负数、srai 移负数这些情况。

---

### 任务 2：R 型（opcode = `0110011` = 0x33）

**格式**
```
 31     25 24   20 19   15 14  12 11    7 6       0
[ funct7  |  rs2  |  rs1  |funct3|  rd   | 0110011 ]
```

**指令和效果**
| 指令 | funct3 | funct7 | 效果 | ALU 操作 |
|---|---|---|---|---|
| add | 000 | 0000000 | rd = rs1 + rs2 | add |
| sub | 000 | **0100000** | rd = rs1 − rs2 | sub |
| mul | 000 | **0000001** | rd = (rs1 × rs2)[31:0] | mul |
| sll | 001 | 0000000 | rd = rs1 << rs2[4:0] | sll |
| mulh | 001 | 0000001 | rd = (rs1 × rs2)[63:32]（有符号） | mulh |
| slt | 010 | 0000000 | rd = (rs1 < rs2) ? 1 : 0（有符号） | slt |
| mulhu | 011 | 0000001 | rd = (rs1 × rs2)[63:32]（无符号） | mulhu |
| xor | 100 | 0000000 | rd = rs1 ^ rs2 | xor |
| srl | 101 | 0000000 | rd = rs1 >> rs2[4:0]（逻辑） | srl |
| sra | 101 | 0100000 | rd = rs1 >> rs2[4:0]（算术） | sra |
| or | 110 | 0000000 | rd = rs1 \| rs2 | or |
| and | 111 | 0000000 | rd = rs1 & rs2 | and |

观察一下：funct7 只有三种取值。0x00 是普通运算；0x20 只用于 sub 和 sra，此时 inst[30]=1；0x01 是乘法类，此时 inst[25]=1。所以只要看 inst[30] 和 inst[25] 这两位就够了。

- **数据通路**：
  - 译码 splitter 加拆 **rs2_index**（inst[24:20]），接到 regfile。
  - ALU 的 B 输入前面加 **BSel mux**：在 rs2 和 imm 之间选。
- **控制**：
  - 把 isR 加进 RegWEn 的 OR 门。
  - BSel：isR 时选 rs2，其他类型都选 imm。🤔 那么 BSel 只需要用哪一根类型线？
  - ALUSel：在任务 1 的基础上，R 型要多看 inst[30] 和 inst[25]。
- **验收**：自定义测试 `r-type.s`。slt 要测 <、>、== 三种情况；sra 要测负数；mulh 和 mulhu 要测负数相乘。

---

### 任务 3：U 型（lui、auipc）

**格式**
```
 31                          12 11    7 6       0
[         imm[31:12]           |  rd   | opcode  ]
```

**指令和效果**
| 指令 | opcode | 效果 |
|---|---|---|
| lui rd, imm | 0110111 (0x37) | rd = imm << 12（低 12 位补 0） |
| auipc rd, imm | 0010111 (0x17) | rd = **PC** + (imm << 12) |

例子：`lui t0, 0x12345` 执行后 t0 = 0x12345000。

- **数据通路**：ALU 的 A 输入前面加 **ASel mux**：在 rs1 和 `EX_PROGRAM_COUNTER` 之间选。
  - 🤔 为什么必须用 EX 阶段的 PC？
- **控制**：
  - lui：ImmSel = U，BSel = imm，ALUSel = bsel（13），因为 imm_gen 的 U 型输出就已经是最终结果。
  - auipc：ImmSel = U，ASel = PC，BSel = imm，ALUSel = add。
  - 两者都要 RegWEn = 1。
- **验收**：sanity 测试 **add-lui-sll** 通过；另外写一个 `auipc.s` 自测。

---

### 任务 4：lw、sw（先只做整字）

**Load 格式**（和 I 型一样，opcode = `0000011` = 0x03）
```
[     imm[11:0]       |  rs1  |funct3|  rd   | 0000011 ]
```
**Store 格式**（S 型，opcode = `0100011` = 0x23）
```
 31     25 24   20 19   15 14  12 11    7 6       0
[imm[11:5]|  rs2  |  rs1  |funct3|imm[4:0]| 0100011 ]
```
S 型没有 rd 字段，这几位用来放立即数，所以 store 指令不写寄存器。

**指令和效果**
| 指令 | funct3 | 效果 |
|---|---|---|
| lw rd, off(rs1) | 010 | rd = Mem[rs1+off] 的 4 个字节 |
| sw rs2, off(rs1) | 010 | Mem[rs1+off] 的 4 个字节 = rs2 |

**内存接口**（内存已在 test harness 里实现好，**不要把 mem.circ 放进 CPU**）
| CPU 引脚 | 方向 | 位宽 | 含义 |
|---|---|---|---|
| WRITE_ADDRESS | 输出 | 32 | 读和写共用的字节地址。内存会忽略低 2 位 |
| WRITE_DATA | 输出 | 32 | 要写入的数据 |
| WRITE_ENABLE | 输出 | 4 | 字节写掩码。例如 1000 表示只写最高字节；不写内存时必须是 0000 |
| READ_DATA | 输入 | 32 | 地址所在那个字的 4 个字节，与写掩码无关 |

- **数据通路**：
  - WRITE_ADDRESS 接 ALU 结果（rs1+imm），WRITE_DATA 接 rs2，WRITE_ENABLE 接写掩码。
  - 写回 rd 前面加 **WBSel mux**：在 ALU 结果和 READ_DATA 之间选。这里直接用 2 位选择端（4 个输入）的 mux，给任务 7 留出位置。
- **控制**：
  - lw：ImmSel = I，BSel = imm，ALUSel = add，WBSel = mem，RegWEn = 1。
  - sw：ImmSel = S，BSel = imm，ALUSel = add，写掩码 = 1111，RegWEn = 0。
  - 其他所有指令：写掩码 = 0000。
- **验收**：sanity 测试 **mem** 通过。

---

### 任务 5：lb、lh、sb、sh（字节和半字）

**指令和效果**
| 指令 | funct3 | 效果 |
|---|---|---|
| lb rd, off(rs1) | 000 | rd = 符号扩展( Mem[rs1+off] 的 1 个字节 ) |
| lh rd, off(rs1) | 001 | rd = 符号扩展( Mem[rs1+off] 的 2 个字节 ) |
| sb rs2, off(rs1) | 000 | Mem[rs1+off] 的 1 字节 = rs2[7:0] |
| sh rs2, off(rs1) | 001 | Mem[rs1+off] 的 2 字节 = rs2[15:0] |

只要求实现**对齐访问**：lh/sh 的地址是 2 的倍数，lw/sw 是 4 的倍数。不要实现非对齐访问。

例子：t0 = 0x1000 时，`sb t1, 2(t0)` 的地址是 0x1002。这一次只改动 0x1000 那个字里的 bit[23:16]，所以写掩码是 0100，WRITE_DATA 的 bit[23:16] 要放 t1[7:0]。

- **数据通路**：
  - 在 READ_DATA 和 WBSel 之间加一个“load 提取”电路：按 addr[1:0] 把对应的字节或半字移到最低位，再按 funct3 做符号扩展。
  - 在 rs2 和 WRITE_DATA 之间加一个“store 对齐”电路：把 rs2 左移 addr[1:0] × 8 位，写掩码也相应左移 addr[1:0] 位。sb 的基础掩码是 0001，sh 是 0011，sw 是 1111。
  - 🤔 “× 8”不需要乘法器。用 splitter 在 addr[1:0] 后面拼 3 个 0，就得到了移位量。
- **验收**：自定义测试 `mem-byte.s`：
  - 地址低 2 位分别取 0、1、2、3；
  - lb/lh 读负数，检查符号扩展；
  - 写完马上 lw，检查相邻字节没被破坏。

---

### 任务 6：分支 + kill（B 型，opcode = `1100011` = 0x63）

**格式**
```
 31   30     25 24   20 19   15 14  12 11    8   7    6       0
[i12| i[10:5]  |  rs2  |  rs1  |funct3| i[4:1] |i11 | 1100011 ]
```
imm 是 13 位，最低位固定为 0，跳转范围是 ±4KB。

**指令和效果**
| 指令 | funct3 | 跳转条件 |
|---|---|---|
| beq | 000 | rs1 == rs2 |
| bne | 001 | rs1 != rs2 |
| blt | 100 | rs1 < rs2（有符号） |
| bge | 101 | rs1 ≥ rs2（有符号） |
| bltu | 110 | rs1 < rs2（无符号） |
| bgeu | 111 | rs1 ≥ rs2（无符号） |

- 条件成立：PC = **EX_PC** + imm，并且 **kill** 掉 IF 阶段已经取到的那条指令。
- 条件不成立：照常 PC + 4，不 kill。
- 分支指令不写寄存器。

**Kill 规则**（官方要求）
- kill 必须这样实现：用 mux 把一条 nop（0x00000013）塞进指令流，送进 EX 阶段。
- 所有跳转都要 kill；分支只在成立时 kill；**不要在 IF 阶段计算分支目标**。
- 原理和逐拍时序见第 5 节。

- **数据通路**：
  - branch_comp 的输入接 rs1、rs2 的值，BrUn 接 control_logic 的输出；BrEq、BrLt 接回 control_logic 的输入。
  - 下一 PC 前面加 **PCSel mux**：在 `PC_IF + 4` 和 ALU 结果之间选。
  - 指令寄存器前面加 **kill mux**：在 INSTRUCTION 和 0x00000013 之间选。它放在你那个 64 位合并 splitter 的 INSTRUCTION 输入之前。
- **控制**：
  - 分支：ImmSel = B，ASel = PC，BSel = imm，ALUSel = add，RegWEn = 0。
  - BrUn：🤔 bltu/bgeu 的 funct3 有什么共同点？
  - PCSel = 分支成立，按 6.0 节的做法用 8 选 1 mux 实现。🤔 把 6 种分支各自的成立条件写成 BrEq、BrLt 的式子。
  - kill = PCSel。
- **验收**：sanity 测试 **branch** 通过。另外自测分支不成立、向后跳这两种情况。

---

### 任务 7：jal、jalr

**jal 格式**（J 型，opcode = `1101111` = 0x6f）
```
 31   30        21  20  19       12 11    7 6       0
[i20|  i[10:1]    |i11|  i[19:12]  |  rd   | 1101111 ]
```
**jalr 格式**（和 I 型一样，opcode = `1100111` = 0x67，funct3 = 000）
```
[     imm[11:0]       |  rs1  | 000  |  rd   | 1100111 ]
```

**指令和效果**
| 指令 | 效果 |
|---|---|
| jal rd, imm | rd = PC + 4；PC = PC + imm（两处的 PC 都是 EX_PC） |
| jalr rd, rs1, imm | rd = PC + 4；PC = **rs1** + imm |

这两条指令**一定会跳**，所以都必须 kill。

伪指令：
- `j label` 等于 `jal x0, label`
- `jr rs` 等于 `jalr x0, 0(rs)`
- `ret` 等于 `jalr x0, 0(ra)`

- **数据通路**：WBSel mux 加第三个输入 `EX_PROGRAM_COUNTER + 4`。
  - 🤔 为什么是 EX 的 PC，而不是 IF 的 PC？
- **控制**：
  - jal：ImmSel = J，ASel = PC，BSel = imm，ALUSel = add，PCSel = 1，WBSel = PC+4，RegWEn = 1。
  - jalr：ImmSel = I，ASel = rs1，其余和 jal 相同。
- **验收**：sanity 测试 **jump** 和 **branch-jump** 通过。另外自测 jalr 的 rd == rs1 的情况，例如 `jalr ra, 0(ra)`。

---

### 任务 8：CSR（opcode = `1110011` = 0x73）

**格式**
```
 31                 20 19   15 14  12 11    7 6       0
[     csr[11:0]       |rs1/uimm|funct3|  rd   | 1110011 ]
```

**指令和效果**
| 指令 | funct3 | 效果 |
|---|---|---|
| csrw csr, rs1 | 001 | CSR[csr] = rs1 的值 |
| csrwi csr, uimm | 101 | CSR[csr] = 零扩展(uimm)。uimm 就是 inst[19:15] 这 5 位本身，不是寄存器编号 |

- 只会用到 csr = 0x51E（tohost）。
- rd 都是 x0，所以不用写寄存器。
- 例子：`csrwi tohost, 1` 执行后 tohost = 1。

**csr.circ 接口**（不要动已有的连接）
| 信号 | 方向 | 位宽 |
|---|---|---|
| CSR_address | 输入 | 12 |
| CSR_din | 输入 | 32 |
| CSR_WE | 输入 | 1 |
| clk | 输入 | 1 |
| tohost | 输出 | 32 |

- **数据通路**：
  - 在 csr.circ 里实现一个 32 位的 tohost 寄存器：CSR_WE = 1 并且 CSR_address == 0x51E 时写入。
  - 在 cpu.circ 里接 csr：地址接 inst[31:20]；CSR_din 前面加 **CSRSel mux**，在 rs1 的值和零扩展的 uimm 之间选。
- **控制**：isCSR 时 CSRWen = 1；CSRSel 由 funct3 决定（001 选 rs1，101 选 uimm）；RegWEn = 0。
- **验收**：sanity 测试 **csrw**、**csrwi** 通过。Venus 不支持 CSR，所以没法写这两条指令的自定义测试，只能靠 sanity 测试。

---

### 任务 9：收尾
- 补齐自定义测试，提高覆盖率。每条指令单独一个 .s 文件，再加几个 `mem-full`、`br-jump-edge` 风格的边界测试，例如：
  - 连续跳转；
  - 跳转后紧跟一条写寄存器的指令（验证 kill）；
  - jalr 的 rd == rs1。
- 写 README.md。
- 可选：设计竞赛优化。

---

### 控制信号总表（每完成一个任务，填好对应那一行；可以放在 log.md 里）



| 指令类 | PCSel | ImmSel | RegWEn | BrUn | ASel | BSel | ALUSel | Write_En | WBSel | CSRWen | CSRSel | Kill |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| R |选取pc+4|无关，不使用立即数刘姝 | | | | | | | | |
| I 算术 | | | | | | | | | | | | |
| lui | | | | | | | | | | | | |
| auipc | | | | | | | | | | | | |
| load | | | | | | | | | | | | |
| store | | | | | | | | | | | | |
| branch | | | | | | | | | | | | |
| jal | | | | | | | | | | | | |
| jalr | | | | | | | | | | | | |
| csrw / csrwi | | | | | | | | | | | | |

---

## 7. 测试

### 官方健全性测试
```
python3 test_runner.py part_b pipelined
```
包含的测试：addi、add-lui-sll、branch、jump、branch-jump、mem、csrw、csrwi。
汇编源码和 hex 在 `tests/part_b/pipelined/inputs/`。

### 查看输出
```
cd tests/part_b/pipelined
python3 binary_to_hex_cpu.py student_output/<文件>
python3 binary_to_hex_cpu.py reference_output/<文件>
```

### 自定义测试（覆盖率占 10% 的分数）
1. 在 `tests/part_b/custom/inputs/` 下写 `xxx.s`，每条指令单独一个文件最好。
2. 生成测试：
   ```
   cd tests/part_b/custom
   python3 create-test.py inputs/xxx.s inputs/yyy.s
   ```
   （只想模拟 N 个周期时，加参数 `-n N`）
3. 运行：
   ```
   python3 test_runner.py part_b custom
   ```
4. 单步调试：打开生成的 .circ 文件，右键 CPU → View main，然后用 Ctrl/Cmd+T 逐拍推进时钟。

### 测试注意事项
- 有**两拍延迟**：例如只有一条 `addi t0, x0, 1` 时，t0 要到第 3 拍才变化。
- 只检查这几个寄存器：**x0、ra、sp、t0、t1、t2、s0、s1、a0**。结果要累积到它们里面。
- 不要写“哑测试”：不改变任何状态的测试没有意义。
- 单元测试要覆盖各种情况。例如 slt 要测 `<`、`>`、`==` 三种。
- 每条指令都要测，包括 sanity 测试里已经覆盖的；所有寄存器都要用到。
- **隐藏测试**里有 `mem-full` 和 `br-jump-edge` 这类边界测试。你应该自己想到的情况：
  - 访存：lb/lh 读负数；地址低 2 位为 0~3；sb/sh 后马上 lw 检查其他字节没被破坏。
  - 跳转：连续跳转；跳转后紧跟一条会写寄存器的指令（验证 kill）；jalr 的 rd == rs1；向后跳的分支；分支不成立。
- 调试方法：逐拍对比学生输出和参考输出，找到**第一拍**出现差异的地方，看那一拍 EX 阶段执行的是哪条指令。

---

## 8. 提交与评分

- 在 README.md 里写清楚实现思路，尤其是控制逻辑的设计理由；如果有搭档，还要写分工。
- 提交前检查：引脚没有移动过、没有多余的 .circ 文件、自定义 .s 文件放在正确的目录。
- 评分：
  - Part A 20%：ALU 8%、RegFile 8%、流水线 addi 4%
  - Part B 80%：sanity 和可见单元测试 20%、测试覆盖率 10%、隐藏测试 50%
- FAQ：如果 autograder 说你的 CPU 是单周期的，通常是 Logisim 打开你的电路时崩溃了，一般是导入问题（用了不该用的子电路，或者文件位置不对）。

### 设计竞赛（可选，需要通过 100% 的测试才有资格）
- **门等效分** = 2×NOT + 2×NAND2 + 8×FF，越低越好。

  | 元件 | NAND2 | NOT | FF |
  |---|---|---|---|
  | 2 输入 AND | 1 | 1 | 0 |
  | 2 输入 OR | 1 | 2 | 0 |
  | 32 位加法器 | 366 | 195 | 0 |
  | 32 位减法器 | 456 | 255 | 0 |
  | 32 位比较器 | 222 | 127 | 0 |
  | 32 位乘法器 | 10849 | 4467 | 0 |
  | 32 位移位器 | 418 | 36 | 0 |
  | 2 输入 32 位 MUX | 128 | 33 | 0 |
  | ROM（每个非零项） | 5.8 | 4.6 | 0 |
  | 32 位寄存器 | 97 | 1 | 32 |

- **最长路径分**：任意两个触发器之间的最长组合逻辑路径，越短越好。
- 优化技巧：
  - 固定量的移位用拆分器实现，零成本。
  - 主要的节省来自控制逻辑的优化。
  - 计算结果尽量复用，不要重复计算。
  - 互相独立的计算放在不同路径上，不要全部串在一条路径里。
