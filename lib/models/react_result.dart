// Copyright (c) 2026 litongshuai
// SPDX-License-Identifier: MIT OR Apache-2.0

import '../models/note.dart';
import '../services/skills/models/skill_result.dart';

class ReActStep {
  final String thought;
  final String? tool;
  final Map<String, dynamic>? args;
  final SkillResult? observation;

  ReActStep({required this.thought, this.tool, this.args, this.observation});

  bool get isToolCall => tool != null;
  bool get isDone => tool == null && observation == null;
}

class ReActResult {
  final List<ReActStep> steps;
  final String finalAnswer;
  final List<Note> referencedNotes;
  final List<ToolCall> toolCalls;
  final String? error;
  final Map<String, dynamic>? uiAction;
  final String? replyLanguage;

  ReActResult({
    required this.steps,
    required this.finalAnswer,
    this.referencedNotes = const [],
    this.toolCalls = const [],
    this.error,
    this.uiAction,
    this.replyLanguage,
  });

  bool get hasError => error != null;
}

class ToolCall {
  final String tool;
  final Map<String, dynamic> args;

  const ToolCall({required this.tool, required this.args});

  factory ToolCall.fromJson(Map<String, dynamic> json) {
    return ToolCall(
      tool: json['tool'] as String? ?? '',
      args: (json['args'] as Map?)?.cast<String, dynamic>() ?? {},
    );
  }
}
