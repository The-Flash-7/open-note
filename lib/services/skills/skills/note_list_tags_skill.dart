// Copyright (c) 2026 litongshuai
// SPDX-License-Identifier: MIT OR Apache-2.0

import '../../../utils/cancellation_token.dart';
import '../../skills/models/skill_result.dart';
import '../../skills/skill_base.dart';
import '../../open_note_tools.dart';

class NoteListTagsSkill extends Skill {
  NoteListTagsSkill()
    : super(
        id: 'note_list_tags',
        name: '列出所有标签',
        description: '获取系统中所有标签及其使用次数',
        parameters: [],
        category: SkillCategory.query,
      );

  @override
  Future<SkillResult> execute(
    Map<String, dynamic> args, {
    CancellationToken? cancellationToken,
  }) async {
    try {
      final allNotes = await OpenNoteTools.searchNotes(limit: 1000);

      final tagMap = <String, int>{};
      for (final note in allNotes) {
        for (final tag in note.tags) {
          tagMap[tag] = (tagMap[tag] ?? 0) + 1;
        }
      }

      if (tagMap.isEmpty) {
        return SkillResult.ok(message: '系统中没有任何标签', metadata: {'tags': []});
      }

      final sortedTags = tagMap.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      final tagList = sortedTags
          .map((e) => '${e.key}: ${e.value} 篇笔记')
          .join('\n');

      return SkillResult.ok(
        message: '系统共有 ${sortedTags.length} 个标签：\n$tagList',
        metadata: {
          'tags': sortedTags
              .map((e) => {'name': e.key, 'count': e.value})
              .toList(),
        },
      );
    } catch (e) {
      return SkillResult.error('获取标签列表失败: $e');
    }
  }

  @override
  String generateUsageExample() {
    return '{"tool": "note_list_tags", "args": {}}';
  }
}
