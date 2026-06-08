// Copyright (c) 2026 litongshuai
// SPDX-License-Identifier: MIT OR Apache-2.0

class NoteData {
  final String title;
  final String content;
  final String? url;
  final String? summary;
  final List<String>? keywords;
  final String? category; // 分类ID（用于存储）
  final String? categoryPath; // 分类路径（用于显示）
  final List<String>? tags;

  NoteData({
    required this.title,
    required this.content,
    this.url,
    this.summary,
    this.keywords,
    this.category,
    this.categoryPath,
    this.tags,
  });

  NoteData copyWith({
    String? title,
    String? content,
    String? url,
    String? summary,
    List<String>? keywords,
    String? category,
    String? categoryPath,
    List<String>? tags,
  }) {
    return NoteData(
      title: title ?? this.title,
      content: content ?? this.content,
      url: url ?? this.url,
      summary: summary ?? this.summary,
      keywords: keywords ?? this.keywords,
      category: category ?? this.category,
      categoryPath: categoryPath ?? this.categoryPath,
      tags: tags ?? this.tags,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'content': content,
      'url': url,
      'summary': summary,
      'keywords': keywords,
      'category': category,
      'categoryPath': categoryPath,
      'tags': tags,
    };
  }
}
