# Copyright (c) 2026 litongshuai
# SPDX-License-Identifier: MIT OR Apache-2.0

import numpy as np
import onnxruntime as ort
from tokenizers import Tokenizer as HfTokenizer
import os
import sys
from typing import List, Optional


def get_resource_path(relative_path: str) -> str:
    """获取资源文件路径（支持 PyInstaller 打包）"""
    if getattr(sys, 'frozen', False):
        base_path = os.path.dirname(sys.executable)
    else:
        base_path = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    return os.path.join(base_path, relative_path)


class LocalEmbeddingService:
    def __init__(self):
        self.ort_session: Optional['ort.InferenceSession'] = None
        self.hf_tokenizer: Optional['HfTokenizer'] = None
        self.model_path: Optional[str] = None
        self.tokenizer_path: Optional[str] = None

    def load_model(self, model_dir: str) -> bool:
        """加载 ONNX 模型和 Tokenizer"""
        try:
            model_file = self._find_model_file(model_dir)
            if not model_file:
                raise Exception(f"找不到 ONNX 模型文件: {model_dir}")

            tokenizer_file = os.path.join(model_dir, "tokenizer.json")
            if not os.path.exists(tokenizer_file):
                parent_dir = os.path.dirname(model_dir)
                tokenizer_file = os.path.join(parent_dir, "tokenizer.json")
                if not os.path.exists(tokenizer_file):
                    raise Exception(
                        f"找不到 tokenizer.json: 尝试了 {model_dir} 和 {parent_dir}"
                    )

            self.model_path = model_dir
            self.tokenizer_path = tokenizer_file

            return self._load_ort_model(model_file, tokenizer_file)

        except Exception as e:
            print(f"EmbeddingService: 模型加载失败: {e}")
            return False

    def _load_ort_model(self, model_file: str, tokenizer_file: str) -> bool:
        """使用标准 onnxruntime 加载模型"""
        try:
            providers = ['CPUExecutionProvider']
            self.ort_session = ort.InferenceSession(model_file, providers=providers)
            self.hf_tokenizer = HfTokenizer.from_file(tokenizer_file)
            print(
                f"EmbeddingService: 模型已加载 {model_file}, "
                f"Tokenizer vocab: {self.hf_tokenizer.get_vocab_size()}"
            )
            return True
        except Exception as e:
            print(f"EmbeddingService: 模型加载失败: {e}")
            return False

    def _find_model_file(self, model_dir: str) -> Optional[str]:
        """按优先级查找模型文件"""
        candidates = [
            'model_fp16.onnx',
            'model_quantized.onnx',
            'model_q4.onnx',
            'model.onnx'
        ]
        for name in candidates:
            path = os.path.join(model_dir, name)
            if os.path.exists(path):
                return path

        if getattr(sys, 'frozen', False):
            for name in candidates:
                path = get_resource_path(name)
                if os.path.exists(path):
                    return path

        return None

    @property
    def is_model_loaded(self) -> bool:
        """检查模型是否已加载"""
        return self.ort_session is not None

    def generate_embedding(self, text: str) -> List[float]:
        """生成文本的 embedding 向量"""
        if self.ort_session is None:
            raise Exception("模型未加载")

        encoded = self.hf_tokenizer.encode(text)
        input_ids = encoded.ids
        attention_mask = encoded.attention_mask

        input_ids_np = np.array([input_ids], dtype=np.int64)
        attention_mask_np = np.array([attention_mask], dtype=np.int64)

        ort_inputs = {
            'input_ids': input_ids_np,
            'attention_mask': attention_mask_np
        }

        ort_outputs = self.ort_session.run(None, ort_inputs)
        token_embeddings = ort_outputs[0]

        embedding = self._mean_pooling(token_embeddings, attention_mask)
        embedding = self._l2_normalize(embedding)

        return embedding.flatten().tolist()

    def _mean_pooling(self, token_embeddings: np.ndarray, attention_mask: List[int]) -> np.ndarray:
        """对 token embeddings 取平均"""
        mask = np.array(attention_mask)[np.newaxis, :, np.newaxis]
        mask_sum = np.sum(mask, axis=1, keepdims=True)

        if mask_sum[0, 0, 0] > 0:
            pooled = np.sum(token_embeddings * mask, axis=1) / mask_sum
        else:
            pooled = np.mean(token_embeddings, axis=1)

        return pooled[0]

    def _l2_normalize(self, vector: np.ndarray) -> np.ndarray:
        """L2 归一化"""
        norm = np.linalg.norm(vector)
        if norm > 0:
            return vector / norm
        return vector

    def unload_model(self):
        """卸载模型"""
        if self.ort_session is not None:
            del self.ort_session
            self.ort_session = None
        self.hf_tokenizer = None
        print("EmbeddingService: 模型已卸载")
