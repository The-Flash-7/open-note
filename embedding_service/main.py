# Copyright (c) 2026 litongshuai
# SPDX-License-Identifier: MIT OR Apache-2.0

import argparse
import os
import asyncio
from datetime import datetime
from typing import Optional
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import uvicorn

from embedding.embedding_router import router as embedding_router, init_chroma, get_embedding_service

app = FastAPI(title="OpenNote Python Service")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(embedding_router)

# --- Service State Management ---
class ServiceState:
    STARTING = "starting"
    INITIALIZING_DB = "initializing_db"
    LOADING_MODEL = "loading_model"
    READY = "ready"
    ERROR_DB_INIT = "error_db_init"
    ERROR_MODEL_LOAD = "error_model_load"
    ERROR_GENERAL = "error_general"

class ComponentStatus:
    PENDING = "pending"
    INITIALIZING = "initializing"
    INITIALIZED = "initialized"
    LOADING = "loading"
    LOADED = "loaded"
    FAILED = "failed"
    NOT_CONFIGURED = "not_configured"

# Global state
_service_state = ServiceState.STARTING
_service_message = "服务刚启动"
_service_start_time = datetime.now()
_chroma_db_status = ComponentStatus.PENDING
_embedding_model_status = ComponentStatus.PENDING
_error_detail = ""
_model_dir_global: Optional[str] = None
_data_dir_global: Optional[str] = None

@app.get("/health")
async def health_check():
    """Simple health check - returns 200 as soon as Uvicorn is listening"""
    return {
        "status": "ok",
        "state": _service_state
    }

@app.get("/api/service/status")
async def service_status():
    """Detailed service status with component-level information"""
    uptime = (datetime.now() - _service_start_time).total_seconds()
    return {
        "state": _service_state,
        "message": _service_message,
        "components": {
            "chroma_db": _chroma_db_status,
            "embedding_model": _embedding_model_status,
        },
        "start_time": _service_start_time.isoformat(),
        "uptime_seconds": int(uptime),
        "error_detail": _error_detail if _error_detail else None,
    }

@app.get("/api/service/identity")
async def service_identity():
    """服务识别接口，用于验证是否是我们的 Python 服务"""
    return {
        "service": "open-note-embedding-service",
        "version": "1.0.0",
        "app_id": "net.zsdn.opennote"
    }

@app.post("/api/service/restart")
async def restart_service():
    """重启服务（重新初始化 ChromaDB 和模型，不终止进程）"""
    global _service_state, _service_message, _chroma_db_status
    global _embedding_model_status, _error_detail, _service_start_time
    
    print("EmbeddingService: 收到重启请求")
    
    # 卸载当前模型
    try:
        embedding_svc = get_embedding_service()
        embedding_svc.unload_model()
        print("EmbeddingService: 已卸载当前模型")
    except Exception as e:
        print(f"EmbeddingService: 卸载模型时异常: {e}")
    
    # 重置状态为启动中
    _service_state = ServiceState.STARTING
    _service_message = "服务正在重启..."
    _chroma_db_status = ComponentStatus.PENDING
    _embedding_model_status = ComponentStatus.PENDING
    _error_detail = ""
    _service_start_time = datetime.now()
    
    # 后台重新初始化（使用原始启动参数）
    asyncio.create_task(initialize_services(_model_dir_global, _data_dir_global))
    
    return {
        "status": "restarting",
        "message": "服务重启已启动，请稍后通过 /api/service/status 检查状态"
    }

