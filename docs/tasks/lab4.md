# 实验四：进程管理

## 实验目的

理解进程的概念和生命周期，掌握进程调度算法和同步机制，实现完整的进程管理子系统。

## 背景知识

### 进程概述

进程是操作系统资源分配和调度的基本单位：

- **进程状态**：就绪、运行、阻塞、终止
- **进程上下文**：寄存器、栈、页表等
- **进程调度**：确定哪个进程获得 CPU
- **进程同步**：协调多个进程的执行

## 实验任务

### 任务一：实现进程控制块

设计并实现 PCB 数据结构：

```c
// process.h
#ifndef PROCESS_H
#define PROCESS_H

#include <stdint.h>

#define MAX_PROCESSES 256

enum proc_state {
    PROC_UNUSED,
    PROC_EMBRYO,
    PROC_RUNNABLE,
    PROC_RUNNING,
    PROC_SLEEPING,
    PROC_ZOMBIE
};

struct context {
    uint32_t edi;
    uint32_t esi;
    uint32_t ebx;
    uint32_t ebp;
    uint32_t eip;
};

struct process {
    uint32_t pid;                   // 进程 ID
    enum proc_state state;          // 进程状态
    struct process *parent;         // 父进程
    struct context *context;        // 保存的上下文
    void *kstack;                   // 内核栈
    struct page_directory *pgdir;   // 页目录
    uint32_t priority;              // 优先级
    uint32_t time_slice;            // 时间片
    uint32_t total_time;            // 总运行时间
    char name[32];                  // 进程名
};

void process_init(void);
struct process *create_process(const char *name, void (*entry)(void));
void exit_process(int status);
int wait_process(int pid);

#endif
```

### 任务二：实现进程创建和销毁

```c
// process.c
#include "process.h"

static struct process processes[MAX_PROCESSES];
static struct process *current_proc = NULL;
static uint32_t next_pid = 1;

void process_init(void) {
    memset(processes, 0, sizeof(processes));
    
    // 创建 init 进程
    struct process *init = &processes[0];
    init->pid = 0;
    init->state = PROC_RUNNING;
    init->parent = NULL;
    strcpy(init->name, "init");
    
    current_proc = init;
}

struct process *create_process(const char *name, void (*entry)(void)) {
    // 查找空闲 PCB
    struct process *proc = NULL;
    for (int i = 0; i < MAX_PROCESSES; i++) {
        if (processes[i].state == PROC_UNUSED) {
            proc = &processes[i];
            break;
        }
    }
    
    if (!proc)
        return NULL;
        
    // 初始化 PCB
    proc->pid = next_pid++;
    proc->state = PROC_EMBRYO;
    proc->parent = current_proc;
    strcpy(proc->name, name);
    
    // 分配内核栈
    proc->kstack = alloc_page();
    
    // 分配页目录
    proc->pgdir = (struct page_directory *)alloc_page();
    memcpy(proc->pgdir, kernel_pd, PAGE_SIZE);
    
    // 设置初始上下文
    proc->context = (struct context *)(proc->kstack + PAGE_SIZE - sizeof(struct context));
    memset(proc->context, 0, sizeof(struct context));
    proc->context->eip = (uint32_t)entry;
    
    // 设置调度参数
    proc->priority = 10;
    proc->time_slice = 10;
    proc->total_time = 0;
    
    proc->state = PROC_RUNNABLE;
    
    printf("Created process %d: %s\n", proc->pid, proc->name);
    
    return proc;
}

void exit_process(int status) {
    current_proc->state = PROC_ZOMBIE;
    
    printf("Process %d exited with status %d\n", current_proc->pid, status);
    
    // 唤醒父进程
    if (current_proc->parent && 
        current_proc->parent->state == PROC_SLEEPING) {
        current_proc->parent->state = PROC_RUNNABLE;
    }
    
    // 重新调度
    schedule();
}

int wait_process(int pid) {
    struct process *child = NULL;
    
    // 查找子进程
    for (int i = 0; i < MAX_PROCESSES; i++) {
        if (processes[i].parent == current_proc && 
            (pid == -1 || processes[i].pid == pid)) {
            child = &processes[i];
            break;
        }
    }
    
    if (!child)
        return -1;
        
    // 等待子进程结束
    while (child->state != PROC_ZOMBIE) {
        current_proc->state = PROC_SLEEPING;
        schedule();
    }
    
    // 回收子进程资源
    int status = 0;  // 获取退出状态
    
    free_page(child->kstack);
    free_page(child->pgdir);
    child->state = PROC_UNUSED;
    
    return status;
}
```

### 任务三：实现进程调度器

实现优先级调度算法：

