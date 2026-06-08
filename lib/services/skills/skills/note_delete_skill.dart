// Copyright (c) 2026 litongshuai
// SPDX-License-Identifier: MIT OR Apache-2.0

import '../../../utils/cancellation_token.dart';
import '../../skills/models/skill_parameter.dart';
import '../../skills/models/skill_result.dart';
import '../../skills/skill_base.dart';
import '../../open_note_tools.dart';

class NoteDeleteSkill extends Skill {
  NoteDeleteSkill()
    : super(
        id: 'note_delete',
        name: '删除笔记',
        description: '将笔记移入回收站（软删除）',
        parameters: [
          const SkillParameter(
            name: 'note_id',
            type: 'string',
            description: '要删除的笔记 ID',
            required: true,
          ),
          const SkillParameter(
            name: 'confirm',
            type: 'boolean',
            description: '确认删除',
            required: false,
            defaultValue: false,
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

      final confirm = args['confirm'] as bool? ?? false;
      if (!confirm) {
        return SkillResult.ok(
          message: '请确认是否删除笔记"${existingNote.title}"',
          data: {
            'note_id': noteId,
            'title': existingNote.title,
            'need_confirm': true,
          },
        );
      }

      final success = await OpenNoteTools.deleteNote(noteId);
      if (!success) {
        return SkillResult.error('删除失败');
      }

      return SkillResult.ok(
        message: '笔记"${existingNote.title}"已移入回收站',
        metadata: {'noteId': noteId},
      );
    } catch (e) {
      return SkillResult.error('删除笔记失败: $e');
    }
  }

  @override
  String generateUsageExample() {
    return '{"tool": "note_delete", "args": {"note_id": "abc123", "confirm": true}}';
  }
}
