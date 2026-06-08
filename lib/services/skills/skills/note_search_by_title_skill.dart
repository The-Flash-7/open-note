// Copyright (c) 2026 litongshuai
// SPDX-License-Identifier: MIT OR Apache-2.0

import '../../../utils/cancellation_token.dart';
import '../../skills/models/skill_parameter.dart';
import '../../skills/models/skill_result.dart';
import '../../skills/skill_base.dart';
import '../../open_note_tools.dart';

class NoteSearchByTitleSkill extends Skill {
  NoteSearchByTitleSkill()
    : super(
        id: 'note_search_by_title',
        name: '按标题搜索笔记',
        description: '通过标题模糊搜索笔记，返回匹配的笔记 ID 和基本信息',
        parameters: [
          const SkillParameter(
            name: 'title_query',
            type: 'string',
            description: '标题搜索关键词',
            required: true,
          ),
          const SkillParameter(
            name: 'limit',
            type: 'number',
            description: '返回数量（默认 10）',
            required: false,
            defaultValue: 10,
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
      final titleQuery = args['title_query'] as String?;
      if (titleQuery == null || titleQuery.isEmpty) {
        return SkillResult.error('标题搜索词不能为空');
      }

      final limit = (args['limit'] as num?)?.toInt() ?? 10;
      final queryLower = titleQuery.toLowerCase();

      // 先通过 searchNotes 进行文本粗搜
      final allNotes = await OpenNoteTools.searchNotes(
        queryList: [titleQuery],
        limit: limit * 5,
      );

      // 二次过滤：只保留标题匹配的笔记
      final matchedNotes = allNotes
          .where((note) => note.title.toLowerCase().contains(queryLower))
          .take(limit)
          .toList();

      if (matchedNotes.isEmpty) {
        return SkillResult.ok(
          message: '没有找到标题包含"$titleQuery"的笔记',
          referencedNotes: [],
          metadata: {'query': titleQuery, 'count': 0},
        );
      }

      final titleList = matchedNotes
          .map(
            (n) =>
                'ID: ${n.id} | 标题: ${n.title} | 分类ID: ${n.category ?? '无'} | 标签: ${n.tags.isEmpty ? '无' : n.tags.join(', ')}',
          )
          .join('\n');

      return SkillResult.ok(
        message: '找到 ${matchedNotes.length} 篇标题包含"$titleQuery"的笔记：\n$titleList',
        referencedNotes: matchedNotes,
        metadata: {'query': titleQuery, 'count': matchedNotes.length},
      );
    } catch (e) {
      return SkillResult.error('按标题搜索失败: $e');
    }
  }

  @override
  String generateUsageExample() {
    return '{"tool": "note_search_by_title", "args": {"title_query": "OKR", "limit": 5}}';
  }
}
