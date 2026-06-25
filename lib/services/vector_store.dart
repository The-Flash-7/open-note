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

    // 清理 HTML 标签和 LaTeX 公式（适用于所有格式）
    contentToIndex = _cleanTextForIndexing(contentToIndex);
    debugPrint('VectorStore: 文本清理完成，长度: ${contentToIndex.length}');

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

  /// 清理文本内容，移除 HTML 标签和 LaTeX 公式，保留纯文本
  String _cleanTextForIndexing(String content) {
    // 1. 清理 LaTeX 公式：保留公式内的文本，转换常见符号
    content = _cleanLatexFormulas(content);
    
    // 2. 清理 HTML 标签：保留链接 URL 和图片 alt 属性
    content = _cleanHtmlTags(content);
    
    return content.trim();
  }

  /// 清理 LaTeX 公式，保留纯文本
  String _cleanLatexFormulas(String content) {
    // 处理行内公式 \(...\) 和独立公式 \[...\]
    content = content.replaceAllMapped(
      RegExp(r'\\[\(\[].*?\\[\)\]]', multiLine: true),
      (match) {
        String formula = match.group(0) ?? '';
        // 移除公式标记
        formula = formula.replaceAll('\\(', '').replaceAll('\\)', '');
        formula = formula.replaceAll('\\[', '').replaceAll('\\]', '');
        
        // 转换希腊字母
        formula = formula.replaceAll('\\alpha', 'α');
        formula = formula.replaceAll('\\beta', 'β');
        formula = formula.replaceAll('\\gamma', 'γ');
        formula = formula.replaceAll('\\delta', 'δ');
        formula = formula.replaceAll('\\epsilon', 'ε');
        formula = formula.replaceAll('\\zeta', 'ζ');
        formula = formula.replaceAll('\\eta', 'η');
        formula = formula.replaceAll('\\theta', 'θ');
        formula = formula.replaceAll('\\iota', 'ι');
        formula = formula.replaceAll('\\kappa', 'κ');
        formula = formula.replaceAll('\\lambda', 'λ');
        formula = formula.replaceAll('\\mu', 'μ');
        formula = formula.replaceAll('\\nu', 'ν');
        formula = formula.replaceAll('\\xi', 'ξ');
        formula = formula.replaceAll('\\omicron', 'ο');
        formula = formula.replaceAll('\\pi', 'π');
        formula = formula.replaceAll('\\rho', 'ρ');
        formula = formula.replaceAll('\\sigma', 'σ');
        formula = formula.replaceAll('\\tau', 'τ');
        formula = formula.replaceAll('\\upsilon', 'υ');
        formula = formula.replaceAll('\\phi', 'φ');
        formula = formula.replaceAll('\\chi', 'χ');
        formula = formula.replaceAll('\\psi', 'ψ');
        formula = formula.replaceAll('\\omega', 'ω');
        
        // 转换数学运算符
        formula = formula.replaceAll('\\forall', '∀');
        formula = formula.replaceAll('\\exists', '∃');
        formula = formula.replaceAll('\\in', '∈');
        formula = formula.replaceAll('\\notin', '∉');
        formula = formula.replaceAll('\\subset', '⊂');
        formula = formula.replaceAll('\\supset', '⊃');
        formula = formula.replaceAll('\\subseteq', '⊆');
        formula = formula.replaceAll('\\supseteq', '⊇');
        formula = formula.replaceAll('\\cup', '∪');
        formula = formula.replaceAll('\\cap', '∩');
        formula = formula.replaceAll('\\emptyset', '∅');
        formula = formula.replaceAll('\\sum', '∑');
        formula = formula.replaceAll('\\prod', '∏');
        formula = formula.replaceAll('\\int', '∫');
        formula = formula.replaceAll('\\oint', '∮');
        formula = formula.replaceAll('\\partial', '∂');
        formula = formula.replaceAll('\\nabla', '∇');
        formula = formula.replaceAll('\\sqrt', '√');
        formula = formula.replaceAll('\\times', '×');
        formula = formula.replaceAll('\\div', '÷');
        formula = formula.replaceAll('\\pm', '±');
        formula = formula.replaceAll('\\mp', '∓');
        formula = formula.replaceAll('\\cdot', '·');
        formula = formula.replaceAll('\\ast', '∗');
        formula = formula.replaceAll('\\circ', '∘');
        formula = formula.replaceAll('\\bullet', '•');
        
        // 转换关系符号
        formula = formula.replaceAll('\\leq', '≤');
        formula = formula.replaceAll('\\geq', '≥');
        formula = formula.replaceAll('\\neq', '≠');
        formula = formula.replaceAll('\\approx', '≈');
        formula = formula.replaceAll('\\equiv', '≡');
        formula = formula.replaceAll('\\sim', '∼');
        formula = formula.replaceAll('\\propto', '∝');
        formula = formula.replaceAll('\\parallel', '∥');
        formula = formula.replaceAll('\\perp', '⊥');
        
        // 转换箭头符号
        formula = formula.replaceAll('\\rightarrow', '→');
        formula = formula.replaceAll('\\leftarrow', '←');
        formula = formula.replaceAll('\\uparrow', '↑');
        formula = formula.replaceAll('\\downarrow', '↓');
        formula = formula.replaceAll('\\Rightarrow', '⇒');
        formula = formula.replaceAll('\\Leftarrow', '⇐');
        formula = formula.replaceAll('\\Uparrow', '⇑');
        formula = formula.replaceAll('\\Downarrow', '⇓');
        formula = formula.replaceAll('\\leftrightarrow', '↔');
        formula = formula.replaceAll('\\Leftrightarrow', '⇔');
        
        // 转换其他符号
        formula = formula.replaceAll('\\infty', '∞');
        formula = formula.replaceAll('\\angle', '∠');
        formula = formula.replaceAll('\\degree', '°');
        formula = formula.replaceAll('\\prime', '′');
        formula = formula.replaceAll('\\doubleprime', '″');
        
        // 移除其他 LaTeX 命令，保留变量名
        formula = formula.replaceAll('\\mathbf{', '');
        formula = formula.replaceAll('\\text{', '');
        formula = formula.replaceAll('\\mathrm{', '');
        formula = formula.replaceAll('\\mathit{', '');
        formula = formula.replaceAll('\\mathcal{', '');
        formula = formula.replaceAll('\\mathbb{', '');
        formula = formula.replaceAll('{', '').replaceAll('}', '');
        formula = formula.replaceAll('\\', '');
        
        return formula;
      },
    );
    
    return content;
  }

  /// 清理 HTML 标签，保留链接 URL 和图片 alt 属性
  String _cleanHtmlTags(String content) {
    // 1. 处理 <a> 标签：保留文本和 URL
    content = content.replaceAllMapped(
      RegExp(r'<a\s+[^>]*href="([^"]*)"[^>]*>(.*?)</a>', multiLine: true, caseSensitive: false),
      (match) => '${match.group(2)} (${match.group(1)})',
    );
    
    // 2. 处理 <img> 标签：保留 alt 属性
    content = content.replaceAllMapped(
      RegExp(r'<img\s+[^>]*alt="([^"]*)"[^>]*/?>', multiLine: true, caseSensitive: false),
      (match) => match.group(1) ?? '',
    );
    
    // 3. 移除其他 HTML 标签
    content = content.replaceAll(RegExp(r'<[^>]+>', multiLine: true), '');
    
    return content;
  }

  void dispose() {
    _client.close();
  }
}
