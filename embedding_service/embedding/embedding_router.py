# Copyright (c) 2026 litongshuai
# SPDX-License-Identifier: MIT OR Apache-2.0

import os
import uuid
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import List, Optional

chromadb = None
Settings = None

def _lazy_import_chromadb():
    """延迟导入 chromadb，优化启动时间"""
    global chromadb, Settings
    if chromadb is None:
        try:
            import chromadb as _chromadb
            from chromadb.config import Settings as _Settings
            chromadb = _chromadb
            Settings = _Settings
        except ImportError:
            pass
    return chromadb, Settings

router = APIRouter(prefix="/api", tags=["embedding"])

embedding_service = None
chroma_client = None
collection = None

# 知识库服务状态标志
_kb_started = False
_model_dir_config = None

def get_embedding_service():
    """延迟导入并获取 embedding service"""
    global embedding_service
    if embedding_service is None:
        from .local_embedding import LocalEmbeddingService
        embedding_service = LocalEmbeddingService()
    return embedding_service

def set_kb_config(model_dir: str | None):
    """设置知识库配置（用于延迟加载）"""
    global _model_dir_config
    _model_dir_config = model_dir

def init_chroma(data_dir: str):
    """初始化 ChromaDB 客户端和集合"""
    global chroma_client, collection
    
    _lazy_import_chromadb()
    
    if chromadb is None:
        raise ImportError("ChromaDB 未安装")
    
    chroma_client = chromadb.PersistentClient(path=data_dir)
    
    collection = chroma_client.get_or_create_collection(
        name="notes",
        embedding_function=None,
        metadata={"hnsw:space": "cosine"}
    )
    print(f"ChromaDB: 集合 '{collection.name}' 已加载，包含 {collection.count()} 个向量")

def get_chroma_collection():
    if collection is None:
        raise HTTPException(status_code=500, detail="ChromaDB 未初始化")
    return collection

class EmbeddingRequest(BaseModel):
    text: str
    model_dir: Optional[str] = None

class EmbeddingResponse(BaseModel):
    embedding: List[float]
    dimensions: int

class VectorChunk(BaseModel):
    id: str
    text: str
    metadata: Optional[dict] = None

class VectorUpsertRequest(BaseModel):
    note_id: str
    chunks: List[VectorChunk]

class VectorSearchRequest(BaseModel):
    query: str
    top_k: int = 5
    note_ids: Optional[List[str]] = None
    titles: Optional[List[str]] = None
    categories: Optional[List[str]] = None

class VectorStatsResponse(BaseModel):
    total_vectors: int
    unique_notes: int

class KBStartRequest(BaseModel):
    model_dir: Optional[str] = None
    data_dir: Optional[str] = None

class KBStopRequest(BaseModel):
    pass

class KBStatusResponse(BaseModel):
    kb_started: bool
    model_loaded: bool
    chroma_initialized: bool
    message: str

