// Copyright (c) 2026 litongshuai
// SPDX-License-Identifier: MIT OR Apache-2.0

import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import '../models/note.dart';
import '../models/note_preview.dart';
import '../models/category.dart' as cat;
import '../services/note_service.dart';
import '../services/ai_service.dart';
import '../services/file_import_service.dart';
import '../services/cici_agent.dart';
import '../services/embedding_service.dart';
import '../services/vector_store.dart';
import '../services/open_note_tools.dart';
import '../services/skills/skill_registry.dart';
import '../services/skills/skill_executor.dart';
import '../services/skills/skills/note_search_skill.dart';
import '../services/skills/skills/note_vector_search_skill.dart';
import '../services/skills/skills/note_create_skill.dart';
import '../services/skills/skills/note_edit_info_skill.dart';
import '../services/skills/skills/note_delete_skill.dart';
import '../services/skills/skills/note_read_skill.dart';
import '../services/skills/skills/note_qa_skill.dart';
import '../services/skills/skills/note_summarize_skill.dart';
import '../services/skills/skills/note_list_recent_skill.dart';
import '../services/skills/skills/note_list_by_category_skill.dart';
import '../services/skills/skills/note_extract_keywords_skill.dart';
import '../services/skills/skills/note_rewrite_skill.dart';
import '../services/skills/skills/note_merge_skill.dart';
import '../services/skills/skills/note_search_by_title_skill.dart';
import '../services/skills/skills/note_list_categories_skill.dart';
import '../services/skills/skills/note_list_tags_skill.dart';
import '../services/skills/skills/note_get_format_skill.dart';
import '../services/skills/skills/note_create_from_url_skill.dart';
import '../services/skills/skills/note_edit_content_skill.dart';
import '../services/skills/skills/note_open_skill.dart';
import 'category_provider.dart';
import '../providers/memory_settings_provider.dart';
import '../l10n/strings.g.dart';

class NotesProvider extends ChangeNotifier {
  final NoteService _noteService = NoteService();
  AIService? _aiService;
  String? _currentEditingNoteId;

  late final EmbeddingService _embeddingService;
  late final VectorStore _vectorStore;
  late final SkillRegistry _skillRegistry;
  late final SkillExecutor _skillExecutor;
  late final CiciAgent _ciciAgent;
  bool _agentInitialized = false;
  String? _knowledgeBaseModelPath;
  CategoryProvider? _pendingCategoryProvider;
  MemorySettingsProvider? _memorySettingsProvider;
  AppLocale _userLanguage = AppLocale.zh;

  void setUserLanguage(AppLocale locale) {
    _userLanguage = locale;
    // 如果 Agent 已初始化，动态更新其语言（无需重新初始化）
    if (_agentInitialized) {
      _ciciAgent.userLanguage = locale;
    }
  }

  void setAIService(AIService service) {
    _aiService = service;
    if (!_agentInitialized) {
      _initializeAgent();
    }
  }

  /// 设置分类 Provider（用于 note_list_categories 工具）
  void setCategoryProvider(CategoryProvider provider) {
    _pendingCategoryProvider = provider;
    if (_agentInitialized) {
      _applyCategoryProvider(provider);
    }
  }

  void setMemorySettingsProvider(MemorySettingsProvider provider) {
    _memorySettingsProvider = provider;
  }

  void _applyCategoryProvider(CategoryProvider provider) {
    final listCategoriesSkill = _skillRegistry.getSkill('note_list_categories');
    if (listCategoriesSkill is NoteListCategoriesSkill) {
      listCategoriesSkill.categoryProvider = provider;
    }

    final listByCategorySkill = _skillRegistry.getSkill(
      'note_list_by_category',
    );
    if (listByCategorySkill is NoteListByCategorySkill) {
      listByCategorySkill.categoryProvider = provider;
    }

    final createFromUrlSkill = _skillRegistry.getSkill('note_create_from_url');
    if (createFromUrlSkill is NoteCreateFromUrlSkill) {
      createFromUrlSkill.categoryProvider = provider;
    }
  }

  void setKnowledgeBaseModelPath(
    String? path, {
    String serviceUrl = 'http://127.0.0.1:8765',
  }) {
    if (_knowledgeBaseModelPath == path) return;

    _knowledgeBaseModelPath = path;

    // 确保 Agent 已初始化（如果尚未初始化则触发初始化）
    if (!_agentInitialized) {
      _initializeAgent();
    }

    if (_agentInitialized && path != null) {
      _embeddingService.initializeLocalModel(
        modelPath: path,
        serviceUrl: serviceUrl,
      );
      debugPrint('NotesProvider: EmbeddingService 已切换到本地模型模式');
    }
  }

