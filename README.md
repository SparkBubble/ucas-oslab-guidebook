# UCAS 操作系统研讨课任务书

国科大操作系统研讨课线上任务书 - 基于 Material for MkDocs

## 简介

本项目为中国科学院大学（UCAS）操作系统研讨课程提供在线任务书和实验指导文档。

## 在线访问

📖 文档地址：[https://sparkbubble.github.io/ucas-oslab-guidebook/](https://sparkbubble.github.io/ucas-oslab-guidebook/)

## 内容概览

### 实验任务
- **Project 0**: 准备知识 - 环境搭建、RISC-V 基础、工具链
- **Project 1**: 引导、镜像文件和ELF文件 - 系统引导、镜像制作
- **Project 2**: 简易内核实现 - 进程管理、调度、系统调用
- **Project 3**: 进程管理、通信与多核执行 - Shell、IPC、多核调度

### 开发指南
- 课程介绍 - 课程背景和目标
- 环境搭建 - 开发环境配置（Linux/Windows）
- Linux 基础 - 常用命令和操作
- Git 使用指南 - 版本控制和协作
- RISC-V 入门 - 架构介绍和汇编基础
- 编译工具链 - 交叉编译器和相关工具
- QEMU 调试 - 虚拟机和 GDB 调试方法
- 提交规范 - 代码规范、文档要求、评分标准
- 附录 - 其他资源和参考资料

## 本地开发

### 环境要求
- Python 3.x
- pip

### 安装依赖

```bash
pip install mkdocs-material
```

### 本地预览

```bash
# 启动开发服务器
mkdocs serve

# 浏览器访问 http://localhost:8000
```

### 构建网站

```bash
mkdocs build
```

生成的静态网站将位于 `site/` 目录。

## 项目结构

```
.
├── docs/                   # 文档源文件
│   ├── index.md           # 首页
│   ├── tasks/             # 实验任务
│   │   ├── overview.md    # 任务概览
│   │   ├── p1.md          # Project 1
│   │   ├── p2.md          # Project 2
│   │   └── p3.md          # Project 3
│   └── guide/             # 开发指南
│       ├── intro.md               # 课程介绍
│       ├── environment-setup.md   # 环境搭建
│       ├── linux-basics.md        # Linux 基础
│       ├── git-guide.md           # Git 使用
│       ├── riscv-intro.md         # RISC-V 入门
│       ├── toolchain.md           # 编译工具链
│       ├── qemu-debugging.md      # QEMU 调试
│       ├── submission.md          # 提交规范
│       └── appendix.md            # 附录
├── mkdocs.yml             # MkDocs 配置文件
├── requirements.txt       # Python 依赖
└── .github/
    └── workflows/
        └── deploy.yml     # GitHub Actions 部署配置
```

## 技术栈

- [MkDocs](https://www.mkdocs.org/) - 静态站点生成器
- [Material for MkDocs](https://squidfunk.github.io/mkdocs-material/) - Material Design 主题
- [PyMdown Extensions](https://facelessuser.github.io/pymdown-extensions/) - Markdown 扩展
- [GitHub Pages](https://pages.github.com/) - 网站托管

## 特性

✨ Material Design 主题  
✨ 响应式设计，支持移动端  
✨ 自动化部署到 GitHub Pages  
✨ 深色/浅色模式切换  
✨ 中文搜索支持  
✨ 代码高亮  
✨ Mermaid 图表支持  

## 贡献

欢迎提交 Issue 和 Pull Request 来改进文档内容。

## 许可

Copyright © 2025 UCAS OS Lab
