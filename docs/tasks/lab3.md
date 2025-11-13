# 实验三：虚拟内存管理

## 实验目的

理解虚拟内存的概念和实现机制，掌握分页机制和页表管理，实现虚拟地址到物理地址的转换。

## 背景知识

### 虚拟内存概述

虚拟内存为每个进程提供独立的地址空间，主要优势：

- **进程隔离**：进程间内存互不干扰
- **内存保护**：控制内存访问权限
- **大地址空间**：提供比物理内存更大的地址空间
- **内存共享**：多个进程可共享同一物理页面

### 分页机制

x86 架构使用多级页表进行地址转换：

- **页目录（Page Directory）**：一级页表
- **页表（Page Table）**：二级页表
- **页表项（PTE）**：存储物理页面地址和标志位

## 实验任务

### 任务一：建立页表映射

实现页表的创建和管理：

```c
// paging.h
#ifndef PAGING_H
#define PAGING_H

#include <stdint.h>

// 页表项标志
#define PTE_P       0x001   // Present
#define PTE_W       0x002   // Writable
#define PTE_U       0x004   // User
#define PTE_PWT     0x008   // Write-Through
#define PTE_PCD     0x010   // Cache Disable
#define PTE_A       0x020   // Accessed
#define PTE_D       0x040   // Dirty
#define PTE_PS      0x080   // Page Size
#define PTE_G       0x100   // Global

typedef uint32_t pte_t;
typedef uint32_t pde_t;

// 页目录和页表
struct page_directory {
    pde_t entries[1024];
};

struct page_table {
    pte_t entries[1024];
};

void paging_init(void);
void map_page(uint32_t virt, uint32_t phys, uint32_t flags);
void unmap_page(uint32_t virt);
uint32_t virt_to_phys(uint32_t virt);

#endif
```

```c
// paging.c
#include "paging.h"
#include "page_alloc.h"

static struct page_directory *kernel_pd;

void paging_init(void) {
    // 分配页目录
    kernel_pd = (struct page_directory *)alloc_page();
    memset(kernel_pd, 0, PAGE_SIZE);
    
    // 恒等映射内核空间 (0-4MB)
    for (uint32_t i = 0; i < 1024; i++) {
        map_page(i * PAGE_SIZE, i * PAGE_SIZE, PTE_P | PTE_W);
    }
    
    // 加载页目录
    asm volatile("mov %0, %%cr3" : : "r"(kernel_pd));
    
    // 启用分页
    uint32_t cr0;
    asm volatile("mov %%cr0, %0" : "=r"(cr0));
    cr0 |= 0x80000000;  // 设置 PG 位
    asm volatile("mov %0, %%cr0" : : "r"(cr0));
    
    printf("Paging enabled\n");
}

void map_page(uint32_t virt, uint32_t phys, uint32_t flags) {
    uint32_t pd_idx = virt >> 22;
    uint32_t pt_idx = (virt >> 12) & 0x3FF;
    
    // 检查页表是否存在
    if (!(kernel_pd->entries[pd_idx] & PTE_P)) {
        struct page_table *pt = (struct page_table *)alloc_page();
        memset(pt, 0, PAGE_SIZE);
        kernel_pd->entries[pd_idx] = ((uint32_t)pt) | PTE_P | PTE_W | PTE_U;
    }
    
    // 获取页表
    struct page_table *pt = (struct page_table *)(kernel_pd->entries[pd_idx] & ~0xFFF);
    
    // 设置页表项
    pt->entries[pt_idx] = (phys & ~0xFFF) | flags;
}

void unmap_page(uint32_t virt) {
    uint32_t pd_idx = virt >> 22;
    uint32_t pt_idx = (virt >> 12) & 0x3FF;
    
    if (!(kernel_pd->entries[pd_idx] & PTE_P))
        return;
        
    struct page_table *pt = (struct page_table *)(kernel_pd->entries[pd_idx] & ~0xFFF);
    pt->entries[pt_idx] = 0;
    
    // 刷新 TLB
    asm volatile("invlpg (%0)" : : "r"(virt));
}

uint32_t virt_to_phys(uint32_t virt) {
    uint32_t pd_idx = virt >> 22;
    uint32_t pt_idx = (virt >> 12) & 0x3FF;
    uint32_t offset = virt & 0xFFF;
    
    if (!(kernel_pd->entries[pd_idx] & PTE_P))
        return 0;
        
    struct page_table *pt = (struct page_table *)(kernel_pd->entries[pd_idx] & ~0xFFF);
    
    if (!(pt->entries[pt_idx] & PTE_P))
        return 0;
        
    return (pt->entries[pt_idx] & ~0xFFF) | offset;
}
```

### 任务二：处理缺页异常

实现缺页异常处理程序：

```c
// page_fault.c
#include "interrupt.h"
#include "paging.h"

void page_fault_handler(struct interrupt_frame *frame) {
    uint32_t fault_addr;
    asm volatile("mov %%cr2, %0" : "=r"(fault_addr));
    
    uint32_t error_code = frame->error_code;
    
    printf("Page Fault at 0x%08x\n", fault_addr);
    printf("Error code: 0x%x\n", error_code);
    
    if (error_code & 0x1)
        printf("  - Page protection violation\n");
    else
        printf("  - Page not present\n");
        
    if (error_code & 0x2)
        printf("  - Write access\n");
    else
        printf("  - Read access\n");
        
    if (error_code & 0x4)
        printf("  - User mode\n");
    else
        printf("  - Kernel mode\n");
    
    // 这里可以实现按需分页
    // 为简单起见，直接 panic
    panic("Page fault");
}

void page_fault_init(void) {
    // 注册缺页异常处理函数 (中断 14)
    idt_set_gate(14, (uint32_t)page_fault_handler, 0x08, 0x8E);
}
```

