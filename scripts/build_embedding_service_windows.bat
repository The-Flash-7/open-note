@echo off
echo 🔧 正在打包 Python 服务 (Windows)...

cd /d "%~dp0.."

REM 检查 Python 环境（使用 py launcher 避免 Store 重定向）
py -3 --version >nul 2>nul
if %errorlevel% neq 0 (
    echo ❌ 错误: 未找到 Python。请确保已安装 Python 3.x 且 py launcher 可用。
    exit /b 1
)

cd embedding_service

REM 安装依赖
echo 📦 安装依赖...
py -3 -m pip install -r requirements.txt
py -3 -m pip install pyinstaller

REM 打包
echo 📦 正在打包...
py -3 -m PyInstaller --onefile ^
  --name embedding_service ^
  --add-data "embedding;embedding" ^
  --hidden-import numpy ^
  --hidden-import onnxruntime ^
  --hidden-import onnxruntime_genai ^
  --hidden-import chromadb ^
  --collect-all onnxruntime_genai ^
  --collect-all chromadb ^
  main.py

echo ✅ 打包完成: embedding_service\dist\embedding_service.exe

REM 复制产物到 Flutter 资源目录
mkdir ..\assets\embedding_service 2>nul
copy /Y dist\embedding_service.exe ..\assets\embedding_service\

echo 📦 已复制到 assets\embedding_service\embedding_service.exe

REM 清理临时文件
rmdir /s /q build 2>nul
rmdir /s /q __pycache__ 2>nul
del /q embedding_service.spec 2>nul

echo ✅ 完成！
