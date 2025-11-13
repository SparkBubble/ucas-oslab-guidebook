# 实验五：文件系统

## 实验目的

理解文件系统的组织结构和实现原理，掌握文件管理机制，实现一个简单但完整的文件系统。

## 背景知识

### 文件系统概述

文件系统负责管理存储设备上的数据：

- **文件**：数据的逻辑组织单位
- **目录**：文件的层次化组织结构
- **inode**：文件元数据的存储结构
- **数据块**：实际数据的存储单位

### 常见文件系统

- **ext2/ext3/ext4**：Linux 经典文件系统
- **FAT**：简单的文件分配表系统
- **NTFS**：Windows 文件系统

## 实验任务

### 任务一：设计文件系统布局

设计磁盘布局和数据结构：

```c
// fs.h
#ifndef FS_H
#define FS_H

#include <stdint.h>

#define BLOCK_SIZE      4096
#define INODE_SIZE      128
#define MAX_NAME_LEN    255
#define MAX_PATH_LEN    4096

// 文件系统超级块
struct superblock {
    uint32_t magic;             // 魔数
    uint32_t block_size;        // 块大小
    uint32_t total_blocks;      // 总块数
    uint32_t total_inodes;      // 总 inode 数
    uint32_t free_blocks;       // 空闲块数
    uint32_t free_inodes;       // 空闲 inode 数
    uint32_t inode_bitmap_block;// inode 位图起始块
    uint32_t block_bitmap_block;// 数据块位图起始块
    uint32_t inode_table_block; // inode 表起始块
    uint32_t data_block_start;  // 数据块起始位置
};

// inode 结构
struct inode {
    uint32_t mode;              // 文件类型和权限
    uint32_t uid;               // 用户 ID
    uint32_t gid;               // 组 ID
    uint32_t size;              // 文件大小
    uint32_t atime;             // 访问时间
    uint32_t mtime;             // 修改时间
    uint32_t ctime;             // 创建时间
    uint32_t nlinks;            // 硬链接数
    uint32_t blocks;            // 占用的块数
    uint32_t direct[12];        // 直接块指针
    uint32_t indirect;          // 一级间接块指针
    uint32_t double_indirect;   // 二级间接块指针
};

// 目录项
struct dirent {
    uint32_t inode;             // inode 号
    uint16_t rec_len;           // 记录长度
    uint8_t  name_len;          // 文件名长度
    uint8_t  file_type;         // 文件类型
    char     name[MAX_NAME_LEN];// 文件名
};

// 文件类型
#define FT_UNKNOWN  0
#define FT_REG_FILE 1
#define FT_DIR      2
#define FT_CHRDEV   3
#define FT_BLKDEV   4
#define FT_FIFO     5
#define FT_SOCK     6
#define FT_SYMLINK  7

void fs_init(void);
int fs_format(void);

#endif
```

### 任务二：实现 inode 管理

```c
// inode.c
#include "fs.h"

static struct superblock *sb;

struct inode *alloc_inode(void) {
    // 在 inode 位图中查找空闲 inode
    uint32_t inode_no = find_free_inode();
    if (inode_no == 0)
        return NULL;
        
    // 标记为已使用
    set_inode_bitmap(inode_no);
    sb->free_inodes--;
    
    // 获取 inode
    struct inode *inode = get_inode(inode_no);
    memset(inode, 0, sizeof(struct inode));
    
    return inode;
}

void free_inode(uint32_t inode_no) {
    // 清除 inode 位图
    clear_inode_bitmap(inode_no);
    sb->free_inodes++;
    
    // 释放数据块
    struct inode *inode = get_inode(inode_no);
    
    // 释放直接块
    for (int i = 0; i < 12; i++) {
        if (inode->direct[i])
            free_block(inode->direct[i]);
    }
    
    // 释放间接块
    if (inode->indirect) {
        free_indirect_block(inode->indirect);
    }
    
    if (inode->double_indirect) {
        free_double_indirect_block(inode->double_indirect);
    }
}

struct inode *get_inode(uint32_t inode_no) {
    uint32_t block_no = sb->inode_table_block + 
                        (inode_no * INODE_SIZE) / BLOCK_SIZE;
    uint32_t offset = (inode_no * INODE_SIZE) % BLOCK_SIZE;
    
    uint8_t buffer[BLOCK_SIZE];
    read_block(block_no, buffer);
    
    return (struct inode *)(buffer + offset);
}

void write_inode(uint32_t inode_no, struct inode *inode) {
    uint32_t block_no = sb->inode_table_block + 
                        (inode_no * INODE_SIZE) / BLOCK_SIZE;
    uint32_t offset = (inode_no * INODE_SIZE) % BLOCK_SIZE;
    
    uint8_t buffer[BLOCK_SIZE];
    read_block(block_no, buffer);
    
    memcpy(buffer + offset, inode, INODE_SIZE);
    
    write_block(block_no, buffer);
}
```

