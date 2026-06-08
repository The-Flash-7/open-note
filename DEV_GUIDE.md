# OpenNote - 开发指南


## 🛠️ 开发

### 环境要求

- Flutter SDK 3.11.5+
- Dart SDK
- Python 3.10+

### 克隆项目

```bash
git clone https://github.com/The-Flash-7/open-note.git
cd open-note
```

### 安装依赖

```bash
# Flutter 依赖
flutter pub get

# Python 服务依赖（开发用）
cd embedding_service
pip install -r requirements.txt
```

### 开源许可证检查
```bash
# flutter
lic_ck check-licenses -c license_config.yaml

# python
./check_python_licenses.sh
```

### 运行

```bash
# macOS
flutter run -d macos

# Windows
flutter run -d windows

# Linux
flutter run -d linux
```

### 构建发布版本

```bash
# 1. 打包 Embedding 服务 (PyInstaller 单文件二进制)
bash scripts/build_embedding_service_macos.sh    # macOS
bash scripts/build_embedding_service_linux.sh    # Linux
scripts\build_embedding_service_windows.bat      # Windows

# 2. 构建 Flutter 应用
flutter build macos    # macOS (.app)
flutter build windows  # Windows (.exe)
flutter build linux    # Linux (binary)
```

## Embedding 服务打包说明

### PyInstaller 打包产物

| 平台 | 产物文件 | 大小 |
|------|----------|------|
| macOS | `dist/embedding_service` | ~50-80MB |
| Windows | `dist\embedding_service.exe` | ~50-80MB |
| Linux | `dist/embedding_service` | ~50-80MB |

### 打包产物放置位置

打包后的可执行文件会自动复制到 `assets/embedding_service/` 目录，Flutter 构建时会将其嵌入到应用中。

### CI/CD

项目使用 GitHub Actions 自动构建多平台安装包：

- **触发条件**：推送 `v*` 标签 或手动触发
- **构建产物**：
    - macOS: `.dmg` 安装包
    - Windows: `.zip` 压缩包
    - Linux: `.tar.gz` 压缩包

## 常见问题

### Q: Embedding服务启动失败？
A: 检查Python版本(需要3.10+)和依赖安装: `pip3 install -r requirements.txt`

### Q: AI功能不工作？
A: 需要在设置中配置AI服务提供商和API密钥

### Q: 应用无法启动？
A: 运行 `flutter clean && flutter pub get` 清理重新安装依赖

## 贡献代码

1. Fork项目
2. 创建feature分支
3. 提交Pull Request

## 更新日志

### v1.0.0 (2026-05-28)
- ✅ MVP版本完成
- ✅ 笔记管理功能
- ✅ 向量索引
- ✅ Cici Agent 智能助手
- ✅ MCP 服务器
- ✅ CLI 工具
- ✅ macOS构建成功