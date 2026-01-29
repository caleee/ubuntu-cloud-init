#!/bin/bash

# Ubuntu Cloud Init 验证脚本
# 描述: 根据入口脚本参数验证每个步骤的执行结果

set -e

# 颜色定义
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# 默认参数
RUN_RUNTIME=true
RUN_STORAGE=true

# 项目信息
PROJECT_NAME="Ubuntu Cloud Init"
PROJECT_VERSION="1.0.0"

# 显示版本信息
show_version() {
    echo -e "${GREEN}$PROJECT_NAME v$PROJECT_VERSION${NC}"
    echo "验证脚本"
    exit 0
}

# 显示帮助信息
show_help() {
    echo -e "${GREEN}$PROJECT_NAME v$PROJECT_VERSION${NC}"
    echo "系统初始化验证脚本"
    echo ""
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  --no-runtime     跳过容器运行时模块的验证"
    echo "  --no-storage     跳过存储依赖模块的验证"
    echo "  --version        显示版本信息"
    echo "  --help           显示此帮助信息"
    echo ""
    exit 0
}

# 解析命令行参数
parse_args() {
    for arg in "$@"; do
        case $arg in
            --no-runtime) RUN_RUNTIME=false ;;
            --no-storage) RUN_STORAGE=false ;;
            --version) show_version ;;
            --help) show_help ;;
            *) 
                echo -e "${RED}错误: 未知参数 '$arg'${NC}"
                show_help
                ;;
        esac
    done
}