  /// 配置 EmbeddingService 使用外部 AI API
  void configureEmbeddingForAPI() {
    if (!_agentInitialized) return;
    if (_aiService?.currentConfig == null) return;

    _embeddingService.setConfig(_aiService!.currentConfig!);
    debugPrint('NotesProvider: EmbeddingService 已切换到 API 模式');
  }

  int _chunkSize = 500;
  int _chunkOverlap = 50;

  void setChunkConfig(int chunkSize, int chunkOverlap) {
    _chunkSize = chunkSize;
    _chunkOverlap = chunkOverlap;
  }

  void _initializeAgent() {
    if (_aiService == null || !_aiService!.hasConfig()) return;

    _embeddingService = EmbeddingService();

    // 注意：这里不立即配置 EmbeddingService
    // 等待 setKnowledgeBaseModelPath 或显式调用 configureForAPI 后再配置

    _vectorStore = VectorStore();

    _skillRegistry = SkillRegistry();
    _skillRegistry.register(NoteSearchSkill());
    _skillRegistry.register(NoteVectorSearchSkill(vectorStore: _vectorStore));
    _skillRegistry.register(NoteCreateSkill(aiService: _aiService));
    _skillRegistry.register(NoteEditInfoSkill());
    _skillRegistry.register(NoteDeleteSkill());
    _skillRegistry.register(NoteReadSkill());
    _skillRegistry.register(NoteQASkill(aiService: _aiService));
    _skillRegistry.register(NoteSummarizeSkill(aiService: _aiService));
    _skillRegistry.register(NoteListRecentSkill());
    _skillRegistry.register(NoteListByCategorySkill());
    _skillRegistry.register(NoteExtractKeywordsSkill(aiService: _aiService));
    _skillRegistry.register(NoteRewriteSkill(aiService: _aiService));
    _skillRegistry.register(NoteMergeSkill(aiService: _aiService));

    _skillRegistry.register(NoteSearchByTitleSkill());
    _skillRegistry.register(NoteListCategoriesSkill());
    _skillRegistry.register(NoteListTagsSkill());
    _skillRegistry.register(NoteGetFormatSkill());
    _skillRegistry.register(NoteCreateFromUrlSkill(aiService: _aiService));
    _skillRegistry.register(NoteEditContentSkill());
    _skillRegistry.register(NoteOpenSkill());

    _skillExecutor = SkillExecutor(_skillRegistry);

    OpenNoteTools.initialize(
      notesProvider: this,
      aiService: _aiService!,
      vectorStore: _vectorStore,
    );

    _ciciAgent = CiciAgent(
      aiService: _aiService!,
      skillRegistry: _skillRegistry,
      skillExecutor: _skillExecutor,
      vectorStore: _vectorStore,
      memorySettings: _memorySettingsProvider!,
      userLanguage: _userLanguage,
    );

    _agentInitialized = true;

    // 应用缓存的 CategoryProvider
    if (_pendingCategoryProvider != null) {
      _applyCategoryProvider(_pendingCategoryProvider!);
    }
  }

  CiciAgent get ciciAgent {
    if (!_agentInitialized) {
      _initializeAgent();
    }
    return _ciciAgent;
  }

  VectorStore get vectorStore => _vectorStore;

  void setCurrentEditingNote(String? noteId) {
    _currentEditingNoteId = noteId;
  }

  String? get currentEditingNoteId => _currentEditingNoteId;

  bool _hasAIConfig() => _aiService != null && _aiService!.hasConfig();

  bool canGenerateSummary(String noteId) {
    return !_isGeneratingSummary || _currentSummaryNoteId != noteId;
  }

  bool canGenerateSuggestions(String noteId) {
    return !_isGeneratingSuggestions || _currentSuggestionsNoteId != noteId;
  }

  bool isGeneratingSummaryForNote(String noteId) {
    return _isGeneratingSummary && _currentSummaryNoteId == noteId;
  }

  bool isGeneratingSuggestionsForNote(String noteId) {
    return _isGeneratingSuggestions && _currentSuggestionsNoteId == noteId;
  }