async def initialize_services(model_dir: str | None, data_dir: str):
    """Initialize ChromaDB and model in background after server starts"""
    global _service_state, _service_message, _chroma_db_status
    global _embedding_model_status, _error_detail
    
    # Phase 1: Initialize ChromaDB
    _service_state = ServiceState.INITIALIZING_DB
    _service_message = "正在初始化数据库..."
    _chroma_db_status = ComponentStatus.INITIALIZING
    
    try:
        print("EmbeddingService: 正在初始化 ChromaDB...")
        print(f"EmbeddingService: 数据目录路径: {data_dir}")
        print(f"EmbeddingService: 数据目录绝对路径: {os.path.abspath(data_dir)}")
        os.makedirs(data_dir, exist_ok=True)
        print(f"EmbeddingService: 数据目录已创建/存在，可写性: {os.access(data_dir, os.W_OK)}")
        init_chroma(data_dir)
        _chroma_db_status = ComponentStatus.INITIALIZED
        print(f"ChromaDB: 数据目录 {data_dir}")
    except Exception as e:
        import traceback
        _service_state = ServiceState.ERROR_DB_INIT
        _service_message = "数据库初始化失败"
        _chroma_db_status = ComponentStatus.FAILED
        _error_detail = f"ChromaDB init error: {str(e)}"
        print(f"EmbeddingService: ChromaDB 初始化失败: {e}")
        print(f"EmbeddingService: 数据目录路径: {data_dir}")
        print(f"EmbeddingService: 完整堆栈跟踪:")
        print(traceback.format_exc())
        return
    
    # Phase 2: Load embedding model (if configured)
    if model_dir:
        _service_state = ServiceState.LOADING_MODEL
        _service_message = "正在加载 AI 模型..."
        _embedding_model_status = ComponentStatus.LOADING
        
        try:
            print("EmbeddingService: 正在加载 Embedding 模型...")
            embedding_svc = get_embedding_service()
            success = embedding_svc.load_model(model_dir)
            if success:
                _embedding_model_status = ComponentStatus.LOADED
                print(f"EmbeddingService: 模型预加载成功: {model_dir}")
            else:
                _embedding_model_status = ComponentStatus.FAILED
                _error_detail = "Model load returned false"
                print(f"EmbeddingService: 模型预加载失败: {model_dir}")
        except Exception as e:
            _embedding_model_status = ComponentStatus.FAILED
            _error_detail = f"Model load error: {str(e)}"
            print(f"EmbeddingService: 模型加载失败: {e}")
        
        # Check if everything is OK
        if _chroma_db_status == ComponentStatus.INITIALIZED and _embedding_model_status == ComponentStatus.LOADED:
            _service_state = ServiceState.READY
            _service_message = "所有组件初始化完成，服务就绪"
            print("EmbeddingService: 所有服务初始化完成")
        elif _chroma_db_status == ComponentStatus.INITIALIZED and _embedding_model_status == ComponentStatus.FAILED:
            # DB is ready but model failed - service is partially functional
            _service_state = ServiceState.ERROR_MODEL_LOAD
            _service_message = "数据库已就绪，但模型加载失败（基础功能仍可用）"
            print("EmbeddingService: 部分初始化完成（模型加载失败）")
        else:
            _service_state = ServiceState.ERROR_GENERAL
            _service_message = "服务初始化异常"
            print(f"EmbeddingService: 初始化异常, state={_service_state}")
    else:
        # No model configured
        _embedding_model_status = ComponentStatus.NOT_CONFIGURED
        if _chroma_db_status == ComponentStatus.INITIALIZED:
            _service_state = ServiceState.READY
            _service_message = "数据库已就绪（未配置模型）"
            print("EmbeddingService: ChromaDB 初始化完成（未配置模型）")
        else:
            _service_state = ServiceState.ERROR_GENERAL
            _service_message = "服务初始化异常"

def main():
    parser = argparse.ArgumentParser(description="OpenNote embedding service")
    parser.add_argument("--port", type=int, default=8765, help="Port to run the service on")
    parser.add_argument("--host", type=str, default="127.0.0.1", help="Host to bind the service to")
    parser.add_argument("--model-dir", type=str, default=None, help="Path to embedding model directory")
    parser.add_argument("--data-dir", type=str, default=None, help="Path to data directory for persistent storage")
    
    args = parser.parse_args()
    
    global _model_dir_global, _data_dir_global
    _data_dir_global = args.data_dir or os.path.join(os.getcwd(), "chroma_data")
    _model_dir_global = args.model_dir
    
    # Schedule initialization to run after server starts
    @app.on_event("startup")
    async def on_startup():
        # Run initialization in background so /health endpoint is available immediately
        asyncio.create_task(initialize_services(_model_dir_global, _data_dir_global))
    
    print(f"Starting OpenNote embedding service on {args.host}:{args.port}")
    uvicorn.run(app, host=args.host, port=args.port)

if __name__ == "__main__":
    main()
