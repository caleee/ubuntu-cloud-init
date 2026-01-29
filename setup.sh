#!/bin/bash

# Ubuntu Cloud Init 脚本
# 版本: 1.0.0
# 描述: 模块化的 Ubuntu 24.04 系统初始化工具

# 颜色定义
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# 默认参数
RUN_RUNTIME=true
RUN_STORAGE=true
AUTO_REBOOT=true

# 项目信息
PROJECT_NAME="Ubuntu Cloud Init"
PROJECT_VERSION="1.0.0"
GITHUB_REPO="caleee/ubuntu-cloud-init"

# 脚本下载源
SCRIPT_BASE_URL="https://cdn.jsdelivr.net/gh/$GITHUB_REPO@main"

# 标记是否为一键命令安装（是否下载了文件）
IS_ONE_CLICK_INSTALL=false

# 检查脚本文件是否存在
check_scripts() {
    local scripts=(
        "scripts/01-core.sh"
        "scripts/02-runtime.sh"
        "scripts/03-storage.sh"
        "verify.sh"
    )
    
    local missing_scripts=()
    
    # 检查脚本目录是否存在
    if [ ! -d "scripts" ]; then
        echo -e "${YELLOW}脚本目录不存在，创建目录...${NC}"
        mkdir -p scripts
    fi
    
    # 检查每个脚本文件
    for script in "${scripts[@]}"; do
        if [ ! -f "$script" ]; then
            missing_scripts+=($script)
        fi
    done
    
    # 如果有缺失的脚本文件，从网络下载
    if [ ${#missing_scripts[@]} -gt 0 ]; then
        echo -e "${YELLOW}检测到缺失的脚本文件，从网络下载...${NC}"
        
        # 设置为一键命令安装模式
        IS_ONE_CLICK_INSTALL=true
        
        for script in "${missing_scripts[@]}"; do
            echo -e "${GREEN}下载 $script...${NC}"
            if curl -sSL "$SCRIPT_BASE_URL/$script" -o "$script"; then
                echo -e "${GREEN}✓ 下载成功: $script${NC}"
                chmod +x "$script"
            else
                echo -e "${RED}✗ 下载失败: $script${NC}"
                echo -e "${RED}错误: 无法下载必要的脚本文件，请检查网络连接${NC}"
                exit 1
            fi
        done
        
        echo -e "${GREEN}所有脚本文件下载完成${NC}"
    else
        echo -e "${GREEN}所有脚本文件已存在${NC}"
    fi
}

# 显示版本信息
show_version() {
    echo -e "${GREEN}$PROJECT_NAME v$PROJECT_VERSION${NC}"
    echo "GitHub: https://github.com/$GITHUB_REPO"
    exit 0
}

# 显示帮助信息
show_help() {
    echo -e "${GREEN}$PROJECT_NAME v$PROJECT_VERSION${NC}"
    echo "模块化的 Ubuntu 24.04 系统初始化工具"
    echo ""
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  --no-runtime     跳过容器运行时模块的安装和配置"
    echo "  --no-storage     跳过存储依赖模块的安装和配置"
    echo "  --no-reboot      执行完成后不自动重启系统"
    echo "  --version        显示版本信息"
    echo "  --help           显示此帮助信息"
    echo ""
    exit 0
}

# 检查用户权限
check_permissions() {
    if ! sudo -n true 2>/dev/null; then
        echo -e "${RED}错误: 您需要具有 sudo 权限才能执行此脚本${NC}"
        echo "请确保您的用户在 sudo 组中，并且能够免密码执行 sudo 命令"
        exit 1
    fi
    
    # 检查当前目录写入权限
    if [ ! -w "." ]; then
        echo -e "${RED}错误: 当前目录没有写入权限${NC}"
        echo "请确保您对当前目录具有写入权限，以便创建scripts目录和下载文件"
        exit 1
    fi
    
    # 检查scripts目录写入权限（如果存在）
    if [ -d "scripts" ] && [ ! -w "scripts" ]; then
        echo -e "${RED}错误: scripts目录没有写入权限${NC}"
        echo "请确保您对scripts目录具有写入权限"
        exit 1
    fi
    
    echo -e "${GREEN}权限检查通过${NC}"
}

# 检查系统版本
check_system() {
    if [ "$(lsb_release -cs)" != "noble" ]; then
        echo -e "${YELLOW}警告: 此脚本专为 Ubuntu 24.04 LTS (noble) 设计${NC}"
        echo -e "${YELLOW}在其他版本上执行可能会导致不可预期的结果${NC}"
        read -p "是否继续执行？ (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
    
    echo -e "${GREEN}系统版本检查完成${NC}"
}

# 解析命令行参数
parse_args() {
    for arg in "$@"; do
        case $arg in
            --no-runtime) RUN_RUNTIME=false ;;
            --no-storage) RUN_STORAGE=false ;;
            --no-reboot) AUTO_REBOOT=false ;;
            --version) show_version ;;
            --help) show_help ;;
            *) 
                echo -e "${RED}错误: 未知参数 '$arg'${NC}"
                show_help
                ;;
        esac
    done
}

