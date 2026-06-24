# Copyright (c) 2026 litongshuai
# SPDX-License-Identifier: MIT OR Apache-2.0

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import Optional, Dict, Any
from .document_parser import DocumentParser

router = APIRouter(prefix="/api/document", tags=["document"])


class DocumentParseRequest(BaseModel):
    file_path: str


class DocumentParseResponse(BaseModel):
    success: bool
    error: Optional[str] = None
    text: Optional[str] = None
    metadata: Optional[Dict[str, Any]] = None
    file_type: Optional[str] = None


@router.post("/parse", response_model=DocumentParseResponse)
async def parse_document(request: DocumentParseRequest):
    result = DocumentParser.parse_document(request.file_path)
    return DocumentParseResponse(**result)


@router.get("/supported_formats")
async def get_supported_formats():
    return {
        "formats": DocumentParser.SUPPORTED_EXTENSIONS,
        "description": {
            ".pdf": "PDF documents",
            ".docx": "Microsoft Word documents (Office 2007+)",
            ".pptx": "Microsoft PowerPoint presentations (Office 2007+)"
        }
    }