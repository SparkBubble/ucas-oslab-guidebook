# 提交规范

本文档说明实验作业的提交要求和规范。

## 提交方式

### Git 仓库提交

每个学生将获得一个私有的 Git 仓库用于提交实验代码。

#### 1. 克隆仓库

```bash
# 替换 YOUR_STUDENT_ID 为你的学号
git clone https://github.com/ucas-os/lab-YOUR_STUDENT_ID.git
cd lab-YOUR_STUDENT_ID
```

#### 2. 创建实验分支

```bash
# 为每个实验创建独立分支
git checkout -b lab1
```

#### 3. 提交代码

```bash
# 添加文件
git add .

# 提交更改
git commit -m "lab1: 完成引导与中断实验"

# 推送到远程仓库
git push origin lab1
```

#### 4. 创建 Pull Request

在 GitHub 上创建 Pull Request，将实验分支合并到 main 分支。

**PR 标题格式**：`[Lab1] 引导与中断实验`

**PR 描述模板**：

```markdown
## 实验信息
- 学号：20xxxxxxxx
- 姓名：张三
- 实验名称：实验一 - 引导与中断

## 完成情况
- [x] 任务一：编写 Bootloader
- [x] 任务二：设置中断描述符表
- [x] 任务三：实现时钟中断
- [x] 任务四：实现键盘中断

## 测试结果
- 所有功能测试通过
- 性能测试结果：平均响应时间 < 1ms

## 遇到的问题
1. 问题描述...
   解决方法...

## 改进与优化
1. 优化了中断处理流程...

## 运行说明
\`\`\`bash
make clean
make
make run
\`\`\`
```

## 代码规范

### 目录结构

```
lab1/
├── boot/           # 引导程序
│   └── boot.asm
├── kernel/         # 内核代码
│   ├── main.c
│   ├── interrupt.c
│   └── idt.c
├── include/        # 头文件
│   ├── types.h
│   └── interrupt.h
├── lib/            # 库函数
│   └── string.c
├── Makefile        # 编译脚本
├── README.md       # 项目说明
└── report.pdf      # 实验报告
```

### 命名规范

#### 文件命名

- 源文件：小写字母，下划线分隔，如 `page_alloc.c`
- 头文件：小写字母，下划线分隔，如 `page_alloc.h`
- 汇编文件：小写字母，`.asm` 扩展名，如 `boot.asm`

#### 函数命名

```c
// 使用小写字母和下划线
void init_idt(void);
int alloc_page(void);
struct process *create_process(const char *name);

// 静态函数使用 static 关键字
static void helper_function(void);
```

#### 变量命名

```c
// 局部变量：小写字母和下划线
int page_count;
struct process *current_proc;

// 全局变量：避免使用，如必须使用则加前缀
static int g_total_pages;

// 常量：大写字母和下划线
#define MAX_PROCESSES 256
#define PAGE_SIZE 4096
```

#### 类型命名

```c
// 结构体：小写字母和下划线
struct page_table {
    // ...
};

// 类型定义：_t 后缀
typedef uint32_t pte_t;
typedef struct process process_t;

// 枚举：小写字母和下划线
enum proc_state {
    PROC_UNUSED,
    PROC_RUNNING,
    PROC_SLEEPING
};
```

### 代码风格

#### 缩进和空格

```c
// 使用 4 个空格缩进（不使用 Tab）
void function(void) {
    if (condition) {
        do_something();
    } else {
        do_other();
    }
}

// 运算符两边加空格
int result = a + b * c;

// 逗号后加空格
function(arg1, arg2, arg3);
```

#### 大括号位置

```c
// K&R 风格：左大括号在行尾
void function(void) {
    if (condition) {
        // code
    }
}

// 结构体定义：左大括号在行尾
struct data {
    int field;
};
```

#### 注释规范

```c
/**
 * 函数功能简述
 * 
 * @param arg1 参数1说明
 * @param arg2 参数2说明
 * @return 返回值说明
 */
int function(int arg1, int arg2) {
    // 单行注释：说明代码逻辑
    int result = arg1 + arg2;
    
    /*
     * 多行注释：
     * 详细说明复杂的算法或逻辑
     */
    return result;
}
```

### 头文件保护

```c
// header.h
#ifndef HEADER_H
#define HEADER_H

// 声明和定义...

#endif // HEADER_H
```

### 错误处理

```c
// 检查返回值
void *ptr = malloc(size);
if (ptr == NULL) {
    printf("Error: failed to allocate memory\n");
    return -1;
}

// 使用断言检查前置条件
#include <assert.h>
assert(ptr != NULL);
assert(size > 0);
```

## 文档要求

### README.md

必须包含以下内容：

