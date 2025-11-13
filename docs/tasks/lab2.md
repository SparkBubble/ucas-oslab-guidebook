# 实验二：物理内存管理

## 实验目的

本实验旨在让学生理解物理内存管理的基本原理，掌握内存分配算法，并实现一个简单但功能完整的物理内存管理子系统。

## 背景知识

### 物理内存管理概述

物理内存管理是操作系统的核心功能之一，主要负责：

- 检测和管理可用的物理内存
- 分配和回收物理页面
- 跟踪内存使用情况

### 常见内存分配算法

1. **首次适配（First Fit）**：从头开始找第一个足够大的空闲块
2. **最佳适配（Best Fit）**：找最小的满足需求的空闲块
3. **伙伴系统（Buddy System）**：将内存按 2 的幂次方大小进行管理

## 实验任务

### 任务一：检测物理内存

通过 BIOS/UEFI 获取系统物理内存信息：

1. 使用 E820 内存映射获取内存布局
2. 解析内存区域信息
3. 标记可用内存区域

**参考代码：**

```c
// memory.h
#ifndef MEMORY_H
#define MEMORY_H

#include <stdint.h>

#define E820_MAX_ENTRIES 128

// E820 内存映射条目
struct e820_entry {
    uint64_t base;
    uint64_t length;
    uint32_t type;
    uint32_t acpi;
} __attribute__((packed));

// 内存类型
#define E820_RAM        1
#define E820_RESERVED   2
#define E820_ACPI       3
#define E820_NVS        4

void detect_memory(void);
void print_memory_map(void);

#endif
```

```c
// memory.c
#include "memory.h"

struct e820_entry memory_map[E820_MAX_ENTRIES];
int memory_map_entries = 0;

void detect_memory(void) {
    // 从 bootloader 传递的内存映射中读取
    // 这里假设 bootloader 已经将 E820 映射放在固定地址
    
    struct e820_entry *map = (struct e820_entry *)0x8000;
    
    for (int i = 0; i < E820_MAX_ENTRIES; i++) {
        if (map[i].length == 0)
            break;
            
        memory_map[i] = map[i];
        memory_map_entries++;
    }
}

void print_memory_map(void) {
    printf("Physical Memory Map:\n");
    printf("Base Address    Length          Type\n");
    
    for (int i = 0; i < memory_map_entries; i++) {
        printf("0x%016llx  0x%016llx  ", 
               memory_map[i].base, 
               memory_map[i].length);
               
        switch (memory_map[i].type) {
            case E820_RAM:
                printf("Available\n");
                break;
            case E820_RESERVED:
                printf("Reserved\n");
                break;
            case E820_ACPI:
                printf("ACPI\n");
                break;
            default:
                printf("Other\n");
                break;
        }
    }
}
```

### 任务二：实现物理页面分配器

设计并实现基本的物理页面分配器：

1. 维护空闲页面链表
2. 实现单页分配和释放
3. 跟踪页面使用状态

**参考代码：**

```c
// page_alloc.h
#ifndef PAGE_ALLOC_H
#define PAGE_ALLOC_H

#include <stdint.h>

#define PAGE_SIZE 4096

// 页面描述符
struct page {
    uint32_t flags;         // 页面状态标志
    uint32_t ref_count;     // 引用计数
    struct page *next;      // 链表指针
};

// 页面标志
#define PAGE_FLAG_FREE      0x01
#define PAGE_FLAG_RESERVED  0x02

void page_alloc_init(void);
struct page *alloc_page(void);
void free_page(struct page *page);
uint32_t get_free_pages(void);

#endif
```

```c
// page_alloc.c
#include "page_alloc.h"
#include "memory.h"

static struct page *free_list = NULL;
static uint32_t total_pages = 0;
static uint32_t free_pages = 0;

void page_alloc_init(void) {
    // 初始化页面描述符数组
    struct page *pages = (struct page *)0x200000;  // 假设放在 2MB 处
    
    // 遍历内存映射，将可用内存加入空闲链表
    for (int i = 0; i < memory_map_entries; i++) {
        if (memory_map[i].type != E820_RAM)
            continue;
            
        uint64_t start = memory_map[i].base;
        uint64_t end = start + memory_map[i].length;
        
        // 按页对齐
        start = (start + PAGE_SIZE - 1) & ~(PAGE_SIZE - 1);
        end = end & ~(PAGE_SIZE - 1);
        
        for (uint64_t addr = start; addr < end; addr += PAGE_SIZE) {
            uint32_t page_idx = addr / PAGE_SIZE;
            pages[page_idx].flags = PAGE_FLAG_FREE;
            pages[page_idx].ref_count = 0;
            pages[page_idx].next = free_list;
            free_list = &pages[page_idx];
            
            total_pages++;
            free_pages++;
        }
    }
    
    printf("Physical memory manager initialized\n");
    printf("Total pages: %d (%d MB)\n", 
           total_pages, total_pages * PAGE_SIZE / 1024 / 1024);
}

struct page *alloc_page(void) {
    if (free_list == NULL)
        return NULL;
        
    struct page *page = free_list;
    free_list = page->next;
    
    page->flags = 0;
    page->ref_count = 1;
    page->next = NULL;
    
    free_pages--;
    
    return page;
}

void free_page(struct page *page) {
    if (page == NULL)
        return;
        
    page->ref_count--;
    
    if (page->ref_count == 0) {
        page->flags = PAGE_FLAG_FREE;
        page->next = free_list;
        free_list = page;
        free_pages++;
    }
}

uint32_t get_free_pages(void) {
    return free_pages;
}
```

