// Copyright (c) 2026 litongshuai
// SPDX-License-Identifier: MIT OR Apache-2.0

import '../../../utils/cancellation_token.dart';
import '../../skills/models/skill_parameter.dart';
import '../../skills/models/skill_result.dart';
import '../../skills/skill_base.dart';
import '../../open_note_tools.dart';
import '../../ai_service.dart';
import '../../../models/note.dart';

class NoteQASkill extends Skill {
  final AIService? aiService;

  NoteQASkill({this.aiService})
    : super(
        id: 'note_qa',
        name: '笔记问答',
        description: '基于笔记内容回答问题',
        parameters: [
          const SkillParameter(
            name: 'question',
            type: 'string',
            description: '要回答的问题',
            required: true,
          ),
          const SkillParameter(
            name: 'note_ids',
            type: 'array',
            description: '指定笔记 ID 列表（可选，不指定则自动检索相关笔记）',
            required: false,
          ),
          const SkillParameter(
            name: 'context',
            type: 'string',
            description: '额外的上下文信息',
            required: false,
          ),
        ],
        category: SkillCategory.qa,
      );

  @override
  Future<SkillResult> execute(
    Map<String, dynamic> args, {
    CancellationToken? cancellationToken,
  }) async {
    try {
      final question = args['question'] as String?;
      if (question == null || question.isEmpty) {
        return SkillResult.error('问题不能为空');
      }

      final noteIds = (args['note_ids'] as List?)?.cast<String>();
      final context = args['context'] as String?;

      List<Note> contextNotes = [];

      if (noteIds != null && noteIds.isNotEmpty) {
        for (final id in noteIds) {
          final note = await OpenNoteTools.getNoteById(id);
          if (note != null) {
            contextNotes.add(note);
          }
        }
      } else {
        final contexts = await OpenNoteTools.retrieveRelevantContext(
          query: question,
          topK: 5,
        );
        for (final ctx in contexts) {
          final note = await OpenNoteTools.getNoteById(ctx.noteId);
          if (note != null) {
            contextNotes.add(note);
          }
        }
      }

      if (contextNotes.isEmpty) {
        return SkillResult.ok(
          message: '没有找到相关笔记，无法基于笔记内容回答问题',
          referencedNotes: [],
        );
      }

      if (aiService == null || !aiService!.hasConfig()) {
        return SkillResult.error('AI 服务未配置，无法回答问题');
      }

      final prompt = _buildQAPrompt(question, contextNotes, context);
      final answer = await aiService!.callAI(
        prompt,
        cancellationToken: cancellationToken,
      );

      return SkillResult.ok(
        message: answer,
        referencedNotes: contextNotes,
        metadata: {
          'question': question,
          'contextNoteCount': contextNotes.length,
        },
      );
    } catch (e) {
      return SkillResult.error('笔记问答失败: $e');
    }
  }

  String _buildQAPrompt(
    String question,
    List<Note> notes,
    String? additionalContext,
  ) {
    final buffer = StringBuffer();
    buffer.writeln('请基于以下笔记内容回答问题。如果笔记中没有相关信息，请明确说明。\n');

    for (int i = 0; i < notes.length; i++) {
      final note = notes[i];
      buffer.writeln('--- 笔记 ${i + 1}: ${note.title} ---');
      buffer.writeln(note.content);
      if (note.summary != null && note.summary!.isNotEmpty) {
        buffer.writeln('摘要: ${note.summary}');
      }
      buffer.writeln();
    }

    if (additionalContext != null && additionalContext.isNotEmpty) {
      buffer.writeln('--- 额外上下文 ---');
      buffer.writeln(additionalContext);
      buffer.writeln();
    }

    buffer.writeln('--- 问题 ---');
    buffer.writeln(question);

    return buffer.toString();
  }

  @override
  String generateUsageExample() {
    return '{"tool": "note_qa", "args": {"question": "我的工作计划是什么？"}}';
  }
}
