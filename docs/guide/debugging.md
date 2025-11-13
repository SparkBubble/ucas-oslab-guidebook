# 调试技巧

掌握系统级调试技巧对于操作系统开发至关重要。本文档介绍常用的调试方法和工具。

## 调试工具概览

### GDB 调试器

GDB 是最强大的调试工具，支持：

- 设置断点和观察点
- 单步执行和查看变量
- 查看内存和寄存器
- 反汇编代码

### QEMU 内置调试功能

QEMU 提供了丰富的调试接口：

- GDB 远程调试支持
- 内置监控器
- 日志记录功能

## 基础调试技巧

### 使用 printf 调试

最简单但有效的方法：

```c
void debug_print_registers(void) {
    uint32_t eax, ebx, ecx, edx;
    asm volatile("mov %%eax, %0" : "=r"(eax));
    asm volatile("mov %%ebx, %0" : "=r"(ebx));
    asm volatile("mov %%ecx, %0" : "=r"(ecx));
    asm volatile("mov %%edx, %0" : "=r"(edx));
    
    printf("EAX: 0x%08x  EBX: 0x%08x\n", eax, ebx);
    printf("ECX: 0x%08x  EDX: 0x%08x\n", ecx, edx);
}
```

**优点**：简单直接  
**缺点**：需要重新编译，可能影响执行流程

### 使用串口输出

配置串口用于调试输出：

```c
// serial.c
#define COM1 0x3F8

void serial_init(void) {
    outb(COM1 + 1, 0x00);    // 禁用中断
    outb(COM1 + 3, 0x80);    // 启用 DLAB
    outb(COM1 + 0, 0x03);    // 设置波特率 38400
    outb(COM1 + 1, 0x00);
    outb(COM1 + 3, 0x03);    // 8 bits, no parity, one stop bit
    outb(COM1 + 2, 0xC7);    // 启用 FIFO
    outb(COM1 + 4, 0x0B);    // 启用中断
}

void serial_putc(char c) {
    while ((inb(COM1 + 5) & 0x20) == 0);
    outb(COM1, c);
}

void debug_printf(const char *fmt, ...) {
    // 实现类似 printf 的函数，输出到串口
}
```

启动 QEMU 时重定向串口：

```bash
qemu-system-i386 -kernel kernel.bin -serial stdio
```

## GDB 调试

### 基本设置

启动调试会话：

```bash
# 终端 1：启动 QEMU 调试服务器
qemu-system-i386 -kernel kernel.bin -s -S

# 终端 2：启动 GDB
gdb kernel.elf
(gdb) target remote localhost:1234
(gdb) break kernel_main
(gdb) continue
```

### 常用 GDB 命令

#### 断点操作

```gdb
# 设置断点
(gdb) break function_name
(gdb) break file.c:line_number
(gdb) break *0x100000

# 查看断点
(gdb) info breakpoints

# 删除断点
(gdb) delete 1
(gdb) delete          # 删除所有断点

# 条件断点
(gdb) break main if argc > 1

# 临时断点
(gdb) tbreak function_name
```

#### 执行控制

```gdb
# 继续执行
(gdb) continue

# 单步执行（跳过函数）
(gdb) next

# 单步执行（进入函数）
(gdb) step

# 执行到函数返回
(gdb) finish

# 执行指定次数
(gdb) step 10
```

#### 查看信息

```gdb
# 查看栈帧
(gdb) backtrace
(gdb) frame 0

# 查看变量
(gdb) print variable_name
(gdb) print *pointer
(gdb) print array[0]@10    # 打印数组的 10 个元素

# 查看内存
(gdb) x/10x 0x100000       # 以十六进制显示 10 个字
(gdb) x/10i 0x100000       # 反汇编 10 条指令
(gdb) x/s 0x100000         # 显示字符串

# 查看寄存器
(gdb) info registers
(gdb) print $eax
(gdb) set $eax = 0x12345678
```

#### 观察点

```gdb
# 设置观察点（当变量值改变时停止）
(gdb) watch variable_name

# 读观察点
(gdb) rwatch variable_name

# 读写观察点
(gdb) awatch variable_name
```

### GDB 脚本

创建 `.gdbinit` 自动化调试：

```gdb
# .gdbinit
target remote localhost:1234

# 定义自定义命令
define show_context
    info registers
    x/10i $eip
    backtrace 5
end

# 在每次停止时自动执行
define hook-stop
    show_context
end

# 设置常用断点
break kernel_main
break panic

# 启动执行
continue
```

