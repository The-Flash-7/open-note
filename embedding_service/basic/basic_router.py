# Copyright (c) 2026 litongshuai
# SPDX-License-Identifier: MIT OR Apache-2.0

from fastapi import APIRouter
from pydantic import BaseModel
from typing import Optional, Dict, Any
from datetime import datetime

router = APIRouter(tags=["basic"])

_start_time = datetime.now()
_advanced_loaded = False
_service_state = "basic_ready"

class DocumentParseRequest(BaseModel):
    file_path: str

class DocumentParseResponse(BaseModel):
    success: bool
    error: Optional[str] = None
    text: Optional[str] = None
    metadata: Optional[Dict[str, Any]] = None
    file_type: Optional[str] = None

@router.get("/health")
async def health_check():
    """健康检查 - 基础服务立即可用"""
    return {
        "status": "ok",
        "state": _service_state,
        "uptime_seconds": int((datetime.now() - _start_time).total_seconds()),
    }

@router.get("/api/service/identity")
async def service_identity():
    """服务识别 - 用于验证服务身份"""
    return {
        "service": "open-note-embedding-service",
        "version": "1.0.0",
        "app_id": "net.zsdn.opennote"
    }

@router.get("/api/service/status")
async def service_status():
    """服务状态 - 区分基础和高级功能状态"""
    uptime = (datetime.now() - _start_time).total_seconds()
    return {
        "state": _service_state,
        "message": "基础服务已就绪" if not _advanced_loaded else "所有服务已就绪",
        "components": {
            "basic_service": "initialized",
            "advanced_service": "loaded" if _advanced_loaded else "not_loaded",
        },
        "start_time": _start_time.isoformat(),
        "uptime_seconds": int(uptime),
        "advanced_loaded": _advanced_loaded,
    }

@router.post("/api/document/parse", response_model=DocumentParseResponse)
async def parse_document(request: DocumentParseRequest):
    """文档解析 - 延迟导入优化启动时间"""
    from .document_parser import DocumentParser
    result = DocumentParser.parse_document(request.file_path)
    return DocumentParseResponse(**result)

@router.get("/api/document/supported_formats")
async def get_supported_formats():
    """获取支持的文档格式"""
    from .document_parser import DocumentParser
    return {
        "formats": DocumentParser.SUPPORTED_EXTENSIONS,
        "description": {
            ".pdf": "PDF documents",
            ".docx": "Microsoft Word documents (Office 2007+)",
            ".pptx": "Microsoft PowerPoint presentations (Office 2007+)"
        }
    }

def set_advanced_loaded(loaded: bool):
    """设置高级功能加载状态"""
    global _advanced_loaded, _service_state
    _advanced_loaded = loaded
    _service_state = "ready" if loaded else "basic_ready"