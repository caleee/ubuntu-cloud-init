#!/bin/bash

# Runtime 模块脚本
# 描述: 安装 Containerd 与 Nerdctl 容器运行时

set -e

# 颜色定义
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# 显示标题
echo -e "${GREEN}=== Runtime 模块: 容器运行时配置 ===${NC}"

# 加载 overlay 与 br_netfilter 模块
echo -e "${GREEN}>>> [01/06] 加载容器相关内核模块...${NC}"
cat <<EOF | sudo tee /etc/modules-load.d/02-runtime.conf
overlay
br_netfilter
EOF

# 加载模块
sudo modprobe overlay
sudo modprobe br_netfilter
echo -e "${GREEN}>>> [01/06] 完成${NC}"

# 配置 sysctl 参数
echo -e "${GREEN}>>> [02/06] 配置容器相关 sysctl 参数...${NC}"
cat <<EOF | sudo tee /etc/sysctl.d/02-runtime.conf
# 容器网络配置
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward = 1
net.ipv4.conf.all.forwarding = 1
EOF

sudo sysctl --system
echo -e "${GREEN}>>> [02/06] 完成${NC}"

# 安装 Containerd (使用 Docker 源，避免版本冲突)
echo -e "${GREEN}>>> [03/06] 安装 Containerd 容器运行时...${NC}"

# 检测网络环境，选择合适的 Docker 源
if curl -s --connect-timeout 2 mirrors.aliyun.com > /dev/null; then
    echo -e "${YELLOW}检测到国内网络环境，使用阿里云 Docker 镜像源${NC}"
    DOCKER_GPG_URL="https://mirrors.aliyun.com/docker-ce/linux/ubuntu/gpg"
    DOCKER_REPO="https://mirrors.aliyun.com/docker-ce/linux/ubuntu"
else
    echo -e "${GREEN}使用官方 Docker 源${NC}"
    DOCKER_GPG_URL="https://download.docker.com/linux/ubuntu/gpg"
    DOCKER_REPO="https://download.docker.com/linux/ubuntu"
fi

# 添加 Docker GPG 密钥
curl -fsSL "$DOCKER_GPG_URL" | sudo gpg --yes --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# 添加 Docker 源
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] $DOCKER_REPO $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# 安装 containerd.io
sudo apt-get update
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y containerd.io
echo -e "${GREEN}>>> [03/06] 完成${NC}"

# 配置 Containerd 使用 SystemdCgroup
echo -e "${GREEN}>>> [04/06] 配置 Containerd 使用 SystemdCgroup...${NC}"
sudo mkdir -p /etc/containerd
temp_config=$(mktemp)
containerd config default > "$temp_config"
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' "$temp_config"
sudo cp "$temp_config" /etc/containerd/config.toml
rm "$temp_config"

# 重启 containerd 服务
sudo systemctl restart containerd
sudo systemctl enable containerd
echo -e "${GREEN}>>> [04/06] 完成${NC}"

# 安装 Nerdctl-full (带自动代理识别)
echo -e "${GREEN}>>> [05/06] 安装 Nerdctl 容器管理工具...${NC}"

# 获取系统架构
ARCH=$(dpkg --print-architecture)

# 获取最新版本
echo -e "${YELLOW}正在检查 Nerdctl 最新版本...${NC}"
VERSION=$(curl -s https://api.github.com/repos/containerd/nerdctl/releases/latest | jq -r .tag_name | sed 's/v//')

if [ -z "$VERSION" ]; then
    echo -e "${RED}错误: 无法获取 Nerdctl 版本信息${NC}"
    exit 1
fi

echo -e "${YELLOW}最新版本: $VERSION${NC}"

# 检测国内外网络环境并选择合适的下载源
echo -e "${GREEN}检测网络环境...${NC}"
if curl -s --connect-timeout 3 google.com > /dev/null; then
    echo -e "${GREEN}检测到国外网络环境，使用 GitHub 官方源下载${NC}"
    URL="https://github.com/containerd/nerdctl/releases/download/v${VERSION}/nerdctl-full-${VERSION}-linux-${ARCH}.tar.gz"
else
    echo -e "${YELLOW}检测到国内网络环境，使国内加速下载${NC}"
    URL="https://cdn.gh-proxy.com/https://github.com/containerd/nerdctl/releases/download/v${VERSION}/nerdctl-full-${VERSION}-linux-${ARCH}.tar.gz"
fi
# 下载并安装
echo -e "${GREEN}正在下载 Nerdctl...${NC}"

# 添加超时设置和重试机制
wget --timeout=60 --tries=2 -O /tmp/nerdctl.tar.gz "$URL"

echo -e "${GREEN}正在安装 Nerdctl...${NC}"
sudo tar -C /usr/local -xzf /tmp/nerdctl.tar.gz
command -v nerdctl &> /dev/null

# 清理临时文件
rm /tmp/nerdctl.tar.gz
echo -e "${GREEN}>>> [05/06] 完成${NC}"

# 配置 Nerdctl 日志、命令补全、别名
echo -e "${GREEN}>>> [06/06] 配置 Nerdctl 相关设置...${NC}"

# 创建配置目录
sudo mkdir -p /etc/nerdctl && sudo touch /etc/nerdctl/nerdctl.toml

# 配置命令补全
sudo nerdctl completion bash | sudo tee /etc/bash_completion.d/nerdctl > /dev/null

# 添加 docker 符号链接
if ! which docker &> /dev/null; then
    sudo ln -s "$(which nerdctl)" /usr/local/bin/docker
    echo -e "${GREEN}已添加 docker 符号链接${NC}"
fi

echo -e "${GREEN}>>> [06/06] 完成${NC}"

echo -e "${GREEN}=== Runtime 模块: 所有任务已完成 ===${NC}"