## QEMU 监控器

### 访问监控器

```bash
# 启动 QEMU 并切换到监控器
qemu-system-i386 -kernel kernel.bin -monitor stdio

# 或者使用组合键 Ctrl+Alt+2
```

### 常用监控命令

```
# 查看寄存器
(qemu) info registers

# 查看内存映射
(qemu) info mem
(qemu) info tlb

# 查看进程信息（需要内核支持）
(qemu) info process

# 内存转储
(qemu) memsave 0x100000 0x1000 dump.bin

# 物理内存转储
(qemu) pmemsave 0x100000 0x1000 pdump.bin

# 单步执行
(qemu) stop
(qemu) step

# 断点
(qemu) gdbserver
```

## 高级调试技巧

### 调试启动过程

使用 Bochs 调试 bootloader：

```bash
# 安装 Bochs
sudo apt install bochs bochs-x

# 创建 bochsrc.txt
display_library: x
romimage: file=/usr/share/bochs/BIOS-bochs-latest
vgaromimage: file=/usr/share/bochs/VGABIOS-lgpl-latest
ata0-master: type=disk, path="disk.img", mode=flat
boot: disk
magic_break: enabled=1

# 启动 Bochs
bochs -f bochsrc.txt
```

### 内存泄漏检测

实现简单的内存追踪：

```c
// memory_debug.h
#ifdef DEBUG_MEMORY

struct alloc_info {
    void *addr;
    size_t size;
    const char *file;
    int line;
};

void *debug_malloc(size_t size, const char *file, int line);
void debug_free(void *ptr, const char *file, int line);
void dump_memory_leaks(void);

#define malloc(size) debug_malloc(size, __FILE__, __LINE__)
#define free(ptr) debug_free(ptr, __FILE__, __LINE__)

#endif
```

### 性能分析

使用 QEMU 的性能计数器：

```bash
# 启用性能统计
qemu-system-i386 -kernel kernel.bin -d cpu_reset,int

# 查看执行的指令数
qemu-system-i386 -kernel kernel.bin -icount shift=0 -d exec
```

### 追踪系统调用

记录和分析系统调用：

```c
void syscall_handler(struct interrupt_frame *frame) {
    uint32_t syscall_num = frame->eax;
    
    #ifdef DEBUG_SYSCALL
    printf("[SYSCALL] num=%d, args: 0x%x, 0x%x, 0x%x\n",
           syscall_num, frame->ebx, frame->ecx, frame->edx);
    #endif
    
    // 处理系统调用...
}
```

## 常见问题调试

### 页面错误

```c
void page_fault_handler(struct interrupt_frame *frame) {
    uint32_t fault_addr;
    asm("mov %%cr2, %0" : "=r"(fault_addr));
    
    printf("Page Fault!\n");
    printf("  Faulting address: 0x%08x\n", fault_addr);
    printf("  Error code: 0x%x\n", frame->error_code);
    printf("  EIP: 0x%08x\n", frame->eip);
    
    if (frame->error_code & 0x1)
        printf("  Reason: Page protection violation\n");
    else
        printf("  Reason: Page not present\n");
    
    // 打印栈回溯
    print_stack_trace();
    
    panic("Unrecoverable page fault");
}
```

### 三重错误

启用 QEMU 日志：

```bash
qemu-system-i386 -kernel kernel.bin -d int,cpu_reset -D qemu.log
```

### 死锁检测

实现简单的死锁检测：

```c
struct lock_info {
    struct process *owner;
    struct process *waiters[MAX_PROCESSES];
    int waiter_count;
};

void detect_deadlock(void) {
    // 检测循环等待
    for (int i = 0; i < num_locks; i++) {
        // 实现死锁检测算法
    }
}
```

## 调试清单

在提交代码前，检查：

- [ ] 所有 printf 调试语句已清理或条件编译
- [ ] 没有内存泄漏
- [ ] 边界条件已测试
- [ ] 错误处理代码已验证
- [ ] 并发问题已排查
- [ ] 性能瓶颈已分析

## 推荐阅读

- [GDB 官方文档](https://sourceware.org/gdb/documentation/)
- [QEMU 调试指南](https://qemu-project.gitlab.io/qemu/system/gdb.html)
- [Linux Kernel Debugging](https://www.kernel.org/doc/html/latest/dev-tools/gdb-kernel-debugging.html)

## 下一步

- 学习 [提交规范](submission.md)
- 开始实验：[任务概览](../tasks/overview.md)
