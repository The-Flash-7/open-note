// Copyright (c) 2026 litongshuai
// SPDX-License-Identifier: MIT OR Apache-2.0

import 'package:flutter/foundation.dart';
import '../models/tag.dart';
import '../services/sqlite_database_service.dart';
import 'package:uuid/uuid.dart';

class TagsProvider extends ChangeNotifier {
  final SQLiteDatabaseService _dbService = SQLiteDatabaseService();
  final Uuid _uuid = const Uuid();

  List<Tag> _tags = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Tag> get tags => _tags;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadTags() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _tags = await _dbService.getAllTagsWithDetails();
    } catch (e) {
      _errorMessage = '加载标签失败: $e';
      debugPrint('Load tags error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Tag?> createTag(String name) async {
    if (name.trim().isEmpty) {
      _errorMessage = '标签名称不能为空';
      notifyListeners();
      return null;
    }

    final existingTag = await _dbService.getTagByName(name.trim());
    if (existingTag != null) {
      _errorMessage = '标签已存在';
      notifyListeners();
      return existingTag;
    }

    final tag = Tag(
      id: _uuid.v4(),
      name: name.trim(),
      createdAt: DateTime.now(),
    );

    try {
      await _dbService.saveTag(tag);
      _tags.insert(0, tag);
      notifyListeners();
      return tag;
    } catch (e) {
      _errorMessage = '创建标签失败: $e';
      debugPrint('Create tag error: $e');
      notifyListeners();
      return null;
    }
  }

  Future<void> updateTag(Tag tag) async {
    try {
      await _dbService.saveTag(tag);
      final index = _tags.indexWhere((t) => t.id == tag.id);
      if (index >= 0) {
        _tags[index] = tag;
      }
      notifyListeners();
    } catch (e) {
      _errorMessage = '更新标签失败: $e';
      debugPrint('Update tag error: $e');
      notifyListeners();
    }
  }

  Future<void> deleteTag(String id) async {
    try {
      await _dbService.deleteTag(id);
      _tags.removeWhere((tag) => tag.id == id);
      notifyListeners();
    } catch (e) {
      _errorMessage = '删除标签失败: $e';
      debugPrint('Delete tag error: $e');
      notifyListeners();
    }
  }

  Future<void> incrementTagUsage(String tagName) async {
    final tag = await _dbService.getTagByName(tagName);
    if (tag != null) {
      final updatedTag = tag.copyWith(usageCount: tag.usageCount + 1);
      await updateTag(updatedTag);
    }
  }

  Future<void> decrementTagUsage(String tagName) async {
    final tag = await _dbService.getTagByName(tagName);
    if (tag != null && tag.usageCount > 0) {
      final updatedTag = tag.copyWith(usageCount: tag.usageCount - 1);
      await updateTag(updatedTag);
    }
  }

  Tag? getTagByName(String name) {
    return _tags.where((tag) => tag.name == name).firstOrNull;
  }

  List<Tag> getTagsByNames(List<String> names) {
    return names.map((name) => getTagByName(name)).whereType<Tag>().toList();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