### 任务三：实现伙伴系统算法

实现 buddy system 内存分配算法，支持不同大小的内存块分配：

1. 维护多个大小级别的空闲链表
2. 实现内存块的分裂和合并
3. 优化内存分配效率

**参考代码：**

```c
// buddy.h
#ifndef BUDDY_H
#define BUDDY_H

#include <stdint.h>

#define MAX_ORDER 11  // 最大支持 2^11 = 2048 页 = 8MB

struct free_area {
    struct page *free_list;
    uint32_t nr_free;
};

void buddy_init(void);
void *buddy_alloc(uint32_t order);
void buddy_free(void *addr, uint32_t order);

#endif
```

```c
// buddy.c
#include "buddy.h"

static struct free_area free_areas[MAX_ORDER];

void buddy_init(void) {
    // 初始化各级空闲链表
    for (int i = 0; i < MAX_ORDER; i++) {
        free_areas[i].free_list = NULL;
        free_areas[i].nr_free = 0;
    }
    
    // 将初始内存块加入最高级链表
    // 实现细节省略
}

void *buddy_alloc(uint32_t order) {
    if (order >= MAX_ORDER)
        return NULL;
        
    // 查找足够大的空闲块
    int current_order = order;
    while (current_order < MAX_ORDER && 
           free_areas[current_order].free_list == NULL) {
        current_order++;
    }
    
    if (current_order >= MAX_ORDER)
        return NULL;
        
    // 从链表中取出一个块
    struct page *page = free_areas[current_order].free_list;
    free_areas[current_order].free_list = page->next;
    free_areas[current_order].nr_free--;
    
    // 分裂较大的块
    while (current_order > order) {
        current_order--;
        
        // 将伙伴块加入下一级链表
        struct page *buddy = page + (1 << current_order);
        buddy->next = free_areas[current_order].free_list;
        free_areas[current_order].free_list = buddy;
        free_areas[current_order].nr_free++;
    }
    
    return page;
}

void buddy_free(void *addr, uint32_t order) {
    struct page *page = (struct page *)addr;
    
    // 尝试与伙伴块合并
    while (order < MAX_ORDER - 1) {
        uint32_t buddy_idx = ((uint32_t)page) ^ (1 << order);
        struct page *buddy = (struct page *)buddy_idx;
        
        // 检查伙伴块是否空闲
        // 如果是，则合并；否则停止
        
        // 合并后继续尝试更高级别的合并
        order++;
    }
    
    // 将块加入相应级别的空闲链表
    page->next = free_areas[order].free_list;
    free_areas[order].free_list = page;
    free_areas[order].nr_free++;
}
```

### 任务四：编写内存管理测试用例

编写测试程序验证内存管理器的正确性：

1. 测试单页分配和释放
2. 测试大块内存分配
3. 测试内存耗尽情况
4. 压力测试

**参考代码：**

```c
// test_memory.c
#include "page_alloc.h"
#include "buddy.h"

void test_page_alloc(void) {
    printf("Testing page allocator...\n");
    
    struct page *pages[10];
    
    // 分配 10 个页面
    for (int i = 0; i < 10; i++) {
        pages[i] = alloc_page();
        if (pages[i] == NULL) {
            printf("Failed to allocate page %d\n", i);
            return;
        }
    }
    
    printf("Allocated 10 pages successfully\n");
    printf("Free pages: %d\n", get_free_pages());
    
    // 释放页面
    for (int i = 0; i < 10; i++) {
        free_page(pages[i]);
    }
    
    printf("Freed 10 pages successfully\n");
    printf("Free pages: %d\n", get_free_pages());
}

void test_buddy_system(void) {
    printf("Testing buddy system...\n");
    
    // 分配不同大小的内存块
    void *ptr1 = buddy_alloc(0);  // 1 page
    void *ptr2 = buddy_alloc(2);  // 4 pages
    void *ptr3 = buddy_alloc(4);  // 16 pages
    
    printf("Allocated blocks: %p, %p, %p\n", ptr1, ptr2, ptr3);
    
    // 释放内存
    buddy_free(ptr1, 0);
    buddy_free(ptr2, 2);
    buddy_free(ptr3, 4);
    
    printf("Freed all blocks\n");
}

void run_memory_tests(void) {
    test_page_alloc();
    test_buddy_system();
}
```

## 实验要求

### 功能要求

- [ ] 正确检测和解析物理内存信息
- [ ] 实现基本的页面分配和释放
- [ ] 实现 buddy system 算法
- [ ] 所有测试用例通过

### 性能要求

- 页面分配和释放的时间复杂度应为 O(1) 或 O(log n)
- 内存碎片率控制在合理范围内

### 代码要求

- 使用合适的数据结构
- 处理边界情况和错误
- 添加详细注释

## 实验报告

实验报告应包含：

1. **算法分析**：分析不同内存分配算法的优缺点
2. **设计文档**：说明数据结构和算法设计
3. **实现说明**：关键函数的实现细节
4. **测试报告**：测试结果和性能分析
5. **问题讨论**：遇到的问题和解决方案

## 参考资料

- [Understanding the Linux Virtual Memory Manager](https://www.kernel.org/doc/gorman/)
- [The Buddy Memory Allocation Technique](https://en.wikipedia.org/wiki/Buddy_memory_allocation)

## 思考题

1. 为什么选择页面作为内存管理的基本单位？
2. buddy system 如何减少外部碎片？
3. 如何改进内存分配器以支持 NUMA 架构？

## 提交说明

请按照 [提交规范](../guide/submission.md) 提交实验成果。