```markdown
# 实验一：引导与中断

## 实验环境
- OS: Ubuntu 22.04
- GCC: 11.3.0
- QEMU: 6.2.0

## 编译方法
\`\`\`bash
make clean
make
\`\`\`

## 运行方法
\`\`\`bash
# 直接运行
make run

# 调试模式
make debug
\`\`\`

## 测试方法
\`\`\`bash
make test
\`\`\`

## 项目结构
- boot/: 引导程序
- kernel/: 内核代码
- include/: 头文件

## 已知问题
- 无

## 参考资料
- [OSDev Wiki](https://wiki.osdev.org/)
```

### 实验报告

实验报告应包含：

1. **封面**
   - 实验名称
   - 学号、姓名
   - 提交日期

2. **摘要**（200-300 字）
   - 实验目的
   - 主要工作
   - 关键成果

3. **实验原理**
   - 相关理论知识
   - 算法原理
   - 数据结构设计

4. **实验设计**
   - 系统架构
   - 模块划分
   - 接口设计

5. **实验实现**
   - 关键代码说明
   - 算法实现细节
   - 数据流程

6. **测试与分析**
   - 测试用例
   - 测试结果
   - 性能分析

7. **问题与总结**
   - 遇到的问题及解决方法
   - 实验心得
   - 改进建议

8. **参考文献**
   - 列出所有参考资料

**报告格式要求**：
- PDF 格式
- A4 纸张
- 正文使用小四号宋体
- 标题使用黑体
- 行间距 1.5 倍
- 页边距：上下 2.54cm，左右 3.17cm

## 提交检查清单

提交前请确认：

- [ ] 代码能够成功编译
- [ ] 所有测试用例通过
- [ ] 代码遵循命名和格式规范
- [ ] 添加了必要的注释
- [ ] README.md 完整且准确
- [ ] 实验报告格式正确
- [ ] Git 提交信息清晰
- [ ] 删除了调试代码和临时文件
- [ ] .gitignore 配置正确

## 评分标准

### 代码评分（50 分）

| 项目 | 分值 | 说明 |
|-----|------|------|
| 功能完整性 | 25 | 实现所有要求的功能 |
| 代码质量 | 15 | 代码结构清晰，规范性好 |
| 错误处理 | 5 | 正确处理异常情况 |
| 性能优化 | 5 | 代码效率高 |

### 报告评分（30 分）

| 项目 | 分值 | 说明 |
|-----|------|------|
| 内容完整性 | 10 | 包含所有必需章节 |
| 理解深度 | 10 | 展示对原理的理解 |
| 表达清晰度 | 5 | 逻辑清晰，易于理解 |
| 格式规范 | 5 | 符合格式要求 |

### 测试评分（10 分）

| 项目 | 分值 | 说明 |
|-----|------|------|
| 测试覆盖率 | 5 | 测试用例全面 |
| 测试质量 | 5 | 测试有效且充分 |

### 创新评分（10 分）

| 项目 | 分值 | 说明 |
|-----|------|------|
| 额外功能 | 5 | 实现额外有价值的功能 |
| 优化改进 | 5 | 对性能或设计的优化 |

## 迟交政策

- 迟交 1-7 天：扣除总分的 20%
- 迟交 8-14 天：扣除总分的 50%
- 迟交超过 14 天：不予接受

特殊情况请提前联系助教说明。

## 学术诚信

### 禁止行为

- ❌ 直接复制他人代码
- ❌ 抄袭网络代码未注明出处
- ❌ 代码雷同度过高
- ❌ 伪造实验数据

### 允许行为

- ✅ 参考文档和教材
- ✅ 与同学讨论思路
- ✅ 使用开源库（需注明）
- ✅ 引用资料并标注出处

### 违规处理

一经发现学术不诚信行为：
1. 首次：该实验成绩为 0
2. 再次：课程成绩为 F
3. 严重者：上报学院处理

## 联系方式

如有疑问，请通过以下方式联系：

- **邮箱**：ta@ucas.edu.cn
- **讨论群**：QQ 群 123456789
- **答疑时间**：每周三 14:00-16:00
- **地点**：计算机楼 201

## 常见问题

??? question "如何查看实验成绩？"
    实验成绩将在 PR 合并后 2 周内通过邮件发送。

??? question "可以使用第三方库吗？"
    原则上应使用标准库。如需使用第三方库，请在 README 中说明并在报告中解释原因。

??? question "代码可以用 C++ 写吗？"
    建议使用 C 语言。如使用 C++，需确保不使用运行时库功能（如异常、RTTI）。

??? question "如何处理编译警告？"
    所有警告都应消除。可使用 `-Wall -Werror` 编译选项。

---

祝你顺利完成实验！📚
