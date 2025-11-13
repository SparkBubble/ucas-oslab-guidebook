# 环境配置

本文档介绍如何搭建操作系统实验开发环境。

## 系统要求

### 硬件要求

- **CPU**：支持虚拟化的 x86-64 处理器
- **内存**：至少 4GB RAM（推荐 8GB 以上）
- **磁盘**：至少 20GB 可用空间

### 软件要求

支持的操作系统：

- Ubuntu 20.04 LTS 或更高版本
- Debian 11 或更高版本
- Fedora 35 或更高版本
- macOS 11 或更高版本（Intel 或 Apple Silicon）
- Windows 10/11（通过 WSL2）

## 安装步骤

### Linux 环境配置

#### 1. 安装基础工具

```bash
# Ubuntu/Debian
sudo apt update
sudo apt install -y build-essential git vim gdb qemu-system-x86 \
    nasm gcc make binutils

# Fedora
sudo dnf install -y gcc gcc-c++ git vim gdb qemu-system-x86 \
    nasm make binutils
```

#### 2. 安装交叉编译工具链

```bash
# 安装 i686-elf-gcc
sudo apt install -y gcc-multilib g++-multilib

# 或者从源码编译（可选）
# 参考：https://wiki.osdev.org/GCC_Cross-Compiler
```

#### 3. 验证安装

```bash
# 检查 gcc 版本
gcc --version

# 检查 nasm 版本
nasm --version

# 检查 QEMU 版本
qemu-system-i386 --version

# 检查 gdb 版本
gdb --version
```

### macOS 环境配置

#### 1. 安装 Homebrew

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

#### 2. 安装开发工具

```bash
# 安装 Xcode Command Line Tools
xcode-select --install

# 安装编译工具
brew install nasm gcc qemu gdb

# 安装交叉编译工具链
brew install i686-elf-gcc
```

### Windows (WSL2) 环境配置

#### 1. 安装 WSL2

打开 PowerShell（管理员模式）：

```powershell
wsl --install -d Ubuntu-22.04
```

重启计算机后，按照 Linux 环境配置步骤继续。

#### 2. 安装 Windows Terminal（可选）

从 Microsoft Store 安装 Windows Terminal，获得更好的终端体验。

## 配置开发环境

### 1. 克隆实验代码仓库

```bash
git clone https://github.com/ucas-os/oslab.git
cd oslab
```

### 2. 配置 Git

```bash
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"
```

### 3. 设置编辑器

推荐使用 VS Code：

```bash
# 安装 VS Code
# Ubuntu/Debian
sudo snap install code --classic

# macOS
brew install --cask visual-studio-code

# 安装推荐插件
code --install-extension ms-vscode.cpptools
code --install-extension ms-vscode.makefile-tools
```

### 4. 配置 Makefile

检查项目根目录的 Makefile，确保编译器路径正确：

```makefile
CC = gcc
AS = nasm
LD = ld
QEMU = qemu-system-i386
```

## 编译和运行

### 编译内核

```bash
make clean
make
```

### 运行内核

```bash
# 在 QEMU 中运行
make run

# 或者手动运行
qemu-system-i386 -kernel kernel.bin
```

### 调试内核

```bash
# 启动 QEMU 调试服务器
make debug

# 在另一个终端启动 GDB
gdb kernel.elf
(gdb) target remote localhost:1234
(gdb) break main
(gdb) continue
```

## 常见问题

### QEMU 无法启动

??? question "错误：Could not initialize SDL"
    ```bash
    # 解决方法：使用无显示模式
    qemu-system-i386 -kernel kernel.bin -nographic
    
    # 或者安装 SDL
    sudo apt install libsdl2-dev
    ```

### 编译错误

??? question "错误：multilib not found"
    ```bash
    # 安装 32 位库支持
    sudo apt install gcc-multilib g++-multilib
    ```

??? question "错误：nasm not found"
    ```bash
    # 安装 NASM
    sudo apt install nasm
    ```

### GDB 调试问题

??? question "无法连接到 QEMU"
    ```bash
    # 确保 QEMU 使用 -s -S 参数启动
    qemu-system-i386 -kernel kernel.bin -s -S
    
    # 在 GDB 中连接
    target remote localhost:1234
    ```

## 推荐工具

### 开发工具

- **编辑器**：VS Code、Vim、Emacs
- **调试器**：GDB、LLDB
- **虚拟机**：QEMU、VirtualBox、VMware

### 辅助工具

- **反汇编**：objdump、IDA Pro、Ghidra
- **十六进制编辑器**：hexdump、xxd
- **系统监控**：htop、iotop

## 进阶配置

### 配置 QEMU 网络

```bash
# 创建 TAP 接口
sudo ip tuntap add dev tap0 mode tap
sudo ip link set tap0 up
sudo ip addr add 192.168.1.1/24 dev tap0

# 使用 TAP 网络启动 QEMU
qemu-system-i386 -kernel kernel.bin \
    -netdev tap,id=net0,ifname=tap0,script=no,downscript=no \
    -device e1000,netdev=net0
```

### 配置自动化测试

创建测试脚本 `test.sh`：

```bash
#!/bin/bash

# 编译
make clean && make || exit 1

# 运行测试
timeout 10s qemu-system-i386 -kernel kernel.bin -nographic | \
    grep -q "Test passed" && echo "✓ Tests passed" || echo "✗ Tests failed"
```

### 使用 Docker 容器

```dockerfile
FROM ubuntu:22.04

RUN apt-get update && apt-get install -y \
    build-essential git nasm qemu-system-x86 gdb \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace

CMD ["/bin/bash"]
```

```bash
# 构建镜像
docker build -t oslab .

# 运行容器
docker run -it -v $(pwd):/workspace oslab
```

## 下一步

环境配置完成后，你可以：

1. 查看 [调试技巧](debugging.md) 学习调试方法
2. 阅读 [任务概览](../tasks/overview.md) 了解实验内容
3. 开始第一个实验：[引导与中断](../tasks/lab1.md)

## 参考资料

- [OSDev Wiki - Getting Started](https://wiki.osdev.org/Getting_Started)
- [QEMU Documentation](https://www.qemu.org/documentation/)
- [GDB Tutorial](https://www.gnu.org/software/gdb/documentation/)
