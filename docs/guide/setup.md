# 环境配置

本页面将指导您搭建 UCAS 操作系统实验的开发环境。

!!! info "环境说明"
    我们的开发环境以 Linux 操作系统为主，使用 RISC-V 交叉编译器、QEMU 虚拟机以及基于 FPGA 的 RISC-V 开发板。

## 快速搭建

为了让大家快速完成开发环境的搭建，我们已经将开发所需的环境集成到我们所给的 VirtualBox 虚拟机镜像中。

### Windows 环境搭建

1. 安装 VirtualBox
2. 导入我们提供的虚拟机镜像
3. 启动虚拟机，用户名 `stu`，密码 `123456`

### Linux 环境搭建

建议在 Linux 下也安装 VirtualBox，然后直接导入我们准备好的虚拟机。

## 工具链安装

详细的工具链安装说明请参考 Project 0 的文档。

## 验证环境

```bash
# 检查 RISC-V 工具链
riscv64-unknown-elf-gcc --version

# 检查 QEMU
qemu-system-riscv64 --version
```

## 常见问题

??? question "无法启动虚拟机？"
    请确保已经安装 VirtualBox 扩展包，并且在 BIOS 中启用了虚拟化支持。

??? question "编译错误？"
    请确保工具链路径已正确配置，可以运行 `which riscv64-unknown-elf-gcc` 检查。
