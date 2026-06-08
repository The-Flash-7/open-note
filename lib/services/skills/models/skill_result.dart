// Copyright (c) 2026 litongshuai
// SPDX-License-Identifier: MIT OR Apache-2.0

import '../../../models/note.dart';

class SkillResult {
  final bool success;
  final String message;
  final dynamic data;
  final List<Note> referencedNotes;
  final Map<String, dynamic>? metadata;

  const SkillResult({
    required this.success,
    required this.message,
    this.data,
    this.referencedNotes = const [],
    this.metadata,
  });

  factory SkillResult.ok({
    required String message,
    dynamic data,
    List<Note> referencedNotes = const [],
    Map<String, dynamic>? metadata,
  }) {
    return SkillResult(
      success: true,
      message: message,
      data: data,
      referencedNotes: referencedNotes,
      metadata: metadata,
    );
  }

  factory SkillResult.error(String message) {
    return SkillResult(success: false, message: message);
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'data': data,
      'referencedNotes': referencedNotes
          .map((n) => {'id': n.id, 'title': n.title})
          .toList(),
      if (metadata != null) 'metadata': metadata,
    };
  }
}
