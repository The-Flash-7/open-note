// Copyright (c) 2026 litongshuai
// SPDX-License-Identifier: MIT OR Apache-2.0

import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_simple_treeview/flutter_simple_treeview.dart';
import 'package:markdown_editor_plus/markdown_editor_plus.dart';
import 'package:markdown_editor_plus/src/toolbar.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/note.dart';
import '../models/category.dart';
import '../providers/notes_provider.dart';
import '../providers/category_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/tags_provider.dart';
import '../widgets/settings_dialog.dart';
import '../widgets/tag_editor.dart';
import '../widgets/markdown_with_code_blocks.dart';
import '../widgets/centered_toolbar_wrapper.dart';
import '../widgets/ai/cici/cici_panel.dart';
import '../widgets/ai/ai_summary_panel.dart';
import '../widgets/editors/plain_text_editor_widget.dart';
import '../widgets/editors/rich_text_editor_widget.dart';
import '../widgets/editors/code_editor_widget.dart';
import '../theme/design_tokens.dart';
import '../utils/snackbar_helper.dart';
import '../utils/category_path_helper.dart';
import '../l10n/strings.g.dart';

class EditorScreen extends StatefulWidget {
  final Note? note;
  final String? initialTitle;
  final String? initialContent;
  final String? sourceUrl;
  final NoteSourceType? sourceType;
  final NoteFormat? initialFormat;
  final bool isEmbedded;
  final bool startInEditMode;
  final String? initialSummary;
  final List<String>? initialKeywords;
  final String? initialCategory;
  final List<String>? initialTags;

  const EditorScreen({
    super.key,
    this.note,
    this.initialTitle,
    this.initialContent,
    this.sourceUrl,
    this.sourceType,
    this.initialFormat,
    this.isEmbedded = false,
    this.startInEditMode = false,
    this.initialSummary,
    this.initialKeywords,
    this.initialCategory,
    this.initialTags,
  });

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late FocusNode _contentFocusNode;
  late Toolbar _toolbar;
  late List<String> _selectedTags;
  String? _selectedCategory;
  bool _categoryChanged = false;
  bool _isPreview = false;
  bool _hasChanges = false;
  bool _isProcessing = false;
  Note? _currentNote;
  String? _sourceUrl;
  NoteSourceType _sourceType = NoteSourceType.manual;
  String? _preGeneratedSummary;
  List<String>? _preGeneratedKeywords;
  bool _isAIPanelOpen = false;

  // 自动保存相关
  Timer? _autoSaveTimer;
  String? _lastSavedTitle;
  String? _lastSavedContent;
  bool _isAutoSaving = false;
  String? _autoSaveStatus;

  NoteFormat _currentFormat = NoteFormat.markdown;
  GlobalKey? _richTextEditorKey;
  String? _richTextDeltaJson;

