#!/bin/bash
set -e

echo "====================================="
echo "  OpenNote CLI 安装脚本"
echo "====================================="

# 检查 Python 版本
if ! command -v python3 &> /dev/null; then
    echo "[错误] 未找到 Python3，请先安装 Python 3.10+"
    exit 1
fi

PYTHON_VERSION=$(python3 --version | cut -d' ' -f2)
echo "[信息] Python 版本: $PYTHON_VERSION"

# 进入 packages 目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# 安装核心库
echo ""
echo "[信息] 安装 open-note-core..."
cd open-note-core && pip install -e . && cd ..

# 安装 MCP 服务
echo ""
echo "[信息] 安装 open-note-mcp..."
cd open-note-mcp && pip install -e . && cd ..

# 安装 CLI 工具
echo ""
echo "[信息] 安装 open-note-cli..."
cd open-note-cli && pip install -e . && cd ..

echo ""
echo "====================================="
echo "  安装完成!"
echo "====================================="
echo ""
echo "使用方法:"
echo "  CLI 命令: opennote --help"
echo "  MCP 服务: open-note-mcp"
echo ""
echo "CLI 示例:"
echo "  opennote note list               # 列出笔记"
echo "  opennote note search '工作计划'   # 搜索笔记"
echo "  opennote mcp start               # 启动 MCP 服务器"
echo ""
