// Copyright (c) 2026 litongshuai
// SPDX-License-Identifier: MIT OR Apache-2.0

class Category {
  final String id;
  final String name;
  final String? parentId;
  final int level;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isVirtual;

  Category({
    required this.id,
    required this.name,
    this.parentId,
    this.level = 0,
    required this.createdAt,
    required this.updatedAt,
    this.isVirtual = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'parentId': parentId,
      'level': level,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'isVirtual': isVirtual ? 1 : 0,
    };
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'] as String,
      name: map['name'] as String,
      parentId: map['parentId'] as String?,
      level: map['level'] as int? ?? 0,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] as int),
      isVirtual: (map['isVirtual'] as int? ?? 0) == 1,
    );
  }

  Category copyWith({
    String? id,
    String? name,
    Object? parentId = _unset,
    int? level,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isVirtual,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      parentId: parentId == _unset ? this.parentId : parentId as String?,
      level: level ?? this.level,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isVirtual: isVirtual ?? this.isVirtual,
    );
  }

  static const _unset = Object();
}

const String allNotesCategoryId = 'all_notes';
