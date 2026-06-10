#!/bin/bash
set -e

echo "正在打包 Python 服务 (macOS)..."

cd "$(dirname "$0")/.."

# 使用 miniforge3 的 Python 环境
MINIFORGE_PYTHON="$HOME/miniforge3/bin/python3"
if [ ! -f "$MINIFORGE_PYTHON" ]; then
    # 回退到系统 Python
    MINIFORGE_PYTHON="python3"
fi

echo "使用 Python: $($MINIFORGE_PYTHON --version)"

cd embedding_service

# 检查 embedding 目录是否存在
if [ ! -d "embedding" ]; then
    echo "错误: embedding 目录不存在"
    exit 1
fi

# 安装依赖
echo "安装依赖..."
$MINIFORGE_PYTHON -m pip install -r requirements.txt || { echo "错误: 依赖安装失败"; exit 1; }
$MINIFORGE_PYTHON -m pip install pyinstaller || { echo "错误: PyInstaller 安装失败"; exit 1; }

# 清理 Python 缓存（确保打包最新代码）
echo "清理缓存..."
find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
find . -type f -name "*.pyc" -delete 2>/dev/null || true

# 打包
echo "正在打包..."
$MINIFORGE_PYTHON -m PyInstaller --onefile \
  --name embedding_service \
  --add-data "embedding:embedding" \
  --hidden-import numpy \
  --hidden-import onnxruntime \
  --hidden-import tqdm \
  --hidden-import hnswlib \
  --hidden-import chromadb \
  --collect-all chromadb \
  main.py || { echo "错误: 打包失败"; exit 1; }

echo "打包完成: embedding_service/dist/embedding_service"

# 复制产物到 Flutter 资源目录
mkdir -p ../assets/embedding_service
cp dist/embedding_service ../assets/embedding_service/

echo "已复制到 assets/embedding_service/embedding_service"

# 清理 PyInstaller 临时文件
rm -rf build __pycache__ embedding_service.spec

echo "完成！"
