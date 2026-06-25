# Copyright (c) 2026 litongshuai
# SPDX-License-Identifier: MIT OR Apache-2.0

import argparse
import os
import asyncio
from datetime import datetime
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import uvicorn

# 只导入基础路由（轻量导入，启动快）
from basic.basic_router import router as basic_router, set_advanced_loaded

# 延迟导入高级路由（只在需要时导入）
_embedding_router_imported = False
_embedding_router = None

def _lazy_import_embedding_router():
    """延迟导入 embedding_router，优化启动时间"""
    global _embedding_router_imported, _embedding_router
    if not _embedding_router_imported:
        try:
            from embedding.embedding_router import router as embedding_router
            _embedding_router = embedding_router
            _embedding_router_imported = True
        except ImportError as e:
            print(f"EmbeddingService: embedding_router 导入失败: {e}")
    return _embedding_router

app = FastAPI(title="OpenNote Python Service")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# 注册基础路由
app.include_router(basic_router)

_start_time = datetime.now()
_model_dir_global = None
_data_dir_global = None

async def load_advanced_features(model_dir: str | None, data_dir: str):
    """非阻塞后台加载高级功能（仅注册路由，延迟初始化）"""
    try:
        print("EmbeddingService: 正在注册高级路由...")
        
        # 延迟导入高级路由
        embedding_router = _lazy_import_embedding_router()
        if embedding_router is None:
            print("EmbeddingService: embedding_router 导入失败，跳过注册")
            return
        
        # 注册高级路由（如果尚未注册）
        if not any(r.path == "/api/embedding" for r in app.routes):
            app.include_router(embedding_router)
            print("EmbeddingService: embedding_router 已注册")
        
        # 设置全局配置（用于延迟加载）
        from embedding.embedding_router import set_kb_config
        set_kb_config(model_dir)
        
        # 设置高级功能已加载状态（路由已注册）
        set_advanced_loaded(True)
        print("EmbeddingService: 高级路由已注册（配置已设置，实例延迟创建）")
        
    except Exception as e:
        print(f"EmbeddingService: 高级路由注册失败: {e}")
        import traceback
        traceback.print_exc()

def main():
    parser = argparse.ArgumentParser(description="OpenNote embedding service")
    parser.add_argument("--port", type=int, default=8765, help="Port to run the service on")
    parser.add_argument("--host", type=str, default="127.0.0.1", help="Host to bind the service to")
    parser.add_argument("--model-dir", type=str, default=None, help="Path to embedding model directory")
    parser.add_argument("--data-dir", type=str, default=None, help="Path to data directory for persistent storage")
    parser.add_argument("--kb-enabled", type=str, default="false", help="知识库是否开启 (true/false)")
    
    args = parser.parse_args()
    
    global _model_dir_global, _data_dir_global
    _data_dir_global = args.data_dir or os.path.join(os.getcwd(), "chroma_data")
    _model_dir_global = args.model_dir
    
    # 解析知识库状态
    kb_enabled = args.kb_enabled.lower() in ('true', '1', 'yes')
    
    # 始终延迟导入并注册 embedding_router（路由注册≠功能加载）
    embedding_router = _lazy_import_embedding_router()
    if embedding_router is not None:
        app.include_router(embedding_router)
        print("EmbeddingService: embedding_router 已注册（延迟初始化）")
    
    # 如果知识库开启，后台加载高级功能
    if kb_enabled:
        @app.on_event("startup")
        async def on_startup():
            asyncio.create_task(load_advanced_features(_model_dir_global, _data_dir_global))
    
    print(f"Starting OpenNote embedding service on {args.host}:{args.port}")
    print(f"知识库状态: {kb_enabled}")
    
    uvicorn.run(app, host=args.host, port=args.port)

if __name__ == "__main__":
    main()