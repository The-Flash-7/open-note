# open-note-core

OpenNote 核心库 - 数据模型和 SQLite 存储层。

## 功能

- SQLite 笔记数据存储（跨平台：macOS/Linux/Windows）
- 笔记、标签、分类、聊天消息、Agent 记忆的模型定义
- 数据库迁移和表管理

## 安装

```bash
pip install open-note-core
```

## 使用

```python
from open_note_core.storage.note_storage import NoteStorage

storage = NoteStorage()

# 创建笔记
note = storage.create_note("标题", "内容", category="工作", tags=["重要"])

# 获取笔记列表
notes = storage.get_notes(limit=10)

# 搜索笔记
results = storage.search_notes("关键词")
```

## 许可证

- MIT
- Apache 2.0
