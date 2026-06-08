# open-note-cli

OpenNote CLI - 跨平台笔记管理命令行工具。

## 功能

- 创建、编辑、删除笔记
- 列出和搜索笔记
- 管理收藏和分类
- 启动和管理 MCP 服务器

## 安装

```bash
pip install open-note-cli
```

## 使用

### 笔记管理

```bash
# 创建笔记
opennote note create --title "我的笔记" --content "笔记内容"

# 列出笔记
opennote note list --limit 20

# 查看笔记详情
opennote note show <note-id>

# 编辑笔记
opennote note edit <note-id> --title "新标题"

# 搜索笔记
opennote note search "关键词"

# 删除笔记
opennote note delete <note-id>
```

### MCP 服务

```bash
# 启动 MCP 服务器
opennote mcp start

# 查看 MCP 配置
opennote mcp inspect
```

### 配置

```bash
# 查看当前配置
opennote config get
```

## 许可证

- MIT
- Apache 2.0
