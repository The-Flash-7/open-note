// Copyright (c) 2026 litongshuai
// SPDX-License-Identifier: MIT OR Apache-2.0

import '../../../utils/cancellation_token.dart';
import '../../skills/models/skill_parameter.dart';
import '../../skills/models/skill_result.dart';
import '../../skills/skill_base.dart';
import '../../open_note_tools.dart';

class NoteSearchSkill extends Skill {
  NoteSearchSkill()
    : super(
        id: 'note_search',
        name: '搜索笔记',
        description: '通过关键词、分类、标签等条件进行文本匹配搜索笔记',
        parameters: [
          const SkillParameter(
            name: 'queryList',
            type: 'array',
            description: '搜索关键词列表（匹配标题、内容、摘要，OR关系，匹配任一即可）',
            required: true,
          ),
          const SkillParameter(
            name: 'category',
            type: 'string',
            description: '按分类过滤',
            required: false,
          ),
          const SkillParameter(
            name: 'tags',
            type: 'array',
            description: '按标签过滤',
            required: false,
          ),
          const SkillParameter(
            name: 'favorites_only',
            type: 'boolean',
            description: '是否只显示收藏笔记',
            required: false,
            defaultValue: false,
          ),
          const SkillParameter(
            name: 'limit',
            type: 'number',
            description: '返回数量限制',
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
      final queryList = (args['queryList'] as List?)?.cast<String>();
      if (queryList == null || queryList.isEmpty) {
        return SkillResult.error('搜索关键词列表不能为空');
      }

      final category = args['category'] as String?;
      final tags = (args['tags'] as List?)?.cast<String>();
      final favoritesOnly = args['favorites_only'] as bool? ?? false;
      final limit = (args['limit'] as num?)?.toInt() ?? 10;

      final results = await OpenNoteTools.searchNotes(
        queryList: queryList,
        category: category,
        tags: tags,
        favoritesOnly: favoritesOnly,
        limit: limit,
      );

      final queryDesc = queryList.join('", "');

      if (results.isEmpty) {
        return SkillResult.ok(
          message: '没有找到与["$queryDesc"]相关的笔记',
          data: [],
          metadata: {'searchMode': 'text', 'queryList': queryList},
        );
      }

      return SkillResult.ok(
        message: '找到 ${results.length} 条相关笔记',
        data: results,
        referencedNotes: results,
        metadata: {
          'searchMode': 'text',
          'queryList': queryList,
          'count': results.length,
        },
      );
    } catch (e) {
      return SkillResult.error('搜索失败: $e');
    }
  }

  @override
  String generateUsageExample() {
    return '{"tool": "note_search", "args": {"queryList": ["Flutter", "状态管理"], "limit": 5}}';
  }
}
