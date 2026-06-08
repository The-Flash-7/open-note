// Copyright (c) 2026 litongshuai
// SPDX-License-Identifier: MIT OR Apache-2.0

import '../../../utils/cancellation_token.dart';
import 'package:flutter/foundation.dart';
import '../../skills/models/skill_parameter.dart';
import '../../skills/models/skill_result.dart';
import '../../skills/skill_base.dart';
import '../../open_note_tools.dart';

class NoteOpenSkill extends Skill {
  NoteOpenSkill()
    : super(
        id: 'note_open',
        name: '打开笔记',
        description: '在编辑器中打开指定笔记并显示内容',
        parameters: [
          const SkillParameter(
            name: 'note_id',
            type: 'string',
            description: '要打开的笔记 ID',
            required: true,
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
      final noteId = args['note_id'] as String?;
      if (noteId == null || noteId.isEmpty) {
        return SkillResult.error('笔记 ID 不能为空');
      }

      final note = await OpenNoteTools.getNoteById(noteId);
      if (note == null) {
        return SkillResult.error('未找到 ID 为 $noteId 的笔记');
      }

      return SkillResult.ok(
        message: '已打开笔记“${note.title}”',
        data: note,
        referencedNotes: [note],
        metadata: {'action': 'open_note', 'noteId': noteId},
      );
    } catch (e) {
      debugPrint('[NoteOpen] 异常: $e');
      return SkillResult.error('打开笔记失败: $e');
    }
  }

  @override
  String generateUsageExample() {
    return '{"tool": "note_open", "args": {"note_id": "abc123"}}';
  }
}
