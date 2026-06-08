// Copyright (c) 2026 litongshuai
// SPDX-License-Identifier: MIT OR Apache-2.0

import 'dart:convert';

class Tag {
  final String id;
  final String name;
  final int usageCount;
  final DateTime createdAt;

  Tag({
    required this.id,
    required this.name,
    this.usageCount = 0,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'usage_count': usageCount,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  factory Tag.fromMap(Map<String, dynamic> map) {
    return Tag(
      id: map['id'] as String,
      name: map['name'] as String,
      usageCount: map['usage_count'] as int? ?? 0,
      createdAt: map['created_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int)
          : DateTime.now(),
    );
  }

  Tag copyWith({
    String? id,
    String? name,
    int? usageCount,
    DateTime? createdAt,
  }) {
    return Tag(
      id: id ?? this.id,
      name: name ?? this.name,
      usageCount: usageCount ?? this.usageCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  static String toJson(Tag tag) => jsonEncode(tag.toMap());

  static Tag fromJson(String source) => Tag.fromMap(jsonDecode(source));

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Tag && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
