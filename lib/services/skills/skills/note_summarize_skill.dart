// Copyright (c) 2026 litongshuai
// SPDX-License-Identifier: MIT OR Apache-2.0

import '../../../models/note.dart';
import '../../../utils/cancellation_token.dart';
import '../../skills/models/skill_parameter.dart';
import '../../skills/models/skill_result.dart';
import '../../skills/skill_base.dart';
import '../../open_note_tools.dart';
import '../../ai_service.dart';

class NoteSummarizeSkill extends Skill {
  final AIService? aiService;

  NoteSummarizeSkill({this.aiService})
    : super(
        id: 'note_summarize',
        name: '总结笔记',
        description: '对单篇或多篇笔记生成简洁摘要',
        parameters: [
          const SkillParameter(
            name: 'note_ids',
            type: 'array',
            description: '要总结的笔记 ID 列表',
            required: true,
          ),
          const SkillParameter(
            name: 'max_length',
            type: 'number',
            description: '摘要最大字数（默认 200）',
            required: false,
            defaultValue: 200,
          ),
        ],
        category: SkillCategory.read,
      );

  @override
  Future<SkillResult> execute(
    Map<String, dynamic> args, {
    CancellationToken? cancellationToken,
  }) async {
    try {
      if (aiService == null || !aiService!.hasConfig()) {
        return SkillResult.error('AI 服务未配置，无法总结笔记');
      }

      final noteIds = (args['note_ids'] as List?)?.cast<String>();
      if (noteIds == null || noteIds.isEmpty) {
        return SkillResult.error('笔记 ID 列表不能为空');
      }

      final maxLength = (args['max_length'] as num?)?.toInt() ?? 200;

      final notes = <Note>[];
      for (final id in noteIds) {
        final note = await OpenNoteTools.getNoteById(id);
        if (note != null) {
          notes.add(note);
        }
      }

      if (notes.isEmpty) {
        return SkillResult.error('未找到指定笔记');
      }

      final prompt = _buildSummarizePrompt(notes, maxLength);
      final summary = await aiService!.callAI(
        prompt,
        cancellationToken: cancellationToken,
      );

      return SkillResult.ok(
        message: notes.length == 1
            ? '笔记"${notes.first.title}"摘要：\n$summary'
            : '${notes.length} 篇笔记摘要：\n$summary',
        referencedNotes: notes,
        metadata: {
          'noteCount': notes.length,
          'maxLength': maxLength,
          'summary': summary,
        },
      );
    } catch (e) {
      return SkillResult.error('总结笔记失败: $e');
    }
  }

  String _buildSummarizePrompt(List<Note> notes, int maxLength) {
    final buffer = StringBuffer();

    if (notes.length == 1) {
      buffer.writeln('请为以下笔记生成简洁摘要（不超过 $maxLength 字）：\n');
      buffer.writeln('标题：${notes.first.title}');
      buffer.writeln(
        '内容：${notes.first.content.length > 1000 ? '${notes.first.content.substring(0, 1000)}...' : notes.first.content}',
      );
    } else {
      buffer.writeln('请为以下 ${notes.length} 篇笔记生成综合摘要（不超过 $maxLength 字）：\n');
      for (int i = 0; i < notes.length; i++) {
        final note = notes[i];
        buffer.writeln('--- 笔记 ${i + 1}: ${note.title} ---');
        buffer.writeln(
          note.content.length > 500
              ? '${note.content.substring(0, 500)}...'
              : note.content,
        );
        buffer.writeln();
      }
    }

    buffer.writeln('请直接返回摘要内容，不要添加额外解释。');
    return buffer.toString();
  }

  @override
  String generateUsageExample() {
    return '{"tool": "note_summarize", "args": {"note_ids": ["abc123"], "max_length": 200}}';
  }
}
