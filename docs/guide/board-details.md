## 附录：开发板内部细节

本节将描述我们的实验平台的一些细节，帮助大家理解前面的一部分可能会使大家感到困惑的地方。

### 概述

PYNQ-Z2上并没有真实的RISC-V芯片，它是一个载有ARM核和FPGA芯片的开发板。既然PYNQ上面是个ARM核，那么，我们为什么可以在其上使用RISC-V核呢？秘诀就在于它载有的FPGA芯片。FPGA是可编程门控阵列的简称，可以用来模拟各种数字电路。我们向SD卡的第一个分区拷贝了BOOT.BIN文件，该文件包含了一个ARM核上的程序和RISC-V软核。开发板启动后，首先会运行BOOT.BIN。BOOT.BIN中的ARM程序会启动与初始化板上的ARM核，并在完成后将RISC-V软核烧到FPGA芯片上，然后启动RISC-V核。RISC-V核启动后会执行BBL，它会帮我们把SD卡上我们自己写的bootloader(也就是第三个分区的头512字节)载入到内存的指定位置，并将控制权移交，从而完成启动的过程。自行制作SD卡的流程参见小节。

### 制作可启动的SD卡{subsec:make-sd-card
}

在拿到裸的开发板和SD卡以后，需要将SD卡格式化为三个分区。第一个分区固定为34MB，采用fat32文件系统；第二个分区建议设定为 100 MB，采用 ext4 文件系统；剩余空间全部划入第三个分区，保持第三个分区为空分区。前两个分区用于PYNQ板上的ARM核的启动与初始化，第三个分区由RISC-V核使用。完成本步的SD卡制作后，在我们的后续实验中，只需对第三个分区进行修改。

在Linux系统下，可以使用fdisk工具对SD卡进行分区：

```bash
// 非root用户请在前面加`sudo `
# fdisk /dev/sdb
// 此处/dev/sdb为你的SD卡设备名，可以使用lsblk命令确认设备名并自行参考修改

Welcome to fdisk (util-linux 2.34).
Changes will remain in memory only, until you decide to write them.
Be careful before using the write command.

Command (m for help):

```

注意，如果你使用的Linux设置了中文，fdisk可能会输出中文提示信息，不影响操作。另外，根据机器上磁盘配置情况的不同,你可能需要自己选择正确的磁盘。比如，这里示例中SD卡设备是/dev/sdb，但在你的机器上可能是/dev/sda或/dev/sdc。sd代表磁盘，一般的机械硬盘和U盘（读卡器）都会被列入这里。如果你的机器（或虚拟机）有一块机械硬盘，则新插入的SD卡可能是/dev/sdb（因为sda一般是机器自己的机械硬盘）。一个简单的方法是，先执行ls /dev/sd*命令，然后插上读卡器再执行一遍这个命令，看多出来的是哪个。比如插上读卡器后多出来了一个/dev/sdb，那么显然，读卡器就是这个/dev/sdb；另一种方法是使用lsblk命令列出所有块设备，根据显示的容量确定SD卡的设备名。

创建第一个分区的过程如下：

```bash
Command (m for help): o
Created a new DOS disklabel with disk identifier 0xae2c98d2.

Command (m for help): n
Partition type
   p   primary (0 primary, 0 extended, 4 free)
   e   extended (container for logical partitions)
Select (default p):

Using default response p.
Partition number (1-4, default 1):
First sector (2048-7626751, default 2048):
Last sector, +/-sectors or +/-size{K,M,G,T,P} (2048-7626751, default 7626751): +34M

Created a new partition 1 of type 'Linux' and of size 34 MiB.

Command (m for help): n
Partition type
   p   primary (1 primary, 0 extended, 3 free)
   e   extended (container for logical partitions)
Select (default p): 

Using default response p.
Partition number (2-4, default 2): 
First sector (71680-30253055, default 71680):      
Last sector, +/-sectors or +/-size{K,M,G,T,P} (71680-30253055, default 30253055): +100M

Created a new partition 2 of type 'Linux' and of size 100 MiB.

```

在fdisk提示输入命令的时候按上面的示例输入。先输入o新建分区表，再输入n新建新分区，然后都默认就可以，只是大小必须为34M。随后再输入 n 新建分区，然后默认，并设置大小为100M。

接下来创建第三个分区，并把第一个分区类型改为fat32，第二个分区改为 Linux，第三个分区设置为 empty。最后按w写入并退出fdisk。

```bash
Command (m for help): n
Partition type
   p   primary (2 primary, 0 extended, 2 free)
   e   extended (container for logical partitions)
Select (default p): 

Using default response p.
Partition number (3,4, default 3): 
First sector (276480-30253055, default 276480): 
Last sector, +/-sectors or +/-size{K,M,G,T,P} (276480-30253055, default 30253055): 

Created a new partition 3 of type 'Linux' and of size 14.3 GiB.

Command (m for help): t
Partition number (1,2, default 2): 1
Hex code (type L to list all codes): b

Changed type of partition 'Linux' to 'W95 FAT32'.

Command (m for help): t
Partition number (1,2, default 2): 2
Hex code or alias (type L to list all): 83

Changed type of partition 'Linux' to 'Linux'.

Command (m for help): t
Partition number (1-3, default 3): 3
Hex code or alias (type L to list all): 0
Type 0 means free space to many systems. Having partitions of type 0 is probably unwise.

Changed type of partition 'Linux' to 'Empty'.

Command (m for help): w

```

创建好分区后，首先需要为第一个分区制作文件系统。制作方法是用mkfs.vfat格式化第一个分区：

```bash
# sudo mkfs.vfat -I /dev/sdb1 -n "BOOT"

```

随后为第二个分区制作 ext4 文件系统，制作方法是使用 mkfs.ext4 工具： 

```bash
# sudo mkfs.ext4 -F /dev/sdb2 -L "ROOTFS"

```

以上两个分区的制作也请注意根据你自己的磁盘设备名情况调整sdb这个参数。

完成SD卡的分区制作以后，将预先提供的BOOT.BIN、boot.scr、image.ub拷入到第一个分区; rootfs.tar.gz 压缩包的内容解压到第二个分区，然后插入到开发板上，上电后就可以看到效果了。

!!! note
    
本材料中出现的shell中的\$和\#都代表命令行前面的提示符。\$代表普通用户，\#代表需要root权限。可以用sudo -i获得具有root权限的终端，而如果只需要以root权限执行某条命令，在命令前面加sudo即可。例如，如果想以root权限执行ls,则可以输入sudo ls。前面没加提示符的内容代表命令的执行结果。

### PYNQ内存地址空间情况

PYNQ板上的内存地址空间情况如表所示。其中，最需要注意的是，BBL所需的内存空间放置了BBL运行所需的数据和代码。请一定不要修改这段内存。BBL为我们提供了读写SD卡和输出字符串的相关服务。如果不小心修改了它的数据或代码，可能导致相关功能异常。

<!-- Table: PYNQ内存地址空间{tab:address-map -->

我们自己编写的内核可以使用的内存空间为0x50200000-0x60000000这一段地址。

另外一点需要注意的是，如果错误地读写了0x0或者其他非memory的地址，那么很有可能触发中断。由于在前面阶段的实验中，我们没有设置中断处理机制，所以一旦访问错误的地址，在开发板上看到的现象就是程序卡死，不再继续执行。建议在调试的时候，多使用QEMU+gdb，或者分成小段一点一点调试。在出现内存相关的错误的情况下，试图直接找到大段代码中的错误很困难，应该一小段一小段逐步缩小范围，从而正确地找到错误的发生位置。

