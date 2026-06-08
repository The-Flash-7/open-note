# Copyright (c) 2026 litongshuai
# SPDX-License-Identifier: MIT OR Apache-2.0

"""OpenNote 笔记数据模型"""
from dataclasses import dataclass, field, asdict
from typing import Optional, List
import json


@dataclass
class Note:
    id: str
    title: str
    content: str = ""
    format: str = "markdown"
    language: Optional[str] = None
    summary: Optional[str] = None
    keywords: List[str] = field(default_factory=list)
    category: Optional[str] = None
    tags: List[str] = field(default_factory=list)
    source_url: Optional[str] = None
    source_type: str = "manual"
    created_at: int = 0
    updated_at: int = 0
    word_count: int = 0
    is_favorite: int = 0
    is_deleted: int = 0
    deleted_at: Optional[int] = None

    def to_dict(self) -> dict:
        return asdict(self)

    def to_json(self) -> str:
        return json.dumps(self.to_dict(), ensure_ascii=False)

    @classmethod
    def from_dict(cls, data: dict) -> "Note":
        return cls(**{k: v for k, v in data.items() if k in cls.__dataclass_fields__})

    @classmethod
    def from_json(cls, json_str: str) -> "Note":
        return cls.from_dict(json.loads(json_str))
