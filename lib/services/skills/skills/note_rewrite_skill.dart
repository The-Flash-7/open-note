// Copyright (c) 2026 litongshuai
// SPDX-License-Identifier: MIT OR Apache-2.0

import '../../../utils/cancellation_token.dart';
import '../../skills/models/skill_parameter.dart';
import '../../skills/models/skill_result.dart';
import '../../skills/skill_base.dart';
import '../../open_note_tools.dart';
import '../../ai_service.dart';

class NoteRewriteSkill extends Skill {
  final AIService? aiService;

  NoteRewriteSkill({this.aiService})
    : super(
        id: 'note_rewrite',
        name: '改写/润色笔记',
        description: '改写或润色笔记内容，提升表达质量',
        parameters: [
          const SkillParameter(
            name: 'note_id',
            type: 'string',
            description: '笔记 ID',
            required: true,
          ),
          const SkillParameter(
            name: 'style',
            type: 'string',
            description:
                '改写风格预设值（formal/casual/concise/detailed），如果用户自定了风格则传入用户的风格',
            required: false,
            defaultValue: 'formal',
            enumValues: ['formal', 'casual', 'concise', 'detailed'],
          ),
        ],
        category: SkillCategory.write,
      );

  @override
  Future<SkillResult> execute(
    Map<String, dynamic> args, {
    CancellationToken? cancellationToken,
  }) async {
    try {
      if (aiService == null || !aiService!.hasConfig()) {
        return SkillResult.error('AI 服务未配置，无法改写笔记');
      }

      final noteId = args['note_id'] as String?;
      if (noteId == null || noteId.isEmpty) {
        return SkillResult.error('笔记 ID 不能为空');
      }

      final style = args['style'] as String? ?? 'formal';

      final note = await OpenNoteTools.getNoteById(noteId);
      if (note == null) {
        return SkillResult.error('未找到指定笔记');
      }

      final styleDesc =
          {
            'formal': '正式、专业的语气',
            'casual': '轻松、口语化的语气',
            'concise': '简洁明了，去除冗余',
            'detailed': '详细展开，补充更多细节',
          }[style] ??
          style;

      final prompt =
          '''
请改写以下笔记内容，使用 $styleDesc 的语气。保持原意不变，但提升表达质量。

标题：${note.title}
内容：
${note.content}

请直接返回改写后的内容，不要添加额外解释。
''';

      final rewrittenContent = await aiService!.callAI(
        prompt,
        cancellationToken: cancellationToken,
      );

      // 可选：直接更新笔记内容
      // await OpenNoteTools.updateNote(noteId: noteId, content: rewrittenContent);

      return SkillResult.ok(
        message: '笔记"${note.title}"已改写完成（风格：$style）\n\n$rewrittenContent',
        referencedNotes: [note],
        metadata: {
          'noteId': noteId,
          'style': style,
          'rewrittenContent': rewrittenContent,
        },
      );
    } catch (e) {
      return SkillResult.error('改写笔记失败: $e');
    }
  }

  @override
  String generateUsageExample() {
    return '{"tool": "note_rewrite", "args": {"note_id": "abc123", "style": "formal"}}';
  }
}
