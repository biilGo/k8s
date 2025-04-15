#!/bin/bash

# ==========================================
# 增强版 Docker 镜像批量构建脚本
# 功能特性：
# 1. 自动检测 Docker 环境
# 2. 带颜色的状态输出
# 3. 构建耗时统计
# 4. 错误中断机制控制
# 5. 日志记录功能
# 6. 自定义镜像名前缀/标签
# 7. 目录排除功能
# 8. 并行构建支持
# ==========================================

# ---------------------------
# 配置参数（可通过命令行参数覆盖）
# ---------------------------
TAG="RSV"                                 # 默认标签
PREFIX="192.168.2.7:80/zrq"               # 镜像名前缀
LOG_FILE="docker_build.log"               # 日志文件路径
EXCLUDE_DIRS=("tools" "deployment_yaml")  # 排除目录列表
ALLOW_FAILURES=3                          # 最大允许失败次数
PARALLEL_BUILD=false                      # 是否启用并行构建
THREADS=4                                 # 并行线程数

# ---------------------------
# 颜色输出配置
# ---------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ---------------------------
# 初始化变量
# ---------------------------
declare -i SUCCESS_COUNT=0
declare -i FAIL_COUNT=0
START_TIME=$(date +%s)
TOTAL_DIRS=0

# ---------------------------
# 函数定义
# ---------------------------

# 检查 Docker 环境
check_docker() {
    if ! command -v docker &> /dev/null; then
        echo -e "${RED}✖ Docker 未安装！${NC}"
        exit 1
    fi
    
    if ! docker info &> /dev/null; then
        echo -e "${RED}✖ Docker 守护进程未运行！${NC}"
        exit 1
    fi
}

# 打印头信息
print_header() {
    echo -e "${BLUE}"
    echo "========================================"
    echo "Docker 镜像批量构建工具"
    echo "• 开始时间: $(date +"%Y-%m-%d %H:%M:%S")"
    echo "• 构建标签: $TAG"
    echo "• 镜像前缀: $PREFIX"
    echo "========================================"
    echo -e "${NC}"
}

# 构建单个镜像
build_image() {
    local dir=$1
    local start=$(date +%s)
    
    echo -e "${YELLOW}▶ 正在构建 ${BLUE}$dir${YELLOW} ...${NC}"
    
    if docker build -t "${PREFIX}/${dir}:${TAG}" . >> "${LOG_FILE}" 2>&1; then
        local end=$(date +%s)
        local duration=$((end - start))
        echo -e "${GREEN}✔ 成功构建 ${dir} (耗时 ${duration}s)${NC}"
        ((SUCCESS_COUNT++))
    else
        echo -e "${RED}✖ 构建失败 ${dir} (日志: ${LOG_FILE})${NC}"
        ((FAIL_COUNT++))
        return 1
    fi
}

# ---------------------------
# 主程序开始
# ---------------------------

# 解析命令行参数
while getopts "t:p:l:e:aj:h" opt; do
    case $opt in
        t) TAG=$OPTARG ;;
        p) PREFIX=$OPTARG ;;
        l) LOG_FILE=$OPTARG ;;
        e) IFS=',' read -r -a EXCLUDE_DIRS <<< "$OPTARG" ;;
        a) PARALLEL_BUILD=true ;;
        j) THREADS=$OPTARG ;;
        h) 
            echo "用法: $0 [-t 标签] [-p 前缀] [-l 日志文件] [-e 排除目录] [-a] [-j 线程数]"
            echo "示例: $0 -t v1.2 -p myrepo -e 'test,demo' -a -j 4"
            exit 0
            ;;
        *) exit 1 ;;
    esac
done

# 清空日志文件
> "${LOG_FILE}"

check_docker
print_header

# 遍历目录
echo -e "${YELLOW}正在扫描工作目录...${NC}"

for dir in */; do
    dir=${dir%/}
    
    # 排除目录检查
    if [[ " ${EXCLUDE_DIRS[@]} " =~ " ${dir} " ]]; then
        echo -e "${YELLOW}⚠ 跳过排除目录: ${dir}${NC}"
        continue
    fi
    
    # Dockerfile 存在性检查
    if [ ! -f "${dir}/Dockerfile" ]; then
        echo -e "${RED}✖ 目录 ${dir} 缺少 Dockerfile${NC}"
        ((FAIL_COUNT++))
        continue
    fi
    
    ((TOTAL_DIRS++))
done

echo -e "发现 ${GREEN}${TOTAL_DIRS}${NC} 个需要构建的目录\n"

# 构建执行
if [ "$PARALLEL_BUILD" = true ]; then
    echo -e "${YELLOW}⚡ 启用并行构建模式 (线程数: ${THREADS})${NC}"
    export -f build_image
    export PREFIX TAG LOG_FILE SUCCESS_COUNT FAIL_COUNT
    find . -mindepth 1 -maxdepth 1 -type d \! -name "${EXCLUDE_DIRS[@]}" -exec bash -c '
        cd "$1" || exit
        build_image "$(basename "$1")"
    ' _ {} \; | tee -a "${LOG_FILE}"
else
    for dir in */; do
        dir=${dir%/}
        [[ " ${EXCLUDE_DIRS[@]} " =~ " ${dir} " ]] && continue
        
        (cd "$dir" && build_image "$dir") || {
            if [ $FAIL_COUNT -ge $ALLOW_FAILURES ]; then
                echo -e "${RED}达到最大失败次数，终止构建！${NC}"
                exit 1
            fi
        }
    done
fi

# ---------------------------
# 打印总结报告
# ---------------------------
END_TIME=$(date +%s)
TOTAL_TIME=$((END_TIME - START_TIME))

echo -e "\n${BLUE}======== 构建报告 ========${NC}"
echo -e "总耗时:    ${TOTAL_TIME}s"
echo -e "成功构建: ${GREEN}${SUCCESS_COUNT}${NC}"
echo -e "构建失败: ${RED}${FAIL_COUNT}${NC}"
echo -e "日志文件: ${YELLOW}${LOG_FILE}${NC}"

if [ $FAIL_COUNT -gt 0 ]; then
    echo -e "\n${RED}‼ 部分镜像构建失败，请检查日志！${NC}"
    exit 1
else
    echo -e "\n${GREEN}所有镜像构建成功！${NC}"
fi
