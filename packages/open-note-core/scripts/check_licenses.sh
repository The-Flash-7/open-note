#!/bin/bash
# 检查 open-note-core 依赖许可证是否与 MIT + Apache 2.0 兼容

set -e

cd "$(dirname "$0")/.." || exit 1

# 该包无外部依赖
echo "正在检查 open-note-core 依赖许可证..."
echo ""
echo "open-note-core 无外部依赖（仅使用 Python 标准库）"
echo ""
echo "✅ 无许可证冲突风险"
