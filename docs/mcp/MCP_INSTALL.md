# Installing OpenNote MCP for OpenCode

## Prerequisites

- Python 3.10 or later
- pip installed

## Installation

### Step 1: Install the MCP package

```bash
pip install open-note-mcp
```

### Step 2: Configure OpenCode

Add to your `opencode.json` (project root or global config `~/.config/opencode/opencode.json`):

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

If `opencode.json` already exists, merge the `mcp` field into it.

### Step 3: Restart OpenCode

The MCP server will start automatically with OpenCode.

## Verify

Ask OpenCode: "List my notes" or "Show me the open-note MCP tools"

You can also check MCP status in terminal:

```bash
opencode mcp list
```

## Usage

After installation, you can use natural language to manage notes:

- "Create a note titled Meeting Notes with content..."
- "Search for notes about Python"
- "Show me note [id]"
- "Update note [id] with new content"
- "Delete note [id]"

## Available Tools

| Tool | Description |
|------|-------------|
| `open-note_search_notes` | Search notes by query |
| `open-note_list_notes` | List all notes |
| `open-note_get_note` | Get note details by ID |
| `open-note_create_note` | Create a new note |
| `open-note_update_note` | Update an existing note |
| `open-note_delete_note` | Delete a note |

## Troubleshooting

### Python not found

Ensure Python 3.10+ is installed:

```bash
python3.11 --version
```

If not installed, download from https://python.org

### Package install fails

Try upgrading pip first:

```bash
pip install --upgrade pip
pip install open-note-mcp
```

### MCP not loading

1. Verify installation: `pip show open-note-mcp`
2. Check server status: `opencode mcp list`
3. Check OpenCode logs for MCP errors

### Custom database path

Add `environment` to the MCP config:

```json
{
  "mcp": {
    "open-note": {
      "type": "local",
      "command": ["open-note-mcp"],
      "environment": {
        "OPENNOTE_DB_PATH": "/path/to/your/opennote.db"
      }
    }
  }
}
```

### Windows users

If you encounter issues with pip, try using the Python Launcher:

```powershell
py -3.11 -m pip install open-note-mcp
```

## Getting Help

- Report issues: https://github.com/The-Flash-7/open-note/issues
- Full documentation: https://github.com/The-Flash-7/open-note/tree/main/packages/open-note-mcp/README.md
