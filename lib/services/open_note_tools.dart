// Copyright (c) 2026 litongshuai
// SPDX-License-Identifier: MIT OR Apache-2.0

import 'package:flutter/foundation.dart';
import '../models/note.dart';
import '../providers/notes_provider.dart';
import '../services/ai_service.dart';
import '../services/vector_store.dart';

class NoteContext {
  final String noteId;
  final String chunkText;
  final double relevanceScore;
  final String title;
  final String? category;
  final List<String> tags;

  NoteContext({
    required this.noteId,
    required this.chunkText,
    required this.relevanceScore,
    required this.title,
    this.category,
    this.tags = const [],
  });
}

class OpenNoteTools {
  static NotesProvider? _notesProvider;
  static AIService? _aiService;
  static VectorStore? _vectorStore;

  static void initialize({
    required NotesProvider notesProvider,
    AIService? aiService,
    required VectorStore vectorStore,
  }) {
    _notesProvider = notesProvider;
    _aiService = aiService;
    _vectorStore = vectorStore;
  }

  static bool get _isInitialized =>
      _notesProvider != null && _vectorStore != null;

  /// 综合搜索笔记
  static Future<List<Note>> searchNotes({
    List<String>? queryList,
    String? category,
    List<String>? tags,
    bool favoritesOnly = false,
    int limit = 10,
  }) async {
    if (!_isInitialized) throw Exception('OpenNoteTools 未初始化');

    List<Note> results = List.from(_notesProvider!.notes);

    // 多关键字 OR 匹配
    if (queryList != null && queryList.isNotEmpty) {
      results = results.where((note) {
        final titleLower = note.title.toLowerCase();
        final contentLower = note.content.toLowerCase();
        final summaryLower = note.summary?.toLowerCase() ?? '';

        return queryList.any((q) {
          final queryLower = q.toLowerCase();
          return titleLower.contains(queryLower) ||
              contentLower.contains(queryLower) ||
              summaryLower.contains(queryLower);
        });
      }).toList();
    }

    if (category != null && category.isNotEmpty) {
      results = results.where((note) => note.category == category).toList();
    }

    if (tags != null && tags.isNotEmpty) {
      results = results.where((note) {
        return tags.any((tag) => note.tags.contains(tag));
      }).toList();
    }

    if (favoritesOnly) {
      results = results.where((note) => note.isFavorite).toList();
    }

    return results.take(limit).toList();
  }

  /// 创建笔记
  static Future<String?> createNote({
    required String title,
    required String content,
    String? category,
    List<String>? tags,
    NoteFormat format = NoteFormat.markdown,
    String? sourceUrl,
    NoteSourceType sourceType = NoteSourceType.manual,
    bool autoGenerateSummary = false,
    String? preGeneratedSummary,
    List<String>? preGeneratedKeywords,
  }) async {
    if (!_isInitialized) throw Exception('OpenNoteTools 未初始化');

    return await _notesProvider!.createNote(
      title: title,
      content: content,
      category: category,
      tags: tags,
      format: format,
      sourceUrl: sourceUrl,
      sourceType: sourceType,
      autoGenerateSummary: autoGenerateSummary,
      preGeneratedSummary: preGeneratedSummary,
      preGeneratedKeywords: preGeneratedKeywords,
    );
  }

  /// 更新笔记
  static Future<bool> updateNote({
    required String noteId,
    String? title,
    String? content,
    String? category,
    List<String>? tags,
    bool? isFavorite,
  }) async {
    if (!_isInitialized) throw Exception('OpenNoteTools 未初始化');

    final existingNote = await _notesProvider!.getNoteById(noteId);
    if (existingNote == null) return false;

    final updatedNote = existingNote.copyWith(
      title: title ?? existingNote.title,
      content: content ?? existingNote.content,
      category: category ?? existingNote.category,
      tags: tags ?? existingNote.tags,
      isFavorite: isFavorite ?? existingNote.isFavorite,
      updatedAt: DateTime.now(),
    );

    await _notesProvider!.updateNote(updatedNote);
    return true;
  }

