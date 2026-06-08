# Changelog

## 0.3.1 (2026-06-02)

### 新增
- 添加 `--version` 和 `-v` 命令，显示 CLI 版本信息

### 修复
- 修复版本检查逻辑，使用 `packaging.version.Version` 进行正确的语义版本比较

---

## 0.3.0 (2026-06-02)

### 新增
- 集成版本检查功能，自动检查更新
- 显示所有 OpenNote 包（core、cli、mcp）的可用更新
- 提供一键升级命令提示

---

## 0.2.0 (2026-06-02)

### 新增
- `opennote mcp start` 增加未安装检测和自动安装引导
- `opennote mcp start` 增加安装确认步骤，不会自动安装
- `opennote mcp start` 增加安装失败时的详细错误提示
- `opennote mcp start` 增加网络超时处理

### 修复
- 修复 `importlib.resources` 在 Python 3.9 不兼容的问题
- 修复测试脚本路径问题

---

## 0.1.0 (2026-05-30)

### 首次发布
- 初始版本，包含笔记 CRUD、MCP 服务管理等核心功能
