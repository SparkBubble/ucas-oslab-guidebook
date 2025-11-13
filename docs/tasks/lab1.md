# 实验一：引导与中断

## 实验目的

本实验旨在让学生理解计算机的启动过程和中断机制，掌握操作系统内核的引导流程和基本的异常处理方法。

## 背景知识

### 计算机启动过程

计算机启动过程大致分为以下几个阶段：

1. **BIOS/UEFI 阶段**：上电后，CPU 执行 BIOS/UEFI 固件代码
2. **引导加载阶段**：BIOS 从启动设备加载 bootloader
3. **内核加载阶段**：bootloader 将内核加载到内存
4. **内核初始化阶段**：内核完成初始化并启动

### 中断机制

中断是操作系统响应硬件事件的核心机制：

- **中断描述符表（IDT）**：存储中断处理函数的地址
- **中断向量**：中断的编号，用于索引 IDT
- **中断处理程序**：响应中断的代码

## 实验任务

### 任务一：编写 Bootloader

实现一个简单的 bootloader，完成以下功能：

1. 从实模式切换到保护模式
2. 设置全局描述符表（GDT）
3. 加载内核到内存
4. 跳转到内核入口点

**参考代码结构：**

```asm
; boot.asm - Bootloader 示例
[BITS 16]
[ORG 0x7c00]

start:
    ; 初始化段寄存器
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7c00

    ; 加载 GDT
    lgdt [gdt_descriptor]

    ; 切换到保护模式
    mov eax, cr0
    or eax, 1
    mov cr0, eax

    ; 跳转到 32 位代码
    jmp 0x08:protected_mode

[BITS 32]
protected_mode:
    ; 设置段寄存器
    mov ax, 0x10
    mov ds, ax
    mov es, ax
    mov ss, ax

    ; 跳转到内核
    jmp 0x100000

; GDT 定义
gdt_start:
    dq 0x0000000000000000  ; 空描述符
    dq 0x00cf9a000000ffff  ; 代码段
    dq 0x00cf92000000ffff  ; 数据段
gdt_end:

gdt_descriptor:
    dw gdt_end - gdt_start - 1
    dd gdt_start

times 510-($-$$) db 0
dw 0xaa55
```

### 任务二：设置中断描述符表

实现 IDT 的初始化和中断处理框架：

1. 定义 IDT 数据结构
2. 填充 IDT 表项
3. 加载 IDT 到 CPU

**参考代码：**

```c
// idt.h
#ifndef IDT_H
#define IDT_H

#include <stdint.h>

// IDT 表项结构
struct idt_entry {
    uint16_t offset_low;    // 处理函数地址低 16 位
    uint16_t selector;      // 代码段选择子
    uint8_t  zero;          // 保留
    uint8_t  type_attr;     // 类型和属性
    uint16_t offset_high;   // 处理函数地址高 16 位
} __attribute__((packed));

// IDT 描述符
struct idt_ptr {
    uint16_t limit;
    uint32_t base;
} __attribute__((packed));

void idt_init(void);
void idt_set_gate(uint8_t num, uint32_t handler, uint16_t sel, uint8_t flags);

#endif
```

```c
// idt.c
#include "idt.h"

#define IDT_ENTRIES 256

struct idt_entry idt[IDT_ENTRIES];
struct idt_ptr idtp;

void idt_set_gate(uint8_t num, uint32_t handler, uint16_t sel, uint8_t flags) {
    idt[num].offset_low = handler & 0xFFFF;
    idt[num].selector = sel;
    idt[num].zero = 0;
    idt[num].type_attr = flags;
    idt[num].offset_high = (handler >> 16) & 0xFFFF;
}

void idt_init(void) {
    idtp.limit = sizeof(idt) - 1;
    idtp.base = (uint32_t)&idt;

    // 清空 IDT
    memset(&idt, 0, sizeof(idt));

    // 设置中断门
    // 在这里设置各个中断处理函数

    // 加载 IDT
    asm volatile("lidt %0" : : "m"(idtp));
}
```

