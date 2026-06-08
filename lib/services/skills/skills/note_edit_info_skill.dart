// Copyright (c) 2026 litongshuai
// SPDX-License-Identifier: MIT OR Apache-2.0

import '../../../utils/cancellation_token.dart';
import '../../skills/models/skill_parameter.dart';
import '../../skills/models/skill_result.dart';
import '../../skills/skill_base.dart';
import '../../open_note_tools.dart';

class NoteEditInfoSkill extends Skill {
  NoteEditInfoSkill()
    : super(
        id: 'note_edit_info',
        name: '编辑笔记属性信息',
        description: '修改已有笔记的标题、分类、标签或收藏状态',
        parameters: [
          const SkillParameter(
            name: 'note_id',
            type: 'string',
            description: '要编辑的笔记 ID',
            required: true,
          ),
          const SkillParameter(
            name: 'title',
            type: 'string',
            description: '新标题',
            required: false,
          ),
          const SkillParameter(
            name: 'categoryId',
            type: 'string',
            description: '新分类ID（可选。如需修改为"未分类"请传null）',
            required: false,
          ),
          const SkillParameter(
            name: 'tags',
            type: 'array',
            description: '新标签列表',
            required: false,
          ),
          const SkillParameter(
            name: 'isFavorite',
            type: 'boolean',
            description: '是否收藏（true=收藏，false=取消收藏）',
            required: false,
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
      final noteId = args['note_id'] as String?;
      if (noteId == null || noteId.isEmpty) {
        return SkillResult.error('笔记 ID 不能为空');
      }

      final existingNote = await OpenNoteTools.getNoteById(noteId);
      if (existingNote == null) {
        return SkillResult.error('未找到 ID 为 $noteId 的笔记');
      }

      final title = args['title'] as String?;
      final categoryId = args['categoryId'] as String?;
      final tags = (args['tags'] as List?)?.cast<String>();
      final isFavorite = args['isFavorite'] as bool?;

      final success = await OpenNoteTools.updateNote(
        noteId: noteId,
        title: title,
        category: categoryId,
        tags: tags,
        isFavorite: isFavorite,
      );

      if (!success) {
        return SkillResult.error('笔记更新失败');
      }

      final updatedNote = await OpenNoteTools.getNoteById(noteId);
      final favoriteInfo = isFavorite != null
          ? (isFavorite ? '，已收藏' : '，已取消收藏')
          : '';
      return SkillResult.ok(
        message: '笔记"${existingNote.title}"已更新$favoriteInfo',
        data: {'id': noteId},
        referencedNotes: updatedNote != null ? [updatedNote] : [],
        metadata: {
          'noteId': noteId,
          'isFavorite': isFavorite ?? updatedNote?.isFavorite,
        },
      );
    } catch (e) {
      return SkillResult.error('编辑笔记失败: $e');
    }
  }

  @override
  String generateUsageExample() {
    return '{"tool": "note_edit_info", "args": {"note_id": "abc123", "title": "新标题", "isFavorite": true}}';
  }
}
