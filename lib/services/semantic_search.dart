// Copyright (c) 2026 litongshuai
// SPDX-License-Identifier: MIT OR Apache-2.0

import 'package:flutter/foundation.dart';
import '../models/note.dart';
import '../models/note_preview.dart';
import '../providers/notes_provider.dart';
import 'vector_store.dart';

enum SearchMode { keyword, semantic, hybrid }

class SemanticSearch {
  final NotesProvider _notesProvider;
  final VectorStore _vectorStore;

  SemanticSearch({
    required NotesProvider notesProvider,
    required VectorStore vectorStore,
  }) : _notesProvider = notesProvider,
       _vectorStore = vectorStore;

  Future<List<Note>> search({
    required String query,
    SearchMode mode = SearchMode.hybrid,
    int limit = 10,
  }) async {
    switch (mode) {
      case SearchMode.keyword:
        return _keywordSearch(query, limit);
      case SearchMode.semantic:
        return _semanticSearch(query, limit);
      case SearchMode.hybrid:
        return _hybridSearch(query, limit);
    }
  }

  Future<List<Note>> _keywordSearch(String query, int limit) async {
    final queryLower = query.toLowerCase();
    final previews = _notesProvider.previews.where((p) {
      return p.title.toLowerCase().contains(queryLower);
    }).toList();

    previews.sort(
      (a, b) => _keywordScorePreview(b, query) - _keywordScorePreview(a, query),
    );

    // 按需加载完整 Note
    final notes = <Note>[];
    for (final preview in previews.take(limit)) {
      final note = await _notesProvider.getFullNote(preview.id);
      if (note != null) notes.add(note);
    }
    return notes;
  }

  int _keywordScorePreview(NotePreview preview, String query) {
    int score = 0;
    final queryLower = query.toLowerCase();
    if (preview.title.toLowerCase() == queryLower) score += 100;
    if (preview.title.toLowerCase().startsWith(queryLower)) score += 80;
    if (preview.title.toLowerCase().contains(queryLower)) score += 60;
    return score;
  }

  Future<List<Note>> _semanticSearch(String query, int limit) async {
    debugPrint('SemanticSearch._semanticSearch: query=$query, limit=$limit');

    final vectorResults = await _vectorStore.search(query, topK: limit);
    debugPrint('SemanticSearch: 向量搜索结果数: ${vectorResults.length}');

    for (final result in vectorResults) {
      debugPrint(
        '  - 笔记ID: ${result.noteId}, 相似度: ${result.score.toStringAsFixed(3)}',
      );
    }

    final notes = <Note>[];
    for (final result in vectorResults) {
      final note = await _notesProvider.getNoteById(result.noteId);
      if (note != null) {
        notes.add(note);
      }
    }

    debugPrint('SemanticSearch: 返回笔记数: ${notes.length}');
    return notes;
  }

  Future<List<Note>> _hybridSearch(String query, int limit) async {
    final keywordResults = await _keywordSearch(query, limit * 2);
    final semanticResults = await _semanticSearch(query, limit * 2);

    final allNoteIds = <String>{};
    for (final note in keywordResults) {
      allNoteIds.add(note.id);
    }
    for (final note in semanticResults) {
      allNoteIds.add(note.id);
    }

    final scoredNotes = <String, double>{};

    final keywordRanks = <String, int>{};
    for (int i = 0; i < keywordResults.length; i++) {
      keywordRanks[keywordResults[i].id] = i + 1;
    }

    final semanticRanks = <String, int>{};
    for (int i = 0; i < semanticResults.length; i++) {
      semanticRanks[semanticResults[i].id] = i + 1;
    }

    for (final noteId in allNoteIds) {
      double score = 0.0;

      final keywordRank = keywordRanks[noteId];
      if (keywordRank != null) {
        score += 1.0 / (60 + keywordRank);
      }

      final semanticRank = semanticRanks[noteId];
      if (semanticRank != null) {
        score += 1.0 / (60 + semanticRank);
      }

      scoredNotes[noteId] = score;
    }

    final sortedNoteIds = scoredNotes.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final finalNoteIds = sortedNoteIds.take(limit).map((e) => e.key).toList();

    final notes = <Note>[];
    for (final noteId in finalNoteIds) {
      final note = await _notesProvider.getNoteById(noteId);
      if (note != null) {
        notes.add(note);
      }
    }

    return notes;
  }
}
