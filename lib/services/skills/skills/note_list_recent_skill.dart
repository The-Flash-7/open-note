// Copyright (c) 2026 litongshuai
// SPDX-License-Identifier: MIT OR Apache-2.0

import '../../../models/note.dart';
import '../../../utils/cancellation_token.dart';
import '../../skills/models/skill_parameter.dart';
import '../../skills/models/skill_result.dart';
import '../../skills/skill_base.dart';
import '../../open_note_tools.dart';

class NoteListRecentSkill extends Skill {
  NoteListRecentSkill()
    : super(
        id: 'note_list_recent',
        name: '列出最近笔记',
        description: '列出最近编辑的笔记',
        parameters: [
          const SkillParameter(
            name: 'limit',
            type: 'number',
            description: '返回数量（默认 10）',
            required: false,
            defaultValue: 10,
          ),
          const SkillParameter(
            name: 'category',
            type: 'string',
            description: '按分类过滤（可选）',
            required: false,
          ),
        ],
        category: SkillCategory.query,
      );

  @override
  Future<SkillResult> execute(
    Map<String, dynamic> args, {
    CancellationToken? cancellationToken,
  }) async {
    try {
      final limit = (args['limit'] as num?)?.toInt() ?? 10;
      final category = args['category'] as String?;

      final notes = await OpenNoteTools.getRecentNotes(limit: limit * 2);

      List<Note> filtered = notes;
      if (category != null && category.isNotEmpty) {
        filtered = notes.where((n) => n.category == category).toList();
      }

      final resultNotes = filtered.take(limit).toList();

      if (resultNotes.isEmpty) {
        return SkillResult.ok(message: '没有最近笔记', referencedNotes: []);
      }

      final titleList = resultNotes.map((n) => n.title).toList();
      return SkillResult.ok(
        message:
            '最近 ${resultNotes.length} 篇笔记：\n${titleList.map((t) => '• $t').join('\n')}',
        referencedNotes: resultNotes,
        metadata: {'count': resultNotes.length, 'titles': titleList},
      );
    } catch (e) {
      return SkillResult.error('列出最近笔记失败: $e');
    }
  }

  @override
  String generateUsageExample() {
    return '{"tool": "note_list_recent", "args": {"limit": 5}}';
  }
}