@router.post("/knowledge-base/start")
async def start_knowledge_base(request: KBStartRequest):
    """启动知识库服务：创建实例、初始化 ChromaDB、加载模型"""
    global _kb_started
    
    # 幂等性检查：如果已启动，跳过
    if _kb_started:
        embedding_svc = get_embedding_service()
        return KBStatusResponse(
            kb_started=True,
            model_loaded=embedding_svc.is_model_loaded,
            chroma_initialized=collection is not None,
            message="知识库服务已启动，跳过重复初始化"
        )
    
    try:
        # 创建实例（首次）
        embedding_svc = get_embedding_service()
        
        # 初始化 ChromaDB（重新连接）
        # 使用请求参数或全局配置
        from main import _data_dir_global
        data_dir = request.data_dir or _data_dir_global
        if data_dir:
            init_chroma(data_dir)
        
        # 加载模型（如果请求中指定了模型路径）
        model_dir = request.model_dir or _model_dir_config
        if model_dir:
            success = embedding_svc.load_model(model_dir)
            if not success:
                raise HTTPException(status_code=500, detail="模型加载失败")
        
        # 设置状态标志
        _kb_started = True
        
        return KBStatusResponse(
            kb_started=True,
            model_loaded=embedding_svc.is_model_loaded,
            chroma_initialized=collection is not None,
            message="知识库服务已启动"
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/knowledge-base/stop")
async def stop_knowledge_base():
    """停止知识库服务：卸载模型、断开连接、清空实例"""
    global _kb_started, embedding_service, chroma_client, collection
    
    # 检查是否已启动
    if not _kb_started:
        return KBStatusResponse(
            kb_started=False,
            model_loaded=False,
            chroma_initialized=False,
            message="知识库服务未启动，无需停止"
        )
    
    try:
        # 卸载模型（如果已加载）
        if embedding_service and embedding_service.is_model_loaded:
            embedding_service.unload_model()
        
        # 清空 Embedding Service 实例
        embedding_service = None
        
        # 断开 ChromaDB 连接（保留数据库文件）
        chroma_client = None
        collection = None
        
        # 重置状态标志
        _kb_started = False
        
        return KBStatusResponse(
            kb_started=False,
            model_loaded=False,
            chroma_initialized=False,
            message="知识库服务已停止（ChromaDB 数据保留）"
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/embedding")
async def generate_embedding(request: EmbeddingRequest):
    """生成文本的 embedding 向量"""
    # 检查知识库是否已启动
    if not _kb_started:
        raise HTTPException(status_code=500, detail="知识库服务未启动，请先调用 /api/knowledge-base/start")
    
    try:
        # 延迟导入并获取 embedding service
        embedding_svc = get_embedding_service()
        
        if request.model_dir and not embedding_svc.is_model_loaded:
            success = embedding_svc.load_model(request.model_dir)
            if not success:
                raise HTTPException(status_code=500, detail="模型加载失败")

        if not embedding_svc.is_model_loaded:
            raise HTTPException(status_code=500, detail="模型未加载")

        embedding = embedding_svc.generate_embedding(request.text)

        return EmbeddingResponse(
            embedding=embedding,
            dimensions=len(embedding)
        )
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/vector/upsert")
async def upsert_vectors(request: VectorUpsertRequest):
    """添加或更新笔记向量"""
    # 检查知识库是否已启动
    if not _kb_started:
        raise HTTPException(status_code=500, detail="知识库服务未启动，请先调用 /api/knowledge-base/start")
    
    try:
        col = get_chroma_collection()
        
        # 延迟导入并获取 embedding service
        embedding_svc = get_embedding_service()
        
        if not embedding_svc.is_model_loaded:
            raise HTTPException(status_code=500, detail="模型未加载")

        ids = []
        embeddings = []
        documents = []
        metadatas = []

        # 先删除该笔记的旧向量
        try:
            col.delete(where={"note_id": request.note_id})
        except Exception:
            pass

        # 准备新向量
        for chunk in request.chunks:
            chunk_id = f"{request.note_id}_{chunk.id}"
            embedding = embedding_svc.generate_embedding(chunk.text)
            
            ids.append(chunk_id)
            embeddings.append(embedding)
            documents.append(chunk.text)
            
            meta = chunk.metadata or {}
            meta["note_id"] = request.note_id
            metadatas.append(meta)

        if ids:
            col.add(
                ids=ids,
                embeddings=embeddings,
                documents=documents,
                metadatas=metadatas
            )
            print(f"ChromaDB: 已添加 {len(ids)} 个向量，笔记 ID: {request.note_id}")

        return {"status": "ok", "added_count": len(ids)}

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/vector/search")
async def search_vectors(request: VectorSearchRequest):
    """语义搜索"""
    # 检查知识库是否已启动
    if not _kb_started:
        raise HTTPException(status_code=500, detail="知识库服务未启动，请先调用 /api/knowledge-base/start")
    
    try:
        col = get_chroma_collection()
        
        # 延迟导入并获取 embedding service
        embedding_svc = get_embedding_service()
        
        if not embedding_svc.is_model_loaded:
            raise HTTPException(status_code=500, detail="模型未加载")

        # 生成查询向量
        query_embedding = embedding_svc.generate_embedding(request.query)

        # 构建 where 过滤条件（AND 关系）
        conditions = []

        if request.note_ids and len(request.note_ids) > 0:
            conditions.append({"note_id": {"$in": request.note_ids}})

        if request.titles and len(request.titles) > 0:
            conditions.append({"title": {"$in": request.titles}})

        if request.categories and len(request.categories) > 0:
            conditions.append({"category": {"$in": request.categories}})

        where = None
        if len(conditions) == 1:
            where = conditions[0]
        elif len(conditions) > 1:
            where = {"$and": conditions}

        # 搜索
        results = col.query(
            query_embeddings=[query_embedding],
            n_results=request.top_k,
            where=where,
            include=["metadatas", "documents", "distances"]
        )

        # 格式化结果
        formatted_results = []
        if results["ids"] and results["ids"][0]:
            for i in range(len(results["ids"][0])):
                formatted_results.append({
                    "id": results["ids"][0][i],
                    "note_id": results["metadatas"][0][i].get("note_id", ""),
                    "text": results["documents"][0][i],
                    "metadata": results["metadatas"][0][i],
                    "distance": results["distances"][0][i],
                    "score": 1.0 - results["distances"][0][i]  # 转换为相似度分数
                })

        return {"results": formatted_results}

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.delete("/vector/note/{note_id}")
async def delete_note_vectors(note_id: str):
    """删除指定笔记的所有向量"""
    try:
        col = get_chroma_collection()
        col.delete(where={"note_id": note_id})
        print(f"ChromaDB: 已删除笔记向量，笔记 ID: {note_id}")
        return {"status": "ok"}
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.delete("/vector/clear_all")
async def clear_all_vectors():
    """清空所有向量（删除并重建整个 Collection）"""
    global collection
    try:
        # 尝试删除 Collection（如果不存在也不会报错）
        try:
            chroma_client.delete_collection(name="notes")
        except Exception:
            pass  # Collection 不存在也无所谓
        
        # 重新创建空的 Collection
        collection = chroma_client.get_or_create_collection(
            name="notes",
            embedding_function=None,
            metadata={"hnsw:space": "cosine"}
        )
        print("ChromaDB: 已彻底清空向量库（重建 Collection）")
        return {"status": "ok"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/vector/stats")
async def get_vector_stats():
    """获取向量统计信息"""
    try:
        col = get_chroma_collection()
        total = col.count()
        
        # 获取所有唯一 note_id
        unique_notes = 0
        if total > 0:
            results = col.get(include=["metadatas"])
            note_ids = set()
            for meta in results.get("metadatas", []):
                if meta and "note_id" in meta:
                    note_ids.add(meta["note_id"])
            unique_notes = len(note_ids)
        
        return VectorStatsResponse(
            total_vectors=total,
            unique_notes=unique_notes
        )
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/embedding/batch")
async def generate_batch_embedding(texts: List[str]):
    """批量生成 embedding 向量"""
    # 检查知识库是否已启动
    if not _kb_started:
        raise HTTPException(status_code=500, detail="知识库服务未启动，请先调用 /api/knowledge-base/start")
    
    try:
        # 延迟导入并获取 embedding service
        embedding_svc = get_embedding_service()
        
        if not embedding_svc.is_model_loaded:
            raise HTTPException(status_code=500, detail="模型未加载")

        results = []
        for text in texts:
            embedding = embedding_svc.generate_embedding(text)
            results.append({
                "text": text,
                "embedding": embedding,
                "dimensions": len(embedding)
            })

        return results

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

class ModelSwitchRequest(BaseModel):
    model_dir: str

class ModelSwitchResponse(BaseModel):
    success: bool
    message: str

@router.post("/model/switch")
async def switch_model(request: ModelSwitchRequest):
    """热切换模型（无需重启服务）"""
    # 检查知识库是否已启动
    if not _kb_started:
        raise HTTPException(status_code=500, detail="知识库服务未启动，请先调用 /api/knowledge-base/start")
    
    try:
        # 延迟导入 embedding service
        embedding_svc = get_embedding_service()
        
        # 卸载旧模型（如果已加载）
        if embedding_svc.is_model_loaded:
            embedding_svc.unload_model()
        
        # 加载新模型
        success = embedding_svc.load_model(request.model_dir)
        
        if success:
            return ModelSwitchResponse(success=True, message="模型切换成功")
        else:
            return ModelSwitchResponse(success=False, message="新模型加载失败")
    except Exception as e:
        return ModelSwitchResponse(success=False, message=str(e))

@router.get("/embedding/status")
async def get_embedding_status():
    """获取 Embedding 服务状态"""
    # 检查知识库是否已启动
    if not _kb_started:
        return {
            "state": "basic_ready",  # 基础服务就绪，知识库服务未启动
            "message": "基础服务已就绪，知识库服务未启动",
            "model_loaded": False,
            "model_path": None,
            "tokenizer_path": None,
            "vocab_size": 0,
            "chroma_status": "not_initialized",
            "kb_started": False,
            "components": {
                "chroma_db": "not_initialized",
                "embedding_model": "not_loaded"
            }
        }
    
    # 延迟导入并获取 embedding service
    embedding_svc = get_embedding_service()
    
    vocab_size = 0
    if embedding_svc.hf_tokenizer is not None:
        try:
            vocab_size = embedding_svc.hf_tokenizer.get_vocab_size()
        except Exception:
            vocab_size = 0

    chroma_status = "initialized" if collection is not None else "not_initialized"
    
    # 根据模型加载状态返回不同的 state
    state = "ready" if embedding_svc.is_model_loaded else "loading_model"
    message = "知识库服务已就绪" if embedding_svc.is_model_loaded else "正在加载模型"

    return {
        "state": state,
        "message": message,
        "model_loaded": embedding_svc.is_model_loaded,
        "model_path": embedding_svc.model_path,
        "tokenizer_path": embedding_svc.tokenizer_path,
        "vocab_size": vocab_size,
        "chroma_status": chroma_status,
        "kb_started": True,
        "components": {
            "chroma_db": "initialized" if collection is not None else "not_initialized",
            "embedding_model": "loaded" if embedding_svc.is_model_loaded else "loading"
        }
    }

@router.post("/model/unload")
async def unload_model():
    """卸载模型（保留 ChromaDB 数据库）"""
    # 检查知识库是否已启动
    if not _kb_started:
        raise HTTPException(status_code=500, detail="知识库服务未启动，请先调用 /api/knowledge-base/start")
    
    try:
        # 延迟导入 embedding service
        embedding_svc = get_embedding_service()
        
        if embedding_svc.is_model_loaded:
            embedding_svc.unload_model()
            return ModelSwitchResponse(success=True, message="模型已卸载")
        else:
            return ModelSwitchResponse(success=True, message="模型未加载，无需卸载")
    except Exception as e:
        return ModelSwitchResponse(success=False, message=str(e))
