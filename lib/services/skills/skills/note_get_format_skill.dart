// Copyright (c) 2026 litongshuai
// SPDX-License-Identifier: MIT OR Apache-2.0

import '../../../utils/cancellation_token.dart';
import '../../skills/models/skill_parameter.dart';
import '../../skills/models/skill_result.dart';
import '../../skills/skill_base.dart';
import '../../open_note_tools.dart';

class NoteGetFormatSkill extends Skill {
  NoteGetFormatSkill()
    : super(
        id: 'note_get_format',
        name: '获取笔记格式',
        description: '查询指定笔记的格式类型（markdown/plainText/richText/code）',
        parameters: [
          const SkillParameter(
            name: 'note_ids',
            type: 'array',
            description: '笔记 ID 数组，可传一个或多个',
            required: true,
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
      final noteIds = (args['note_ids'] as List?)?.cast<String>();
      if (noteIds == null || noteIds.isEmpty) {
        return SkillResult.error('笔记 ID 数组不能为空');
      }

      final results = <Map<String, dynamic>>[];

      for (final noteId in noteIds) {
        final note = await OpenNoteTools.getNoteById(noteId);
        if (note != null) {
          results.add({
            'note_id': noteId,
            'format': note.format.name,
            'title': note.title,
          });
        } else {
          results.add({
            'note_id': noteId,
            'format': 'not_found',
            'title': null,
          });
        }
      }

      final foundCount = results
          .where((r) => r['format'] != 'not_found')
          .length;
      final notFoundCount = results.length - foundCount;

      String message;
      if (notFoundCount > 0) {
        message =
            '已查询 ${results.length} 篇笔记的格式，找到 $foundCount 篇，$notFoundCount 篇未找到';
      } else {
        message = '已查询 ${results.length} 篇笔记的格式';
      }

      return SkillResult.ok(
        message: message,
        data: results,
        metadata: {
          'totalCount': results.length,
          'foundCount': foundCount,
          'notFoundCount': notFoundCount,
        },
      );
    } catch (e) {
      return SkillResult.error('获取笔记格式失败: $e');
    }
  }

  @override
  String generateUsageExample() {
    return '{"tool": "note_get_format", "args": {"note_ids": ["abc123", "def456"]}}';
  }
}
