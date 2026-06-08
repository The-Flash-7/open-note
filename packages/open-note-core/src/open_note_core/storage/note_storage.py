# Copyright (c) 2026 litongshuai
# SPDX-License-Identifier: MIT OR Apache-2.0

"""OpenNote SQLite 数据存储层"""
import sqlite3
import json
import platform
import uuid
from datetime import datetime
from pathlib import Path
from typing import Optional, List, Dict, Any
from open_note_core.models.note import Note


class NoteStorage:
    """SQLite 笔记数据存储"""

    def __init__(self, db_path: Optional[str] = None):
        if db_path is None:
            db_path = self._get_default_db_path()

        self.db_path = db_path
        self.conn = sqlite3.connect(db_path, check_same_thread=False)
        self.conn.row_factory = sqlite3.Row
        self._init_tables()

    def _get_default_db_path(self) -> str:
        """获取默认数据库路径（与 Flutter 端一致）"""
        system = platform.system()
        if system == "Darwin":  # macOS
            base = Path.home() / "Library" / "Application Support" / "net.zsdn.opennote"
        elif system == "Linux":
            base = Path.home() / ".local" / "share" / "open_note"
        elif system == "Windows":
            base = Path.home() / "AppData" / "Roaming" / "open_note"
        else:
            raise ValueError(f"Unsupported platform: {system}")

        base.mkdir(parents=True, exist_ok=True)
        return str(base / "opennote.db")

    def _init_tables(self):
        """创建数据表（与 Flutter 端一致）"""
        self.conn.executescript("""
            CREATE TABLE IF NOT EXISTS notes (
                id TEXT PRIMARY KEY,
                title TEXT NOT NULL,
                content TEXT DEFAULT '',
                format TEXT DEFAULT 'markdown',
                language TEXT,
                summary TEXT,
                keywords TEXT,
                category TEXT,
                tags TEXT,
                source_url TEXT,
                source_type TEXT DEFAULT 'manual',
                created_at INTEGER NOT NULL,
                updated_at INTEGER NOT NULL,
                word_count INTEGER DEFAULT 0,
                is_favorite INTEGER DEFAULT 0,
                is_deleted INTEGER DEFAULT 0,
                deleted_at INTEGER
            );
            CREATE TABLE IF NOT EXISTS tags (
                id TEXT PRIMARY KEY,
                name TEXT UNIQUE NOT NULL,
                color TEXT,
                usage_count INTEGER DEFAULT 0
            );
            CREATE TABLE IF NOT EXISTS categories (
                id TEXT PRIMARY KEY,
                name TEXT NOT NULL,
                parentId TEXT,
                level INTEGER DEFAULT 0,
                createdAt INTEGER NOT NULL,
                updatedAt INTEGER NOT NULL,
                isVirtual INTEGER DEFAULT 0
            );
            CREATE TABLE IF NOT EXISTS config (
                key TEXT PRIMARY KEY,
                value TEXT
            );
            CREATE TABLE IF NOT EXISTS chat_messages (
                id TEXT PRIMARY KEY,
                role TEXT NOT NULL,
                content TEXT NOT NULL,
                timestamp TEXT NOT NULL,
                note_references TEXT,
                tool_calls TEXT,
                thinking TEXT
            );
            CREATE TABLE IF NOT EXISTS agent_memories (
                id TEXT PRIMARY KEY,
                type TEXT NOT NULL,
                content TEXT NOT NULL,
                confidence REAL DEFAULT 1.0,
                last_accessed TEXT,
                created_at TEXT NOT NULL,
                is_expired INTEGER DEFAULT 0
            );
            CREATE INDEX IF NOT EXISTS idx_notes_updated ON notes(updated_at DESC);
            CREATE INDEX IF NOT EXISTS idx_notes_favorite ON notes(is_favorite, updated_at DESC);
            CREATE INDEX IF NOT EXISTS idx_notes_category ON notes(category, is_deleted, updated_at DESC);
            CREATE INDEX IF NOT EXISTS idx_notes_deleted ON notes(is_deleted);
            CREATE INDEX IF NOT EXISTS idx_tags_name ON tags(name);
        """)
        self.conn.commit()

    def get_notes(self, limit: int = 100, category: Optional[str] = None, is_favorite: bool = False) -> List[Dict[str, Any]]:
        """获取笔记列表"""
        query = "SELECT * FROM notes WHERE is_deleted = 0"
        args = []
        if category:
            query += " AND category = ?"
            args.append(category)
        if is_favorite:
            query += " AND is_favorite = 1"
        query += " ORDER BY updated_at DESC LIMIT ?"
        args.append(limit)
        rows = self.conn.execute(query, args).fetchall()
        return [dict(r) for r in rows]

    def get_note(self, note_id: str) -> Optional[Dict[str, Any]]:
        """获取笔记详情"""
        row = self.conn.execute("SELECT * FROM notes WHERE id = ? AND is_deleted = 0", [note_id]).fetchone()
        return dict(row) if row else None

    def search_notes(self, query: str, limit: int = 20, category: Optional[str] = None, tags: Optional[List[str]] = None, favorites_only: bool = False) -> List[Dict[str, Any]]:
        """搜索笔记"""
        sql_query = "SELECT * FROM notes WHERE is_deleted = 0 AND (title LIKE ? OR content LIKE ? OR summary LIKE ?)"
        args = [f"%{query}%", f"%{query}%", f"%{query}%"]
        if category:
            sql_query += " AND category = ?"
            args.append(category)
        if favorites_only:
            sql_query += " AND is_favorite = 1"
        if tags:
            for tag in tags:
                sql_query += " AND tags LIKE ?"
                args.append(f"%{tag}%")
        sql_query += " ORDER BY updated_at DESC LIMIT ?"
        args.append(limit)
        rows = self.conn.execute(sql_query, args).fetchall()
        return [dict(r) for r in rows]

    def create_note(self, title: str, content: str = "", category: Optional[str] = None, tags: Optional[List[str]] = None, format: str = "markdown", language: Optional[str] = None, source_url: Optional[str] = None, source_type: str = "manual") -> Dict[str, Any]:
        """创建笔记"""
        now = int(datetime.now().timestamp() * 1000)
        note_id = str(uuid.uuid4())
        word_count = len(content.split())
        tags_json = json.dumps(tags or [], ensure_ascii=False)
        self.conn.execute(
            """INSERT INTO notes (id, title, content, format, language, category, tags, source_url, source_type, created_at, updated_at, word_count, is_favorite, is_deleted)
               VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 0, 0)""",
            [note_id, title, content, format, language, category, tags_json, source_url, source_type, now, now, word_count]
        )
        self.conn.commit()
        return self.get_note(note_id) or {}

    def update_note(self, note_id: str, title: Optional[str] = None, content: Optional[str] = None) -> Optional[Dict[str, Any]]:
        """更新笔记"""
        existing = self.get_note(note_id)
        if not existing:
            return None
        now = int(datetime.now().timestamp() * 1000)
        updates = []
        args = []
        if title is not None:
            updates.append("title = ?")
            args.append(title)
        if content is not None:
            updates.append("content = ?")
            args.append(content)
            word_count = len(content.split())
            updates.append("word_count = ?")
            args.append(word_count)
        updates.append("updated_at = ?")
        args.append(now)
        args.append(note_id)
        self.conn.execute(f"UPDATE notes SET {', '.join(updates)} WHERE id = ?", args)
        self.conn.commit()
        return self.get_note(note_id)

    def delete_note(self, note_id: str) -> bool:
        """删除笔记（软删除）"""
        now = int(datetime.now().timestamp() * 1000)
        cursor = self.conn.execute(
            "UPDATE notes SET is_deleted = 1, deleted_at = ? WHERE id = ? AND is_deleted = 0",
            [now, note_id]
        )
        self.conn.commit()
        return cursor.rowcount > 0

    def get_notes_count(self, category: Optional[str] = None) -> int:
        """获取笔记数量"""
        query = "SELECT COUNT(*) as count FROM notes WHERE is_deleted = 0"
        args = []
        if category:
            query += " AND category = ?"
            args.append(category)
        row = self.conn.execute(query, args).fetchone()
        return row["count"] if row else 0

    def get_config(self, key: str) -> Optional[str]:
        """获取配置"""
        row = self.conn.execute("SELECT value FROM config WHERE key = ?", [key]).fetchone()
        return row["value"] if row else None

    def set_config(self, key: str, value: str):
        """设置配置"""
        self.conn.execute(
            "INSERT INTO config (key, value) VALUES (?, ?) ON CONFLICT(key) DO UPDATE SET value = ?",
            [key, value, value]
        )
        self.conn.commit()

    def close(self):
        """关闭数据库连接"""
        self.conn.close()

    def __del__(self):
        self.close()
