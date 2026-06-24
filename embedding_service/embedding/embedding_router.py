# Copyright (c) 2026 litongshuai
# SPDX-License-Identifier: MIT OR Apache-2.0

import os
import uuid
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import List, Optional
from embedding import LocalEmbeddingService

try:
    import chromadb
    from chromadb.config import Settings
except ImportError:
    chromadb = None

router = APIRouter(prefix="/api", tags=["embedding"])

embedding_service = LocalEmbeddingService()
chroma_client = None
collection = None

# Model switch status (updated by /model/switch endpoint)
_embedding_model_status = "pending"  # "pending", "loading", "loaded", "failed"

def init_chroma(data_dir: str):
    """初始化 ChromaDB 客户端和集合"""
    global chroma_client, collection
    if chromadb is None:
        raise ImportError("ChromaDB 未安装")
    
    chroma_client = chromadb.PersistentClient(path=data_dir)
    
    # 获取或创建集合，不使用内置 embedding_function，由我们手动传入 vectors
    collection = chroma_client.get_or_create_collection(
        name="notes",
        embedding_function=None,
        metadata={"hnsw:space": "cosine"}  # 使用余弦相似度
    )
    print(f"ChromaDB: 集合 '{collection.name}' 已加载，包含 {collection.count()} 个向量")

def get_embedding_service():
    return embedding_service

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

@router.post("/embedding")
async def generate_embedding(request: EmbeddingRequest):
    """生成文本的 embedding 向量"""
    try:
        if request.model_dir and not embedding_service.is_model_loaded:
            success = embedding_service.load_model(request.model_dir)
            if not success:
                raise HTTPException(status_code=500, detail="模型加载失败")

        if not embedding_service.is_model_loaded:
            raise HTTPException(status_code=500, detail="模型未加载")

        embedding = embedding_service.generate_embedding(request.text)

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
    try:
        col = get_chroma_collection()
        if not embedding_service.is_model_loaded:
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
            embedding = embedding_service.generate_embedding(chunk.text)
            
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
    try:
        col = get_chroma_collection()
        if not embedding_service.is_model_loaded:
            raise HTTPException(status_code=500, detail="模型未加载")

        # 生成查询向量
        query_embedding = embedding_service.generate_embedding(request.query)

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
    try:
        if not embedding_service.is_model_loaded:
            raise HTTPException(status_code=500, detail="模型未加载")

        results = []
        for text in texts:
            embedding = embedding_service.generate_embedding(text)
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
    global _embedding_model_status
    try:
        # 卸载旧模型
        embedding_svc = get_embedding_service()
        embedding_svc.unload_model()
        
        # 加载新模型
        success = embedding_svc.load_model(request.model_dir)
        
        if success:
            _embedding_model_status = "loaded"
            return ModelSwitchResponse(success=True, message="模型切换成功")
        else:
            _embedding_model_status = "failed"
            return ModelSwitchResponse(success=False, message="新模型加载失败")
    except Exception as e:
        _embedding_model_status = "failed"
        return ModelSwitchResponse(success=False, message=str(e))

@router.get("/embedding/status")
async def get_embedding_status():
    """获取 Embedding 服务状态"""
    vocab_size = 0
    if embedding_service.hf_tokenizer is not None:
        try:
            vocab_size = embedding_service.hf_tokenizer.get_vocab_size()
        except Exception:
            vocab_size = 0

    chroma_status = "initialized" if collection is not None else "not_initialized"

    return {
        "model_loaded": embedding_service.is_model_loaded,
        "model_path": embedding_service.model_path,
        "tokenizer_path": embedding_service.tokenizer_path,
        "vocab_size": vocab_size,
        "chroma_status": chroma_status
    }

@router.post("/model/unload")
async def unload_model():
    """卸载模型（保留 ChromaDB 数据库）"""
    global _embedding_model_status
    try:
        embedding_svc = get_embedding_service()
        embedding_svc.unload_model()
        _embedding_model_status = "pending"
        
        return ModelSwitchResponse(success=True, message="模型已卸载")
    except Exception as e:
        _embedding_model_status = "failed"
        return ModelSwitchResponse(success=False, message=str(e))