### 任务三：实现页面置换算法

实现 LRU 或 Clock 页面置换算法：

```c
// page_replace.h
#ifndef PAGE_REPLACE_H
#define PAGE_REPLACE_H

#include <stdint.h>

#define MAX_FRAMES 256

struct frame_info {
    uint32_t virt_addr;
    uint32_t access_time;
    uint8_t  referenced;
    uint8_t  modified;
};

void page_replace_init(void);
uint32_t select_victim_page(void);
void swap_out_page(uint32_t frame_no);
void swap_in_page(uint32_t virt_addr);

#endif
```

```c
// page_replace.c - Clock 算法实现
#include "page_replace.h"

static struct frame_info frames[MAX_FRAMES];
static uint32_t clock_hand = 0;

void page_replace_init(void) {
    memset(frames, 0, sizeof(frames));
}

uint32_t select_victim_page(void) {
    while (1) {
        if (!frames[clock_hand].referenced) {
            uint32_t victim = clock_hand;
            clock_hand = (clock_hand + 1) % MAX_FRAMES;
            return victim;
        }
        
        frames[clock_hand].referenced = 0;
        clock_hand = (clock_hand + 1) % MAX_FRAMES;
    }
}

void swap_out_page(uint32_t frame_no) {
    // 如果页面被修改，写回磁盘
    if (frames[frame_no].modified) {
        // 写入交换空间
        printf("Swapping out page at frame %d\n", frame_no);
    }
    
    // 从页表中删除映射
    unmap_page(frames[frame_no].virt_addr);
}

void swap_in_page(uint32_t virt_addr) {
    // 选择牺牲页面
    uint32_t frame_no = select_victim_page();
    
    // 换出旧页面
    swap_out_page(frame_no);
    
    // 从交换空间读取页面
    printf("Swapping in page for virt addr 0x%08x\n", virt_addr);
    
    // 建立新映射
    uint32_t phys = frame_no * PAGE_SIZE;
    map_page(virt_addr, phys, PTE_P | PTE_W | PTE_U);
    
    frames[frame_no].virt_addr = virt_addr;
    frames[frame_no].referenced = 1;
    frames[frame_no].modified = 0;
}
```

### 任务四：实现写时复制

实现 Copy-on-Write (COW) 机制：

```c
// cow.c
#include "paging.h"

void setup_cow_mapping(uint32_t parent_virt, uint32_t child_virt, uint32_t phys) {
    // 父进程和子进程都映射为只读
    map_page(parent_virt, phys, PTE_P | PTE_U);  // 去掉 PTE_W
    map_page(child_virt, phys, PTE_P | PTE_U);
    
    // 增加物理页面引用计数
    struct page *page = get_page_from_addr(phys);
    page->ref_count++;
}

void handle_cow_fault(uint32_t fault_addr) {
    uint32_t phys = virt_to_phys(fault_addr);
    struct page *page = get_page_from_addr(phys);
    
    if (page->ref_count > 1) {
        // 分配新页面
        struct page *new_page = alloc_page();
        uint32_t new_phys = page_to_addr(new_page);
        
        // 复制内容
        memcpy((void *)new_phys, (void *)phys, PAGE_SIZE);
        
        // 更新映射为可写
        map_page(fault_addr & ~0xFFF, new_phys, PTE_P | PTE_W | PTE_U);
        
        // 减少旧页面引用计数
        page->ref_count--;
    } else {
        // 只有一个引用，直接设置为可写
        map_page(fault_addr & ~0xFFF, phys, PTE_P | PTE_W | PTE_U);
    }
}
```

## 实验要求

### 功能要求

- [ ] 正确建立和管理页表
- [ ] 实现虚拟地址到物理地址的转换
- [ ] 正确处理缺页异常
- [ ] 实现至少一种页面置换算法
- [ ] （可选）实现写时复制机制

### 测试要求

编写测试程序验证：

1. 页表映射的正确性
2. 地址转换的准确性
3. 缺页异常处理
4. 页面置换算法的有效性

## 实验报告

实验报告应包含：

1. **虚拟内存原理**：说明分页机制的工作原理
2. **页表设计**：描述页表结构和管理方法
3. **异常处理**：说明缺页异常的处理流程
4. **算法分析**：分析页面置换算法的性能
5. **测试结果**：展示测试结果和性能数据

## 参考资料

- [Intel SDM - Paging](https://www.intel.com/content/www/us/en/developer/articles/technical/intel-sdm.html)
- [OSDev Wiki - Paging](https://wiki.osdev.org/Paging)
- [Linux Memory Management](https://www.kernel.org/doc/html/latest/admin-guide/mm/)

## 思考题

1. 为什么需要 TLB？如何提高 TLB 命中率？
2. 多级页表相比单级页表有什么优势？
3. 如何实现大页（Huge Pages）支持？

## 提交说明

请按照 [提交规范](../guide/submission.md) 提交实验成果。
