# Changelog

## 0.3.2 (2026-06-11)

### 修复
- 修复版本检查逻辑，动态获取元数据的版本定义

---

## 0.3.1 (2026-06-02)

### 修复
- 修复版本检查逻辑，使用 `packaging.version.Version` 进行正确的语义版本比较
- 修复 `0.3.0 → 0.2.0` 被误判为有新版本的问题

---

## 0.3.0 (2026-06-02)

### 新增
- 新增 `version_checker.py` 模块，支持检查 PyPI 版本更新
- 新增 `check_update()` 函数，检查指定包是否有可用更新
- 新增 `check_all_opennote_updates()` 函数，检查所有 OpenNote 包更新
- 新增 `format_update_message()` 函数，格式化更新提示信息

---

## 0.2.0 (2026-06-02)

### 新增
- `open-note-mcp` 新增 `--help` 命令，显示帮助信息
- `open-note-mcp` 新增 `--version` 命令，显示版本和协议版本
- `open-note-mcp` 新增 `tools` 子命令，列出所有可用工具
- `open-note-mcp` 新增 `status` 子命令，检查服务器状态和配置
- `open-note-cli` `mcp start` 增加未安装检测和自动安装引导
- `open-note-cli` `mcp start` 增加安装失败时的详细错误提示

### 修复
- `open-note-core` 修复 `import json` 缺失导致的运行错误
- `open-note-mcp` 修复无效参数导致 Python traceback 的问题
- `open-note-cli` 修复 Python 3.9 兼容性（`importlib.resources`）
- `open-note-mcp` 修复 macOS 下 `mktemp` 不兼容问题

### 文档
- 完善 `open-note-mcp` README，添加完整的命令行选项说明
- 添加 OpenCode 配置格式（`opencode.json`）到 README
- 添加 `.opencode/INSTALL.md` 用于 OpenCode Agent 自动安装
- 添加配置字段说明和 `autoApprove` 推荐配置

---

## 0.1.0 (2026-05-30)

### 首次发布
- 初始版本，包含核心功能
