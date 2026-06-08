// Copyright (c) 2026 litongshuai
// SPDX-License-Identifier: MIT OR Apache-2.0

import 'dart:convert';

enum MemoryType { profile, fact, experience }

class AgentMemory {
  final String id;
  final MemoryType type;
  final String key;
  final String value;
  final List<String> tags;
  final int confidence;
  final int frequency;
  final DateTime createdAt;
  final DateTime lastAccessedAt;

  AgentMemory({
    required this.id,
    required this.type,
    required this.key,
    required this.value,
    this.tags = const [],
    this.confidence = 1,
    this.frequency = 1,
    DateTime? createdAt,
    DateTime? lastAccessedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       lastAccessedAt = lastAccessedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.name,
      'key': key,
      'value': value,
      'tags': tags.isNotEmpty ? jsonEncode(tags) : null,
      'confidence': confidence,
      'frequency': frequency,
      'created_at': createdAt.toIso8601String(),
      'last_accessed': lastAccessedAt.toIso8601String(),
    };
  }

  factory AgentMemory.fromMap(Map<String, dynamic> map) {
    final tagsStr = map['tags'] as String?;
    List<String> tags = [];
    if (tagsStr != null && tagsStr.isNotEmpty) {
      try {
        tags = (jsonDecode(tagsStr) as List).cast<String>();
      } catch (_) {}
    }

    final rawConfidence = map['confidence'];
    final confidence = rawConfidence is int
        ? rawConfidence
        : rawConfidence is num
        ? rawConfidence.toInt()
        : 1;

    return AgentMemory(
      id: map['id'] as String,
      type: MemoryType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => MemoryType.fact,
      ),
      key: map['key'] as String? ?? '',
      value: map['value'] as String? ?? '',
      tags: tags,
      confidence: confidence,
      frequency: map['frequency'] as int? ?? 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      lastAccessedAt: DateTime.parse(map['last_accessed'] as String),
    );
  }

  AgentMemory copyWith({
    String? id,
    MemoryType? type,
    String? key,
    String? value,
    List<String>? tags,
    int? confidence,
    int? frequency,
    DateTime? createdAt,
    DateTime? lastAccessedAt,
  }) {
    return AgentMemory(
      id: id ?? this.id,
      type: type ?? this.type,
      key: key ?? this.key,
      value: value ?? this.value,
      tags: tags ?? this.tags,
      confidence: confidence ?? this.confidence,
      frequency: frequency ?? this.frequency,
      createdAt: createdAt ?? this.createdAt,
      lastAccessedAt: lastAccessedAt ?? this.lastAccessedAt,
    );
  }

  bool isExpired({int daysThreshold = 30}) {
    final daysSinceAccessed = DateTime.now().difference(lastAccessedAt).inDays;
    return daysSinceAccessed > daysThreshold;
  }

  int get decayedConfidence {
    final daysSinceAccessed = DateTime.now().difference(lastAccessedAt).inDays;
    final decay = daysSinceAccessed ~/ 7;
    return (confidence - decay).clamp(0, 5);
  }
}
