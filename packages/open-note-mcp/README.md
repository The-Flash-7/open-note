# open-note-mcp

OpenNote MCP Server - Model Context Protocol 服务。

## 功能

提供标准 MCP 协议的笔记管理工具，可集成到 Claude Desktop、Cursor、Windsurf、OpenCode、Cline 等 AI 编辑器中。

### 可用工具

| 工具名 | 描述 | 参数 |
|--------|------|------|
| `search_notes` | 搜索笔记 | `query`, `limit`, `category`, `tags`, `favorites_only` |
| `list_notes` | 列出笔记 | `limit`, `category`, `favorites_only` |
| `get_note` | 查看笔记详情 | `note_id` |
| `create_note` | 创建笔记 | `title`, `content`, `category`, `tags`, `format` |
| `update_note` | 编辑笔记 | `note_id`, `title`, `content` |
| `delete_note` | 删除笔记 | `note_id` |

## 安装

```bash
pip install open-note-mcp
```

## 使用

### 独立运行

```bash
# 启动 MCP 服务器（默认行为）
open-note-mcp

# 或使用子命令
open-note-mcp server
```

### 命令行选项

```bash
# 查看帮助
open-note-mcp --help

# 查看版本
open-note-mcp --version

# 列出可用工具
open-note-mcp tools

# 检查服务器状态
open-note-mcp status
```

### OpenCode 配置格式

OpenCode 使用不同的配置格式，配置添加到项目根目录的 `opencode.json`：

```json
{
  "$schema": "https://opencode.ai/config.json",
  "mcp": {
    "open-note": {
      "type": "local",
      "command": ["open-note-mcp"],
      "enabled": true
    }
  }
}
```

**注意**：OpenCode 使用 `mcp` 字段（而非 `mcpServers`），命令格式为数组 `[command]`（而非 `command` + `args`），环境变量字段为 `environment`（而非 `env`）。

## 集成到 AI 编辑器

### 1. Cursor

**设置路径**：`Settings → Features → MCP`

**配置文件**：`~/.cursor/mcp.json`

```json
{
  "mcpServers": {
    "open-note": {
      "type": "stdio",
      "command": "open-note-mcp",
      "args": []
    }
  }
}
```

### 2. Claude Desktop

**设置路径**：`Settings → Developer → Edit Config`

**配置文件路径**：
- macOS: `~/Library/Application Support/Claude/claude_desktop_config.json`
- Windows: `%APPDATA%\Claude\claude_desktop_config.json`

```json
{
  "mcpServers": {
    "open-note": {
      "type": "stdio",
      "command": "open-note-mcp",
      "args": []
    }
  }
}
```

### 3. Cline (VS Code 扩展)

**设置路径**：Cline 面板 → Settings → MCP Servers

```json
{
  "mcpServers": {
    "open-note": {
      "type": "stdio",
      "command": "open-note-mcp",
      "args": [],
      "autoApprove": [
        "list_notes",
        "get_note",
        "search_notes"
      ],
      "timeout": 60
    }
  }
}
```

### 4. Windsurf (Cascade)

**设置路径**：`Settings → MCP`

**配置文件路径**：`~/.codeium/windsurf/mcp_config.json`

```json
{
  "mcpServers": {
    "open-note": {
      "type": "stdio",
      "command": "open-note-mcp",
      "args": []
    }
  }
}
```

### 5. OpenCode

**配置文件**：项目根目录 `opencode.json` 或全局配置 `~/.config/opencode/opencode.json`

```json
{
  "$schema": "https://opencode.ai/config.json",
  "mcp": {
    "open-note": {
      "type": "local",
      "command": ["open-note-mcp"],
      "enabled": true
    }
  }
}
```

**注意**：OpenCode 使用 `mcp` 字段（而非 `mcpServers`），命令格式为数组 `[command]`（而非 `command` + `args`）。

### 6. VS Code (GitHub Copilot)

**设置路径**：`Settings → Features → GitHub Copilot → MCP Servers`

点击 **Add Server**，选择 **stdio** 类型：
- Name: `open-note`
- Command: `open-note-mcp`

## 配置字段说明

### Cline 等工具的扩展字段

| 字段 | 类型 | 说明 | 是否必须 |
|------|------|------|----------|
| `type` | string | 传输类型：`stdio`（标准输入输出）或 `sse`/`http`（HTTP） | 建议 |
| `command` | string | 启动命令 | 必须 |
| `args` | array | 命令参数 | 必须 |
| `env` | object | 环境变量，如 `{"OPENNOTE_DB_PATH": "/path/to/db"}` | 可选 |
| `autoApprove` | array | 自动批准的工具列表，Agent 调用时无需用户确认 | 可选 |
| `disabled` | boolean | 是否禁用该服务器 | 可选 |
| `timeout` | number | 超时时间（秒） | 可选 |

### `autoApprove` 推荐配置

| 工具 | 推荐自动批准 | 原因 |
|------|-------------|------|
| `list_notes` | ✅ | 只读操作，安全 |
| `get_note` | ✅ | 只读操作，安全 |
| `search_notes` | ✅ | 只读操作，安全 |
| `create_note` | ⚠️ 可选 | 会创建新笔记 |
| `update_note` | ❌ 不推荐 | 会修改内容 |
| `delete_note` | ❌ 不推荐 | 会删除内容 |

## 自定义数据库路径

如果需要使用自定义数据库路径，在配置中添加 `env` 字段：

```json
{
  "mcpServers": {
    "open-note": {
      "type": "stdio",
      "command": "open-note-mcp",
      "args": [],
      "env": {
        "OPENNOTE_DB_PATH": "/path/to/your/opennote.db"
      }
    }
  }
}
```

**须知**：如自定义数据库路径，则桌面端OpenNote应用无法读取

## 许可证

- MIT
- Apache 2.0
