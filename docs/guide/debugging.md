# 调试技巧

操作系统开发过程中，调试是一个重要的环节。本页面介绍一些常用的调试技巧和工具。

## 使用 GDB 调试

GDB 是最重要的调试工具之一。

### 启动 QEMU 调试模式

```bash
make debug
```

### 在另一个终端连接 GDB

```bash
riscv64-unknown-elf-gdb kernel
(gdb) target remote :1234
(gdb) b main
(gdb) c
```

### 常用 GDB 命令

- `b <位置>`: 设置断点
- `c`: 继续执行
- `s`: 单步执行（进入函数）
- `n`: 单步执行（不进入函数）
- `p <变量>`: 打印变量值
- `info registers`: 查看寄存器
- `x/<n>x <地址>`: 查看内存

## 使用 printf 调试

最简单的调试方法是使用 printf 输出关键信息。

```c
printf("DEBUG: pid=%d, status=%d\n", pid, status);
```

## 内核 panic 处理

当内核遇到严重错误时，应该及时 panic 并输出错误信息：

```c
void panic(const char *msg) {
    printf("KERNEL PANIC: %s\n", msg);
    while(1);  // 停止执行
}
```

## 常见问题排查

### 程序卡死

1. 检查是否访问了错误的内存地址
2. 检查是否进入了死循环
3. 使用 GDB 查看当前 PC 值

### 随机崩溃

1. 检查栈溢出
2. 检查未初始化的变量
3. 检查数组越界

## 调试建议

!!! tip "调试技巧"
    - 多使用 QEMU + GDB 而不是直接在板卡上调试
    - 分小段测试代码，不要一次写太多
    - 保持代码简洁，添加必要的注释
    - 遇到问题多查看日志和错误信息