# 执行脚本
run_script() {
    local script_path=$1
    local script_name
    script_name=$(basename "$script_path")
    
    echo -e "${GREEN}=== 执行 $script_name ===${NC}"
    
    if [ -f "$script_path" ]; then
        chmod +x "$script_path"
        if "$script_path"; then
            echo -e "${GREEN}=== $script_name 执行完成 ===${NC}"
        else
            echo -e "${RED}错误: $script_name 执行失败${NC}"
            return 1
        fi
    else
        echo -e "${RED}错误: 脚本文件 $script_path 不存在${NC}"
        return 1
    fi
    
    return 0
}

# 执行验证
run_verification() {
    local verify_args=()
    
    if [ "$RUN_RUNTIME" = false ]; then
        verify_args+=("--no-runtime")
    fi
    
    if [ "$RUN_STORAGE" = false ]; then
        verify_args+=("--no-storage")
    fi
    
    echo -e "${GREEN}=== 执行验证 ===${NC}"
    
    if [ -f "verify.sh" ]; then
        chmod +x "verify.sh"
        if ./verify.sh "${verify_args[@]}"; then
            echo -e "${GREEN}=== 验证完成 ===${NC}"
        else
            echo -e "${RED}错误: 验证失败${NC}"
            return 1
        fi
    else
        echo -e "${RED}错误: 验证脚本 verify.sh 不存在${NC}"
        return 1
    fi
    
    return 0
}

# 清理函数
cleanup() {
    # 检查是否为一键命令安装（是否下载了文件）
    if [ "$IS_ONE_CLICK_INSTALL" = true ]; then
        echo -e "${YELLOW}清理临时文件...${NC}"
        
        # 清理下载的脚本文件
        local script_files=(
            "scripts/01-core.sh"
            "scripts/02-runtime.sh"
            "scripts/03-storage.sh"
        )
        
        for script_file in "${script_files[@]}"; do
            if [ -f "$script_file" ]; then
                rm -f "$script_file"
                echo -e "${GREEN}✓ 清理 $script_file 文件${NC}"
            fi
        done
        
        # 检查scripts目录是否为空，如果为空则删除
        if [ -d "scripts" ] && [ -z "$(ls -A "scripts")" ]; then
            rm -rf scripts
            echo -e "${GREEN}✓ 清理空的 scripts 目录${NC}"
        fi
        
        if [ -f "verify.sh" ]; then
            rm -f verify.sh
            echo -e "${GREEN}✓ 清理 verify.sh 文件${NC}"
        fi
        
        echo -e "${GREEN}清理完成${NC}"
    fi
}

# 主函数
main() {
    echo -e "${GREEN}=== $PROJECT_NAME v$PROJECT_VERSION 初始化开始 ===${NC}"
    echo -e "${GREEN}GitHub: https://github.com/$GITHUB_REPO${NC}"
    echo
    
    # 检查权限
    check_permissions
    
    # 检查系统
    check_system
    
    # 检查并下载脚本文件
    check_scripts
    
    # 执行核心模块
    if ! run_script "scripts/01-core.sh"; then
        echo -e "${RED}初始化失败: 核心模块执行出错${NC}"
        cleanup
        exit 1
    fi
    
    # 执行运行时模块
    if [ "$RUN_RUNTIME" = true ]; then
        if ! run_script "scripts/02-runtime.sh"; then
            echo -e "${RED}初始化失败: 运行时模块执行出错${NC}"
            cleanup
            exit 1
        fi
    else
        echo -e "${YELLOW}跳过运行时模块${NC}"
    fi
    
    # 执行存储模块
    if [ "$RUN_STORAGE" = true ]; then
        if ! run_script "scripts/03-storage.sh"; then
            echo -e "${RED}初始化失败: 存储模块执行出错${NC}"
            cleanup
            exit 1
        fi
    else
        echo -e "${YELLOW}跳过存储模块${NC}"
    fi
    
    # 执行验证
    if ! run_verification; then
        echo -e "${RED}初始化失败: 验证出错${NC}"
        cleanup
        exit 1
    fi

    # 完成信息
    echo
    echo -e "${GREEN}=== 所有初始化任务已完成！===${NC}"

    # 执行清理
    cleanup

    # 自动重启
    if [ "$AUTO_REBOOT" = true ]; then
        echo -e "${YELLOW}系统将在 10 秒后重启...${NC}"
        echo -e "${YELLOW}按 Ctrl+C 取消重启${NC}"
        
        for i in {10..1}; do
            echo -ne "${YELLOW}$i...${NC}\r"
            sleep 1
        done
        
        echo
        echo -e "${GREEN}正在重启系统...${NC}"
        sudo reboot
    else
        echo -e "${YELLOW}自动重启已禁用${NC}"
        echo -e "${GREEN}请在适当的时候手动重启系统以应用所有更改${NC}"
    fi
}

# 解析参数
parse_args "$@"

# 执行主函数
main