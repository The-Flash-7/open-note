@echo off
echo Building Python service (Windows)...

cd /d "%~dp0.."

REM Check Python environment (prefer python/venv, fallback to py launcher)
where python >nul 2>nul
if %errorlevel% equ 0 (
    set PYTHON_CMD=python
) else (
    set PYTHON_CMD=py -3
)

%PYTHON_CMD% --version >nul 2>nul
if %errorlevel% neq 0 (
    echo ERROR: Python not found. Please install Python 3.8-3.11.
    exit /b 1
)

REM Check Python version compatibility
for /f "tokens=2" %%a in ('%PYTHON_CMD% --version 2^>^&1') do set PY_VERSION=%%a
echo Detected Python version: %PY_VERSION%

cd embedding_service

REM Install dependencies (exit on failure)
echo Installing dependencies...
%PYTHON_CMD% -m pip install -r requirements.txt
if %errorlevel% neq 0 (
    echo ERROR: Dependency installation failed
    exit /b 1
)
%PYTHON_CMD% -m pip install "pyinstaller>=6.0"
if %errorlevel% neq 0 (
    echo ERROR: PyInstaller installation failed
    exit /b 1
)

REM Build
echo Building...
%PYTHON_CMD% -m PyInstaller --onefile ^
  --name embedding_service ^
  --add-data "embedding;embedding" ^
  --hidden-import numpy ^
  --hidden-import onnxruntime ^
  --hidden-import tqdm ^
  --hidden-import hnswlib ^
  --hidden-import tzdata ^
  --hidden-import chromadb ^
  --collect-all chromadb ^
  main.py

if %errorlevel% neq 0 (
    echo ERROR: Build failed
    exit /b 1
)

echo Build complete: embedding_service\dist\embedding_service.exe

REM Copy artifact to Flutter assets directory
if not exist "..\assets\embedding_service" mkdir "..\assets\embedding_service"
copy /Y dist\embedding_service.exe "..\assets\embedding_service\"

echo Copied to assets\embedding_service\embedding_service.exe

REM Clean up temporary files
rmdir /s /q build 2>nul
rmdir /s /q __pycache__ 2>nul
del /q embedding_service.spec 2>nul

echo Done!
