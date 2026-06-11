# Copyright (c) 2026 litongshuai
# SPDX-License-Identifier: MIT OR Apache-2.0

"""OpenNote 核心库 - 数据模型和存储层"""
try:
    import importlib.metadata
    __version__ = importlib.metadata.version("open-note-core")
except Exception:
    __version__ = "0.3.1"
