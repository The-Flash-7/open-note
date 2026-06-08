// Copyright (c) 2026 litongshuai
// SPDX-License-Identifier: MIT OR Apache-2.0

import 'package:uuid/uuid.dart';
import '../models/category.dart';
import 'sqlite_database_service.dart';
import 'note_service.dart';

class CategoryService {
  final SQLiteDatabaseService _dbService = SQLiteDatabaseService();
  final NoteService _noteService = NoteService();
  final Uuid _uuid = const Uuid();

  static const int maxLevel = 2; // 最多3层（level 0-2）

  Future<void> init() async {
    await _dbService.init();

    // 创建"所有笔记"虚拟分类（如果不存在）
    final allNotesDir = await getCategory(allNotesCategoryId);
    if (allNotesDir == null) {
      await _dbService.saveCategory(
        Category(
          id: allNotesCategoryId,
          name: '所有笔记',
          parentId: null,
          level: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          isVirtual: true,
        ),
      );
    }
  }

  Future<void> createCategory({required String name, String? parentId}) async {
    // 验证名称长度
    if (name.isEmpty || name.length > 20) {
      throw Exception('分类名称长度应在1-20字符之间');
    }

    // 验证层级深度
    int level = 0;
    if (parentId != null && parentId != allNotesCategoryId) {
      final parent = await getCategory(parentId);
      if (parent == null) {
        throw Exception('父分类不存在');
      }
      level = parent.level + 1;
      if (level > maxLevel) {
        throw Exception('分类层级不能超过${maxLevel + 1}层');
      }
    }

    // 验证同级重名
    final categories = await getAllCategories();
    final siblings = categories.where((d) => d.parentId == parentId);
    if (siblings.any((d) => d.name == name)) {
      throw Exception('同级分类已存在同名目录');
    }

    final now = DateTime.now();
    final category = Category(
      id: _uuid.v4(),
      name: name,
      parentId: parentId,
      level: level,
      createdAt: now,
      updatedAt: now,
      isVirtual: false,
    );

    await _dbService.saveCategory(category);
  }

  Future<Category?> getCategory(String id) async {
    return await _dbService.getCategory(id);
  }

  Future<List<Category>> getAllCategories() async {
    return await _dbService.getAllCategoriesList();
  }

  Future<List<Category>> getChildCategories(String? parentId) async {
    final categories = await getAllCategories();
    return categories.where((d) => d.parentId == parentId).toList();
  }

  Future<void> updateCategoryName(String id, String newName) async {
    final category = await getCategory(id);
    if (category == null) {
      throw Exception('分类不存在');
    }

    if (category.isVirtual) {
      throw Exception('虚拟分类不能编辑');
    }

    // 验证名称长度
    if (newName.isEmpty || newName.length > 20) {
      throw Exception('分类名称长度应在1-20字符之间');
    }

    // 验证同级重名
    final categories = await getAllCategories();
    final siblings = categories.where(
      (c) => c.parentId == category.parentId && c.id != id,
    );
    if (siblings.any((c) => c.name == newName)) {
      throw Exception('同级分类已存在同名分类');
    }

    final updatedCategory = category.copyWith(
      name: newName,
      updatedAt: DateTime.now(),
    );

    await _dbService.saveCategory(updatedCategory);
  }

  Future<void> deleteCategory(String id) async {
    final category = await getCategory(id);
    if (category == null) {
      throw Exception('分类不存在');
    }

    if (category.isVirtual) {
      throw Exception('虚拟分类不能删除');
    }

    // 递归删除子分类和笔记
    final childDirs = await getChildCategories(id);
    for (final child in childDirs) {
      await deleteCategory(child.id);
    }

    // 删除该分类下的所有笔记
    await _noteService.deleteNotesByCategory(id);

    await _dbService.deleteCategory(id);
  }

  Future<bool> canMoveToParent(String categoryId, String? newParentId) async {
    final category = await getCategory(categoryId);
    if (category == null) return false;

    if (category.isVirtual) return false;

    // 如果newParentId是自身，不允许
    if (newParentId == categoryId) return false;

    // 如果newParentId是自身的子分类，不允许（防止循环引用）
    if (newParentId != null && newParentId != allNotesCategoryId) {
      final allDirs = await getAllCategories();
      final children = _getAllChildren(categoryId, allDirs);
      if (children.any((c) => c.id == newParentId)) return false;
    }

    // 验证层级深度
    int newLevel = 0;
    if (newParentId != null && newParentId != allNotesCategoryId) {
      final newParent = await getCategory(newParentId);
      if (newParent == null) return false;
      newLevel = newParent.level + 1;
      if (newLevel > maxLevel) return false;
    }

    // 验证同级重名
    final categories = await getAllCategories();
    final siblings = categories.where(
      (c) => c.parentId == newParentId && c.id != categoryId,
    );
    if (siblings.any((c) => c.name == category.name)) return false;

    return true;
  }

  Future<void> moveCategory(String id, String? newParentId) async {
    if (!await canMoveToParent(id, newParentId)) {
      throw Exception('无法移动到目标位置');
    }

    final category = await getCategory(id);
    if (category == null) return;

    int newLevel = 0;
    if (newParentId != null && newParentId != allNotesCategoryId) {
      final newParent = await getCategory(newParentId);
      if (newParent != null) {
        newLevel = newParent.level + 1;
      }
    }

    final updatedCategory = category.copyWith(
      parentId: newParentId,
      level: newLevel,
      updatedAt: DateTime.now(),
    );

    await _dbService.saveCategory(updatedCategory);

    // 更新子分类的层级
    await _updateChildrenLevels(id, newLevel);
  }

  Future<void> _updateChildrenLevels(String parentId, int parentLevel) async {
    final children = await getChildCategories(parentId);
    for (final child in children) {
      final newLevel = parentLevel + 1;
      final updated = child.copyWith(
        level: newLevel,
        updatedAt: DateTime.now(),
      );
      await _dbService.saveCategory(updated);
      await _updateChildrenLevels(child.id, newLevel);
    }
  }

  List<Category> _getAllChildren(String parentId, List<Category> allDirs) {
    final children = allDirs.where((d) => d.parentId == parentId).toList();
    final result = <Category>[];
    for (final child in children) {
      result.add(child);
      result.addAll(_getAllChildren(child.id, allDirs));
    }
    return result;
  }

  Future<void> migrateToCategories() async {
    final categories = await _noteService.getAllCategories();

    for (final category in categories) {
      // 检查是否已存在同名目录
      final categories = await getAllCategories();
      if (!categories.any(
        (c) => c.name == category.name && c.parentId == null,
      )) {
        await createCategory(name: category.name, parentId: null);
      }
    }
  }
}
