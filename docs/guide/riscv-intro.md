## RISC-V架构介绍

### 寄存器说明

关于RISC-V 寄存器说明的详细内容，可以参阅 [RISC-V 指令集手册](http://riscvbook.com/chinese/RISC-V-Reader-Chinese-v2p1.pdf)。

我们的实验基于 RISC-V 64 位架构。与大家在计算机组成原理实验课中接触到的RISC-V 32位架构不同，在 RISC-V 64 架构中，寄存器和指针的宽度都是 64 位。

RISC-V 64 位架构总共有 32 个通用寄存器(General-purpose   register，简称GPR)和若干控制状态寄存器（Control Status Register，简称CSR） 。通用寄存器用于存储和操作通用数据,它们是处理器中用于执行各种计算和数据传输操作的主要寄存器。

CSR是一种特殊的寄存器，由处理器硬件定义和管理。它通常包含一组位字段（bits），每个位字段代表不同的状态或控制标志。这些位字段可以存储和读取处理器的运行状态、中断状态、特权级别、运行模式等信息。
CSR的具体功能和位字段的含义会因不同的处理器体系结构而异。RISC-V 架构中有一组约定的CSR，用于管理和控制处理器的运行状态，如以下示例：

    
- **sstatus**: 包含处理器的运行状态和特权级别信息。
    
- **sie**: 包含处理器中断使能的标志位。
    
- **scause**：用于存储最近的中断或异常原因。
    
- **sepc**：存储异常程序计数器，指向中断或异常处理程序的地址。

通过读取和写入CSR的位字段，软件可以查询和修改处理器的运行状态和控制标志。例如，通过将位字段设置为特定的值，可以启用或禁用中断，修改特权级别，触发异常处理等。在 RISC-V 架构中，只能使用控制状态寄存器指令（csrr、csrw 等）访问和修改 CSR。控制状态寄存器指令的使用与特权级相关，相关的内容将在后续的实验中介绍。

CSR在处理器的内部实现中起着重要的作用，它提供了一种机制来管理和控制处理器的行为。同时，CSR也是处理器与操作系统、编译器等软件之间的接口，用于进行状态传递和控制。

### 应用程序二进制接口

应用程序二进制接口（Application Binary interface，简称 ABI）定义了应用程序二进制代码中相关数据结构和函数模块的格式及其访问方式。这个约定是人为的，硬件上并不强制这些内容，自成体系的软件可以不遵循部分或者全部 ABI。为了和编译器以及其他的库配合，我们应该在写汇编代码时尽量遵循约定。ABI 包含但不限于以下内容：

    
- 处理器基础数据类型的大小。布局和对齐要求。
    
- 寄存器使用约定。约定通用寄存器的使用方法、别名等。
    
- 函数调用约定。约定参数调用、结果返回、栈的使用。
    
- 可执行文件格式。
    
- 系统调用约定。

下面主要介绍寄存器使用约定。

#### 通用寄存器使用约定

RISC-V 中的通用寄存器分为两类，一类在函数调用的过程中不保留，称为**临时寄存器**。另一类寄存器则对应地称为 **保存寄存器**。表罗列出了寄存器的 RISC-V 应用程序二进制接口（ABI）名称和它们在函数调用中是否保留的规定。除了保存寄存器之外，调用者需要保证用于存储返回地址的寄存器( ra )和存储栈指针的寄存器( sp )在函数调用前后保持不变。

简而言之，如果某次函数调用需要改变保存寄存器的值，就需要采用适当的措施在退出函数时恢复保存寄存器的值。在下一节中将结合相应的汇编代码对寄存器使用约定和函数调用约定做进一步的介绍。

| 寄存器编号 | 助记符 | 用途 | 在调用中是否保留 |
|------------|--------|------|------------------|
| x0         | zero   | Hard-wired zero  | ---              |
| x1         | ra     | Return address   | No               |
| x2         | sp     | Stack pointer    | Yes              |
| x3         | gp     | Global pointer   | ---              |
| x4         | tp     | Thread pointer   | ---              |
| x5         | t0     | Temporary/alternate link register | No |
| x6--7      | t1--2  | Temporaries      | No               |
| x8         | s0/fp  | Saved register/frame pointer | Yes |
| x9         | s1     | Saved register   | Yes              |
| x10--11    | a0--1  | Function arguments/return values | No               |
| x12--17    | a2--7  | Function arguments | No             |
| x18--27    | s2--11 | Saved registers  | Yes              |
| x28--31    | t3--6  | Temporaries      | No               |
||
| f0--7      | ft0--7  | FP temporaries   | No               |
| f8--9      | fs0--1  | FP saved registers | Yes             |
| f10--11    | fa0--1  | FP arguments/return values | No               |
| f12--17    | fa2--7  | FP arguments   | No               |
| f18--27    | fs2--11 | FP saved registers | Yes             |
| f28--31    | ft8--11 | FP temporaries  | No               |


## RISC-V汇编介绍

### RISC-V汇编语言

关于RISC-V汇编语言的详细内容，可以参阅 [RISC-V 指令集手册](http://riscvbook.com/chinese/RISC-V-Reader-Chinese-v2p1.pdf) 与 [Risc-v assembly programmer’s manual](https://github.com/riscv-non-isa/riscv-asm-manual/)。

在此，我们讲述一些C语言和RISC-V语言的对应关系，便于大家后面编写汇编代码。汇编语言可以理解为机器语言的直接翻译，是对于处理器的最直接的操作。RISC类型的处理器使用load/store类指令将变量在内存与寄存器间进行转移，除了这类指令外，其他指令都是在寄存器与寄存器之间的操作。

为了便于大家理解汇编如何编写，下面我们演示一下，我们所熟悉的C语言是如何被转换为汇编的。作为例子，这里选用一个简单的选择排序代码来作为演示。为了演示到所有的情况，我们有意使用了循环、函数调用等元素。

``` c
#include <stdio.h>
#include <stdlib.h>

#define MAX_N 100

int buf[MAX_N];

void do_sort(int a[], int n)
{
    for (int i = 0; i < n; ++i) {
        for (int j = i + 1; j < n; ++j) {
	    if (a[i] > a[j]) {
	        // swap a[i],a[j]
	        a[i] ^= a[j];
		a[j] ^= a[i];
	        a[i] ^= a[j];
	    }
	}
    }
}

int main()
{
    int n;
    scanf("%d", &n);

    int t = n;
    while (t--) {
        scanf("%d",&buf[t]);
    }

    do_sort(buf,n);

    for (int i = 0; i < n; ++i) {
        printf("%d ",buf[i]);
    }
    printf("\n");
    return 0;
}
```

那么，上面这段C代码对应的汇编代码是什么样呢？

首先，GCC有一个特性：所有的循环，都会换成`do{}while();`的形式来实现。
例如，GCC翻译出来的循环用C语言形象地表示是这个样子的：

``` c
for (int i = 0; i < n; ++i) {
   // ...
}
// 会被翻译成
int i = 0;
if (i >= n) goto END;
do {
   // ...
   ++i;
} while (i < n);
END:
// 进一步被翻译成
int i = 0;
goto L2;
L1:
  // ...
  ++i;
L2:
  if (!(i<n)) goto END;
  goto L1;
END:

```

函数调用会将第一个参数放在a0寄存器，第二个参数放在a1寄存器，依次类推，最后用call指令调用相应的函数。

```asm
ld a1, -24(s0); # 假设第二个参数位于-24(s0)
ld a0, -20(s0); # 假设第二个参数位于-20(s0)
call func # 相当于func(a0,a1);

```

进入函数时，先分配栈空间。分配方法就是将栈指针减去需要的空间字节数（栈是向下增长的）。sp到sp-X这X字节的空间就是当前函数运行所需的栈空间。将保存寄存器和返回地址寄存器( ra )的值存储在这部分栈空间中，退出时恢复。对于调用者来说，保存寄存器和返回地址寄存器( ra )的值在函数调用前后是不变的。栈指针( sp )的值也会在函数退出时进行恢复。此外，如果函数中使用了较多的局部变量，也会在栈空间上多开辟一部分空间用于存储局部变量。在内核编程中，内核栈的大小通常是有限的，如果函数中使用了大量的局部数据，很可能会发生栈溢出，覆盖了其他的内存区域，而引发奇怪的问题。

```asm
func:
  addi sp,sp,-32
  sd   s0, 0(sp)
  sd   s1, 8(sp)
  sd   ra, 16(sp)
  # ...
  ld   ra, 16(sp)
  ld   s1, 8(sp)
  ld   s0, 0(sp)
  addi sp,sp,32
  jr ra

```

一般汇编里加载地址有两个常用方式：绝对地址加载和PC相对加载。

直接加载绝对地址的示例如下：

```asm
.section .text
.globl _start
_start:
        lui a0,       
        addi a0, a0,  
        jal ra, puts
2:      j 2b

.section .rodata
msg:
        .string "Hello World"

```

PC相对的地址加载方式如下：

```asm
.section .text
.globl _start
_start:
1:      auipc a0,     
        addi  a0, a0, 
        jal ra, puts
2:      j 2b

.section .rodata
msg:
        .string "Hello World"

```

下面是C编译器翻译出来的代码对应的RISC-V汇编代码。

```asm
	.file	"riscv-example.c"
	.option nopic
	.text
	.comm	buf,400,8
	.align	1
	.globl	do_sort
	.type	do_sort, @function
# void do_sort(int a[], int n)
do_sort:
	addi	sp,sp,-48
	sd	s0,40(sp)
	addi	s0,sp,48
	sd	a0,-40(s0)
	mv	a5,a1
	sw	a5,-44(s0)
	sw	zero,-20(s0)
	j	.L2
	# ...
	# 未经优化的代码太长了，不再赘述
	# 下面做了个a[i]^=a[j]
	lw	a5,-20(s0) # -20(s0)是i
	slli	a5,a5,2  # a5=i*4
	ld	a2,-40(s0) # 取出a[]的首地址
	add	a5,a2,a5 # a5现在是a[i]的地址了
	xor	a4,a3,a4 # a[i]^a[j]，a[i]和a[j]在前面已经load进a3和a4了
	sext.w	a4,a4
	sw	a4,0(a5) # 把结果写回a[i]的地址上
	# ...
	# 恢复保留寄存器的值，返回
	ld	s0,40(sp)
	addi	sp,sp,48
	jr	ra
	.size	do_sort, .-do_sort
	.section	.rodata
	.align	3
.LC0:
	.string	"%d"
	.align	3
.LC1:
	.string	"%d "
	.text
	.align	1
	.globl	main
	.type	main, @function
# int main()
main:
	# 分配栈空间,sp为栈顶，栈向下增长
	addi	sp,sp,-32
	# 保存保留寄存器
	sd	ra,24(sp)
	sd	s0,16(sp)
	# s0用作帧指针，指向栈底
	addi	s0,sp,32
	# scanf("%d", &n);
	addi	a5,s0,-28 # -28(s0) 是n的位置
	mv	a1,a5     # 把n作为scanf的第二个参数
	lui	a5,%hi(.LC0)
	addi	a0,a5,%lo(.LC0) # 把"%d"作为第一个参数
	call	__isoc99_scanf # 调用scanf
	# int t = n;
	lw	a5,-28(s0) # -28(s0)是n
	sw	a5,-20(s0) # -20(s0)是t
	j	.L8 # goto .L8
	# do {
.L9:
	# scanf("%d",&buf[t]);
	lw	a5,-20(s0)
	slli	a4,a5,2 # a4=t*4,int为4字节
	lui	a5,%hi(buf) 
	addi	a5,a5,%lo(buf) # a5=buf
	add	a5,a4,a5 # a5=buf+t*4,即&buf[t]
	mv	a1,a5  # a5作为scanf第二个参数
	lui	a5,%hi(.LC0) 
	addi	a0,a5,%lo(.LC0) # "%d"作为scanf第一个参数
	call	__isoc99_scanf  # 调用scanf
.L8:    # } while ((t--) != 0);
	lw	a5,-20(s0)
	addiw	a4,a5,-1
	sw	a4,-20(s0)
	# 上面三句实现的是t--，
	# 先把值取到a5,再把a5-1存回t的位置
	bne	a5,zero,.L9 # t!=0时跳回.L9,实现while的语义

	# sort(buf, n);
	lw	a5,-28(s0)
	mv	a1,a5 # n作为第二个参数
	lui	a5,%hi(buf) # buf作为第一个参数
	addi	a0,a5,%lo(buf)
	call	do_sort # 调用do_sort
	
	# int i = 0; goto .L10
	sw	zero,-24(s0) # -24(s0)是i 
	j	.L10
	# do {
.L11:
        # printf("%d ",buf[i])
	lui	a5,%hi(buf)
	addi	a4,a5,%lo(buf) # a4=buf
	lw	a5,-24(s0)
	slli	a5,a5,2 # a5= t*4
	add	a5,a4,a5 # a5=buf+t*4
	lw	a5,0(a5) # a5 = buf[t]
	mv	a1,a5 # buf[t]作为第二个参数
	lui	a5,%hi(.LC1)
	addi	a0,a5,%lo(.LC1) # "%d "作为第一个参数
	call	printf # 调用printf
	# ++i;
	lw	a5,-24(s0)
	addiw	a5,a5,1
	sw	a5,-24(s0)
.L10:   # } while (i < n);
	lw	a4,-28(s0)
	lw	a5,-24(s0)
	sext.w	a5,a5
	blt	a5,a4,.L11
	# printf("\n"); 用putchar('\n')实现的
	li	a0,10
	call	putchar
	li	a5,0
	# return 0;
	mv	a0,a5 # a0放返回值
	# 恢复ra、s0、sp原来的值
	ld	ra,24(sp)
	ld	s0,16(sp)
	addi	sp,sp,32
	jr	ra # 返回
	.size	main, .-main
	.ident	"GCC: (GNU) 8.3.0"
	.section	.note.GNU-stack,"",@progbits
```
### RISC-V常用汇编指令

RISC-V的算术、逻辑运算等指令用法可以参考 [RISC-V 指令集手册](http://riscvbook.com/chinese/RISC-V-Reader-Chinese-v2p1.pdf) 一书。
RISC常用伪指令如表和表所示。伪指令是为了编写汇编方便所准备的指令，会被汇编器自动翻译成多条汇编指令。

<!-- \begin{table}[H]
    \begin{small}
        \begin{center}
            \begin{tabularx}{\textwidth}{l l X}
                \toprule
                伪指令 & 基础指令(即被汇编器翻译后的指令) & 含义 \\
                \midrule
                {\tt fence} & {\tt fence iorw, iorw} & Fence on all memory and I/O \\
                \hline
                {\tt rdinstret[h] rd} & {\tt csrrs rd, instret[h], x0} & Read instructions-retired counter \\
                {\tt rdcycle[h] rd} & {\tt csrrs rd, cycle[h], x0} & Read cycle counter \\
                {\tt rdtime[h] rd} & {\tt csrrs rd, time[h], x0} & Read real-time clock \\
                \hline
                {\tt csrr rd, csr} & {\tt csrrs rd, csr, x0} & Read CSR \\
                {\tt csrw csr, rs} & {\tt csrrw x0, csr, rs} & Write CSR \\
                {\tt csrwi csr, imm} & {\tt csrrwi x0, csr, imm} & Write CSR, immediate \\
                \hline
                {\tt j offset} & {\tt jal x0, offset} & Jump \\
                {\tt jal offset} & {\tt jal x1, offset} & Jump and link \\
                {\tt jr rs} & {\tt jalr x0, 0(rs)} & Jump register \\
                {\tt ret} & {\tt jalr x0, 0(x1)} & Return from subroutine \\
                \tt call offset & {\tt auipc x1, ${\tt offset[31:12]} + {\tt offset[11]}$} & Call far-away subroutine \\
                                & {\tt jalr x1, offset[11:0](x1)}                          & \\
                \tt tail offset & {\tt auipc x6, ${\tt offset[31:12]} + {\tt offset[11]}$} & Tail call far-away subroutine \\
                                & {\tt jalr x0, offset[11:0](x6)}                          & \\
                \bottomrule
            \end{tabularx}
        \end{center}
    \end{small}
    \caption{RISC-V 伪指令\cite{riscv-spec}}
    \label{csr-pseudos}
\end{table} -->

<!-- 汇编多讲一点，作业劝退
汇编作业涉及到内存的访问
堆栈传参，栈的使用
两个汇编作业（下次讨论）：
第一个访存，寄存器，调用 -->

<!-- \begin{table}[H]
\begin{small}
\begin{center}
\begin{tabularx}{\textwidth}{l l X}
\toprule
伪指令 & 基础指令(即被汇编器翻译后的指令) & 含义 \\ \midrule

\tt la rd, symbol (\emph{non-PIC}) & {\tt auipc rd, ${\tt delta[31:12]} + {\tt delta[11]}$} & Load absolute address, \\
                  & {\tt addi rd, rd, delta[11:0]}                         & where ${\tt delta} = {\tt symbol} - {\tt pc}$ \\[1ex]
\tt la rd, symbol (\emph{PIC})& {\tt auipc rd, ${\tt delta[31:12]} + {\tt delta[11]}$} & Load absolute address, \\
                  & {\tt l\{w|d\} rd, rd, delta[11:0]}                         & where ${\tt delta} = {\tt GOT[symbol]} - {\tt pc}$ \\[1ex]
\tt lla rd, symbol& {\tt auipc rd, ${\tt delta[31:12]} + {\tt delta[11]}$} & Load local address, \\
                  & {\tt addi rd, rd, delta[11:0]}                         & where ${\tt delta} = {\tt symbol} - {\tt pc}$ \\[1ex]
\tt l\{b|h|w|d\} rd, symbol & {\tt auipc rd, ${\tt delta[31:12]} + {\tt delta[11]}$} & Load global \\
                            & {\tt l\{b|h|w|d\} rd, delta[11:0](rd)}                 & \\[1ex]
\tt s\{b|h|w|d\} rd, symbol, rt & {\tt auipc rt, ${\tt delta[31:12]} + {\tt delta[11]}$} & Store global \\
                               & {\tt s\{b|h|w|d\} rd, delta[11:0](rt)}                 & \\[1ex]
\multicolumn{3}{p{.99\textwidth}}{\small \em The base instructions use {\tt pc}-relative addressing, so the linker subtracts {\tt pc} from {\tt symbol} to get {\tt delta}.  The linker adds {\tt delta[11]} to the 20-bit high part, counteracting sign extension of the 12-bit low part.} \\
~\\
\hline
{\tt nop} & {\tt addi x0, x0, 0} & No operation \\
{\tt li rd, immediate} & {\em Myriad sequences} & Load immediate \\
{\tt mv rd, rs} & {\tt addi rd, rs, 0} & Copy register \\
{\tt not rd, rs} & {\tt xori rd, rs, -1} & One's complement \\
{\tt neg rd, rs} & {\tt sub rd, x0, rs} & Two's complement \\
{\tt negw rd, rs} & {\tt subw rd, x0, rs} & Two's complement word \\
{\tt sext.w rd, rs} & {\tt addiw rd, rs, 0} & Sign extend word \\
{\tt seqz rd, rs} & {\tt sltiu rd, rs, 1} & Set if $=$ zero \\
{\tt snez rd, rs} & {\tt sltu rd, x0, rs} & Set if $\neq$ zero \\
{\tt sltz rd, rs} & {\tt slt rd, rs, x0} & Set if $<$ zero \\
{\tt sgtz rd, rs} & {\tt slt rd, x0, rs} & Set if $>$ zero \\
\hline
{\tt beqz rs, offset} & {\tt beq rs, x0, offset} & Branch if $=$ zero \\
{\tt bnez rs, offset} & {\tt bne rs, x0, offset} & Branch if $\neq$ zero \\
{\tt blez rs, offset} & {\tt bge x0, rs, offset} & Branch if $\leq$ zero \\
{\tt bgez rs, offset} & {\tt bge rs, x0, offset} & Branch if $\geq$ zero \\
{\tt bltz rs, offset} & {\tt blt rs, x0, offset} & Branch if $<$ zero \\
{\tt bgtz rs, offset} & {\tt blt x0, rs, offset} & Branch if $>$ zero \\
\hline
{\tt bgt rs, rt, offset} & {\tt blt rt, rs, offset} & Branch if $>$ \\
{\tt ble rs, rt, offset} & {\tt bge rt, rs, offset} & Branch if $\leq$ \\
{\tt bgtu rs, rt, offset} & {\tt bltu rt, rs, offset} & Branch if $>$, unsigned \\
{\tt bleu rs, rt, offset} & {\tt bgeu rt, rs, offset} & Branch if $\leq$, unsigned \\
\bottomrule

\end{tabularx}
\end{center}
\end{small}
\caption{RISC-V 伪指令(续)\cite{riscv-spec}}
\label{pseudos}
\end{table} -->

| 伪指令 | 基础指令(即被汇编器翻译后的指令) | 含义 |
|--------|----------------------------------|------|
|fence | fence iorw, iorw | Fence on all memory and I/O |
|rdinstret[h] rd | csrrs rd, instret[h], x0 | Read instructions-retired counter |
|rdcycle[h] rd | csrrs rd, cycle[h], x0 | Read cycle counter |
|rdtime[h] rd | csrrs rd, time[h], x0 | Read real-time clock |
|csrr rd, csr | csrrs rd, csr, x0 | Read CSR |
|csrw csr, rs | csrrw x0, csr, rs | Write CSR |
|csrwi csr, imm | csrrwi x0, csr, imm | Write CSR, immediate |
|j offset | jal x0, offset | Jump |
|jal offset | jal x1, offset | Jump and link |
|jr rs | jalr x0, 0(rs) | Jump register |
|ret | jalr x0, 0(x1) | Return from subroutine |
|call offset | auipc x1, offset\[31:12] + offset\[11] <br> jalr x1, offset\[11:0](x1) | Call far-away subroutine |
|tail offset | auipc x6, offset\[31:12] + offset\[11] <br> jalr x0, offset\[11:0](x6) | Tail call far-away subroutine |
|la rd, symbol (non-PIC) | auipc rd, delta\[31:12] + delta\[11] <br> addi rd, rd, delta\[11:0] | Load absolute address, where delta = symbol - pc |
|la rd, symbol (PIC) | auipc rd, delta\[31:12] + delta\[11] <br> l{w|d} rd, rd, delta\[11:0] | Load absolute address, where delta = GOT[symbol] - pc |
|lla rd, symbol | auipc rd, delta\[31:12] + delta\[11] <br> addi rd, rd, delta\[11:0] | Load local address, where delta = symbol - pc |
|l{b\|h\|w\|d} rd, symbol | auipc rd, delta\[31:12] + delta\[11] <br> l{b\|h\|w\|d} rd, delta\[11:0](rd) | Load global |
|s{b\|h\|w\|d} rd, symbol, rt | auipc rt, delta\[31:12] + delta\[11] <br> s{b\|h\|w\|d} rd, delta\[11:0](rt) | Store global |
|nop | addi x0, x0, 0 | No operation |
|li rd, immediate | Myriad sequences | Load immediate |
|mv rd, rs | addi rd, rs, 0 | Copy register |
|not rd, rs | xori rd, rs, -1 | One's complement |
|neg rd, rs | sub rd, x0, rs | Two's complement |
|negw rd, rs | subw rd, x0, rs | Two's complement word |
|sext.w rd, rs | addiw rd, rs, 0 | Sign extend word |
|seqz rd, rs | sltiu rd, rs, 1 | Set if = zero |
|snez rd, rs | sltu rd, x0, rs | Set if ≠ zero |
|sltz rd, rs | slt rd, rs, x0 | Set if < zero |
|sgtz rd, rs | slt rd, x0, rs | Set if > zero |
|beqz rs, offset | beq rs, x0, offset | Branch if = zero |
|bnez rs, offset | bne rs, x0, offset | Branch if ≠ zero |
|blez rs, offset | bge x0, rs, offset | Branch if ≤ zero |
|bgez rs, offset | bge rs, x0, offset | Branch if ≥ zero |
|bltz rs, offset | blt rs, x0, offset | Branch if < zero |
|bgtz rs, offset | blt x0, rs, offset | Branch if > zero |
|bgt rs, rt, offset | blt rt, rs, offset | Branch if > |
|ble rs, rt, offset | bge rt, rs, offset | Branch if ≤ |
|bgtu rs, rt, offset | bltu rt, rs, offset | Branch if >, unsigned |
|bleu rs, rt, offset | bgeu rt, rs, offset | Branch if ≤, unsigned |