### 任务三：实现文件读写操作

```c
// file.c
#include "fs.h"

int file_open(const char *path, int flags) {
    // 解析路径，查找 inode
    uint32_t inode_no = path_to_inode(path);
    
    if (inode_no == 0 && (flags & O_CREAT)) {
        // 创建新文件
        inode_no = create_file(path);
    }
    
    if (inode_no == 0)
        return -1;
        
    // 分配文件描述符
    int fd = alloc_fd();
    if (fd < 0)
        return -1;
        
    // 初始化文件描述符
    struct file *file = get_file(fd);
    file->inode_no = inode_no;
    file->offset = 0;
    file->flags = flags;
    
    return fd;
}

int file_read(int fd, void *buf, size_t count) {
    struct file *file = get_file(fd);
    if (!file)
        return -1;
        
    struct inode *inode = get_inode(file->inode_no);
    
    // 检查读取范围
    if (file->offset >= inode->size)
        return 0;
        
    if (file->offset + count > inode->size)
        count = inode->size - file->offset;
        
    size_t bytes_read = 0;
    uint8_t *buffer = (uint8_t *)buf;
    
    while (bytes_read < count) {
        // 计算当前块号和偏移
        uint32_t block_idx = (file->offset + bytes_read) / BLOCK_SIZE;
        uint32_t block_off = (file->offset + bytes_read) % BLOCK_SIZE;
        
        // 获取物理块号
        uint32_t block_no = get_data_block(inode, block_idx);
        if (block_no == 0)
            break;
            
        // 读取块数据
        uint8_t block_buf[BLOCK_SIZE];
        read_block(block_no, block_buf);
        
        // 复制数据
        size_t to_copy = MIN(BLOCK_SIZE - block_off, count - bytes_read);
        memcpy(buffer + bytes_read, block_buf + block_off, to_copy);
        
        bytes_read += to_copy;
    }
    
    file->offset += bytes_read;
    
    return bytes_read;
}

int file_write(int fd, const void *buf, size_t count) {
    struct file *file = get_file(fd);
    if (!file)
        return -1;
        
    struct inode *inode = get_inode(file->inode_no);
    
    size_t bytes_written = 0;
    const uint8_t *buffer = (const uint8_t *)buf;
    
    while (bytes_written < count) {
        // 计算当前块号和偏移
        uint32_t block_idx = (file->offset + bytes_written) / BLOCK_SIZE;
        uint32_t block_off = (file->offset + bytes_written) % BLOCK_SIZE;
        
        // 获取或分配物理块
        uint32_t block_no = get_data_block(inode, block_idx);
        if (block_no == 0) {
            block_no = alloc_block();
            if (block_no == 0)
                break;
            set_data_block(inode, block_idx, block_no);
        }
        
        // 读取现有数据
        uint8_t block_buf[BLOCK_SIZE];
        if (block_off != 0 || count - bytes_written < BLOCK_SIZE) {
            read_block(block_no, block_buf);
        }
        
        // 写入新数据
        size_t to_copy = MIN(BLOCK_SIZE - block_off, count - bytes_written);
        memcpy(block_buf + block_off, buffer + bytes_written, to_copy);
        
        write_block(block_no, block_buf);
        
        bytes_written += to_copy;
    }
    
    // 更新文件大小
    if (file->offset + bytes_written > inode->size) {
        inode->size = file->offset + bytes_written;
        write_inode(file->inode_no, inode);
    }
    
    file->offset += bytes_written;
    
    return bytes_written;
}

void file_close(int fd) {
    free_fd(fd);
}
```

