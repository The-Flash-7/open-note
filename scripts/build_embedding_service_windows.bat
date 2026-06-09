@echo off
echo 正在打包 Python 服务 (Windows)...

cd /d "%~dp0.."

REM 检查 Python 环境（优先使用 py launcher，回退到 python）
where py >nul 2>nul
if %errorlevel% equ 0 (
    set PYTHON_CMD=py -3
) else (
    set PYTHON_CMD=python
)

%PYTHON_CMD% --version >nul 2>nul
if %errorlevel% neq 0 (
    echo 错误: 未找到 Python。请确保已安装 Python 3.8-3.11。
    exit /b 1
)

REM 检查 Python 版本兼容性（3.8-3.11）
for /f "tokens=2" %%a in ('%PYTHON_CMD% --version 2^>^&1') do set PY_VERSION=%%a
echo 检测到 Python 版本: %PY_VERSION%

cd embedding_service

REM 安装依赖（失败则退出）
echo 安装依赖...
%PYTHON_CMD% -m pip install -r requirements.txt
if %errorlevel% neq 0 (
    echo 错误: 依赖安装失败
    exit /b 1
)
%PYTHON_CMD% -m pip install pyinstaller
if %errorlevel% neq 0 (
    echo 错误: PyInstaller 安装失败
    exit /b 1
)

REM 打包
echo 正在打包...
%PYTHON_CMD% -m PyInstaller --onefile ^
  --name embedding_service ^
  --add-data "embedding;embedding" ^
  --hidden-import numpy ^
  --hidden-import onnxruntime ^
  --hidden-import chromadb ^
  --collect-all chromadb ^
  main.py

if %errorlevel% neq 0 (
    echo 错误: 打包失败
    exit /b 1
)

echo 打包完成: embedding_service\dist\embedding_service.exe

REM 复制产物到 Flutter 资源目录
if not exist "..\assets\embedding_service" mkdir "..\assets\embedding_service"
copy /Y dist\embedding_service.exe "..\assets\embedding_service\"

echo 已复制到 assets\embedding_service\embedding_service.exe

REM 清理临时文件
rmdir /s /q build 2>nul
rmdir /s /q __pycache__ 2>nul
del /q embedding_service.spec 2>nul

echo 完成！
