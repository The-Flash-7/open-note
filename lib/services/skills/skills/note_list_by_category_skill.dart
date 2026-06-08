// Copyright (c) 2026 litongshuai
// SPDX-License-Identifier: MIT OR Apache-2.0

import '../../../utils/cancellation_token.dart';
import '../../skills/models/skill_parameter.dart';
import '../../skills/models/skill_result.dart';
import '../../skills/skill_base.dart';
import '../../open_note_tools.dart';
import '../../../providers/category_provider.dart';

class NoteListByCategorySkill extends Skill {
  CategoryProvider? _categoryProvider;

  set categoryProvider(CategoryProvider? provider) {
    _categoryProvider = provider;
  }

  NoteListByCategorySkill()
    : super(
        id: 'note_list_by_category',
        name: '按分类列出笔记',
        description: '列出指定分类下的所有笔记，支持通过分类ID或分类名称查找',
        parameters: [
          const SkillParameter(
            name: 'categoryId',
            type: 'string',
            description: '分类ID（可调用 note_list_categories 获取可用分类ID）',
            required: false,
          ),
          const SkillParameter(
            name: 'categoryName',
            type: 'string',
            description: '分类名称（与 categoryId 二选一，如果同时提供则优先使用 categoryId）',
            required: false,
          ),
          const SkillParameter(
            name: 'limit',
            type: 'number',
            description: '返回数量（默认 20）',
            required: false,
            defaultValue: 20,
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
      String? categoryId = args['categoryId'] as String?;
      final categoryName = args['categoryName'] as String?;
      final limit = (args['limit'] as num?)?.toInt() ?? 20;

      // 优先使用 categoryId，如果没有则尝试通过 categoryName 查找
      if ((categoryId == null || categoryId.isEmpty) &&
          categoryName != null &&
          categoryName.isNotEmpty) {
        if (_categoryProvider == null) {
          return SkillResult.error('无法通过分类名称查找，分类服务未初始化');
        }

        // 通过名称查找对应的分类 ID
        final matchedCategory = _categoryProvider!.categories.firstWhere(
          (c) => c.name == categoryName,
          orElse: () => throw Exception('not found'),
        );
        categoryId = matchedCategory.id;
      }

      if (categoryId == null || categoryId.isEmpty) {
        return SkillResult.error('请提供分类ID (categoryId) 或分类名称 (categoryName)');
      }

      final notes = await OpenNoteTools.searchNotes(
        category: categoryId,
        limit: limit,
      );

      final displayName = categoryName ?? categoryId;

      if (notes.isEmpty) {
        return SkillResult.ok(
          message: '分类"$displayName"下没有笔记',
          referencedNotes: [],
        );
      }

      final titleList = notes.map((n) => n.title).toList();
      return SkillResult.ok(
        message:
            '分类"$displayName"下有 ${notes.length} 篇笔记：\n${titleList.map((t) => '• $t').join('\n')}',
        referencedNotes: notes,
        metadata: {
          'categoryId': categoryId,
          'categoryName': categoryName,
          'count': notes.length,
          'titles': titleList,
        },
      );
    } catch (e) {
      if (e.toString().contains('not found')) {
        return SkillResult.error('未找到名称为"${args['categoryName']}"的分类');
      }
      return SkillResult.error('列出分类笔记失败: $e');
    }
  }

  @override
  String generateUsageExample() {
    return '{"tool": "note_list_by_category", "args": {"categoryId": "cat_123", "limit": 10}}';
  }
}
