// Copyright (c) 2026 litongshuai
// SPDX-License-Identifier: MIT OR Apache-2.0

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/note.dart';

class SearchResult {
  final String noteId;
  final double score;
  final String chunkText;
  final Map<String, dynamic> metadata;

  SearchResult({
    required this.noteId,
    required this.score,
    required this.chunkText,
    this.metadata = const {},
  });

  factory SearchResult.fromJson(Map<String, dynamic> json) {
    return SearchResult(
      noteId: json['note_id'] ?? '',
      score: (json['score'] ?? 0.0).toDouble(),
      chunkText: json['text'] ?? '',
      metadata: json['metadata'] ?? {},
    );
  }
}

class VectorIndexStats {
  final int totalEntries;
  final int uniqueNotes;
  final int vectorDimensions;

  VectorIndexStats({
    required this.totalEntries,
    required this.uniqueNotes,
    this.vectorDimensions = 0,
  });
}

class VectorStore {
  final String _baseUrl;
  final http.Client _client = http.Client();

  VectorStore({String baseUrl = 'http://127.0.0.1:8765'}) : _baseUrl = baseUrl;

  bool get isAvailable => true; // 只要 Python 服务在运行就认为可用

  Future<void> indexNote(
    Note note, {
    int chunkSize = 500,
    int chunkOverlap = 50,
  }) async {
    debugPrint(
      'VectorStore.indexNote: note=${note.title}, contentLength=${note.content.length}',
    );

    // 提取用于索引的文本内容
    String contentToIndex = note.content;

    // 富文本笔记需要先提取纯文本（去除 Quill Delta JSON 结构）
    if (note.format == NoteFormat.richText) {
      contentToIndex = _extractPlainTextFromRichText(note.content);
      debugPrint('VectorStore: 富文本笔记纯文本提取完成，长度: ${contentToIndex.length}');
    }

    if (contentToIndex.isEmpty) {
      debugPrint('VectorStore: 笔记内容为空，跳过索引');
      return;
    }

    final chunks = _chunkContent(
      contentToIndex,
      maxChunkSize: chunkSize,
      overlap: chunkOverlap,
    );
    debugPrint('VectorStore: 笔记分块数: ${chunks.length}');

    final chunkData = chunks.asMap().entries.map((entry) {
      final index = entry.key;
      final chunk = entry.value;
      return {
        'id': '${note.id}_chunk${index}_${chunk.hashCode}',
        'text': chunk,
        'metadata': {'title': note.title, 'category': note.category ?? ''},
      };
    }).toList();

    try {
      final response = await _client
          .post(
            Uri.parse('$_baseUrl/api/vector/upsert'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'note_id': note.id, 'chunks': chunkData}),
          )
          .timeout(const Duration(seconds: 120));

      if (response.statusCode == 200) {
        debugPrint('VectorStore: 成功索引笔记 ${note.title}');
      } else {
        debugPrint('VectorStore: 索引笔记失败 ${note.title}: ${response.body}');
        throw Exception('索引笔记失败: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('VectorStore: 索引笔记异常: $e');
      throw Exception('索引笔记异常: $e');
    }
  }

  Future<void> removeNote(String noteId) async {
    try {
      final response = await _client
          .delete(Uri.parse('$_baseUrl/api/vector/note/$noteId'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        debugPrint('VectorStore: 已删除笔记向量 $noteId');
      } else {
        debugPrint('VectorStore: 删除笔记向量失败 $noteId: ${response.body}');
      }
    } catch (e) {
      debugPrint('VectorStore: 删除笔记向量异常: $e');
    }
  }

  Future<void> updateNote(Note note) async {
    await removeNote(note.id);
    await indexNote(note);
  }

  Future<void> clearAll() async {
    try {
      final response = await _client
          .delete(Uri.parse('$_baseUrl/api/vector/clear_all'))
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        debugPrint('VectorStore: 已清空所有向量');
      } else {
        debugPrint('VectorStore: 清空向量失败: ${response.body}');
      }
    } catch (e) {
      debugPrint('VectorStore: 清空向量异常: $e');
    }
  }

  Future<List<SearchResult>> search(
    String query, {
    int topK = 5,
    List<String>? noteIds,
    List<String>? titles,
    List<String>? categoryIds,
  }) async {
    debugPrint(
      'VectorStore.search: query=$query, topK=$topK, noteIds=$noteIds, titles=$titles, categories=$categoryIds',
    );

    try {
      final body = {
        'query': query,
        'top_k': topK,
        if (noteIds != null && noteIds.isNotEmpty) 'note_ids': noteIds,
        if (titles != null && titles.isNotEmpty) 'titles': titles,
        if (categoryIds != null && categoryIds.isNotEmpty)
          'categories': categoryIds,
      };

      final response = await _client
          .post(
            Uri.parse('$_baseUrl/api/vector/search'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final results = (data['results'] as List)
            .map((r) => SearchResult.fromJson(r as Map<String, dynamic>))
            .toList();
        debugPrint('VectorStore: 搜索结果数: ${results.length}');
        debugPrint('VectorStore: 搜索结果: ${response.body}');
        return results;
      } else {
        debugPrint('VectorStore: 搜索失败: ${response.body}');
        return [];
      }
    } catch (e) {
      debugPrint('VectorStore: 搜索异常: $e');
      return [];
    }
  }

  Future<VectorIndexStats> getStats() async {
    try {
      final response = await _client
          .get(Uri.parse('$_baseUrl/api/vector/stats'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return VectorIndexStats(
          totalEntries: data['total_vectors'] as int? ?? 0,
          uniqueNotes: data['unique_notes'] as int? ?? 0,
        );
      }
    } catch (e) {
      debugPrint('VectorStore: 获取统计信息异常: $e');
    }

    return VectorIndexStats(totalEntries: 0, uniqueNotes: 0);
  }

  List<String> _chunkContent(
    String content, {
    int maxChunkSize = 500,
    int overlap = 50,
  }) {
    final paragraphs = content.split('\n\n');
    final chunks = <String>[];
    var currentChunk = '';
    var lastChunkTail = '';

    for (final paragraph in paragraphs) {
      final trimmed = paragraph.trim();
      if (trimmed.isEmpty) continue;

      if ((currentChunk.length + trimmed.length) > maxChunkSize) {
        if (currentChunk.isNotEmpty) {
          chunks.add(currentChunk.trim());
          // 记录最后一个 chunk 的尾部，用于重叠
          lastChunkTail = currentChunk.length > overlap
              ? currentChunk.substring(currentChunk.length - overlap)
              : currentChunk;
        }
        currentChunk = lastChunkTail.isNotEmpty
            ? '$lastChunkTail\n\n$trimmed'
            : trimmed;
        lastChunkTail = '';
      } else {
        if (currentChunk.isNotEmpty) {
          currentChunk += '\n\n$trimmed';
        } else {
          currentChunk = trimmed;
        }
      }
    }

    if (currentChunk.isNotEmpty) {
      chunks.add(currentChunk.trim());
    }

    if (chunks.isEmpty && content.isNotEmpty) {
      var lastTail = '';
      for (int i = 0; i < content.length; i += maxChunkSize) {
        final start = lastTail.isNotEmpty ? i - lastTail.length : i;
        final actualStart = start < i ? i - lastTail.length : i;
        final end = (i + maxChunkSize < content.length)
            ? i + maxChunkSize
            : content.length;
        final chunk = content
            .substring(actualStart < 0 ? 0 : actualStart, end)
            .trim();
        chunks.add(chunk);
        lastTail = chunk.length > overlap
            ? chunk.substring(chunk.length - overlap)
            : chunk;
      }
    }

    return chunks;
  }

  /// 从 Quill Delta JSON 提取纯文本
  String _extractPlainTextFromRichText(String jsonContent) {
    try {
      final delta = jsonDecode(jsonContent) as List;
      final buffer = StringBuffer();
      for (final item in delta) {
        if (item is Map && item['insert'] is String) {
          buffer.write(item['insert']);
        }
      }
      return buffer.toString().trim();
    } catch (e) {
      debugPrint('VectorStore: 富文本提取失败，返回原文: $e');
      return jsonContent;
    }
  }

  void dispose() {
    _client.close();
  }
}