### 任务三：实现时钟中断

实现可编程间隔定时器（PIT）的时钟中断：

1. 配置 PIT 芯片
2. 实现时钟中断处理函数
3. 更新系统时间计数

**参考代码：**

```c
// timer.c
#include "timer.h"
#include "idt.h"
#include "io.h"

static uint32_t tick = 0;

void timer_handler(void) {
    tick++;
    
    // 每 100 次时钟中断打印一次
    if (tick % 100 == 0) {
        printf("Tick: %d\n", tick);
    }
    
    // 发送 EOI 到 PIC
    outb(0x20, 0x20);
}

void timer_init(uint32_t frequency) {
    // 注册时钟中断处理函数
    idt_set_gate(32, (uint32_t)timer_handler, 0x08, 0x8E);
    
    // 计算分频值
    uint32_t divisor = 1193180 / frequency;
    
    // 配置 PIT
    outb(0x43, 0x36);
    outb(0x40, divisor & 0xFF);
    outb(0x40, (divisor >> 8) & 0xFF);
}
```

### 任务四：实现键盘中断

实现键盘中断处理，读取键盘输入：

1. 配置键盘控制器
2. 实现键盘中断处理函数
3. 将键盘扫描码转换为字符

**参考代码：**

```c
// keyboard.c
#include "keyboard.h"
#include "idt.h"
#include "io.h"

#define KEYBOARD_DATA_PORT   0x60
#define KEYBOARD_STATUS_PORT 0x64

void keyboard_handler(void) {
    uint8_t scancode = inb(KEYBOARD_DATA_PORT);
    
    // 处理扫描码
    char c = scancode_to_char(scancode);
    if (c != 0) {
        printf("%c", c);
    }
    
    // 发送 EOI
    outb(0x20, 0x20);
}

void keyboard_init(void) {
    // 注册键盘中断处理函数
    idt_set_gate(33, (uint32_t)keyboard_handler, 0x08, 0x8E);
}
```

## 实验要求

### 功能要求

- [ ] bootloader 能够正确引导系统
- [ ] 正确设置和加载 IDT
- [ ] 时钟中断正常工作
- [ ] 键盘中断能够接收输入

### 代码要求

- 代码结构清晰，模块划分合理
- 添加必要的注释说明关键步骤
- 遵循代码规范

### 报告要求

实验报告应包含：

1. **实验原理**：说明引导过程和中断机制的原理
2. **设计思路**：描述各个任务的设计思路
3. **实现细节**：说明关键代码的实现
4. **测试结果**：展示程序运行结果
5. **问题总结**：记录遇到的问题及解决方法
6. **心得体会**：个人学习收获

## 参考资料

- [Intel 64 and IA-32 Architectures Software Developer's Manual](https://www.intel.com/content/www/us/en/developer/articles/technical/intel-sdm.html)
- [OSDev Wiki - Interrupts](https://wiki.osdev.org/Interrupts)
- [OSDev Wiki - Real Mode](https://wiki.osdev.org/Real_Mode)

## 常见问题

??? question "如何调试 bootloader？"
    可以使用 QEMU + GDB 进行调试。启动 QEMU 时加上 `-s -S` 参数，然后使用 GDB 连接进行调试。

??? question "IDT 表项的 type_attr 字段如何设置？"
    对于中断门，通常设置为 `0x8E`（Present=1, DPL=0, Type=0xE）。对于陷阱门，设置为 `0x8F`。

??? question "时钟中断频率应该设置为多少？"
    通常设置为 100Hz 或 1000Hz。频率越高，系统响应越及时，但开销也越大。

## 提交说明

请在截止日期前提交：

1. 完整的源代码（包含 Makefile）
2. 实验报告（PDF 格式）
3. README 文件（说明如何编译和运行）

提交方式：请参考 [提交规范](../guide/submission.md)。