# 验证核心模块
verify_core() {
    echo -e "${GREEN}=== 验证核心模块 ===${NC}"
    
    # 检查系统时区
    echo -e "${YELLOW}检查系统时区...${NC}"
    if [ "$(timedatectl show --property=Timezone --value)" == "Asia/Shanghai" ]; then
        echo -e "${GREEN}✓ 时区设置正确: Asia/Shanghai${NC}"
    else
        echo -e "${RED}✗ 时区设置错误${NC}"
        return 1
    fi
    
    # 检查必备工具软件
    echo -e "${YELLOW}检查必备工具软件...${NC}"
    core_packages=(apt-transport-https ca-certificates curl wget gnupg lsb-release net-tools iputils-ping dnsutils tcpdump traceroute htop iotop sysstat lsof strace vim git jq rsync unzip zip bash-completion)
    
    missing_packages=()
    for pkg in "${core_packages[@]}"; do
        if ! dpkg -l | grep -q "^ii.*$pkg"; then
            missing_packages+=("$pkg")
        fi
    done
    
    if [ ${#missing_packages[@]} -eq 0 ]; then
        echo -e "${GREEN}✓ 所有必备工具软件已安装${NC}"
    else
        echo -e "${RED}✗ 缺少以下软件包: ${missing_packages[*]}${NC}"
        return 1
    fi
    
    # 检查防火墙状态
    echo -e "${YELLOW}检查防火墙状态...${NC}"
    if ! sudo ufw status | grep -q "Status: inactive"; then
        echo -e "${RED}✗ 防火墙未禁用${NC}"
        return 1
    else
        echo -e "${GREEN}✓ 防火墙已禁用${NC}"
    fi
    
    # 检查 Swap 状态
    echo -e "${YELLOW}检查 Swap 状态...${NC}"
    if swapon --show | grep -q "swap"; then
        echo -e "${RED}✗ Swap 未禁用${NC}"
        return 1
    else
        echo -e "${GREEN}✓ Swap 已禁用${NC}"
    fi
    
    # 检查 Sysctl 参数
    echo -e "${YELLOW}检查内核参数...${NC}"
    if sysctl net.ipv4.tcp_congestion_control | grep -q "bbr"; then
        echo -e "${GREEN}✓ TCP BBR 已启用${NC}"
    else
        echo -e "${RED}✗ TCP BBR 未启用${NC}"
        return 1
    fi
    
    if sysctl net.core.default_qdisc | grep -q "fq"; then
        echo -e "${GREEN}✓ 默认队列调度器已设置为 fq${NC}"
    else
        echo -e "${RED}✗ 默认队列调度器未设置为 fq${NC}"
        return 1
    fi
    
    # 检查系统日志配置
    echo -e "${YELLOW}检查系统日志配置...${NC}"
    if [ -f "/etc/systemd/journald.conf.d/limit.conf" ]; then
        echo -e "${GREEN}✓ 系统日志配置文件已创建${NC}"
    else
        echo -e "${RED}✗ 系统日志配置文件未创建${NC}"
        return 1
    fi
    
    echo -e "${GREEN}=== 核心模块验证完成 ===${NC}"
    return 0
}

# 验证运行时模块
verify_runtime() {
    echo -e "${GREEN}=== 验证运行时模块 ===${NC}"
    
    # 检查 Containerd 是否安装
    echo -e "${YELLOW}检查 Containerd 容器运行时...${NC}"
    if ! dpkg -l | grep -q "^ii.*containerd.io"; then
        echo -e "${RED}✗ Containerd 未安装${NC}"
        return 1
    else
        echo -e "${GREEN}✓ Containerd 已安装${NC}"
    fi
    
    # 检查 Containerd 服务状态
    echo -e "${YELLOW}检查 Containerd 服务状态...${NC}"
    if sudo systemctl is-active --quiet containerd; then
        echo -e "${GREEN}✓ Containerd 服务运行正常${NC}"
    else
        echo -e "${RED}✗ Containerd 服务未运行${NC}"
        return 1
    fi
    
    # 检查 Containerd 配置
    echo -e "${YELLOW}检查 Containerd 配置...${NC}"
    if grep -q "SystemdCgroup = true" /etc/containerd/config.toml; then
        echo -e "${GREEN}✓ Containerd 已配置为使用 SystemdCgroup${NC}"
    else
        echo -e "${RED}✗ Containerd 配置错误${NC}"
        return 1
    fi
    
    # 检查 Nerdctl 是否安装
    echo -e "${YELLOW}检查 Nerdctl 容器管理工具...${NC}"
    if [ -f "/usr/local/bin/nerdctl" ]; then
        echo -e "${GREEN}✓ Nerdctl 已安装${NC}"
        echo -e "${YELLOW}Nerdctl 版本: $(sudo /usr/local/bin/nerdctl version | grep 'Version:' | head -n 1 | awk '{print $2}')${NC}"
    else
        echo -e "${RED}✗ Nerdctl 未安装${NC}"
        return 1
    fi
    
    # 检查容器相关内核模块
    echo -e "${YELLOW}检查容器相关内核模块...${NC}"
    if lsmod | grep -q overlay && lsmod | grep -q br_netfilter; then
        echo -e "${GREEN}✓ 容器相关内核模块已加载${NC}"
    else
        echo -e "${RED}✗ 容器相关内核模块未加载${NC}"
        return 1
    fi
    
    # 检查容器相关 sysctl 参数
    echo -e "${YELLOW}检查容器相关内核参数...${NC}"
    if sysctl net.bridge.bridge-nf-call-iptables | grep -q "1" && \
       sysctl net.bridge.bridge-nf-call-ip6tables | grep -q "1" && \
       sysctl net.ipv4.ip_forward | grep -q "1"; then
        echo -e "${GREEN}✓ 容器相关内核参数已配置${NC}"
    else
        echo -e "${RED}✗ 容器相关内核参数未配置${NC}"
        return 1
    fi
    
    echo -e "${GREEN}=== 运行时模块验证完成 ===${NC}"
    return 0
}

# 验证存储模块
verify_storage() {
    echo -e "${GREEN}=== 验证存储模块 ===${NC}"
    
    # 检查 Longhorn 依赖组件
    echo -e "${YELLOW}检查 Longhorn 依赖组件...${NC}"
    storage_packages=(open-iscsi nfs-common util-linux)
    
    missing_packages=()
    for pkg in "${storage_packages[@]}"; do
        if ! dpkg -l | grep -q "^ii.*$pkg"; then
            missing_packages+=("$pkg")
        fi
    done
    
    if [ ${#missing_packages[@]} -eq 0 ]; then
        echo -e "${GREEN}✓ 所有 Longhorn 依赖组件已安装${NC}"
    else
        echo -e "${RED}✗ 缺少以下依赖组件: ${missing_packages[*]}${NC}"
        return 1
    fi
    
    # 检查存储相关内核模块
    echo -e "${YELLOW}检查存储相关内核模块...${NC}"
    storage_modules=(iscsi_tcp dm_snapshot dm_mirror dm_thin_pool)
    
    missing_modules=()
    for mod in "${storage_modules[@]}"; do
        if ! lsmod | grep -q "^$mod"; then
            missing_modules+=("$mod")
        fi
    done
    
    if [ ${#missing_modules[@]} -eq 0 ]; then
        echo -e "${GREEN}✓ 所有存储相关内核模块已加载${NC}"
    else
        echo -e "${YELLOW}⚠ 以下存储模块未加载: ${missing_modules[*]}${NC}"
        echo -e "${YELLOW}⚠ 模块将在需要时自动加载${NC}"
    fi
    
    # 检查 iscsid 服务状态
    echo -e "${YELLOW}检查 iscsid 服务状态...${NC}"
    if sudo systemctl is-active --quiet iscsid; then
        echo -e "${GREEN}✓ iscsid 服务运行正常${NC}"
    else
        echo -e "${RED}✗ iscsid 服务未运行${NC}"
        return 1
    fi
    
    # 检查 iSCSI 配置
    echo -e "${YELLOW}检查 iSCSI 配置...${NC}"
    if grep -q "node.session.timeo.replacement_timeout = 20" /etc/iscsi/iscsid.conf; then
        echo -e "${GREEN}✓ iSCSI 超时设置已优化${NC}"
    else
        echo -e "${YELLOW}⚠ iSCSI 超时设置未优化${NC}"
    fi
    
    # 检查 multipathd 服务状态
    echo -e "${YELLOW}检查 multipathd 服务状态...${NC}"
    if sudo systemctl is-enabled --quiet multipathd; then
        echo -e "${RED}✗ multipathd 服务未禁用${NC}"
        return 1
    else
        echo -e "${GREEN}✓ multipathd 服务已禁用${NC}"
    fi
    
    echo -e "${GREEN}=== 存储模块验证完成 ===${NC}"
    return 0
}

# 主函数
main() {
    echo -e "${GREEN}=== $PROJECT_NAME v$PROJECT_VERSION 验证开始 ===${NC}"
    echo
    
    # 验证核心模块
    if ! verify_core; then
        echo -e "${RED}验证失败: 核心模块验证出错${NC}"
        exit 1
    fi
    
    # 验证运行时模块
    if [ "$RUN_RUNTIME" = true ]; then
        if ! verify_runtime; then
            echo -e "${RED}验证失败: 运行时模块验证出错${NC}"
            exit 1
        fi
    else
        echo -e "${YELLOW}跳过运行时模块验证${NC}"
    fi
    
    # 验证存储模块
    if [ "$RUN_STORAGE" = true ]; then
        if ! verify_storage; then
            echo -e "${RED}验证失败: 存储模块验证出错${NC}"
            exit 1
        fi
    else
        echo -e "${YELLOW}跳过存储模块验证${NC}"
    fi
    
    # 完成信息
    echo
    echo -e "${GREEN}=== 所有验证任务已完成！===${NC}"
    echo -e "${GREEN}✓ 系统初始化验证成功${NC}"
    echo -e "${YELLOW}提示: 建议重启系统以确保所有更改生效${NC}"
}

# 解析参数
parse_args "$@"

# 执行主函数
main