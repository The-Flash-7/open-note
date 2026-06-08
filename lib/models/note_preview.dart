// Copyright (c) 2026 litongshuai
// SPDX-License-Identifier: MIT OR Apache-2.0

import 'dart:convert';
import 'note.dart';

class NotePreview {
  final String id;
  final String title;
  final String? summary;
  final String? contentPreview;
  final DateTime updatedAt;
  final bool isFavorite;
  final String? category;
  final List<String> tags;
  final int wordCount;
  final NoteFormat format;
  final bool isDeleted;
  final String? language;
  final String? sourceUrl;

  NotePreview({
    required this.id,
    required this.title,
    this.summary,
    this.contentPreview,
    required this.updatedAt,
    this.isFavorite = false,
    this.category,
    this.tags = const [],
    this.wordCount = 0,
    this.format = NoteFormat.markdown,
    this.isDeleted = false,
    this.language,
    this.sourceUrl,
  });

  factory NotePreview.fromMap(Map<String, dynamic> map) {
    return NotePreview(
      id: map['id'] as String,
      title: map['title'] as String,
      summary: map['summary'] as String?,
      contentPreview: extractContentPreview(map['content'] as String?),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
      isFavorite: (map['is_favorite'] as int? ?? 0) == 1,
      category: map['category'] as String?,
      tags: map['tags'] != null
          ? List<String>.from(jsonDecode(map['tags'] as String))
          : [],
      wordCount: map['word_count'] as int? ?? 0,
      format: map['format'] != null
          ? NoteFormat.values.firstWhere(
              (e) => e.name == map['format'],
              orElse: () => NoteFormat.markdown,
            )
          : NoteFormat.markdown,
      isDeleted: (map['is_deleted'] as int? ?? 0) == 1,
      language: map['language'] as String?,
      sourceUrl: map['source_url'] as String?,
    );
  }

  factory NotePreview.fromNote(Note note) {
    return NotePreview(
      id: note.id,
      title: note.title,
      summary: note.summary,
      contentPreview: extractContentPreview(note.content),
      updatedAt: note.updatedAt,
      isFavorite: note.isFavorite,
      category: note.category,
      tags: note.tags,
      wordCount: note.wordCount,
      format: note.format,
      isDeleted: note.isDeleted,
      language: note.language,
      sourceUrl: note.sourceUrl,
    );
  }

  /// 提取内容前50个字符作为预览
  static String extractContentPreview(String? content) {
    if (content == null || content.isEmpty) return '';

    final cleanContent = content
        .replaceAll(RegExp(r'[\[\]{}"]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    if (cleanContent.length <= 50) return cleanContent;
    return '${cleanContent.substring(0, 50)}...';
  }

  NotePreview copyWith({
    String? title,
    String? summary,
    String? contentPreview,
    DateTime? updatedAt,
    bool? isFavorite,
    String? category,
    List<String>? tags,
    int? wordCount,
    NoteFormat? format,
    bool? isDeleted,
  }) {
    return NotePreview(
      id: id,
      title: title ?? this.title,
      summary: summary ?? this.summary,
      contentPreview: contentPreview ?? this.contentPreview,
      updatedAt: updatedAt ?? this.updatedAt,
      isFavorite: isFavorite ?? this.isFavorite,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      wordCount: wordCount ?? this.wordCount,
      format: format ?? this.format,
      isDeleted: isDeleted ?? this.isDeleted,
      language: language,
      sourceUrl: sourceUrl,
    );
  }
}
