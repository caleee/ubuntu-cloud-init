#!/bin/bash

# Storage 模块脚本
# 描述: 配置 Longhorn 存储依赖

set -e

# 颜色定义
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
# RED='\033[0;31m'
NC='\033[0m' # No Color

# 显示标题
echo -e "${GREEN}=== Storage 模块: Longhorn 存储依赖配置 ===${NC}"

# 加载 iSCSI 与 LVM 模块
echo -e "${GREEN}>>> [01/05] 加载存储相关内核模块...${NC}"
cat <<EOF | sudo tee /etc/modules-load.d/03-storage.conf
iscsi_tcp
dm_snapshot
dm_mirror
dm_thin_pool
EOF

# 加载模块
MODULES=(iscsi_tcp dm_snapshot dm_mirror dm_thin_pool)
for m in "${MODULES[@]}"; do
    echo -e "${YELLOW}加载模块: $m${NC}"
    sudo modprobe "$m"
 done
echo -e "${GREEN}>>> [01/05] 完成${NC}"

# 配置 sysctl 参数
echo -e "${GREEN}>>> [02/05] 配置存储相关 sysctl 参数...${NC}"
cat <<EOF | sudo tee /etc/sysctl.d/03-storage.conf
# 增加线程上限，支持大量存储 Volume
kernel.threads-max = 2000000
EOF

sudo sysctl --system
echo -e "${GREEN}>>> [02/05] 完成${NC}"

# 安装 Longhorn 依赖组件
echo -e "${GREEN}>>> [03/05] 安装 Longhorn 依赖组件...${NC}"

# 定义依赖包
STORAGE_PACKAGES=(open-iscsi nfs-common util-linux)

# 安装依赖包
sudo apt-get update
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y "${STORAGE_PACKAGES[@]}"
echo -e "${GREEN}>>> [03/05] 完成${NC}"

# 禁用 multipathd 以防止与 Longhorn 冲突
echo -e "${GREEN}>>> [04/05] 禁用 multipathd 服务...${NC}"
sudo systemctl disable --now multipathd || true
sudo systemctl mask multipathd || true
echo -e "${GREEN}>>> [04/05] 完成${NC}"

# 配置 iSCSI 性能调优
echo -e "${GREEN}>>> [05/05] 配置 iSCSI 性能调优...${NC}"

# 检查 iscsid.conf 文件是否存在
if [ -f "/etc/iscsi/iscsid.conf" ]; then
    # 备份原始配置
    sudo cp /etc/iscsi/iscsid.conf /etc/iscsi/iscsid.conf.bak
    
    # 修改超时设置
    sudo sed -i 's/node.session.timeo.replacement_timeout = 120/node.session.timeo.replacement_timeout = 20/' /etc/iscsi/iscsid.conf
    
    echo -e "${GREEN}已修改 iSCSI 超时设置为 20 秒${NC}"
else
    echo -e "${YELLOW}警告: /etc/iscsi/iscsid.conf 文件不存在${NC}"
    echo -e "${YELLOW}将创建默认配置文件${NC}"
    sudo mkdir -p /etc/iscsi
    cat <<EOF | sudo tee /etc/iscsi/iscsid.conf
node.session.timeo.replacement_timeout = 20
EOF
fi

# 启用并重启 iscsid 服务
sudo systemctl enable --now iscsid
sudo systemctl restart iscsid

echo -e "${GREEN}>>> [05/05] 完成${NC}"

echo -e "${GREEN}=== Storage 模块: 所有任务已完成 ===${NC}"
echo -e "${YELLOW}提示: Longhorn 存储依赖已配置完成，可以开始部署 Longhorn 服务${NC}"