  @override
  void initState() {
    super.initState();
    _currentNote = widget.note;
    _sourceUrl = widget.note?.sourceUrl ?? widget.sourceUrl;
    _sourceType =
        widget.note?.sourceType ?? widget.sourceType ?? NoteSourceType.manual;
    _currentFormat =
        widget.note?.format ?? widget.initialFormat ?? NoteFormat.markdown;

    _titleController = TextEditingController(
      text: widget.note?.title ?? widget.initialTitle ?? '',
    );
    _selectedTags = List.from(widget.note?.tags ?? widget.initialTags ?? []);
    _selectedCategory = widget.note?.category ?? widget.initialCategory;

    // 如果有initialCategory且是新建笔记，标记为已变化（从URL创建笔记的情况）
    if (widget.initialCategory != null && widget.note == null) {
      _categoryChanged = true;
    }

    _preGeneratedSummary = widget.note?.summary ?? widget.initialSummary;
    _preGeneratedKeywords = widget.note?.keywords ?? widget.initialKeywords;

    _isPreview = widget.note != null && !widget.startInEditMode;

    _contentController = TextEditingController(
      text: _extractContent(
        widget.note?.content ?? widget.initialContent ?? '',
        format: _currentFormat,
      ),
    );
    _contentFocusNode = FocusNode();

    if (_currentFormat == NoteFormat.richText) {
      final noteContent = widget.note?.content ?? widget.initialContent ?? '';
      if (noteContent.isNotEmpty) {
        _richTextDeltaJson = noteContent;
      }
    }

    // 初始化自动保存记录
    _lastSavedTitle = widget.note?.title ?? widget.initialTitle ?? '';
    _lastSavedContent = _contentController.text;

    // 监听标题变化
    _titleController.addListener(() {
      if (_titleController.text != _lastSavedTitle) {
        setState(() {
          _hasChanges = true;
        });
        _triggerAutoSave();
      }
    });

    _toolbar = Toolbar(
      controller: _contentController,
      bringEditorToFocus: () {
        if (!_contentFocusNode.hasFocus) {
          _contentFocusNode.requestFocus();
        }
      },
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotesProvider>().setCurrentEditingNote(widget.note?.id);

      // URL创建笔记时立即触发自动保存
      if (widget.sourceType == NoteSourceType.url &&
          widget.note == null &&
          widget.initialTitle != null &&
          widget.initialContent != null) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            _triggerAutoSave(immediate: true, force: true);
          }
        });
      }
    });
  }

  String _extractContent(String content, {NoteFormat? format}) {
    if (content.isEmpty) return '';

    if (format == NoteFormat.richText) {
      return content;
    }

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

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    _titleController.dispose();
    _contentController.dispose();
    _contentFocusNode.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(EditorScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.note?.id != oldWidget.note?.id) {
      _currentNote = widget.note;
      _sourceUrl = widget.note?.sourceUrl ?? widget.sourceUrl;
      _sourceType =
          widget.note?.sourceType ?? widget.sourceType ?? NoteSourceType.manual;
      _currentFormat =
          widget.note?.format ?? widget.initialFormat ?? NoteFormat.markdown;

      _titleController.text = widget.note?.title ?? widget.initialTitle ?? '';
      _selectedTags = List.from(widget.note?.tags ?? []);
      _selectedCategory = widget.note?.category;

      _contentController.text = _extractContent(
        widget.note?.content ?? widget.initialContent ?? '',
        format: _currentFormat,
      );

      _isPreview = widget.note != null && !widget.startInEditMode;
      _hasChanges = false;

      _richTextDeltaJson = null;
      _richTextEditorKey = null;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.read<NotesProvider>().setCurrentEditingNote(widget.note?.id);
        }
      });
    }
  }

  void _onContentChanged(String value) {
    setState(() {
      _hasChanges = true;
    });
    _triggerAutoSave();
  }

  void _onTagsChanged(List<String> tags) {
    setState(() {
      _selectedTags = tags;
      _hasChanges = true;
    });
    _triggerAutoSave();
  }

  void _triggerAutoSave({bool immediate = false, bool force = false}) {
    _autoSaveTimer?.cancel();

    if (immediate) {
      _performAutoSave(force: force);
    } else {
      _autoSaveTimer = Timer(const Duration(seconds: 2), () {
        _performAutoSave(force: force);
      });
    }
  }

  Future<void> _performAutoSave({bool force = false}) async {
    if (_isPreview) return;

    final t = Translations.of(context);

    var title = _titleController.text.trim();
    var content = _contentController.text;

    if (_currentFormat == NoteFormat.richText) {
      if (_richTextDeltaJson != null && _richTextDeltaJson!.isNotEmpty) {
        content = _richTextDeltaJson!;
      } else if (_richTextEditorKey?.currentWidget != null) {
        final state = _richTextEditorKey!.currentState;
        if (state != null && state.mounted) {
          content = (state as dynamic).getCurrentDeltaJson();
        }
      }
    }

    if (title.isEmpty && content.isEmpty) {
      return;
    }

    if (title.isEmpty) {
      title = t.editor_untitledNote;
    }

    if (!force &&
        title == _lastSavedTitle &&
        content == _lastSavedContent &&
        !_hasChanges) {
      return;
    }

    setState(() {
      _isAutoSaving = true;
      _autoSaveStatus = t.editor_saving;
    });

    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    try {
      final provider = context.read<NotesProvider>();
      final tagsProvider = context.read<TagsProvider>();

      String? category;
      if (_categoryChanged) {
        category = _selectedCategory;
      } else if (_currentNote != null) {
        category = _currentNote!.category;
      } else {
        category = _selectedCategory;
      }

      String? noteId;
      if (_currentNote == null) {
        noteId = await provider.createNote(
          title: title,
          content: content,
          tags: _selectedTags,
          category: category,
          sourceUrl: _sourceUrl,
          sourceType: _sourceType,
          format: _currentFormat,
          preGeneratedSummary: _preGeneratedSummary,
          preGeneratedKeywords: _preGeneratedKeywords,
        );
      } else {
        final updatedNote = _currentNote!.copyWith(
          title: title,
          content: content,
          tags: _selectedTags,
          category: category,
          sourceUrl: _sourceUrl,
          sourceType: _sourceType,
          format: _currentFormat,
        );
        await provider.updateNote(updatedNote);
        noteId = _currentNote!.id;
      }

      for (final tagName in _selectedTags) {
        var existingTag = tagsProvider.getTagByName(tagName);
        existingTag ??= await tagsProvider.createTag(tagName);
        if (existingTag != null) {
          await tagsProvider.incrementTagUsage(tagName);
        }
      }

      if (noteId != null && mounted) {
        final updatedNote = await provider.getNoteById(noteId);
        if (updatedNote != null) {
          setState(() {
            _currentNote = updatedNote;
            _lastSavedTitle = title;
            _lastSavedContent = content;
            _hasChanges = false;
            _categoryChanged = false;
            _isAutoSaving = false;
            _autoSaveStatus = t.editor_autoSaved;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isAutoSaving = false;
          _autoSaveStatus = t.editor_autoSaveFailed;
        });

        Timer(const Duration(seconds: 5), () {
          if (mounted) {
            setState(() {
              _autoSaveStatus = null;
            });
          }
        });
      }
    }
  }

  Widget _buildCategorySelector(BuildContext context) {
    final t = Translations.of(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Icon(
          Icons.folder_outlined,
          size: 18,
          color: Theme.of(context).textTheme.bodySmall?.color,
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () => _showCategoryDialog(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isDarkMode
                  ? DesignTokens.darkPrimary700.withValues(alpha: 0.3)
                  : Theme.of(context).primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Consumer<CategoryProvider>(
                  builder: (context, dirProvider, _) {
                    // 根据id查找分类名称
                    Category? directory;
                    try {
                      directory = dirProvider.categories.firstWhere(
                        (d) => d.id == _selectedCategory,
                      );
                    } catch (e) {
                      directory = null;
                    }
                    final displayText =
                        directory?.name ?? t.editor_selectCategory;

                    return Text(
                      displayText,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).primaryColor,
                      ),
                    );
                  },
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.arrow_drop_down,
                  size: 16,
                  color: Theme.of(context).primaryColor,
                ),
              ],
            ),
          ),
        ),
        if (_selectedCategory != null)
          IconButton(
            icon: const Icon(Icons.close, size: 16),
            onPressed: () {
              setState(() {
                _selectedCategory = null;
                _categoryChanged = true;
                _hasChanges = true;
              });
              _triggerAutoSave();
            },
            tooltip: t.editor_clearCategory,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
          ),
      ],
    );
  }

  void _showCategoryDialog(BuildContext context) {
    final t = Translations.of(context);
    final dirProvider = context.read<CategoryProvider>();

    final directories = dirProvider.categories
        .where((d) => !d.isVirtual)
        .toList();

    final rootDirs = directories
        .where((d) => d.parentId == null || d.parentId == allNotesCategoryId)
        .where((d) => d.id != allNotesCategoryId)
        .toList();

    final nodes = _buildCategoryTreeNodes(rootDirs, directories, context);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.editor_selectCategory),
        content: SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                InkWell(
                  onTap: () {
                    setState(() {
                      _selectedCategory = null;
                      _categoryChanged = true;
                      _hasChanges = true;
                    });
                    _triggerAutoSave();
                    Navigator.pop(ctx);
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: _selectedCategory == null
                        ? BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          )
                        : null,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.folder_open,
                          size: 16,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white70
                              : Colors.black54,
                        ),
                        SizedBox(width: 8),
                        Text(
                          t.editor_noCategory,
                          style: TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
                const Divider(height: 16),
                TreeView(nodes: nodes, indent: 16),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(t.common_cancel),
          ),
        ],
      ),
    );
  }

  List<TreeNode> _buildCategoryTreeNodes(
    List<Category> rootDirs,
    List<Category> allDirectories,
    BuildContext context,
  ) {
    return rootDirs.map((dir) {
      final children = allDirectories
          .where((d) => d.parentId == dir.id)
          .toList();
      final childNodes = children.isEmpty
          ? <TreeNode>[]
          : _buildCategoryTreeNodes(children, allDirectories, context);

      return TreeNode(
        content: _buildCategoryItem(dir, context),
        children: childNodes.isEmpty ? null : childNodes,
      );
    }).toList();
  }

  Widget _buildCategoryItem(Category dir, BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedCategory = dir.id;
          _categoryChanged = true;
          _hasChanges = true;
        });
        _triggerAutoSave();
        Navigator.pop(context);
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: _selectedCategory == dir.id
            ? BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              )
            : null,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.folder_outlined,
              size: 16,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
            SizedBox(width: 8),
            Flexible(
              child: Text(
                dir.name,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white : Colors.black,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveNote() async {
    final t = Translations.of(context);

    var title = _titleController.text.trim();
    var content = _contentController.text;

    if (_currentFormat == NoteFormat.richText) {
      if (_richTextDeltaJson != null && _richTextDeltaJson!.isNotEmpty) {
        content = _richTextDeltaJson!;
      } else if (_richTextEditorKey?.currentWidget != null) {
        final state = _richTextEditorKey!.currentState;
        if (state != null && state.mounted) {
          content = (state as dynamic).getCurrentDeltaJson();
        }
      }
    }

    if (title.isEmpty && content.isEmpty) {
      SnackBarHelper.show(context, t.editor_noteContentCannotBeEmpty);
      return;
    }

    if (title.isEmpty) {
      title = t.editor_untitledNote;
    }

    setState(() => _isProcessing = true);

    try {
      final provider = context.read<NotesProvider>();
      final tagsProvider = context.read<TagsProvider>();

      String? category;
      if (_categoryChanged) {
        category = _selectedCategory;
      } else if (_currentNote != null) {
        category = _currentNote!.category;
      } else {
        // 兜底：新建笔记未手动选择分类，使用_selectedCategory
        category = _selectedCategory;
      }

      String? noteId;
      if (_currentNote == null) {
        noteId = await provider.createNote(
          title: title,
          content: content,
          tags: _selectedTags,
          category: category,
          sourceUrl: _sourceUrl,
          sourceType: _sourceType,
          format: _currentFormat,
          preGeneratedSummary: _preGeneratedSummary,
          preGeneratedKeywords: _preGeneratedKeywords,
        );
      } else {
        final updatedNote = _currentNote!.copyWith(
          title: title,
          content: content,
          tags: _selectedTags,
          category: category,
          sourceUrl: _sourceUrl,
          sourceType: _sourceType,
          format: _currentFormat,
        );
        await provider.updateNote(updatedNote);
        noteId = _currentNote!.id;
      }

      for (final tagName in _selectedTags) {
        var existingTag = tagsProvider.getTagByName(tagName);
        existingTag ??= await tagsProvider.createTag(tagName);
        if (existingTag != null) {
          await tagsProvider.incrementTagUsage(tagName);
        }
      }

      if (noteId != null) {
        final updatedNote = await provider.getNoteById(noteId);
        if (updatedNote != null && mounted) {
          setState(() {
            _currentNote = updatedNote;
            _hasChanges = false;
            _categoryChanged = false;
          });
        }
      } else {
        setState(() {
          _hasChanges = false;
          _categoryChanged = false;
        });
      }

      if (mounted) {
        SnackBarHelper.showWithDuration(
          context,
          t.editor_saveSuccess,
          duration: const Duration(seconds: 2),
        );
      }
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showWithDuration(
          context,
          t.editor_saveFailed(error: e),
          duration: const Duration(seconds: 3),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _regenerateSummary() async {
    if (_currentNote == null) return;

    final provider = context.read<NotesProvider>();
    final plainText = _contentController.text;
    final tempNote = _currentNote!.copyWith(content: plainText);
    await provider.updateNote(tempNote, generateSummary: true);

    final updatedNote = await provider.getNoteById(_currentNote!.id);
    if (updatedNote != null && mounted) {
      setState(() => _currentNote = updatedNote);
    }
  }

  void _navigateToSettings() {
    showDialog(context: context, builder: (context) => const SettingsDialog());
  }

  Future<void> _generateSuggestions() async {
    final t = Translations.of(context);

    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (title.isEmpty || content.isEmpty) {
      SnackBarHelper.show(context, t.editor_fillTitleAndContentFirst);
      return;
    }

    final settingsProvider = context.read<SettingsProvider>();

    // 如果正在加载配置，等待加载完成
    if (settingsProvider.isLoading) {
      setState(() => _isProcessing = true);
      // 等待加载完成（最多等待5秒）
      int waitCount = 0;
      while (settingsProvider.isLoading && waitCount < 50) {
        await Future.delayed(const Duration(milliseconds: 100));
        waitCount++;
      }
      setState(() => _isProcessing = false);

      if (!mounted) return;

      // 如果等待超时或仍未配置，提示用户
      if (settingsProvider.isLoading) {
        SnackBarHelper.show(context, t.editor_configTimeoutRetry);
        return;
      }
    }

    if (!settingsProvider.hasActiveProvider) {
      SnackBarHelper.show(context, t.editor_configureAIFirst);
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final tagsProvider = context.read<TagsProvider>();
      final existingTags = tagsProvider.tags.map((t) => t.name).toList();
      final aiService = settingsProvider.aiService;

      // 获取分类路径列表
      final dirProvider = context.read<CategoryProvider>();
      final categoryPaths = CategoryPathHelper.generateCategoryPathsWithId(
        dirProvider,
      );

      final result = await aiService.generateCategoryAndTags(
        title,
        content,
        existingTags,
        categoryPaths,
      );

      final categoryPath = result['categoryPath'];
      final category = result['category'];
      final tags = result['tags'];

      if (mounted) {
        _showSuggestionsDialog(categoryPath, category, tags);
      }
    } catch (e) {
      if (mounted) {
        SnackBarHelper.show(
          context,
          t.editor_generateSuggestionsFailed(error: e),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _showSuggestionsDialog(
    String? categoryPath,
    String? categoryId,
    List<String> tags,
  ) {
    String? tempCategory = _selectedCategory;
    List<String> tempTags = List.from(_selectedTags);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          final t = Translations.of(dialogCtx);
          return AlertDialog(
            title: Row(
              children: [
                Icon(Icons.auto_awesome, size: 24),
                SizedBox(width: 8),
                Text(t.editor_smartSuggestions),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (categoryPath != null && categoryId != null) ...[
                    Text(
                      t.editor_categorySuggestion,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ListTile(
                      title: Text(categoryPath),
                      leading: Icon(
                        Icons.folder,
                        color: tempCategory == categoryId ? Colors.blue : null,
                      ),
                      trailing: tempCategory == categoryId
                          ? const Icon(Icons.check, color: Colors.green)
                          : const Icon(Icons.add),
                      selected: tempCategory == categoryId,
                      onTap: () {
                        setDialogState(() {
                          tempCategory = categoryId;
                        });
                      },
                    ),
                    const Divider(),
                  ],
                  if (tags.isNotEmpty) ...[
                    Text(
                      t.editor_tagSuggestion,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: tags.map((tag) {
                        final isSelected = tempTags.contains(tag);
                        return FilterChip(
                          label: Text(tag),
                          selected: isSelected,
                          onSelected: (selected) {
                            setDialogState(() {
                              if (selected) {
                                tempTags.add(tag);
                              } else {
                                tempTags.remove(tag);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ],
                  if (categoryPath == null && tags.isEmpty)
                    Text(t.editor_noSuggestions),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(t.common_cancel),
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    final categoryChanged = tempCategory != _selectedCategory;
                    if (categoryChanged) {
                      _selectedCategory = tempCategory;
                      _categoryChanged = true;
                      _hasChanges = true;
                    }
                    final tagsChanged = tempTags.length != _selectedTags.length;
                    if (tagsChanged) {
                      _selectedTags = tempTags;
                      _hasChanges = true;
                    }
                    if (categoryChanged || tagsChanged) {
                      _triggerAutoSave();
                    }
                  });
                  Navigator.pop(ctx);
                },
                child: Text(t.editor_applySuggestions),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        // 预览页面：直接返回
        if (!widget.startInEditMode) {
          Navigator.of(context).pop();
          return;
        }

        // 编辑页面：始终调用自动保存函数
        await _performAutoSave(force: true);

        if (!context.mounted) return;
        Navigator.of(context).pop();
      },
      child: Scaffold(
        backgroundColor: isDarkMode ? DesignTokens.darkSurface : Colors.white,
        appBar: AppBar(
          leadingWidth: Platform.isMacOS && !widget.isEmbedded ? 120 : null,
          leading: widget.isEmbedded
              ? null
              : (Platform.isMacOS
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(width: 70),
                          IconButton(
                            icon: const Icon(Icons.arrow_back),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      )
                    : null),
          title: Text(
            _isPreview && _titleController.text.isNotEmpty
                ? _titleController.text
                : (_currentNote == null ? t.editor_newNote : t.editor_editNote),
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: DesignTokens.fontSizeH3,
              fontWeight: DesignTokens.fontWeightSemiBold,
              color: isDarkMode
                  ? DesignTokens.darkTextPrimary
                  : DesignTokens.gray900,
            ),
          ),
          backgroundColor: isDarkMode ? DesignTokens.darkSurface : Colors.white,
          elevation: 0,
          surfaceTintColor: isDarkMode
              ? DesignTokens.darkSurface
              : Colors.white,
          shadowColor: isDarkMode
              ? DesignTokens.darkBorder.withValues(alpha: 0.3)
              : DesignTokens.gray200,
          actions: [
            IconButton(
              icon: Icon(
                _isPreview ? Icons.edit : Icons.visibility,
                color: DesignTokens.primary500,
              ),
              iconSize: DesignTokens.iconSizeStandard,
              onPressed: () {
                if (_isPreview) {
                  if (!widget.startInEditMode) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditorScreen(
                          note: _currentNote ?? widget.note,
                          startInEditMode: true,
                        ),
                      ),
                    );
                  } else {
                    setState(() {
                      _isPreview = false;
                    });
                  }
                } else {
                  setState(() {
                    _isPreview = true;
                  });
                }
              },
              tooltip: _isPreview ? t.common_edit : t.editor_preview,
            ),
            if (!_isPreview)
              IconButton(
                icon: Icon(
                  Icons.auto_awesome,
                  size: DesignTokens.iconSizeStandard,
                  color: DesignTokens.primary500,
                ),
                onPressed: _generateSuggestions,
                tooltip: t.editor_smartSuggestionsTooltip,
              ),
            if (!_isPreview && _autoSaveStatus != null)
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: DesignTokens.space2,
                  vertical: DesignTokens.space1,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_isAutoSaving)
                      SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isDarkMode
                                ? DesignTokens.darkTextSecondary
                                : DesignTokens.gray400,
                          ),
                        ),
                      ),
                    if (_isAutoSaving) SizedBox(width: DesignTokens.space2),
                    Text(
                      _autoSaveStatus!,
                      style: TextStyle(
                        fontSize: DesignTokens.fontSizeCaption,
                        color: _autoSaveStatus == t.editor_autoSaveFailed
                            ? DesignTokens.error
                            : (isDarkMode
                                  ? DesignTokens.darkTextSecondary
                                  : DesignTokens.gray500),
                      ),
                    ),
                  ],
                ),
              ),
            if (!_isPreview)
              IconButton(
                icon: _isProcessing
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            DesignTokens.primary500,
                          ),
                        ),
                      )
                    : Icon(Icons.save),
                iconSize: DesignTokens.iconSizeStandard,
                color: _isProcessing
                    ? DesignTokens.gray400
                    : DesignTokens.primary500,
                onPressed: _isProcessing ? null : _saveNote,
                tooltip: t.common_save,
              ),
            if (!widget.isEmbedded)
              IconButton(
                icon: Image.asset(
                  'assets/images/ai-assistant-panel/ai-assistant-dialogue-bubble.png',
                  width: 25,
                  height: 25,
                ),
                onPressed: () =>
                    setState(() => _isAIPanelOpen = !_isAIPanelOpen),
                tooltip: t.editor_aiAssistant,
              ),
            const SizedBox(width: 8),
          ],
        ),
        body: Stack(
          children: [
            Column(
              children: [
                if (_sourceUrl != null && _sourceUrl!.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).secondaryHeaderColor,
                      border: Border(
                        bottom: BorderSide(
                          color: Theme.of(context).dividerColor,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          t.editor_source,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(context).disabledColor,
                              ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final uri = Uri.parse(_sourceUrl!);
                              if (await canLaunchUrl(uri)) {
                                await launchUrl(uri);
                              }
                            },
                            child: Text(
                              _sourceUrl!,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                    decoration: TextDecoration.underline,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: _isPreview
                      ? _buildPreview(isDarkMode)
                      : _buildEditor(),
                ),
              ],
            ),
            CiciPanel(
              isOpen: _isAIPanelOpen,
              onClose: () => setState(() => _isAIPanelOpen = false),
              currentNote: widget.note,
              onNoteTap: _handleNoteTapFromCici,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSection(bool isDarkMode) {
    return Container(
      padding: EdgeInsets.all(DesignTokens.space8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _titleController,
            onChanged: (_) => _hasChanges = true,
            decoration: InputDecoration(
              hintText: t.editor_title,
              hintStyle: TextStyle(
                fontSize: DesignTokens.fontSizeH3,
                fontWeight: DesignTokens.fontWeightSemiBold,
                color: DesignTokens.gray400,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
            style: TextStyle(
              fontSize: DesignTokens.fontSizeH3,
              fontWeight: DesignTokens.fontWeightSemiBold,
              color: isDarkMode
                  ? DesignTokens.darkTextPrimary
                  : DesignTokens.gray900,
            ),
          ),
          SizedBox(height: DesignTokens.space4),
          _buildCategorySelector(context),
          SizedBox(height: DesignTokens.space6),
          TagEditor(selectedTags: _selectedTags, onTagsChanged: _onTagsChanged),
        ],
      ),
    );
  }

  Widget _buildEditor() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final noteFormat = _currentFormat;

    if (noteFormat == NoteFormat.richText) {
      _richTextEditorKey ??= GlobalKey();

      return Container(
        color: isDarkMode ? DesignTokens.darkSurface : Colors.white,
        child: Column(
          children: [
            _buildHeaderSection(isDarkMode),
            Divider(
              color: isDarkMode
                  ? DesignTokens.darkBorder.withValues(alpha: 0.3)
                  : DesignTokens.gray200,
              height: DesignTokens.space12,
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: DesignTokens.space8),
                child: RichTextEditorWidget(
                  key: _richTextEditorKey,
                  content: _contentController.text,
                  onChanged: (deltaJson) {
                    _richTextDeltaJson = deltaJson;
                    _onContentChanged(deltaJson);
                  },
                  isDarkMode: isDarkMode,
                ),
              ),
            ),
            _buildSummarySection(),
          ],
        ),
      );
    }

    return Container(
      color: isDarkMode ? DesignTokens.darkSurface : Colors.white,
      child: Column(
        children: [
          if (noteFormat == NoteFormat.markdown)
            CenteredToolbarWrapper(
              controller: _contentController,
              toolbar: _toolbar,
              toolbarBackground: isDarkMode
                  ? DesignTokens.darkSurface
                  : Colors.white,
              unfocus: () => _contentFocusNode.unfocus(),
            ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(DesignTokens.space8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _titleController,
                    onChanged: (_) => _hasChanges = true,
                    decoration: InputDecoration(
                      hintText: t.editor_title,
                      hintStyle: TextStyle(
                        fontSize: DesignTokens.fontSizeH3,
                        fontWeight: DesignTokens.fontWeightSemiBold,
                        color: DesignTokens.gray400,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                    style: TextStyle(
                      fontSize: DesignTokens.fontSizeH3,
                      fontWeight: DesignTokens.fontWeightSemiBold,
                      color: isDarkMode
                          ? DesignTokens.darkTextPrimary
                          : DesignTokens.gray900,
                    ),
                  ),
                  SizedBox(height: DesignTokens.space4),
                  _buildCategorySelector(context),
                  SizedBox(height: DesignTokens.space6),
                  TagEditor(
                    selectedTags: _selectedTags,
                    onTagsChanged: _onTagsChanged,
                  ),
                  Divider(
                    color: isDarkMode
                        ? DesignTokens.darkBorder.withValues(alpha: 0.3)
                        : DesignTokens.gray200,
                    height: DesignTokens.space12,
                  ),
                  _buildEditorByFormat(noteFormat, isDarkMode),
                ],
              ),
            ),
          ),
          _buildSummarySection(),
        ],
      ),
    );
  }

  Widget _buildEditorByFormat(NoteFormat format, bool isDarkMode) {
    switch (format) {
      case NoteFormat.markdown:
        return MarkdownField(
          controller: _contentController,
          focusNode: _contentFocusNode,
          onChanged: _onContentChanged,
          emojiConvert: false,
          maxLines: null,
          minLines: 10,
          decoration: InputDecoration(
            hintText: t.editor_startWritingMarkdown,
            hintStyle: TextStyle(
              fontSize: DesignTokens.fontSizeBody,
              color: DesignTokens.gray400,
            ),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: EdgeInsets.zero,
            fillColor: Colors.transparent,
            hoverColor: Colors.transparent,
          ),
          style: TextStyle(
            fontSize: DesignTokens.fontSizeBody,
            color: isDarkMode
                ? DesignTokens.darkTextPrimary
                : DesignTokens.gray700,
            height: DesignTokens.lineHeightBody / DesignTokens.fontSizeBody,
          ),
        );

      case NoteFormat.plainText:
        return PlainTextEditorWidget(
          content: _contentController.text,
          onChanged: (text) {
            _contentController.text = text;
            _onContentChanged(text);
          },
          isDarkMode: isDarkMode,
        );

      case NoteFormat.richText:
        return SizedBox.shrink();

      case NoteFormat.code:
        return CodeEditorWidget(
          content: _contentController.text,
          language: _currentNote?.language ?? 'plaintext',
          onChanged: (text) {
            _contentController.text = text;
            _onContentChanged(text);
          },
          isDarkMode: isDarkMode,
        );
    }
  }

  Widget _buildPreview(bool isDarkMode) {
    final noteId = widget.note?.id;

    if (noteId == null) {
      return _buildPreviewContent(isDarkMode);
    }

    return Selector<NotesProvider, Note?>(
      selector: (context, provider) {
        try {
          return provider.notes.firstWhere((n) => n.id == noteId);
        } catch (e) {
          return null;
        }
      },
      builder: (context, note, child) {
        if (note != null && note != _currentNote) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _currentNote = note;
                _titleController.text = note.title;
                _contentController.text = _extractContent(
                  note.content,
                  format: note.format,
                );
                _selectedTags = List.from(note.tags);
                _selectedCategory = note.category;
                _currentFormat = note.format;
              });
            }
          });
        }
        return _buildPreviewContent(isDarkMode);
      },
    );
  }

  Widget _buildPreviewContent(bool isDarkMode) {
    return Column(
      children: [
        Expanded(
          child: Align(
            alignment: Alignment.topLeft,
            child: SelectionArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SelectionContainer.disabled(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_selectedCategory != null &&
                              _selectedCategory!.isNotEmpty)
                            Consumer<CategoryProvider>(
                              builder: (context, dirProvider, _) {
                                Category? directory;
                                try {
                                  directory = dirProvider.categories.firstWhere(
                                    (d) => d.id == _selectedCategory,
                                  );
                                } catch (e) {
                                  directory = null;
                                }
                                final categoryName =
                                    directory?.name ?? _selectedCategory!;

                                return Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: DesignTokens.space4,
                                    vertical: DesignTokens.space2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isDarkMode
                                        ? DesignTokens.darkPrimary700
                                              .withValues(alpha: 0.3)
                                        : DesignTokens.primary100,
                                    borderRadius: BorderRadius.circular(
                                      DesignTokens.radiusXS,
                                    ),
                                  ),
                                  child: Text(
                                    categoryName,
                                    style: TextStyle(
                                      fontSize: DesignTokens.fontSizeCaption,
                                      fontWeight: DesignTokens.fontWeightMedium,
                                      color: isDarkMode
                                          ? DesignTokens.darkPrimary500
                                          : DesignTokens.primary700,
                                    ),
                                  ),
                                );
                              },
                            ),
                          if (_selectedTags.isNotEmpty) ...[
                            SizedBox(height: DesignTokens.space4),
                            Wrap(
                              spacing: DesignTokens.space2,
                              runSpacing: DesignTokens.space2,
                              children: _selectedTags.map((tag) {
                                return Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: DesignTokens.space3,
                                    vertical: DesignTokens.space1,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isDarkMode
                                        ? DesignTokens.darkPrimary700
                                              .withValues(alpha: 0.2)
                                        : DesignTokens.primary50,
                                    borderRadius: BorderRadius.circular(
                                      DesignTokens.radiusFull,
                                    ),
                                  ),
                                  child: Text(
                                    '#$tag',
                                    style: TextStyle(
                                      fontSize: DesignTokens.fontSizeCaption,
                                      color: isDarkMode
                                          ? DesignTokens.darkPrimary500
                                          : DesignTokens.primary700,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                          if (_selectedCategory != null ||
                              _selectedTags.isNotEmpty)
                            SizedBox(height: DesignTokens.space6),
                        ],
                      ),
                    ),
                    _buildPreviewByFormat(isDarkMode),
                  ],
                ),
              ),
            ),
          ),
        ),
        _buildSummarySection(),
      ],
    );
  }

  Widget _buildPreviewByFormat(bool isDarkMode) {
    final noteFormat = _currentFormat;

    switch (noteFormat) {
      case NoteFormat.markdown:
        return MarkdownWithCodeBlocks(
          data: _contentController.text,
          selectable: true,
          isDarkMode: isDarkMode,
        );

      case NoteFormat.plainText:
        return SizedBox(
          width: double.infinity,
          child: SelectableText(
            _contentController.text,
            style: TextStyle(
              fontSize: DesignTokens.fontSizeBody,
              fontFamily: 'JetBrainsMono',
              color: isDarkMode
                  ? DesignTokens.darkTextPrimary
                  : DesignTokens.gray700,
            ),
          ),
        );

      case NoteFormat.richText:
        try {
          final deltaJson = jsonDecode(_contentController.text);

          final document = Document.fromJson(deltaJson);

          final controller = QuillController(
            document: document,
            selection: const TextSelection.collapsed(offset: 0),
          );

          return QuillEditor(
            controller: controller,
            focusNode: FocusNode(),
            scrollController: ScrollController(),
            config: const QuillEditorConfig(
              scrollable: true,
              expands: false,
              minHeight: 200,
              padding: EdgeInsets.zero,
            ),
          );
        } catch (e) {
          return SelectableText(
            _contentController.text,
            style: TextStyle(
              fontSize: DesignTokens.fontSizeBody,
              color: isDarkMode
                  ? DesignTokens.darkTextPrimary
                  : DesignTokens.gray700,
            ),
          );
        }

      case NoteFormat.code:
        final language = _currentNote?.language ?? 'plaintext';
        return CodeEditorWidget(
          content: _contentController.text,
          language: language,
          onChanged: (_) {},
          isDarkMode: isDarkMode,
        );
    }
  }

  Widget _buildSummarySection() {
    final hasSummary =
        (_currentNote?.summary != null && _currentNote!.summary!.isNotEmpty) ||
        (_preGeneratedSummary != null && _preGeneratedSummary!.isNotEmpty);

    final displaySummary =
        (_currentNote?.summary != null && _currentNote!.summary!.isNotEmpty)
        ? _currentNote!.summary!
        : (_preGeneratedSummary ?? '');
    final displayKeywords =
        (_currentNote?.keywords != null && _currentNote!.keywords.isNotEmpty)
        ? _currentNote!.keywords
        : (_preGeneratedKeywords ?? []);

    final settingsProvider = context.read<SettingsProvider>();
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.all(DesignTokens.space8),
      decoration: BoxDecoration(
        color: isDarkMode ? DesignTokens.darkSurface : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDarkMode
                ? DesignTokens.darkBorder.withValues(alpha: 0.3)
                : DesignTokens.gray200,
            width: 1,
          ),
        ),
      ),
      child: Selector<NotesProvider, bool>(
        selector: (ctx, provider) => provider.isGeneratingSummary,
        builder: (ctx, isGenerating, _) {
          return AISummaryPanel(
            key: ValueKey(_currentNote?.id),
            summary: displaySummary,
            keywords: displayKeywords,
            isGenerating: isGenerating,
            initiallyExpanded: false,
            onRegenerate:
                !_isPreview && hasSummary && settingsProvider.hasActiveProvider
                ? () => _regenerateSummary()
                : null,
            onGenerate:
                !_isPreview && !hasSummary && settingsProvider.hasActiveProvider
                ? () => _regenerateSummary()
                : null,
            onNavigateToSettings:
                !_isPreview &&
                    !hasSummary &&
                    !settingsProvider.hasActiveProvider
                ? () => _navigateToSettings()
                : null,
          );
        },
      ),
    );
  }

  Future<void> _handleNoteTapFromCici(Note note) async {
    final notesProvider = context.read<NotesProvider>();
    final fullNote = await notesProvider.getFullNote(note.id);
    if (fullNote != null && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              EditorScreen(note: fullNote, startInEditMode: false),
        ),
      );
    }
  }
}
