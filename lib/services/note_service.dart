// Copyright (c) 2026 litongshuai
// SPDX-License-Identifier: MIT OR Apache-2.0

import 'package:uuid/uuid.dart';
import '../models/note.dart';
import '../models/note_preview.dart';
import '../models/category.dart';
import 'sqlite_database_service.dart';

class NoteService {
  final SQLiteDatabaseService _dbService = SQLiteDatabaseService();
  final Uuid _uuid = const Uuid();

  Future<void> init() async {
    await _dbService.init();
  }

  Future<String> createNote({
    required String title,
    required String content,
    String? summary,
    List<String>? keywords,
    String? category,
    List<String>? tags,
    String? sourceUrl,
    NoteSourceType sourceType = NoteSourceType.manual,
    NoteFormat format = NoteFormat.markdown,
    String? language,
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isFavorite,
  }) async {
    final now = DateTime.now();
    final noteId = id ?? _uuid.v4();
    final wordCount = _countWords(content);

    final note = Note(
      id: noteId,
      title: title,
      content: content,
      format: format,
      language: language,
      summary: summary,
      keywords: keywords ?? [],
      category: category,
      tags: tags ?? const [],
      sourceUrl: sourceUrl,
      sourceType: sourceType,
      createdAt: createdAt ?? now,
      updatedAt: updatedAt ?? now,
      wordCount: wordCount,
      isFavorite: isFavorite ?? false,
    );

    await _dbService.saveNote(note);
    return noteId;
  }

  Future<Note?> getNoteById(String id) async {
    return await _dbService.getNoteById(id);
  }

  Future<Note?> getNoteByIdIncludingDeleted(String id) async {
    return await _dbService.getNoteByIdIncludingDeleted(id);
  }

  Future<List<Note>> getAllNotes() async {
    return await _dbService.getNotes();
  }

  Future<List<NotePreview>> getAllNotePreviews() async {
    final notes = await _dbService.getNotes(limit: 10000);
    return notes.map((note) => NotePreview.fromNote(note)).toList();
  }

  /// 分页加载笔记预览（用于 UI 懒加载）
  Future<List<NotePreview>> getNotePreviewsPaginated({
    required int offset,
    int limit = 50,
  }) async {
    final notes = await _dbService.getNotes(limit: limit, offset: offset);
    return notes.map((note) => NotePreview.fromNote(note)).toList();
  }

  /// 获取笔记总数
  Future<int> getNotesCount({String? categoryId, bool? isFavorite}) async {
    return await _dbService.getNotesCount(
      categoryId: categoryId,
      isFavorite: isFavorite,
    );
  }

  Future<List<Note>> searchNotes(String query) async {
    return await _dbService.searchNotes(query);
  }

  Future<void> updateNote(Note note) async {
    final updatedNote = note.copyWith(
      updatedAt: DateTime.now(),
      wordCount: _countWords(note.content),
    );
    await _dbService.saveNote(updatedNote);
  }

  Future<void> deleteNote(String id) async {
    await _dbService.deleteNote(id);
  }

  Future<void> hardDeleteNote(String id) async {
    await _dbService.hardDeleteNote(id);
  }

  Future<List<Note>> getTrashNotes() async {
    return await _dbService.getDeletedNotes();
  }

  Future<void> toggleFavorite(String id) async {
    final note = await getNoteById(id);
    if (note != null) {
      final updatedNote = note.copyWith(isFavorite: !note.isFavorite);
      await updateNote(updatedNote);
    }
  }

  Future<List<Note>> getFavoriteNotes() async {
    final notes = await getAllNotes();
    return notes.where((note) => note.isFavorite).toList();
  }

  Future<List<Note>> getNotesByCategory(String category) async {
    final notes = await getAllNotes();
    return notes.where((note) => note.category == category).toList();
  }

  Future<List<Note>> getNotesByTag(String tag) async {
    final notes = await getAllNotes();
    return notes.where((note) => note.tags.contains(tag)).toList();
  }

  Future<List<Category>> getAllCategories() async {
    return await _dbService.getCategories();
  }

  Future<List<String>> getAllTags() async {
    final tags = await _dbService.getTags();
    return tags.map((t) => t.name).toList();
  }

  int _countWords(String content) {
    return content.trim().split(RegExp(r'\s+')).length;
  }

  Future<void> deleteNotesByCategory(String categoryId) async {
    final notes = await getAllNotes();
    final notesInDirectory = notes.where((note) => note.category == categoryId);
    for (final note in notesInDirectory) {
      await deleteNote(note.id);
    }
  }
}
