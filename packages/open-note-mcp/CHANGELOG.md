# Changelog

## 0.3.1 (2026-06-02)

### 修复
- 修复版本检查逻辑，使用 `packaging.version.Version` 进行正确的语义版本比较

---

## 0.3.0 (2026-06-02)

### 新增
- 集成版本检查功能，`status` 命令显示最新版本信息
- 版本信息使用 `importlib.metadata` 动态获取，与安装包一致
- 有新版本时显示升级提示

---

## 0.2.0 (2026-06-02)

### 新增
- 新增 `--help` 命令，显示完整的帮助信息和用法示例
- 新增 `--version` 命令，显示版本号和 MCP 协议版本
- 新增 `tools` 子命令，列出所有可用的 MCP 工具及描述
- 新增 `status` 子命令，检查服务器状态（版本、工具数、数据库路径等）
- 新增 `server` 子命令，显式启动 MCP 服务器

### 修复
- 修复无效参数导致 Python traceback 的问题
- 修复 macOS 下 `mktemp` 不兼容问题
- 修复 Python 版本检测问题

### 文档
- 完善 README，添加完整的命令行选项说明
- 添加 OpenCode 配置格式（`opencode.json`）到 README
- 添加 6 个主流 AI 编辑器的集成配置示例（Cursor、Claude Desktop、Cline、Windsurf、OpenCode、VS Code）
- 添加配置字段说明和 `autoApprove` 推荐配置

---

## 0.1.0 (2026-05-30)

### 首次发布
- 初始版本，包含 6 个 MCP 工具（search_notes、list_notes、get_note、create_note、update_note、delete_note）
