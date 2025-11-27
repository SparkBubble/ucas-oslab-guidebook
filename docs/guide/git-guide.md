## Git介绍

Git 是一个免费的开源分布式版本控制系统。在其 [官网](https://git-scm.com/) 上的原话是这样的：

> Git is a free and open source distributed version control system designed to handle everything from small to very large projects with speed and efficiency.

> Git is easy to learn and has a tiny footprint with lightning fast performance. It outclasses SCM tools like Subversion, CVS, Perforce, and ClearCase with features like cheap local branching, convenient staging areas, and multiple workflows.


### Git介绍

我猜很多国内的同学在了解 Git 之前，先知道了 Github 这个网站。可能也有相当多的同学在知道如何使用 Git 之前，就已经先在 Github 上下载过不少源代码、文件来使用。实际上，Github 是一个基于 Git 建立的第三方仓库，或者说是一个帮你存储代码版本的远程仓库。在使用 Git 管理代码的版本时，你可以选择将 Git 产生的一整套东西推送至远程仓库，以方便进行代码备份、合作，而 Github 就是一个能够提供帮助的网站。

简单地说，Git 为每个仓库组织了一个类似有向无环图的数据结构，其结点是不同的版本，而其有向边是每次对仓库中文件进行的修改。Git 在版本库中存储不同版本的快照，如果有需要，可以选择其中一个进行阅读、修改。另外，Git 仓库中存在一个暂存区，里面是未保存到特定版本的临时修改。

为什么要使用 Git 呢？这源于代码管理中遇到的现实问题。对于比较大的项目，我们不太可能一个阶段完成修改，在尝试新的一阶段的时候很可能翻车。如果直接在一份代码上修改，就找不到修改前的版本了，容易引入新的 bug，或者进行错误修改。这时候，我们就需要一个能以版本为单位管理代码的工具了。如果有更多的工作需要多人分工协作完成，如何让其他成员获得最新修改的代码？如果多人修改了同一个文件，如何合并不同的修改，以形成一个稳定的版本？这就需要一个分布式的代码管理系统，来让分布在各处的修改便于统一整合。在本地，Git 可以记录修改信息，管理不同版本，以实现对比和回退等功能。再通过云服务器，Git 也可以实现代码的备份以及多人修改的合并。

虽然本实验并不涉及多人合作的情况，但很有可能需要同学们在多个平台对代码进行测试，所以建议还不擅长使用 Git 的同学们尽快熟悉其使用方法。

### Git简单命令

我们建议同学们自行在网络上搜寻与 Git 有关的资料进行学习。这里列出几条同学们应当学会使用的指令：

    
- `git add`：将当前工作区的修改加到暂存区。
    
    `git add <file1> ...` 或用 . 代表所有文件
    
    
- `git commit`：将暂存区中的修改确认并提交到当前分支（记为 HEAD），这将记录一个版本（默认会有一个 master 分支），并且清空暂存区
    
    `git commit -m <commit message>` 其中 `<commit message>` 为本次提交的备注信息字符串。在命令行中输入字符串时若含有空格，可使用双引号`""`将其包括起来。
    
    
- `git checkout` 可以切换当前代码的版本

    
- `git branch` 可以控制不同分支
    
    
- `git reset` 可以进行版本回退。这是一个危险操作，请慎用。
    
    
- `git log` 可以查看不同版本的信息。
    
    
- `git merge` 可以进行不同分支的合并。
    
    
- `git rebase` 可以将一个分支的起始位置切换到其他地方。
    
    
- `git tag` 可以控制标签。

    
- `git show` 可以展示标签。

    
- `git clone` 克隆远程仓库到本地

    
- `git remote` 和云端仓库有关的操作。例如：`git remote add upstream <URL>` 添加一个远端仓库并标记为 upstream
    
    
- `git pull` 拉取云端仓库的修改到本地。例如：`git pull upstream master`

    
- `git push` 推送本地仓库的修改到云端。例如：`git push origin master`

### Git学习指南

请通过查阅网络、阅读手册的方式学习 Git 的使用。建议学习 [MIT The Missing Semester的版本控制一课](https://missing-semester-cn.github.io/2020/version-control/) 。
