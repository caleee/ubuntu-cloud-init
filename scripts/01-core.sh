#!/bin/bash

# Core 模块脚本
# 描述: 系统内核与基础环境优化

set -e

# 颜色定义
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
# RED='\033[0;31m'
NC='\033[0m' # No Color

# 显示标题
echo -e "${GREEN}=== Core 模块: 系统内核与基础环境优化 ===${NC}"

# 修复 Cloud-init 用户 Shell 为 Bash
echo -e "${GREEN}>>> [01/11] 修复 Cloud-init 用户 Shell 为 Bash...${NC}"
sudo chsh -s /bin/bash "$USER"
echo -e "${GREEN}>>> [01/11] 完成${NC}"

# 更新系统软件包
echo -e "${GREEN}>>> [02/11] 更新系统软件包...${NC}"
sudo apt-get update
sudo DEBIAN_FRONTEND=noninteractive apt-get upgrade -y
echo -e "${GREEN}>>> [02/11] 完成${NC}"

# 安装必备工具软件
echo -e "${GREEN}>>> [03/11] 安装必备工具软件...${NC}"
sudo apt-get update

# 定义要安装的软件包
PACKAGES=(
    # 基础与传输
    apt-transport-https
    ca-certificates
    curl
    wget
    gnupg
    lsb-release

    # 网络诊断
    net-tools
    iputils-ping
    dnsutils
    tcpdump
    traceroute

    # 监控与调试
    htop
    iotop
    sysstat
    lsof
    strace

    # 效率工具
    vim
    git
    jq
    rsync
    unzip
    zip
    bash-completion
)

# 安装软件包（使用 --no-install-recommends 保持系统精简）
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends "${PACKAGES[@]}"
echo -e "${GREEN}>>> [03/11] 完成${NC}"

# 关闭防火墙 (UFW)
echo -e "${GREEN}>>> [04/11] 关闭防火墙 (UFW)...${NC}"
sudo ufw disable || true
sudo systemctl disable --now ufw || true
sudo systemctl mask ufw || true
echo -e "${GREEN}>>> [04/11] 完成${NC}"

# 永久关闭 Swap
echo -e "${GREEN}>>> [05/11] 永久关闭 Swap...${NC}"
sudo swapoff -a
# 移除 fstab 中的 swap 条目
sudo sed -i '/swap/d' /etc/fstab
echo -e "${GREEN}>>> [05/11] 完成${NC}"

# 优化磁盘 I/O 与文件句柄
echo -e "${GREEN}>>> [06/11] 优化磁盘 I/O 与文件句柄...${NC}"
cat <<EOF | sudo tee -a /etc/security/limits.conf
* soft nofile 655350
* hard nofile 655350
* soft nproc 655350
* hard nproc 655350
EOF
echo -e "${GREEN}>>> [06/11] 完成${NC}"

# 动态计算 nf_conntrack_max (每 1GB 内存分配 25w 条)
echo -e "${GREEN}>>> [07/11] 动态计算 nf_conntrack_max...${NC}"
mem_gb=$(free -g | awk '/^Mem:/{print $2}')
[ "$mem_gb" -lt 1 ] && mem_gb=1
conn_max=$((mem_gb * 262144))
echo -e "${YELLOW}内存大小: ${mem_gb}GB, 计算的连接数上限: ${conn_max}${NC}"
echo -e "${GREEN}>>> [07/11] 完成${NC}"

# 写入 Sysctl 参数
echo -e "${GREEN}>>> [08/11] 写入 Sysctl 参数...${NC}"
cat <<EOF | sudo tee /etc/sysctl.d/99-universal-core.conf
# 网络优化
net.ipv4.tcp_congestion_control = bbr
net.core.default_qdisc = fq
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_fin_timeout = 15
net.netfilter.nf_conntrack_max = $conn_max
net.core.somaxconn = 65535

# 文件系统优化
fs.file-max = 2000000
fs.nr_open = 2000000
fs.inotify.max_user_instances = 8192
fs.inotify.max_user_watches = 1048576

# 内存管理
vm.swappiness = 0

# 系统稳定性
kernel.panic = 10
kernel.panic_on_oops = 1
EOF
echo -e "${GREEN}>>> [08/11] 完成${NC}"

# 加载 BBR 模块
echo -e "${GREEN}>>> [09/11] 加载 BBR 模块...${NC}"
echo "tcp_bbr" | sudo tee -a /etc/modules-load.d/modules.conf
sudo modprobe tcp_bbr || true
sudo sysctl --system
echo -e "${GREEN}>>> [09/11] 完成${NC}"

# 设置系统时区与时间同步
echo -e "${GREEN}>>> [10/11] 设置系统时区与时间同步...${NC}"
sudo timedatectl set-timezone Asia/Shanghai
# 启用时间同步
sudo systemctl enable --now systemd-timesyncd || true
echo -e "${GREEN}>>> [10/11] 完成${NC}"

# 配置系统日志
echo -e "${GREEN}>>> [11/11] 配置系统日志...${NC}"
sudo mkdir -p /etc/systemd/journald.conf.d
echo -e "[Journal]\nSystemMaxUse=500M\nForwardToSyslog=no" | sudo tee /etc/systemd/journald.conf.d/limit.conf
sudo systemctl restart systemd-journald
echo -e "${GREEN}>>> [11/11] 完成${NC}"

echo -e "${GREEN}=== Core 模块: 所有任务已完成 ===${NC}"