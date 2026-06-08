// Copyright (c) 2026 litongshuai
// SPDX-License-Identifier: MIT OR Apache-2.0

import '../../../utils/cancellation_token.dart';
import '../../skills/models/skill_parameter.dart';
import '../../skills/models/skill_result.dart';
import '../../skills/skill_base.dart';
import '../../open_note_tools.dart';
import '../../ai_service.dart';

class NoteExtractKeywordsSkill extends Skill {
  final AIService? aiService;

  NoteExtractKeywordsSkill({this.aiService})
    : super(
        id: 'note_extract_keywords',
        name: '提取关键词',
        description: '从笔记中提取关键词并生成标签建议',
        parameters: [
          const SkillParameter(
            name: 'note_id',
            type: 'string',
            description: '笔记 ID',
            required: true,
          ),
          const SkillParameter(
            name: 'max_count',
            type: 'number',
            description: '最大关键词数量（默认 5）',
            required: false,
            defaultValue: 5,
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
        return SkillResult.error('AI 服务未配置，无法提取关键词');
      }

      final noteId = args['note_id'] as String?;
      if (noteId == null || noteId.isEmpty) {
        return SkillResult.error('笔记 ID 不能为空');
      }

      final maxCount = (args['max_count'] as num?)?.toInt() ?? 5;

      final note = await OpenNoteTools.getNoteById(noteId);
      if (note == null) {
        return SkillResult.error('未找到指定笔记');
      }

      final prompt =
          '''
请从以下笔记内容中提取最多 $maxCount 个关键词，用逗号分隔返回，不要添加任何额外文字：

标题：${note.title}
内容：${note.content.length > 1000 ? '${note.content.substring(0, 1000)}...' : note.content}
''';

      final response = await aiService!.callAI(
        prompt,
        cancellationToken: cancellationToken,
      );
      final keywords = response
          .split(',')
          .map((k) => k.trim())
          .where((k) => k.isNotEmpty)
          .take(maxCount)
          .toList();

      return SkillResult.ok(
        message: '笔记"${note.title}"的关键词：${keywords.join(', ')}',
        referencedNotes: [note],
        metadata: {'keywords': keywords, 'noteId': noteId},
      );
    } catch (e) {
      return SkillResult.error('提取关键词失败: $e');
    }
  }

  @override
  String generateUsageExample() {
    return '{"tool": "note_extract_keywords", "args": {"note_id": "abc123", "max_count": 5}}';
  }
}
