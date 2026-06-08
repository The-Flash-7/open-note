// Copyright (c) 2026 litongshuai
// SPDX-License-Identifier: MIT OR Apache-2.0

class ArticleData {
  final String title;
  final String textContent;
  final String htmlContent;
  final String? author;
  final String? publishDate;
  final String? excerpt;
  final String url;

  ArticleData({
    required this.title,
    required this.textContent,
    required this.htmlContent,
    this.author,
    this.publishDate,
    this.excerpt,
    required this.url,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'textContent': textContent,
      'htmlContent': htmlContent,
      'author': author,
      'publishDate': publishDate,
      'excerpt': excerpt,
      'url': url,
    };
  }

  factory ArticleData.fromMap(Map<String, dynamic> map) {
    return ArticleData(
      title: map['title'] as String,
      textContent: map['textContent'] as String,
      htmlContent: map['htmlContent'] as String,
      author: map['author'] as String?,
      publishDate: map['publishDate'] as String?,
      excerpt: map['excerpt'] as String?,
      url: map['url'] as String,
    );
  }
}