```c
// scheduler.c
#include "process.h"

extern struct process *current_proc;

struct process *pick_next_process(void) {
    struct process *next = NULL;
    uint32_t max_priority = 0;
    
    // 选择优先级最高的就绪进程
    for (int i = 0; i < MAX_PROCESSES; i++) {
        if (processes[i].state == PROC_RUNNABLE && 
            processes[i].priority > max_priority) {
            max_priority = processes[i].priority;
            next = &processes[i];
        }
    }
    
    return next;
}

void schedule(void) {
    struct process *prev = current_proc;
    struct process *next = pick_next_process();
    
    if (!next)
        next = prev;  // 没有其他就绪进程，继续运行当前进程
        
    if (next == prev)
        return;
        
    // 保存当前进程状态
    if (prev->state == PROC_RUNNING)
        prev->state = PROC_RUNNABLE;
        
    // 切换到新进程
    next->state = PROC_RUNNING;
    current_proc = next;
    
    printf("Switching from %s to %s\n", prev->name, next->name);
    
    // 上下文切换
    switch_context(&prev->context, next->context);
}

void timer_tick(void) {
    if (!current_proc)
        return;
        
    current_proc->total_time++;
    current_proc->time_slice--;
    
    // 时间片用完，重新调度
    if (current_proc->time_slice <= 0) {
        current_proc->time_slice = 10;  // 重置时间片
        schedule();
    }
}
```

### 任务四：实现进程同步机制

实现信号量和互斥锁：

```c
// sync.h
#ifndef SYNC_H
#define SYNC_H

#include <stdint.h>

// 信号量
struct semaphore {
    int value;
    struct process *wait_queue[MAX_PROCESSES];
    int wait_count;
};

// 互斥锁
struct mutex {
    int locked;
    struct process *owner;
    struct process *wait_queue[MAX_PROCESSES];
    int wait_count;
};

void sem_init(struct semaphore *sem, int value);
void sem_wait(struct semaphore *sem);
void sem_post(struct semaphore *sem);

void mutex_init(struct mutex *mutex);
void mutex_lock(struct mutex *mutex);
void mutex_unlock(struct mutex *mutex);

#endif
```

```c
// sync.c
#include "sync.h"
#include "process.h"

void sem_init(struct semaphore *sem, int value) {
    sem->value = value;
    sem->wait_count = 0;
}

void sem_wait(struct semaphore *sem) {
    // 关中断，保证原子性
    disable_interrupts();
    
    sem->value--;
    
    if (sem->value < 0) {
        // 加入等待队列
        sem->wait_queue[sem->wait_count++] = current_proc;
        current_proc->state = PROC_SLEEPING;
        
        enable_interrupts();
        schedule();  // 让出 CPU
    } else {
        enable_interrupts();
    }
}

void sem_post(struct semaphore *sem) {
    disable_interrupts();
    
    sem->value++;
    
    if (sem->value <= 0 && sem->wait_count > 0) {
        // 唤醒一个等待进程
        struct process *proc = sem->wait_queue[0];
        
        // 移除队首元素
        for (int i = 0; i < sem->wait_count - 1; i++) {
            sem->wait_queue[i] = sem->wait_queue[i + 1];
        }
        sem->wait_count--;
        
        proc->state = PROC_RUNNABLE;
    }
    
    enable_interrupts();
}

void mutex_init(struct mutex *mutex) {
    mutex->locked = 0;
    mutex->owner = NULL;
    mutex->wait_count = 0;
}

void mutex_lock(struct mutex *mutex) {
    disable_interrupts();
    
    while (mutex->locked) {
        // 加入等待队列
        mutex->wait_queue[mutex->wait_count++] = current_proc;
        current_proc->state = PROC_SLEEPING;
        
        enable_interrupts();
        schedule();
        disable_interrupts();
    }
    
    mutex->locked = 1;
    mutex->owner = current_proc;
    
    enable_interrupts();
}

void mutex_unlock(struct mutex *mutex) {
    disable_interrupts();
    
    if (mutex->owner != current_proc) {
        printf("Warning: trying to unlock mutex not owned by current process\n");
        enable_interrupts();
        return;
    }
    
    mutex->locked = 0;
    mutex->owner = NULL;
    
    if (mutex->wait_count > 0) {
        // 唤醒一个等待进程
        struct process *proc = mutex->wait_queue[0];
        
        for (int i = 0; i < mutex->wait_count - 1; i++) {
            mutex->wait_queue[i] = mutex->wait_queue[i + 1];
        }
        mutex->wait_count--;
        
        proc->state = PROC_RUNNABLE;
    }
    
    enable_interrupts();
}
```

## 实验要求

### 功能要求

- [ ] 实现完整的进程控制块
- [ ] 正确创建和销毁进程
- [ ] 实现进程调度算法
- [ ] 实现信号量和互斥锁
- [ ] 处理进程间的父子关系

### 测试要求

编写测试程序验证：

1. 进程创建和销毁
2. 进程调度的公平性
3. 同步机制的正确性
4. 生产者-消费者问题
5. 哲学家就餐问题（可选）

## 实验报告

实验报告应包含：

1. **进程管理原理**：说明进程的概念和生命周期
2. **调度算法分析**：分析不同调度算法的特点
3. **同步机制设计**：说明信号量和互斥锁的实现
4. **测试与分析**：展示测试结果和性能分析
5. **死锁问题**：讨论死锁的预防和检测

## 参考资料

- [Operating System Concepts](https://www.os-book.com/)
- [Linux Kernel Development](https://www.kernel.org/doc/)

## 思考题

1. 如何避免优先级反转问题？
2. 实现读写锁有什么优势？
3. 如何实现多核调度？

## 提交说明

请按照 [提交规范](../guide/submission.md) 提交实验成果。
