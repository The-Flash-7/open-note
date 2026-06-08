// Copyright (c) 2026 litongshuai
// SPDX-License-Identifier: MIT OR Apache-2.0

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/category.dart';
import '../services/category_service.dart';

class CategoryProvider extends ChangeNotifier {
  final CategoryService _categoryService = CategoryService();

  List<Category> _categories = [];
  Category? _selectedCategory;
  bool _isTreeViewMode = true;
  final Map<String, bool> _expandedState = {};
  bool _isLoading = false;
  String? _error;
  bool _isInitialized = false;

  List<Category> get categories => _categories;
  Category? get selectedCategory => _selectedCategory;
  bool get isTreeViewMode => _isTreeViewMode;
  Map<String, bool> get expandedState => _expandedState;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isInitialized => _isInitialized;

  void _safeNotifyListeners() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  Future<void> init() async {
    _isLoading = true;
    _safeNotifyListeners();

    await _categoryService.init();
    await loadCategories();
    await loadExpandedState();
    await loadViewMode();

    _isInitialized = true;
    _isLoading = false;
    _safeNotifyListeners();
  }

  Future<void> loadCategories() async {
    _isLoading = true;
    _error = null;
    _safeNotifyListeners();

    try {
      _categories = await _categoryService.getAllCategories();

      // 默认选中"所有笔记"
      _selectedCategory ??= _categories.firstWhere(
        (d) => d.id == allNotesCategoryId,
        orElse: () => _categories.first,
      );

      _isLoading = false;
      _safeNotifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      _safeNotifyListeners();
    }
  }

  Future<void> createCategory(String name, String? parentId) async {
    try {
      await _categoryService.createCategory(name: name, parentId: parentId);
      await loadCategories();
    } catch (e) {
      _error = e.toString();
      _safeNotifyListeners();
      rethrow;
    }
  }

  Future<void> updateCategoryName(String id, String newName) async {
    try {
      await _categoryService.updateCategoryName(id, newName);
      await loadCategories();
    } catch (e) {
      _error = e.toString();
      _safeNotifyListeners();
      rethrow;
    }
  }

  Future<void> deleteCategory(String id) async {
    try {
      await _categoryService.deleteCategory(id);

      // 如果删除的是当前选中的目录，切换到"所有笔记"
      if (_selectedCategory?.id == id) {
        _selectedCategory = _categories.firstWhere(
          (d) => d.id == allNotesCategoryId,
          orElse: () => _categories.first,
        );
      }

      await loadCategories();
    } catch (e) {
      _error = e.toString();
      _safeNotifyListeners();
      rethrow;
    }
  }

  Future<void> moveCategory(String id, String? newParentId) async {
    try {
      await _categoryService.moveCategory(id, newParentId);
      await loadCategories();
    } catch (e) {
      _error = e.toString();
      _safeNotifyListeners();
      rethrow;
    }
  }

  void selectCategory(Category? directory) {
    _selectedCategory = directory;
    _safeNotifyListeners();
  }

  void toggleViewMode() {
    _isTreeViewMode = !_isTreeViewMode;
    saveViewMode(_isTreeViewMode);
    _safeNotifyListeners();
  }

  void toggleExpanded(String categoryId) {
    _expandedState[categoryId] = !(_expandedState[categoryId] ?? false);
    saveExpandedState(_expandedState);
    _safeNotifyListeners();
  }

  bool isExpanded(String categoryId) {
    return _expandedState[categoryId] ?? false;
  }

  List<Category> getChildCategories(String? parentId) {
    return _categories.where((d) => d.parentId == parentId).toList();
  }

  List<String> getAllDescendantCategoryIds(String categoryId) {
    final ids = <String>[categoryId];
    final children = getChildCategories(categoryId);
    for (final child in children) {
      ids.addAll(getAllDescendantCategoryIds(child.id));
    }
    return ids;
  }

  List<Category> getRootCategories() {
    // "所有笔记" + 所有parentId为null或allNotesCategoryId的目录
    final allNotes = _categories.where((d) => d.id == allNotesCategoryId);
    final topLevel = _categories
        .where((d) => d.parentId == null || d.parentId == allNotesCategoryId)
        .toList();

    return [...allNotes, ...topLevel.where((d) => d.id != allNotesCategoryId)];
  }

  Future<void> loadExpandedState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final expandedKeys = prefs.getKeys().where(
        (k) => k.startsWith('cat_exp_'),
      );

      for (final key in expandedKeys) {
        final dirId = key.replaceFirst('cat_exp_', '');
        _expandedState[dirId] = prefs.getBool(key) ?? false;
      }
    } catch (e) {
      debugPrint('Load expanded state error: $e');
    }
  }

  Future<void> saveExpandedState(Map<String, bool> state) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      for (final entry in state.entries) {
        await prefs.setBool('dir_exp_${entry.key}', entry.value);
      }
    } catch (e) {
      debugPrint('Save expanded state error: $e');
    }
  }

  Future<void> loadViewMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isTreeViewMode = prefs.getBool('cat_view_mode') ?? true;
    } catch (e) {
      debugPrint('Load view mode error: $e');
    }
  }

  Future<void> saveViewMode(bool isTree) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('cat_view_mode', isTree);
    } catch (e) {
      debugPrint('Save view mode error: $e');
    }
  }

  void clearError() {
    _error = null;
    _safeNotifyListeners();
  }
}
