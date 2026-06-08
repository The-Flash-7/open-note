// Copyright (c) 2026 litongshuai
// SPDX-License-Identifier: MIT OR Apache-2.0

import 'package:flutter/foundation.dart' hide Category;
import '../models/category.dart';
import '../providers/category_provider.dart';

class CategoryPathHelper {
  static const String allNotesCategoryId = 'all_notes';

  /// 生成分类路径+id映射（用于AI提示词）
  /// 例如：{"wxy1242": "学习-数学-作业", "def456": "Flutter开发"}
  static Map<String, String> generateCategoryPathsWithId(
    CategoryProvider dirProvider,
  ) {
    final directories = dirProvider.categories
        .where((d) => !d.isVirtual)
        .toList();
    final pathMap = <String, String>{};

    for (final dir in directories) {
      final path = _buildCategoryPath(dir, directories);
      if (path.isNotEmpty) {
        pathMap[dir.id] = path;
      }
    }

    return pathMap;
  }

  /// 构建单个目录的完整路径（递归）
  static String _buildCategoryPath(Category dir, List<Category> allDirs) {
    if (dir.parentId == null || dir.parentId == allNotesCategoryId) {
      return dir.name;
    }

    Category? parent;
    try {
      parent = allDirs.firstWhere((d) => d.id == dir.parentId);
    } catch (e) {
      parent = null;
    }

    if (parent == null) {
      return dir.name;
    }

    final parentPath = _buildCategoryPath(parent, allDirs);
    return '$parentPath-${dir.name}';
  }

  /// 调试：打印分类路径列表
  static void printCategoryPaths(Map<String, String> pathMap) {
    debugPrint('=== 分类路径列表 ===');
    if (pathMap.isEmpty) {
      debugPrint('暂无可选分类');
    } else {
      for (final entry in pathMap.entries) {
        debugPrint('ID: ${entry.key} → 路径: "${entry.value}"');
      }
    }
    debugPrint('==================');
  }
}