### 任务四：实现目录管理

```c
// directory.c
#include "fs.h"

int create_directory(const char *path) {
    // 分配 inode
    uint32_t inode_no = alloc_inode();
    if (inode_no == 0)
        return -1;
        
    struct inode *inode = get_inode(inode_no);
    inode->mode = S_IFDIR | 0755;
    inode->nlinks = 2;  // . 和父目录
    
    // 分配数据块
    uint32_t block_no = alloc_block();
    inode->direct[0] = block_no;
    inode->blocks = 1;
    
    // 创建 . 和 .. 目录项
    uint8_t buffer[BLOCK_SIZE];
    memset(buffer, 0, BLOCK_SIZE);
    
    struct dirent *dot = (struct dirent *)buffer;
    dot->inode = inode_no;
    dot->rec_len = sizeof(struct dirent);
    dot->name_len = 1;
    dot->file_type = FT_DIR;
    strcpy(dot->name, ".");
    
    struct dirent *dotdot = (struct dirent *)(buffer + dot->rec_len);
    uint32_t parent_inode = get_parent_inode(path);
    dotdot->inode = parent_inode;
    dotdot->rec_len = sizeof(struct dirent);
    dotdot->name_len = 2;
    dotdot->file_type = FT_DIR;
    strcpy(dotdot->name, "..");
    
    write_block(block_no, buffer);
    write_inode(inode_no, inode);
    
    // 在父目录中添加目录项
    add_dir_entry(parent_inode, basename(path), inode_no, FT_DIR);
    
    return 0;
}

int list_directory(const char *path) {
    uint32_t inode_no = path_to_inode(path);
    if (inode_no == 0)
        return -1;
        
    struct inode *inode = get_inode(inode_no);
    
    if (!(inode->mode & S_IFDIR))
        return -1;
        
    // 遍历目录项
    for (uint32_t i = 0; i < inode->blocks; i++) {
        uint32_t block_no = inode->direct[i];
        uint8_t buffer[BLOCK_SIZE];
        read_block(block_no, buffer);
        
        struct dirent *entry = (struct dirent *)buffer;
        
        while ((uint8_t *)entry < buffer + BLOCK_SIZE && 
               entry->inode != 0) {
            printf("%s\n", entry->name);
            entry = (struct dirent *)((uint8_t *)entry + entry->rec_len);
        }
    }
    
    return 0;
}

int remove_file(const char *path) {
    uint32_t inode_no = path_to_inode(path);
    if (inode_no == 0)
        return -1;
        
    struct inode *inode = get_inode(inode_no);
    
    // 减少链接计数
    inode->nlinks--;
    
    if (inode->nlinks == 0) {
        // 释放 inode 和数据块
        free_inode(inode_no);
    } else {
        write_inode(inode_no, inode);
    }
    
    // 从父目录中删除目录项
    uint32_t parent_inode = get_parent_inode(path);
    remove_dir_entry(parent_inode, basename(path));
    
    return 0;
}
```

## 实验要求

### 功能要求

- [ ] 设计合理的文件系统布局
- [ ] 实现 inode 的分配和管理
- [ ] 实现文件的读写操作
- [ ] 实现目录的创建和遍历
- [ ] 支持文件的创建和删除

### 测试要求

编写测试程序验证：

1. 文件系统格式化
2. 文件创建、读写、删除
3. 目录操作
4. 大文件读写性能
5. 并发访问（可选）

## 实验报告

实验报告应包含：

1. **文件系统设计**：说明磁盘布局和数据结构
2. **实现细节**：关键函数的实现说明
3. **性能分析**：文件操作的性能测试
4. **对比分析**：与其他文件系统的对比
5. **改进方向**：可能的优化和改进

## 参考资料

- [ext2 File System](https://www.nongnu.org/ext2-doc/)
- [File System Design](https://wiki.osdev.org/File_Systems)
- [Linux VFS](https://www.kernel.org/doc/html/latest/filesystems/)

## 思考题

1. 如何实现日志文件系统以提高可靠性？
2. 如何优化小文件的存储效率？
3. 如何实现文件系统的配额管理？

## 提交说明

请按照 [提交规范](../guide/submission.md) 提交实验成果。
