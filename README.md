## 目录

1. [项目介绍](#一项目介绍)
   - [前提条件](#1前提条件)
   - [适配镜像](#2适配镜像)
   - [核心特性](#3核心特性)
2. [功能特性](#二功能特性)
   - [核心模块 (Core)](#1核心模块-core)
   - [运行时模块 (Runtime)](#2运行时模块-runtime)
   - [存储模块 (Storage)](#3存储模块-storage)
   - [验证模块 (Verification)](#4验证模块-verification)
3. [快速开始](#三快速开始)
   - [一键安装](#1一键安装)
   - [下载安装](#2下载安装)
   - [注意事项](#3注意事项)
4. [参数说明](#四参数说明)
5. [安装内容](#五安装内容)
   - [核心模块安装的软件包](#1核心模块安装的软件包)
   - [运行时模块安装的软件](#2运行时模块安装的软件)
   - [存储模块安装的软件](#3存储模块安装的软件)
6. [系统优化内容](#六系统优化内容)
   - [内核参数优化](#1内核参数优化)
   - [安全配置](#2安全配置)
   - [网络优化](#3网络优化)
7. [验证功能](#七验证功能)
   - [安装过程中的验证](#1安装过程中的验证)
   - [独立验证](#2独立验证)
8. [常见问题](#八常见问题)
9. [故障排查](#九故障排查)
10. [声明](#十声明)

## 一、项目介绍

一个模块化的 Ubuntu 24.04 系统初始化工具，专为官方 Ubuntu 24.04.3 LTS (Noble Numbat) 镜像定制和优化。

### 1、前提条件

执行本项目脚本需要以下前提条件：
- **sudo 权限**：用户必须具有 sudo 权限，并且能够免密码执行 sudo 命令
- **网络连接**：系统需要具备互联网连接，用于下载软件包和更新
- **官方镜像**：使用官方 Ubuntu 24.04.3 LTS noble-server-cloudimg 镜像

### 2、适配镜像

本项目专为以下官方 Ubuntu 24.04.3 LTS 镜像定制和优化：
- **镜像来源**：[https://cloud-images.ubuntu.com/noble/current/](https://cloud-images.ubuntu.com/noble/current/)
- **镜像名称**：noble-server-cloudimg
- **系统版本**：Ubuntu 24.04.3 LTS (Noble Numbat)
- **架构支持**：amd64、arm64

### 3、核心特性

- **模块化设计**：核心模块、运行时模块、存储模块可独立选择安装
- **验证功能**：安装过程中集成验证功能，确保所有模块安装成功
- **网络环境检测**：自动检测网络环境，选择最佳下载源
- **GitHub加速**：国内网络环境下自动使用加速服务，提高下载速度
- **自动化配置**：Docker GPG key自动覆盖，无交互式提示
- **智能配置**：根据系统内存自动计算最优参数
- **全面验证**：提供独立的验证脚本，支持根据安装方式选择验证模块

## 二、功能特性

### 1、核心模块 (Core)
- 系统基础优化与更新
- 必备工具软件安装
- 网络与安全配置
- 内核参数调优
- 时区与时间同步设置
- 系统日志配置
- 自动检测网络环境

### 2、运行时模块 (Runtime)
- Containerd 容器运行时安装
- Nerdctl 容器管理工具配置
- 网络模块加载与配置
- 容器相关内核参数优化
- GitHub加速下载支持
- Docker GPG key自动覆盖
- Nerdctl日志参数配置

### 3、存储模块 (Storage)
- Longhorn 存储依赖配置
- iSCSI 与 LVM 模块加载
- 存储相关内核参数调优
- iSCSI 性能优化
- multipathd 服务禁用

### 4、验证模块 (Verification)
- 核心模块验证
- 运行时模块验证
- 存储模块验证
- 根据安装方式选择验证模块

## 三、快速开始

### 1、一键安装

**国内网络选择 jsdelivr CDN 加速连接**

- **全量安装**

```bash
curl -sSL https://raw.githubusercontent.com/caleee/ubuntu-cloud-init/main/setup.sh | bash
```
```bash
curl -sSL https://cdn.jsdelivr.net/gh/caleee/ubuntu-cloud-init@main/setup.sh | bash
```

- **只做系统优化（不做容器和存储）**

```bash
curl -sSL https://raw.githubusercontent.com/caleee/ubuntu-cloud-init/main/setup.sh | bash -s -- --no-runtime --no-storage
```
```bash
curl -sSL https://cdn.jsdelivr.net/gh/caleee/ubuntu-cloud-init@main/setup.sh | bash -s -- --no-runtime --no-storage
```

- **只安装核心系统和容器运行时**

```bash
curl -sSL https://raw.githubusercontent.com/caleee/ubuntu-cloud-init/main/setup.sh | bash -s -- --no-storage
```
```bash
curl -sSL https://cdn.jsdelivr.net/gh/caleee/ubuntu-cloud-init@main/setup.sh | bash -s -- --no-storage
```

- **只安装核心系统和存储依赖**

```bash
curl -sSL https://raw.githubusercontent.com/caleee/ubuntu-cloud-init/main/setup.sh | bash -s -- --no-runtime
```
```bash
curl -sSL https://cdn.jsdelivr.net/gh/caleee/ubuntu-cloud-init@main/setup.sh | bash -s -- --no-runtime
```

- **验证安装结果**

```bash
curl -sSL https://raw.githubusercontent.com/caleee/ubuntu-cloud-init/main/verify.sh | bash
```
```bash
curl -sSL https://cdn.jsdelivr.net/gh/caleee/ubuntu-cloud-init@main/verify.sh | bash
```

### 2、下载安装

**克隆项目仓库 或 下载release版本 或 直接下载项目zip包**

```bash
# 进入项目目录
cd ubuntu-cloud-init

# 全量安装
bash setup.sh

# 只做系统优化（不做容器和存储）
bash setup.sh --no-runtime --no-storage

# 只安装核心系统和容器运行时
bash setup.sh --no-storage

# 只安装核心系统和存储依赖
bash setup.sh --no-runtime

# 验证安装结果
bash verify.sh
```

### 3、注意事项

- **智能依赖处理**：setup.sh 脚本现在具有自动检测和下载缺失脚本文件的功能，即使直接使用 curl 管道执行也能正常工作
- **国内访问**：国内用户使用 jsdelivr CDN 可以获得更好的访问速度，解决 GitHub 访问困难的问题
- **网络问题**：如果遇到网络问题，请尝试使用不同的安装方式
- **权限要求**：执行脚本需要 sudo 权限，并且能够免密码执行 sudo 命令
- **系统要求**：仅支持 Ubuntu 24.04 LTS 版本
- **自动重启**：默认情况下，脚本执行完成后会自动重启系统
- **备份数据**：执行前请确保重要数据已备份
- **验证功能**：安装完成后会自动进行验证，确保所有功能正常
- **网络环境**：脚本会自动检测网络环境，选择最佳下载源

## 四、参数说明

| 参数 | 说明 |
|------|------|
| `--no-runtime` | 跳过容器运行时模块的安装和配置 |
| `--no-storage` | 跳过存储依赖模块的安装和配置 |
| `--no-reboot` | 执行完成后不自动重启系统（默认会重启） |

## 五、安装内容

### 1、核心模块安装的软件包
- 基础与传输：apt-transport-https, ca-certificates, curl, wget, gnupg, lsb-release
- 网络诊断：net-tools, iputils-ping, dnsutils, tcpdump, traceroute
- 监控与调试：htop, iotop, sysstat, lsof, strace
- 效率工具：vim, git, jq, rsync, unzip, zip, bash-completion

### 2、运行时模块安装的软件
- containerd.io (来自 Docker 官方源或国内镜像源)
- nerdctl-full (容器管理工具，自动选择最佳下载源)

### 3、存储模块安装的软件
- open-iscsi (iSCSI 客户端)
- nfs-common (NFS 客户端)
- util-linux (系统工具)

## 六、系统优化内容

### 1、内核参数优化
- 启用 TCP BBR 拥塞控制算法
- 优化 TCP 连接回收
- 增加文件句柄限制
- 优化内存管理
- 增加网络连接数限制
- 容器网络相关参数优化

### 2、安全配置
- 关闭 UFW 防火墙（请根据实际环境调整）
- 永久关闭 Swap
- 配置系统日志限制

### 3、网络优化
- 自动检测网络环境
- 国内网络环境下使用加速服务
- 优化网络连接超时设置
- 增加网络连接重试机制

## 七、验证功能

### 1、安装过程中的验证
- 核心模块安装完成后自动验证
- 运行时模块安装完成后自动验证
- 存储模块安装完成后自动验证
- 验证失败时立即停止安装过程

### 2、独立验证
- 可单独运行验证脚本进行验证
- 支持根据需要选择验证模块
- 详细的验证结果输出

## 八、常见问题

### Q: 执行脚本时出现权限错误
A: 请确保您的用户具有 sudo 权限，并且在执行过程中能够正确输入密码

### Q: 网络连接失败导致安装中断
A: 请检查网络连接后重新执行脚本，脚本具有部分幂等性

### Q: 不需要自动重启系统怎么办
A: 使用 `--no-reboot` 参数跳过自动重启

### Q: 可以在现有系统上执行吗
A: 可以，但建议在新安装的系统上执行以获得最佳效果

### Q: 验证失败怎么办
A: 检查验证输出的错误信息，根据提示修复问题后重新执行脚本

### Q: 国内网络下载速度慢怎么办
A: 脚本会自动检测网络环境，在国内网络环境下使用加速服务

## 九、故障排查

- **检查日志**：执行过程中的输出会显示详细信息

- **查看系统状态**：使用 `systemctl status` 检查服务状态

- **验证安装**：执行完成后可以使用 `nerdctl version` 验证容器运行时安装

- **运行验证脚本**：使用 `bash verify.sh` 进行全面验证

## 十、声明

- 仅用于定制和优化官方 Ubuntu 24.04.3 LTS noble-server-cloudimg 镜像，不建议在其他系统上使用。
- 部分内容为 AI 生成，多轮测试未发现问题，但不保证准确性和可靠性，仅供研究学习使用，用户请自行承担风险。

---