  /// 删除笔记（软删除）
  static Future<bool> deleteNote(String noteId) async {
    if (!_isInitialized) throw Exception('OpenNoteTools 未初始化');

    try {
      await _notesProvider!.deleteNote(noteId);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// 读取笔记详情
  static Future<Note?> getNoteById(String noteId) async {
    if (!_isInitialized) throw Exception('OpenNoteTools 未初始化');

    return await _notesProvider!.getNoteById(noteId);
  }

  /// 批量删除笔记
  static Future<int> batchDeleteNotes(List<String> noteIds) async {
    if (!_isInitialized) throw Exception('OpenNoteTools 未初始化');

    int deletedCount = 0;
    for (final noteId in noteIds) {
      try {
        await _notesProvider!.deleteNote(noteId);
        deletedCount++;
      } catch (e) {
        debugPrint('batchDeleteNotes: 删除 $noteId 失败: $e');
      }
    }
    return deletedCount;
  }

  /// 检索相关上下文（为 RAG/问答准备）
  /// 优先使用向量语义搜索，失败时降级到文本搜索
  static Future<List<NoteContext>> retrieveRelevantContext({
    required String query,
    int topK = 5,
  }) async {
    if (!_isInitialized) throw Exception('OpenNoteTools 未初始化');

    // 1. 首先尝试向量语义搜索
    if (_vectorStore != null && _vectorStore!.isAvailable) {
      try {
        final vectorResults = await _vectorStore!.search(query, topK: topK);
        if (vectorResults.isNotEmpty) {
          final contexts = <NoteContext>[];
          final seenNoteIds = <String>{};

          for (final result in vectorResults) {
            // 去重：同一个笔记只保留一次
            if (seenNoteIds.contains(result.noteId)) continue;
            seenNoteIds.add(result.noteId);

            final note = await getNoteById(result.noteId);
            if (note != null) {
              contexts.add(
                NoteContext(
                  noteId: note.id,
                  chunkText: result.chunkText,
                  relevanceScore: result.score,
                  title: note.title,
                  category: note.category,
                  tags: note.tags,
                ),
              );
            }

            if (contexts.length >= topK) break;
          }

          if (contexts.isNotEmpty) {
            return contexts;
          }
        }
      } catch (e) {
        debugPrint('向量搜索失败，降级到文本搜索: $e');
      }
    }

    // 2. 降级：文本搜索
    return _retrieveByKeywordText(query, topK);
  }

  /// 文本搜索后备方案
  static Future<List<NoteContext>> _retrieveByKeywordText(
    String query,
    int topK,
  ) async {
    final notes = await searchNotes(queryList: [query], limit: topK * 2);
    final queryLower = query.toLowerCase();

    final contexts = <NoteContext>[];
    for (final note in notes) {
      double score = 0.0;

      if (note.title.toLowerCase().contains(queryLower)) score += 3.0;
      if (note.content.toLowerCase().contains(queryLower)) score += 1.0;
      if (note.summary?.toLowerCase().contains(queryLower) ?? false) {
        score += 2.0;
      }

      contexts.add(
        NoteContext(
          noteId: note.id,
          chunkText: note.content.length > 500
              ? note.content.substring(0, 500)
              : note.content,
          relevanceScore: score,
          title: note.title,
          category: note.category,
          tags: note.tags,
        ),
      );
    }

    contexts.sort((a, b) => b.relevanceScore.compareTo(a.relevanceScore));
    return contexts.take(topK).toList();
  }

  /// 获取最近笔记
  static Future<List<Note>> getRecentNotes({int limit = 10}) async {
    if (!_isInitialized) throw Exception('OpenNoteTools 未初始化');

    final notes = _notesProvider!.notes.whereType<Note>().toList();
    notes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return notes.take(limit).toList();
  }

  static Future<List<Note>> getFavoriteNotes({int limit = 20}) async {
    if (!_isInitialized) throw Exception('OpenNoteTools 未初始化');

    final favorites = _notesProvider!.notes
        .whereType<Note>()
        .where((note) => note.isFavorite)
        .toList();
    favorites.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return favorites.take(limit).toList();
  }
}
