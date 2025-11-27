## QEMU和gdb调试

本节将介绍本课程的软件模拟器调试工具 [QEMU](https://www.qemu.org) 模拟器，以及基于QEMU模拟器的gdb调试基本技巧。在我们提供的虚拟机环境中已经安装了可以完全模拟开发板功能的QEMU模拟器以及gdb工具链，大家可以善用于日常的开发调试中。

### QEMU的启动

 QEMU 的启动命令已经包含在之后我们发布给大家的代码文章中的 Makefile 文件当中，下面给出一段启动 QEMU 模拟器的命令行示例：

```bash
/home/stu/OSLab-RISC-V/qemu/riscv64-softmmu/qemu-system-riscv64 
    -nographic -machine virt -m 256M 
    -kernel /home/stu/OSLab-RISC-V/u-boot/u-boot 
    -bios none 
    -drive if=none,format=raw,id=image,file=./build/image 
    -device virtio-blk-device,drive=image
```

其中 `qemu-system-riscv64` 为 QEMU 模拟器；`-nographic -machine virt -m 256M` 参数表示虚拟板卡的配置：关闭图形界面，并且虚拟板卡的物理内存为 256M；`-kernel /home/stu/OSLab-RISC-V/u-boot/u-boot` 表示 QEMU 模拟器运行的 kernel 镜像的路径。

QEMU 为了模拟开发板的从 SD 卡加载和启动操作系统的流程，也模拟了类似的 USB 设备。上述命令行中的 `-drive if=none,format=raw,id=image,file=./build/image  -device virtio-blk-device,drive=image`，表示将 `./build/image` 文件作为块设备，其实也就是模拟出来的 SD 卡。在后续的实验框架中，需要将我们的操作系统制作为镜像，作为 QEMU 虚拟出来的 SD 卡使用。上述命令行中的整个流程表现为: QEMU 模拟器启动 u-boot ,随后在 u-boot 命令行中输入命令从 SD 卡中启动我们的操作系统。

!!! warning "注意"
    QEMU 的退出需要使用 ctrl+a x 这样的组合命令，注意是 ctrl+a 先一起按下去，然后按 x ，就可以看到 QEMU 模拟器被关闭，退回到 Linux 系统命令行。请大家注意不要随意使用其他的方法退出 QEMU ，可能会导致下一次 QEMU 启动失败。

### gdb调试

gdb 是功能强大的代码调试工具，RISC-V 版本的 gdb 命令为 riscv64-unknown-linux-gnu-gdb，已安装在我们的虚拟机环境中。输出该命令即可启动 gdb 。

在 gdb 命令行内输入 `target remote localhost:1234`，即可与 QEMU 模拟器连接，连接成功之后 QEMU 模拟器的运行被暂停，需要在 gdb 这边手动继续运行。注意，使用 `target remote` 连接 QEMU 之前请确保 QEMU 模拟器已经启动。通过 `symbol-file main` 命令可以载入符号表，此处的 `main` 为编译生成的文件名称。（要求 `gcc` 编译时加上 `-g` 选项）

gdb的一些常用命令：

- 设置断点：`b`，后面跟上内存地址或代码中的行数，例：`b *0xa0800000`

- 继续运行：`c`

- 单步运行（单条汇编指令）：`si`

- 查看当前寄存器内容：`i r`

- 查看特定寄存器的值：`p $a1` 或者 `p/x $a1`

- 查看内存内容：`x`，命令格式：`x/nfu [addr]`，n 是内存单元个数，f 是显示格式，u 是内存单元大小

- 显示指定地址之后的10条汇编指令：`x/10i addr`

- 显示指定地址之后的10条数据单元：`x/10x addr`

- 退出：`q`

以上只是一些基础的命令和使用例子，请大家自己搜索并使用 gdb 的各种功能，思考调试思路。
