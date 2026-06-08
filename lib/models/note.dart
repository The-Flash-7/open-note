// Copyright (c) 2026 litongshuai
// SPDX-License-Identifier: MIT OR Apache-2.0

import 'dart:convert';

enum NoteSourceType { manual, paste, url, file }

enum NoteFormat { markdown, plainText, richText, code }

class Note {
  final String id;
  final String title;
  final String content;
  final NoteFormat format;
  final String? language;
  final String? summary;
  final List<String> keywords;
  // 这个字段里存的是分类ID，不是分类名称
  final String? category;
  final List<String> tags;
  final String? sourceUrl;
  final NoteSourceType sourceType;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int wordCount;
  final bool isFavorite;
  final bool isDeleted;
  final DateTime? deletedAt;

  Note({
    required this.id,
    required this.title,
    required this.content,
    this.format = NoteFormat.markdown,
    this.language,
    this.summary,
    this.keywords = const [],
    this.category,
    this.tags = const [],
    this.sourceUrl,
    required this.sourceType,
    required this.createdAt,
    required this.updatedAt,
    this.wordCount = 0,
    this.isFavorite = false,
    this.isDeleted = false,
    this.deletedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'format': format.name,
      'language': language,
      'summary': summary,
      'keywords': jsonEncode(keywords),
      'category': category,
      'tags': jsonEncode(tags),
      'source_url': sourceUrl,
      'source_type': sourceType.name,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
      'word_count': wordCount,
      'is_favorite': isFavorite ? 1 : 0,
      'is_deleted': isDeleted ? 1 : 0,
      'deleted_at': deletedAt?.millisecondsSinceEpoch,
    };
  }

  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'] as String,
      title: map['title'] as String,
      content: map['content'] as String,
      format: map['format'] != null
          ? NoteFormat.values.firstWhere(
              (e) => e.name == map['format'],
              orElse: () => NoteFormat.markdown,
            )
          : NoteFormat.markdown,
      language: map['language'] as String?,
      summary: map['summary'] as String?,
      keywords: map['keywords'] != null
          ? List<String>.from(jsonDecode(map['keywords'] as String))
          : [],
      category: map['category'] as String?,
      tags: map['tags'] != null
          ? List<String>.from(jsonDecode(map['tags'] as String))
          : [],
      sourceUrl: map['source_url'] as String?,
      sourceType: NoteSourceType.values.firstWhere(
        (e) => e.name == map['source_type'],
        orElse: () => NoteSourceType.manual,
      ),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
      wordCount: map['word_count'] as int? ?? 0,
      isFavorite: (map['is_favorite'] as int? ?? 0) == 1,
      isDeleted: (map['is_deleted'] as int? ?? 0) == 1,
      deletedAt: map['deleted_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['deleted_at'] as int)
          : null,
    );
  }

  Note copyWith({
    String? id,
    String? title,
    String? content,
    NoteFormat? format,
    String? language,
    String? summary,
    List<String>? keywords,
    Object? category = _unset,
    List<String>? tags,
    String? sourceUrl,
    NoteSourceType? sourceType,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? wordCount,
    bool? isFavorite,
    bool? isDeleted,
    Object? deletedAt = _unset,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      format: format ?? this.format,
      language: language ?? this.language,
      summary: summary ?? this.summary,
      keywords: keywords ?? this.keywords,
      category: category == _unset ? this.category : category as String?,
      tags: tags ?? this.tags,
      sourceUrl: sourceUrl ?? this.sourceUrl,
      sourceType: sourceType ?? this.sourceType,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      wordCount: wordCount ?? this.wordCount,
      isFavorite: isFavorite ?? this.isFavorite,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedAt: deletedAt == _unset ? this.deletedAt : deletedAt as DateTime?,
    );
  }
}

const _unset = Object();