  String extractPlainText(String content) {
    if (content.isEmpty) return '';
    try {
      final deltaJson = jsonDecode(content);
      if (deltaJson is List) {
        final buffer = StringBuffer();
        for (final item in deltaJson) {
          if (item is Map && item['insert'] is String) {
            buffer.write(item['insert']);
          }
        }
        return buffer.toString().trim();
      }
    } catch (e) {
      return content;
    }
    return content;
  }

  List<NotePreview> _previews = [];
  List<NotePreview> _filteredPreviews = [];
  final Map<String, Note> _fullNotesCache = {}; // 懒加载的完整笔记缓存
  List<Note> _trashNotes = []; // 回收站缓存
  Note? _selectedNote;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _isGeneratingSummary = false;
  bool _isGeneratingSuggestions = false;
  String? _currentSummaryNoteId;
  String? _currentSuggestionsNoteId;
  String? _suggestedCategory; // 分类ID（用于存储）
  String? _suggestedCategoryPath; // 分类路径（用于显示）
  List<String> _suggestedTags = [];
  String _searchQuery = '';
  String? _selectedCategory;
  String? _selectedTag;
  bool _showFavoritesOnly = false;

  // 分页配置
  static const int _pageSize = 50;
  bool _hasMore = true;

  // 对外暴露的接口
  List<NotePreview> get previews => _filteredPreviews;
  List<NotePreview> get allPreviews => _previews;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;
  bool get isGeneratingSummary => _isGeneratingSummary;
  bool get isGeneratingSuggestions => _isGeneratingSuggestions;
  String? get suggestedCategory => _suggestedCategory;
  String? get suggestedCategoryPath => _suggestedCategoryPath;
  List<String> get suggestedTags => _suggestedTags;
  String get searchQuery => _searchQuery;
  String? get selectedCategory => _selectedCategory;
  String? get selectedTag => _selectedTag;
  bool get showFavoritesOnly => _showFavoritesOnly;

  // 向后兼容：保留原有的 notes 和 allNotes getter
  List<Note> get notes => _filteredPreviews
      .map((p) => _fullNotesCache[p.id] ?? _previewToNoteStub(p))
      .toList();
  List<Note> get allNotes => _previews
      .map((p) => _fullNotesCache[p.id] ?? _previewToNoteStub(p))
      .toList();
  Note? get selectedNote => _selectedNote;

  /// 将 NotePreview 转换为 Note 的占位对象（content 为空）
  Note _previewToNoteStub(NotePreview preview) {
    return Note(
      id: preview.id,
      title: preview.title,
      content: '', // 占位，实际内容需要懒加载
      format: preview.format,
      language: preview.language,
      summary: preview.summary,
      keywords: [],
      category: preview.category,
      tags: preview.tags,
      sourceUrl: preview.sourceUrl,
      sourceType: NoteSourceType.manual,
      createdAt: preview.updatedAt,
      updatedAt: preview.updatedAt,
      wordCount: preview.wordCount,
      isFavorite: preview.isFavorite,
      isDeleted: preview.isDeleted,
    );
  }

  /// 获取完整笔记（懒加载）
  Future<Note?> getFullNote(String id) async {
    if (_fullNotesCache.containsKey(id)) {
      return _fullNotesCache[id];
    }

    final note = await _noteService.getNoteById(id);
    if (note != null) {
      _fullNotesCache[id] = note;
    }
    return note;
  }

