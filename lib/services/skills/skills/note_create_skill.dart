// Copyright (c) 2026 litongshuai
// SPDX-License-Identifier: MIT OR Apache-2.0

import '../../../utils/cancellation_token.dart';
import '../../skills/models/skill_parameter.dart';
import '../../skills/models/skill_result.dart';
import '../../skills/skill_base.dart';
import '../../open_note_tools.dart';
import '../../ai_service.dart';
import '../../../models/note.dart';

class NoteCreateSkill extends Skill {
  final AIService? aiService;

  NoteCreateSkill({this.aiService})
    : super(
        id: 'note_create',
        name: '创建笔记',
        description: '创建一条新笔记，自动生成摘要和关键词',
        parameters: [
          const SkillParameter(
            name: 'title',
            type: 'string',
            description: '笔记标题',
            required: true,
          ),
          const SkillParameter(
            name: 'content',
            type: 'string',
            description: '笔记内容（注意笔记内容的格式需要与`format`笔记格式要一致）',
            required: true,
          ),
          const SkillParameter(
            name: 'categoryId',
            type: 'string',
            description: '笔记分类ID（可选。如需"未分类"请省略此参数）',
            required: false,
          ),
          const SkillParameter(
            name: 'tags',
            type: 'array',
            description: '笔记标签',
            required: false,
          ),
          const SkillParameter(
            name: 'format',
            type: 'string',
            description: '笔记格式（markdown/plainText/richText）',
            required: false,
            defaultValue: 'markdown',
            enumValues: ['markdown', 'plainText', 'richText'],
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
      final title = args['title'] as String?;
      final content = args['content'] as String?;
      final categoryId = args['categoryId'] as String?;
      final tags = (args['tags'] as List?)?.cast<String>();
      final formatStr = args['format'] as String? ?? 'markdown';

      if (title == null || title.isEmpty) {
        return SkillResult.error('标题不能为空');
      }
      if (content == null || content.isEmpty) {
        return SkillResult.error('内容不能为空');
      }

      final format = _parseFormat(formatStr);

      final noteId = await OpenNoteTools.createNote(
        title: title,
        content: content,
        category: categoryId,
        tags: tags,
        format: format,
        autoGenerateSummary: true, // 自动生成摘要
      );

      if (noteId == null) {
        return SkillResult.error('笔记创建失败');
      }

      final createdNote = await OpenNoteTools.getNoteById(noteId);
      final hasSummary =
          createdNote?.summary != null && createdNote!.summary!.isNotEmpty;
      final summaryInfo = hasSummary ? '，已生成摘要' : '';
      return SkillResult.ok(
        message: '笔记"$title"已创建成功$summaryInfo',
        data: {'id': noteId},
        referencedNotes: createdNote != null ? [createdNote] : [],
        metadata: {'noteId': noteId, 'summaryGenerated': hasSummary},
      );
    } catch (e) {
      return SkillResult.error('创建笔记失败: $e');
    }
  }

  NoteFormat _parseFormat(String formatStr) {
    switch (formatStr) {
      case 'plainText':
        return NoteFormat.plainText;
      case 'richText':
        return NoteFormat.richText;
      default:
        return NoteFormat.markdown;
    }
  }

  @override
  String generateUsageExample() {
    return '{"tool": "note_create", "args": {"title": "会议记录", "content": "会议内容...", "format": "markdown"}}';
  }
}
