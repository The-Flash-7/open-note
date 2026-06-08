// Copyright (c) 2026 litongshuai
// SPDX-License-Identifier: MIT OR Apache-2.0

import '../../../utils/cancellation_token.dart';
import '../../skills/models/skill_result.dart';
import '../../skills/skill_base.dart';
import '../../open_note_tools.dart';
import '../../../providers/category_provider.dart';
import '../../../utils/category_path_helper.dart';

class NoteListCategoriesSkill extends Skill {
  CategoryProvider? _categoryProvider;

  set categoryProvider(CategoryProvider? provider) {
    _categoryProvider = provider;
  }

  NoteListCategoriesSkill()
    : super(
        id: 'note_list_categories',
        name: '列出所有分类',
        description:
            '获取系统中所有笔记分类及其笔记数量，返回分类ID、名称、路径、包含笔记数量。创建笔记时如需设置分类请使用分类ID作为参数',
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

      // 统计每个分类ID的笔记数量
      final noteCountByCategoryId = <String, int>{};
      for (final note in allNotes) {
        final catId = note.category ?? CategoryPathHelper.allNotesCategoryId;
        noteCountByCategoryId[catId] = (noteCountByCategoryId[catId] ?? 0) + 1;
      }

      final categoryList = <Map<String, dynamic>>[];
      int uncategorizedCount = 0;

      if (_categoryProvider != null) {
        final categories = _categoryProvider!.categories;
        final allCategories = categories.where((c) => !c.isVirtual).toList();

        // 构建 ID → 路径映射
        final pathMap = CategoryPathHelper.generateCategoryPathsWithId(
          _categoryProvider!,
        );

        for (final cat in allCategories) {
          final count = noteCountByCategoryId[cat.id] ?? 0;
          categoryList.add({
            'id': cat.id,
            'name': cat.name,
            'path': pathMap[cat.id] ?? cat.name,
            'count': count,
          });
        }

        // 处理"未分类"（笔记的 category 字段为 null 的情况）
      } else {
        // 如果没有 CategoryProvider，只从笔记中提取
        for (final entry in noteCountByCategoryId.entries) {
          final catId = entry.key;
          if (catId == CategoryPathHelper.allNotesCategoryId) continue;
          categoryList.add({
            'id': catId,
            'name': catId,
            'path': catId,
            'count': entry.value,
          });
        }
      }

      if (categoryList.isEmpty) {
        return SkillResult.ok(
          message: '系统中没有任何笔记分类',
          metadata: {'categories': []},
        );
      }

      // 按数量降序排序
      categoryList.sort(
        (a, b) => (b['count'] as int).compareTo(a['count'] as int),
      );

      final messageBuffer = StringBuffer();
      messageBuffer.writeln('系统共有 ${categoryList.length} 个分类：');
      messageBuffer.writeln('（以下为内部数据，回复用户时请使用分类路径，不要展示ID）');
      for (final cat in categoryList) {
        messageBuffer.writeln(
          '- [内部ID: ${cat['id']}] ${cat['path']}: ${cat['count']} 篇笔记',
        );
      }
      if (uncategorizedCount > 0) {
        messageBuffer.writeln(
          '\n另有 $uncategorizedCount 篇未分类笔记（创建笔记时不指定分类即可归入未分类）',
        );
      }
      messageBuffer.writeln('\n提示：创建笔记时，category 参数请使用分类ID（内部ID）');
      messageBuffer.writeln('注意：回复用户时，请使用分类路径（如 工作-项目A），不要展示内部ID');

      return SkillResult.ok(
        message: messageBuffer.toString().trim(),
        metadata: {'categories': categoryList},
      );
    } catch (e) {
      return SkillResult.error('获取分类列表失败: $e');
    }
  }

  @override
  String generateUsageExample() {
    return '{"tool": "note_list_categories", "args": {}}';
  }
}