  /// 加载更多笔记（从数据库分页加载）
  Future<void> loadMoreNotes() async {
    if (!_hasMore || _isLoadingMore) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      final newPreviews = await _noteService.getNotePreviewsPaginated(
        offset: _previews.length,
        limit: _pageSize,
      );

      if (newPreviews.isNotEmpty) {
        _previews.addAll(newPreviews);
        _hasMore = newPreviews.length >= _pageSize;
        _applyFilters();
      } else {
        _hasMore = false;
      }
    } catch (e) {
      debugPrint('Load more notes error: $e');
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  /// 重置分页（重新从头加载）
  void resetPagination() {
    _hasMore = _previews.length >= _pageSize;
  }

  Future<void> loadNotes() async {
    _isLoading = true;
    notifyListeners();

    try {
      // 初始只加载一页
      _previews = await _noteService.getNotePreviewsPaginated(
        offset: 0,
        limit: _pageSize,
      );
      resetPagination();

      // 同时加载回收站数据
      _trashNotes = await _noteService.getTrashNotes();

      _applyFilters();
    } catch (e) {
      debugPrint('Load notes error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Note?> getNoteById(String id) async {
    return await _noteService.getNoteById(id);
  }

  Future<Note?> getNoteByIdIncludingDeleted(String id) async {
    return await _noteService.getNoteByIdIncludingDeleted(id);
  }

  Future<String?> createNote({
    required String title,
    required String content,
    String? sourceUrl,
    NoteSourceType sourceType = NoteSourceType.manual,
    NoteFormat format = NoteFormat.markdown,
    String? language,
    List<String>? tags,
    String? category,
    bool autoGenerateSummary = false,
    String? preGeneratedSummary,
    List<String>? preGeneratedKeywords,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      String? summary;
      List<String>? keywords;

      if (preGeneratedSummary != null && preGeneratedKeywords != null) {
        summary = preGeneratedSummary;
        keywords = preGeneratedKeywords;
      } else if (autoGenerateSummary && _hasAIConfig() && content.isNotEmpty) {
        try {
          final plainText = extractPlainText(content);
          if (plainText.isNotEmpty) {
            final result = await _aiService!.generateSummaryAndKeywords(
              plainText,
            );
            summary = result['summary'];
            keywords = result['keywords'];
          }
        } catch (e) {
          debugPrint('Generate summary error: $e');
        }
      }

      final noteId = await _noteService.createNote(
        title: title,
        content: content,
        sourceUrl: sourceUrl,
        sourceType: sourceType,
        format: format,
        language: language,
        tags: tags,
        category: category,
        summary: summary,
        keywords: keywords,
      );

      await loadNotes();

      // 如果知识库已启用且向量服务可用，自动为新笔记建索引
      if (_knowledgeBaseModelPath != null &&
          _vectorStore.isAvailable &&
          content.isNotEmpty) {
        unawaited(_indexNoteInBackground(noteId, title, format));
      }

      return noteId;
    } catch (e) {
      debugPrint('Create note error: $e');
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> importNoteFromFile(File file) async {
    _isLoading = true;
    notifyListeners();

    try {
      final importService = FileImportService();
      final result = await importService.importFromFile(file);

      if (result == null) {
        debugPrint('Import failed: unsupported file format');
        return null;
      }

      final noteId = await createNote(
        title: result.title,
        content: result.content,
        format: result.format,
        language: result.language,
        sourceType: NoteSourceType.file,
      );

      return noteId;
    } catch (e) {
      debugPrint('Import file error: $e');
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateNote(Note note, {bool generateSummary = false}) async {
    if (generateSummary) {
      if (!canGenerateSummary(note.id)) {
        debugPrint('摘要生成已在进行中，跳过重复请求');
        return;
      }

      _isGeneratingSummary = true;
      _currentSummaryNoteId = note.id;
      notifyListeners();
    }

    try {
      String? summary = note.summary;
      List<String>? keywords = note.keywords;

      if (generateSummary && _hasAIConfig() && note.content.isNotEmpty) {
        try {
          final plainText = extractPlainText(note.content);
          if (plainText.isNotEmpty) {
            final result = await _aiService!.generateSummaryAndKeywords(
              plainText,
            );
            summary = result['summary'];
            keywords = result['keywords'];
          }
        } on FormatException catch (e) {
          debugPrint('AI返回格式错误: $e');
          throw Exception('AI生成失败：返回格式不符合预期');
        } catch (e) {
          debugPrint('Generate summary error: $e');
        }
      }

      final updatedNote = note.copyWith(summary: summary, keywords: keywords);

      await _noteService.updateNote(updatedNote);
      _updateNoteInList(updatedNote);

      // 如果知识库已启用且向量服务可用，自动更新该笔记的索引
      if (_knowledgeBaseModelPath != null &&
          _vectorStore.isAvailable &&
          updatedNote.content.isNotEmpty) {
        unawaited(
          _indexNoteInBackground(
            updatedNote.id,
            updatedNote.title,
            updatedNote.format,
          ),
        );
      }
    } catch (e) {
      debugPrint('Update note error: $e');
    } finally {
      if (generateSummary) {
        _isGeneratingSummary = false;
        _currentSummaryNoteId = null;
        notifyListeners();
      }
    }
  }

  void _updateNoteInList(Note updatedNote) {
    final index = _previews.indexWhere((p) => p.id == updatedNote.id);
    if (index != -1) {
      _previews[index] = NotePreview(
        id: updatedNote.id,
        title: updatedNote.title,
        summary: updatedNote.summary,
        contentPreview: NotePreview.extractContentPreview(updatedNote.content),
        updatedAt: updatedNote.updatedAt,
        isFavorite: updatedNote.isFavorite,
        category: updatedNote.category,
        tags: updatedNote.tags,
        wordCount: updatedNote.wordCount,
        format: updatedNote.format,
        isDeleted: updatedNote.isDeleted,
        language: updatedNote.language,
        sourceUrl: updatedNote.sourceUrl,
      );
      _fullNotesCache[updatedNote.id] = updatedNote;
      _applyFilters();
      notifyListeners();
    }
  }

  Future<void> deleteNote(String id) async {
    try {
      final note = await getNoteById(id);
      if (note != null) {
        final deletedNote = note.copyWith(
          isDeleted: true,
          deletedAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await _noteService.updateNote(deletedNote);
        _previews.removeWhere((p) => p.id == id);
        _fullNotesCache.remove(id);
        _trashNotes.add(deletedNote);
        _applyFilters();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Delete note error: $e');
    }
  }

  /// 同步获取回收站笔记（从缓存）
  List<Note> getTrashNotes() {
    return _trashNotes;
  }

  /// 异步刷新回收站数据
  Future<void> refreshTrashNotes() async {
    _trashNotes = await _noteService.getTrashNotes();
  }

  Future<void> restoreFromTrash(String id) async {
    try {
      final note = await getNoteByIdIncludingDeleted(id);
      if (note != null && note.isDeleted) {
        final restoredNote = note.copyWith(
          isDeleted: false,
          deletedAt: null,
          updatedAt: DateTime.now(),
        );
        await _noteService.updateNote(restoredNote);
        _trashNotes.removeWhere((n) => n.id == id);
        await loadNotes();
        _applyFilters();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Restore from trash error: $e');
    }
  }

  Future<void> permanentlyDelete(String id) async {
    try {
      await _noteService.hardDeleteNote(id);
      _previews.removeWhere((p) => p.id == id);
      _fullNotesCache.remove(id);
      _trashNotes.removeWhere((n) => n.id == id);
      await _vectorStore.removeNote(id);
      _applyFilters();
      notifyListeners();
    } catch (e) {
      debugPrint('Permanently delete error: $e');
    }
  }

  Future<void> emptyTrash() async {
    try {
      for (final note in _trashNotes) {
        await _noteService.hardDeleteNote(note.id);
        await _vectorStore.removeNote(note.id);
      }
      _trashNotes.clear();
      _applyFilters();
      notifyListeners();
    } catch (e) {
      debugPrint('Empty trash error: $e');
    }
  }

  Future<void> cleanExpiredTrash() async {
    try {
      final now = DateTime.now();
      final expiredNotes = _trashNotes.where((note) {
        final deletedAt = note.deletedAt ?? note.updatedAt;
        return now.difference(deletedAt).inDays >= 30;
      }).toList();

      for (final note in expiredNotes) {
        await _noteService.hardDeleteNote(note.id);
        await _vectorStore.removeNote(note.id);
      }

      if (expiredNotes.isNotEmpty) {
        _trashNotes.removeWhere((n) => expiredNotes.any((e) => e.id == n.id));
        _applyFilters();
        notifyListeners();
        debugPrint('Cleaned ${expiredNotes.length} expired notes from trash');
      }
    } catch (e) {
      debugPrint('Clean expired trash error: $e');
    }
  }

  Future<void> toggleFavorite(String id) async {
    try {
      await _noteService.toggleFavorite(id);
      await loadNotes();
    } catch (e) {
      debugPrint('Toggle favorite error: $e');
    }
  }

  void searchNotes(String query) {
    _searchQuery = query;
    _applyFilters();
    notifyListeners();
  }

  void filterByCategory(String? category) {
    _selectedCategory = category;
    _applyFilters();
    notifyListeners();
  }

  void filterByTag(String? tag) {
    _selectedTag = tag;
    _applyFilters();
    notifyListeners();
  }

  void toggleFavoritesFilter() {
    _showFavoritesOnly = !_showFavoritesOnly;
    _applyFilters();
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _selectedCategory = null;
    _selectedTag = null;
    _showFavoritesOnly = false;
    _applyFilters();
    notifyListeners();
  }

  void selectNote(Note? note) {
    _selectedNote = note;
    notifyListeners();
  }

  Future<void> generateSuggestions(
    String title,
    String content,
    Map<String, String> categories,
  ) async {
    if (_aiService == null) {
      debugPrint('AI服务未初始化');
      return;
    }

    if (_currentEditingNoteId != null &&
        !canGenerateSuggestions(_currentEditingNoteId!)) {
      debugPrint('智能建议生成已在进行中，跳过重复请求');
      return;
    }

    _isGeneratingSuggestions = true;
    _currentSuggestionsNoteId = _currentEditingNoteId;
    notifyListeners();

    try {
      final existingTags = await getAllTags();

      final result = await _aiService!.generateCategoryAndTags(
        title,
        content,
        existingTags,
        categories, // 传递分类列表
      );

      _suggestedCategory = result['category'];
      _suggestedCategoryPath = result['categoryPath'];
      _suggestedTags = result['tags'];
    } on FormatException catch (e) {
      debugPrint('AI返回格式错误: $e');
      _suggestedCategory = null;
      _suggestedTags = [];
    } catch (e) {
      debugPrint('Generate suggestions error: $e');
      _suggestedCategory = null;
      _suggestedTags = [];
    } finally {
      _isGeneratingSuggestions = false;
      _currentSuggestionsNoteId = null;
      notifyListeners();
    }
  }

  void clearSuggestions() {
    _suggestedCategory = null;
    _suggestedCategoryPath = null;
    _suggestedTags = [];
    notifyListeners();
  }

  void applySuggestedCategory() {
    if (_suggestedCategory != null && _selectedNote != null) {
      final updatedNote = _selectedNote!.copyWith(category: _suggestedCategory);
      updateNote(updatedNote);
    }
  }

  void applySuggestedTags(List<String> additionalTags) {
    if (_selectedNote != null) {
      final allTags = [..._selectedNote!.tags, ...additionalTags];
      final uniqueTags = allTags.toSet().toList();
      final updatedNote = _selectedNote!.copyWith(tags: uniqueTags);
      updateNote(updatedNote);
    }
  }

  void _applyFilters() {
    List<NotePreview> filtered = List.from(_previews);

    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((p) {
        return p.title.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    if (_selectedCategory != null) {
      filtered = filtered
          .where((p) => p.category == _selectedCategory)
          .toList();
    }

    if (_selectedTag != null) {
      filtered = filtered.where((p) => p.tags.contains(_selectedTag)).toList();
    }

    if (_showFavoritesOnly) {
      filtered = filtered.where((p) => p.isFavorite).toList();
    }

    // 过滤已删除的笔记（回收站笔记不在主列表显示）
    filtered = filtered.where((p) => !p.isDeleted).toList();

    _filteredPreviews = filtered;
  }

  Future<List<cat.Category>> getAllCategories() async {
    return await _noteService.getAllCategories();
  }

  Future<List<String>> getAllTags() async {
    return await _noteService.getAllTags();
  }

  Future<void> restoreNote(Note note) async {
    try {
      await _noteService.createNote(
        title: note.title,
        content: note.content,
        sourceUrl: note.sourceUrl,
        sourceType: note.sourceType,
        tags: note.tags,
        category: note.category,
        summary: note.summary,
        keywords: note.keywords,
        id: note.id,
        createdAt: note.createdAt,
        updatedAt: DateTime.now(),
        isFavorite: note.isFavorite,
      );

      await loadNotes();
      notifyListeners();
    } catch (e) {
      debugPrint('Restore note error: $e');
    }
  }

  /// 后台索引笔记（不阻塞主流程）
  Future<void> _indexNoteInBackground(
    String noteId,
    String title,
    NoteFormat format,
  ) async {
    try {
      final note = await getNoteById(noteId);
      if (note == null || note.content.isEmpty) return;

      String contentToIndex = note.content;
      if (format == NoteFormat.richText) {
        // 富文本需要先提取纯文本
        try {
          final delta = jsonDecode(note.content) as List;
          final buffer = StringBuffer();
          for (final item in delta) {
            if (item is Map && item['insert'] is String) {
              buffer.write(item['insert']);
            }
          }
          contentToIndex = buffer.toString().trim();
        } catch (e) {
          debugPrint('NotesProvider: 富文本提取失败: $e');
        }
      }

      if (contentToIndex.isEmpty) return;

      await _vectorStore.indexNote(
        note,
        chunkSize: _chunkSize,
        chunkOverlap: _chunkOverlap,
      );
      debugPrint('NotesProvider: 自动索引笔记成功: $title');
    } catch (e) {
      debugPrint('NotesProvider: 自动索引笔记失败 ($title): $e');
    }
  }
}
