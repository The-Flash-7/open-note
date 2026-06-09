// Copyright (c) 2026 litongshuai
// SPDX-License-Identifier: MIT OR Apache-2.0

import 'package:flutter/material.dart';
import 'package:clipboard_watcher/clipboard_watcher.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:cross_file/cross_file.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../providers/notes_provider.dart';
import '../models/note_preview.dart';
import '../providers/background_summary_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/memory_settings_provider.dart';
import '../providers/category_provider.dart';
import '../providers/knowledge_base_provider.dart';
import '../models/note.dart';
import '../models/category.dart';
import '../services/clipboard_service.dart';
import '../widgets/url_input_dialog.dart';
import '../widgets/search_dialog.dart';
import '../utils/responsive.dart';
import '../utils/snackbar_helper.dart';
import '../theme/design_tokens.dart';
import '../widgets/navigation/desktop_nav_bar.dart';
import '../widgets/navigation/mobile_bottom_nav.dart';
import '../widgets/cards/note_card.dart';
import '../widgets/feedback/empty_state.dart';
import '../widgets/feedback/skeleton_loader.dart';
import '../widgets/ai/cici/cici_panel.dart';
import '../widgets/onboarding/onboarding_guide_widget.dart';
import '../widgets/category/category_panel.dart';
import '../widgets/format_option_widget.dart';
import 'editor_screen.dart';
import '../widgets/settings_dialog.dart';
import '../l10n/strings.g.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with ClipboardListener {
  final ClipboardService _clipboardService = ClipboardService();
  bool _showClipboardHint = false;
  String? _clipboardUrl;

  int _selectedNavIndex = 0;
  Note? _selectedNote;
  bool _isAIPanelOpen = false;
  bool _isSelectionMode = false;
  final Set<String> _selectedNoteIds = {};
  String? _isDeletingNoteId;

  double _noteListWidthDesktop = DesignTokens.noteListWidthDesktop;
  double _noteListWidthTablet = DesignTokens.noteListWidthTablet;
  double _categoryPanelWidth = 180;
  static const double _categoryPanelWidthMin = 120;
  static const double _categoryPanelWidthMax = 300;

  final List<NavItemData> _desktopNavItems = [
    NavItemData(icon: Icons.home, label: '首页'),
    NavItemData(icon: Icons.folder, label: '目录'),
    NavItemData(icon: Icons.star, label: '收藏'),
  ];

  final List<NavItem> _mobileNavItems = [
    NavItem(icon: Icons.home, label: '首页'),
    NavItem(icon: Icons.folder, label: '目录'),
    NavItem(icon: Icons.auto_awesome, label: 'AI'),
    NavItem(icon: Icons.star, label: '收藏'),
    NavItem(icon: Icons.settings, label: '设置'),
  ];

  @override
  void initState() {
    super.initState();
    clipboardWatcher.addListener(this);
    clipboardWatcher.start();
    _loadNoteListWidths();

    // 延迟到首帧渲染完成后再准备 Python 服务（避免 notifyListeners 在 build 期间被触发）
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _preparePythonServiceInBackground();
    });

    // 在 HomeScreen 初始化完成后触发向导（Navigator 已创建）
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final settingsProvider = context.read<SettingsProvider>();
      final notesProvider = context.read<NotesProvider>();
      final bgProvider = context.read<BackgroundSummaryProvider>();
      final directoryProvider = context.read<CategoryProvider>();

      // 确保笔记列表已加载
      if (notesProvider.previews.isEmpty && !notesProvider.isLoading) {
        await notesProvider.loadNotes();
      }

      if (!directoryProvider.isInitialized) {
        await directoryProvider.init();
      }

      final hasShown = await settingsProvider.hasShownOnboarding();

      if (!hasShown && !settingsProvider.hasActiveProvider) {
        if (!mounted) return;

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (dialogCtx) {
            return OnboardingGuideWidget(
              onComplete: () {
                Navigator.pop(dialogCtx);
                // 同步刷新 MemorySettingsProvider 以识别新配置的 AI 模型
                context.read<MemorySettingsProvider>().loadAvailableProviders(
                  settingsProvider.providerConfigs,
                );
                _initAppServices(notesProvider, bgProvider);
              },
              onSkip: () async {
                await settingsProvider.setOnboardingShown();
                if (!dialogCtx.mounted) return;
                Navigator.pop(dialogCtx);
                _initAppServices(notesProvider, bgProvider);
              },
            );
          },
        );
      } else {
        _initAppServices(notesProvider, bgProvider);
      }
    });
  }

  void _initAppServices(
    NotesProvider notesProvider,
    BackgroundSummaryProvider bgProvider,
  ) {
    bgProvider.startBackgroundGeneration();
  }

  Future<void> _loadNoteListWidths() async {
    final prefs = await SharedPreferences.getInstance();

    final savedDesktop = prefs.getDouble('note_list_width_desktop');
    if (savedDesktop != null) {
      _noteListWidthDesktop = savedDesktop.clamp(
        DesignTokens.noteListWidthDesktop,
        DesignTokens.noteListWidthDesktopMax,
      );
    }

    final savedTablet = prefs.getDouble('note_list_width_tablet');
    if (savedTablet != null) {
      _noteListWidthTablet = savedTablet.clamp(
        DesignTokens.noteListWidthTablet,
        DesignTokens.noteListWidthTabletMax,
      );
    }

    final savedDirWidth = prefs.getDouble('category_panel_width');
    if (savedDirWidth != null) {
      _categoryPanelWidth = savedDirWidth.clamp(
        _categoryPanelWidthMin,
        _categoryPanelWidthMax,
      );
    }

    setState(() {});
  }

  Future<void> _preparePythonServiceInBackground() async {
    final kbProvider = context.read<KnowledgeBaseProvider>();

    // 后台准备服务（不阻塞 UI）
    final prepared = await kbProvider.preparePythonService(
      onProgress: (status, progress) {
        debugPrint(
          'Python 服务准备: $status (${(progress * 100).toStringAsFixed(0)}%)',
        );
      },
    );

    // 如果知识库已启用且准备成功，启动服务
    if (prepared && kbProvider.isReady && !kbProvider.isPythonServiceRunning) {
      await _startPythonService(kbProvider);
    }
  }

  Future<void> _startPythonService(KnowledgeBaseProvider kbProvider) async {
    final notesProvider = context.read<NotesProvider>();

    // 通过 KnowledgeBaseProvider 启动服务，确保 _isPythonServiceRunning 被正确设置
    final success = await kbProvider.startPythonService(
      modelPath: kbProvider.config.modelPath,
    );

    if (success) {
      notesProvider.setKnowledgeBaseModelPath(
        kbProvider.config.modelPath,
        serviceUrl: kbProvider.pythonServiceUrl,
      );

      // 同步分块配置到 NotesProvider
      notesProvider.setChunkConfig(
        kbProvider.config.chunkSize,
        kbProvider.config.chunkOverlap,
      );

      // 服务启动成功后，延迟同步最新索引统计（确保 Python 服务完全就绪）
      Future.delayed(const Duration(seconds: 2), () {
        kbProvider.refreshIndexStats(notesProvider);
      });

      debugPrint('Python 服务已启动并配置到 NotesProvider');
    } else {
      debugPrint('Python 服务启动失败');
    }
  }

  Future<void> _saveNoteListWidth(String key, double width) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(key, width);
  }

  Future<void> _saveCategoryPanelWidth(double width) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('category_panel_width', width);
  }

  @override
  void dispose() {
    // 同步停止 Python 服务
    try {
      final kbProvider = context.read<KnowledgeBaseProvider>();
      kbProvider.stopPythonServiceSync();
    } catch (e) {
      debugPrint('HomeScreen: 停止 Python 服务失败: $e');
    }

    clipboardWatcher.removeListener(this);
    clipboardWatcher.stop();
    super.dispose();
  }

  @override
  void onClipboardChanged() async {
    final content = await _clipboardService.getClipboardContent();

    if (_clipboardService.isNewContent(content) &&
        _clipboardService.isUrl(content!)) {
      setState(() {
        _showClipboardHint = true;
        _clipboardUrl = content;
      });
    } else {
      setState(() {
        _showClipboardHint = false;
        _clipboardUrl = null;
      });
    }
  }

  void _useClipboardUrl() {
    if (_clipboardUrl != null) {
      _clipboardService.updateLastContent(_clipboardUrl!);
      setState(() {
        _showClipboardHint = false;
      });
      _showUrlInputDialogWithUrl(_clipboardUrl!);
    }
  }

  void _dismissClipboardHint() {
    final content = _clipboardUrl;
    if (content != null) {
      _clipboardService.updateLastContent(content);
    }
    setState(() {
      _showClipboardHint = false;
      _clipboardUrl = null;
    });
  }

  void _showUrlInputDialogWithUrl(String initialUrl) {
    showDialog(
      context: context,
      builder: (ctx) => URLInputDialog(
        initialUrl: initialUrl,
        onSave: (noteData) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (ctx) => EditorScreen(
                initialTitle: noteData.title,
                initialContent: noteData.content,
                sourceUrl: noteData.url,
                sourceType: NoteSourceType.url,
                initialSummary: noteData.summary,
                initialKeywords: noteData.keywords,
                initialCategory: noteData.category,
                initialTags: noteData.tags,
              ),
            ),
          );
        },
      ),
    );
  }

  void _showUrlInputDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => URLInputDialog(
        onSave: (noteData) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (ctx) => EditorScreen(
                initialTitle: noteData.title,
                initialContent: noteData.content,
                sourceUrl: noteData.url,
                sourceType: NoteSourceType.url,
                initialSummary: noteData.summary,
                initialKeywords: noteData.keywords,
                initialCategory: noteData.category,
                initialTags: noteData.tags,
              ),
            ),
          );
        },
      ),
    );
  }

  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    return DropTarget(
      onDragEntered: (details) {
        setState(() {
          _isDragging = true;
        });
      },
      onDragExited: (details) {
        setState(() {
          _isDragging = false;
        });
      },
      onDragDone: (details) {
        setState(() {
          _isDragging = false;
        });
        _handleDropFiles(details.files);
      },
      child: Stack(
        children: [
          ResponsiveLayout(
            mobile: _buildMobileLayout(),
            tablet: _buildTabletLayout(),
            desktop: _buildDesktopLayout(),
          ),
          if (_isDragging)
            Positioned.fill(
              child: Container(
                color: Theme.of(context).brightness == Brightness.dark
                    ? DesignTokens.darkPrimary700.withValues(alpha: 0.1)
                    : DesignTokens.primary500.withValues(alpha: 0.1),
                child: Center(
                  child: Container(
                    padding: EdgeInsets.all(DesignTokens.space8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? DesignTokens.darkSurface
                          : Colors.white,
                      borderRadius: BorderRadius.circular(
                        DesignTokens.radiusLG,
                      ),
                      border: Border.all(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? DesignTokens.darkPrimary500
                            : DesignTokens.primary500,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.upload_file,
                          size: 48,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? DesignTokens.darkPrimary500
                              : DesignTokens.primary500,
                        ),
                        SizedBox(height: DesignTokens.space4),
                        Text(
                          t.home_dragDropImport,
                          style: TextStyle(
                            fontSize: DesignTokens.fontSizeH3,
                            fontWeight: DesignTokens.fontWeightSemiBold,
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                ? DesignTokens.darkTextPrimary
                                : DesignTokens.gray900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _handleDropFiles(List<XFile> files) async {
    if (files.isEmpty) return;

    final notesProvider = context.read<NotesProvider>();

    int successCount = 0;
    int failCount = 0;

    for (final xFile in files) {
      final file = File(xFile.path);
      try {
        final noteId = await notesProvider.importNoteFromFile(file);
        if (noteId != null) {
          successCount++;
        } else {
          failCount++;
        }
      } catch (e) {
        debugPrint('Failed to import file ${xFile.path}: $e');
        failCount++;
      }
    }

    if (mounted) {
      if (successCount > 0) {
        SnackBarHelper.showWithDuration(
          context,
          '成功导入 $successCount 个文件',
          duration: const Duration(seconds: 2),
        );
      }
      if (failCount > 0) {
        SnackBarHelper.showWithDuration(
          context,
          '$failCount 个文件导入失败',
          duration: const Duration(seconds: 2),
        );
      }
    }
  }

  Widget _buildDesktopLayout() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              TopBar(
                title: 'OpenNote',
                onSearchTap: () => _openSearchDialog(),
                onAIButtonTap: () =>
                    setState(() => _isAIPanelOpen = !_isAIPanelOpen),
                showAIButton: true,
              ),
              if (_showClipboardHint) _buildClipboardHintBar(isDark),
              Consumer<BackgroundSummaryProvider>(
                builder: (ctx, bgProvider, _) {
                  if (!bgProvider.isRunning && !bgProvider.isPaused) {
                    return const SizedBox.shrink();
                  }
                  return _buildBackgroundSummaryProgress(bgProvider, isDark);
                },
              ),
              Expanded(
                child: Stack(
                  children: [
                    Row(
                      children: [
                        DesktopNavBar(
                          selectedIndex: _selectedNavIndex,
                          onItemSelected: _onNavItemSelected,
                          items: _desktopNavItems,
                          onSettingsTap: () => _navigateToSettings(),
                          onThemeToggle: () => _showThemeQuickSwitch(context),
                        ),
                        if (_selectedNavIndex == 1)
                          SizedBox(
                            width: _categoryPanelWidth,
                            child: Stack(
                              children: [
                                Positioned.fill(
                                  child: CategoryPanel(
                                    width: _categoryPanelWidth,
                                  ),
                                ),
                                Positioned(
                                  right: 0,
                                  top: 0,
                                  bottom: 0,
                                  width: 5,
                                  child: MouseRegion(
                                    cursor: SystemMouseCursors.resizeColumn,
                                    child: GestureDetector(
                                      behavior: HitTestBehavior.translucent,
                                      onHorizontalDragUpdate: (details) {
                                        setState(() {
                                          _categoryPanelWidth +=
                                              details.delta.dx;
                                          _categoryPanelWidth =
                                              _categoryPanelWidth.clamp(
                                                _categoryPanelWidthMin,
                                                _categoryPanelWidthMax,
                                              );
                                        });
                                      },
                                      onHorizontalDragEnd: (_) {
                                        _saveCategoryPanelWidth(
                                          _categoryPanelWidth,
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        SizedBox(
                          width: _noteListWidthDesktop,
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: _buildNoteListPanel(isDark),
                              ),
                              Positioned(
                                right: 0,
                                top: 0,
                                bottom: 0,
                                width: 5,
                                child: MouseRegion(
                                  cursor: SystemMouseCursors.resizeColumn,
                                  child: GestureDetector(
                                    behavior: HitTestBehavior.translucent,
                                    onHorizontalDragUpdate: (details) {
                                      setState(() {
                                        _noteListWidthDesktop +=
                                            details.delta.dx;
                                        _noteListWidthDesktop =
                                            _noteListWidthDesktop.clamp(
                                              DesignTokens.noteListWidthDesktop,
                                              DesignTokens
                                                  .noteListWidthDesktopMax,
                                            );
                                      });
                                    },
                                    onHorizontalDragEnd: (_) {
                                      _saveNoteListWidth(
                                        'note_list_width_desktop',
                                        _noteListWidthDesktop,
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(child: _buildContentArea(isDark)),
                      ],
                    ),
                    CiciPanel(
                      isOpen: _isAIPanelOpen,
                      onClose: () => setState(() => _isAIPanelOpen = false),
                      currentNote: _selectedNote,
                      onNoteTap: _handleNoteTapFromCici,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabletLayout() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      drawer: _buildTabletDrawer(isDark),
      body: Column(
        children: [
          if (_showClipboardHint) _buildClipboardHintBar(isDark),
          Consumer<BackgroundSummaryProvider>(
            builder: (ctx, bgProvider, _) {
              if (!bgProvider.isRunning && !bgProvider.isPaused) {
                return const SizedBox.shrink();
              }
              return _buildBackgroundSummaryProgress(bgProvider, isDark);
            },
          ),
          Builder(
            builder: (context) => TopBar(
              title: 'OpenNote',
              onMenuTap: () => Scaffold.of(context).openDrawer(),
              onSearchTap: () => _openSearchDialog(),
              onAIButtonTap: () =>
                  setState(() => _isAIPanelOpen = !_isAIPanelOpen),
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                Row(
                  children: [
                    SizedBox(
                      width: _noteListWidthTablet,
                      child: _buildNoteListPanel(isDark),
                    ),
                    Expanded(child: _buildContentArea(isDark)),
                  ],
                ),
                CiciPanel(
                  isOpen: _isAIPanelOpen,
                  onClose: () => setState(() => _isAIPanelOpen = false),
                  currentNote: _selectedNote,
                  onNoteTap: _handleNoteTapFromCici,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Scaffold(
      body: Column(
        children: [
          if (_showClipboardHint) _buildClipboardHintBar(false),
          Consumer<BackgroundSummaryProvider>(
            builder: (ctx, bgProvider, _) {
              if (!bgProvider.isRunning && !bgProvider.isPaused) {
                return const SizedBox.shrink();
              }
              return _buildBackgroundSummaryProgress(bgProvider, false);
            },
          ),
          MobileHomeHeader(),
          Expanded(
            child: Consumer<NotesProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading) {
                  return _buildLoadingState();
                }

                final notes = _getFilteredNotes(provider, null);

                if (notes.isEmpty) {
                  return EmptyNotesState(onCreateNew: () => _createNewNote());
                }

                return ListView.builder(
                  padding: EdgeInsets.all(DesignTokens.space4),
                  itemCount: notes.length,
                  itemBuilder: (context, index) {
                    return NoteCard(
                      note: notes[index],
                      isSelected: _selectedNote?.id == notes[index].id,
                      onTap: () => _openNote(notes[index]),
                      onFavoriteToggle: () => _toggleFavorite(notes[index]),
                    );
                  },
                );
              },
            ),
          ),
          MobileBottomNav(
            selectedIndex: _selectedNavIndex,
            onItemSelected: _onNavItemSelected,
            items: _mobileNavItems,
            onAIButtonTap: () => _showAIBottomSheet(),
          ),
        ],
      ),
    );
  }

  Widget _buildClipboardHintBar(bool isDark) {
    return Material(
      color: DesignTokens.primary500.withValues(alpha: isDark ? 0.65 : 0.1),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: DesignTokens.space8,
          vertical: DesignTokens.space6,
        ),
        child: Row(
          children: [
            Icon(Icons.link, size: 18, color: DesignTokens.primary500),
            SizedBox(width: DesignTokens.space6),
            Expanded(
              child: Text(
                t.home_clipboardUrlDetected,
                style: TextStyle(
                  color: DesignTokens.primary500,
                  fontSize: DesignTokens.fontSizeBody,
                ),
              ),
            ),
            TextButton(
              onPressed: _useClipboardUrl,
              style: TextButton.styleFrom(
                foregroundColor: DesignTokens.primary500,
              ),
              child: Text(t.dialog_createNote),
            ),
            TextButton(
              onPressed: _dismissClipboardHint,
              style: TextButton.styleFrom(
                foregroundColor: DesignTokens.gray500,
              ),
              child: Text(t.home_dismiss),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackgroundSummaryProgress(
    BackgroundSummaryProvider bgProvider,
    bool isDark,
  ) {
    return Material(
      color: DesignTokens.primary500.withValues(alpha: isDark ? 0.65 : 0.1),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: DesignTokens.space8,
          vertical: DesignTokens.space4,
        ),
        child: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  DesignTokens.primary500,
                ),
              ),
            ),
            SizedBox(width: DesignTokens.space6),
            Expanded(
              child: Text(
                bgProvider.isPaused
                    ? '摘要生成已暂停 (${bgProvider.processedCount}/${bgProvider.totalPending})'
                    : bgProvider.progressText,
                style: TextStyle(
                  color: DesignTokens.primary500,
                  fontSize: DesignTokens.fontSizeSmall,
                ),
              ),
            ),
            TextButton(
              onPressed: bgProvider.isRunning
                  ? bgProvider.pauseGeneration
                  : bgProvider.resumeGeneration,
              style: TextButton.styleFrom(
                foregroundColor: DesignTokens.primary500,
              ),
              child: Text(
                bgProvider.isRunning ? t.common_pause : t.common_resume,
                style: TextStyle(fontSize: DesignTokens.fontSizeSmall),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoteListPanel(bool isDark) {
    final t = Translations.of(context);
    return Container(
      decoration: BoxDecoration(
        color: isDark ? DesignTokens.darkSurface : Colors.white,
        border: Border(
          right: BorderSide(
            color: isDark
                ? DesignTokens.darkBorder.withValues(alpha: 0.3)
                : DesignTokens.gray200,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(DesignTokens.space6),
            child: Row(
              children: [
                if (_isSelectionMode)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Text(
                      '已选中 ${_selectedNoteIds.length} 个',
                      style: TextStyle(
                        fontSize: DesignTokens.fontSizeSmall,
                        color: DesignTokens.primary500,
                        fontWeight: DesignTokens.fontWeightMedium,
                      ),
                    ),
                  ),
                Expanded(
                  child: Consumer<CategoryProvider>(
                    builder: (context, dirProvider, _) {
                      String title;
                      if (_isSelectionMode) {
                        title = '';
                      } else if (_selectedNavIndex == 0) {
                        title = t.home_allNotes;
                      } else if (_selectedNavIndex == 2) {
                        title = t.home_favorites;
                      } else {
                        title =
                            dirProvider.selectedCategory?.name ??
                            t.home_allNotes;
                      }

                      return Text(
                        title,
                        style: TextStyle(
                          fontSize: DesignTokens.fontSizeH3,
                          fontWeight: DesignTokens.fontWeightSemiBold,
                          color: isDark
                              ? DesignTokens.darkTextPrimary
                              : DesignTokens.gray900,
                        ),
                      );
                    },
                  ),
                ),
                if (_isSelectionMode)
                  IconButton(
                    icon: Icon(Icons.close, size: 18),
                    onPressed: _toggleSelectionMode,
                    tooltip: t.home_cancelMultiSelect,
                    color: DesignTokens.error,
                  ),
                if (!_isSelectionMode) ...[
                  IconButton(
                    icon: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isDark
                            ? DesignTokens.darkPrimary700.withValues(alpha: 0.3)
                            : DesignTokens.primary50,
                        borderRadius: BorderRadius.circular(
                          DesignTokens.radiusMD,
                        ),
                      ),
                      child: Icon(
                        Icons.checklist,
                        size: 16,
                        color: isDark
                            ? DesignTokens.darkPrimary500
                            : DesignTokens.primary500,
                      ),
                    ),
                    onPressed: _toggleSelectionMode,
                    tooltip: t.home_multiSelect,
                  ),
                  SizedBox(width: DesignTokens.space2),
                  Consumer<NotesProvider>(
                    builder: (context, provider, _) {
                      final trashCount = provider.getTrashNotes().length;
                      return IconButton(
                        icon: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: trashCount > 0
                                ? DesignTokens.error.withValues(
                                    alpha: isDark ? 0.6 : 0.1,
                                  )
                                : (isDark
                                      ? DesignTokens.darkPrimary700.withValues(
                                          alpha: 0.3,
                                        )
                                      : DesignTokens.primary50),
                            borderRadius: BorderRadius.circular(
                              DesignTokens.radiusMD,
                            ),
                          ),
                          child: Icon(
                            Icons.archive,
                            size: 16,
                            color: trashCount > 0
                                ? DesignTokens.error
                                : (isDark
                                      ? DesignTokens.darkPrimary500
                                      : DesignTokens.primary500),
                          ),
                        ),
                        onPressed: _showTrashDialog,
                        tooltip: trashCount > 0
                            ? t.home_trashWithCount(count: trashCount)
                            : t.home_trash,
                      );
                    },
                  ),
                ],
                PopupMenuButton<String>(
                  tooltip: t.home_newNote,
                  icon: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isDark
                          ? DesignTokens.darkPrimary700.withValues(alpha: 0.3)
                          : DesignTokens.primary50,
                      borderRadius: BorderRadius.circular(
                        DesignTokens.radiusMD,
                      ),
                    ),
                    child: Icon(
                      Icons.add,
                      size: 16,
                      color: isDark
                          ? DesignTokens.darkPrimary500
                          : DesignTokens.primary500,
                    ),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(DesignTokens.radiusMD),
                  ),
                  elevation: 8,
                  color: isDark ? DesignTokens.darkSurface : Colors.white,
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'new',
                      height: 40,
                      child: Row(
                        children: [
                          Icon(
                            Icons.note_add,
                            size: 18,
                            color: isDark
                                ? DesignTokens.darkPrimary500
                                : DesignTokens.primary500,
                          ),
                          SizedBox(width: DesignTokens.space3),
                          Text(
                            t.home_newBlankNote,
                            style: TextStyle(
                              fontSize: DesignTokens.fontSizeBody,
                              color: isDark
                                  ? DesignTokens.darkTextPrimary
                                  : DesignTokens.gray700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'url',
                      height: 40,
                      child: Row(
                        children: [
                          Icon(
                            Icons.link,
                            size: 18,
                            color: isDark
                                ? DesignTokens.darkPrimary500
                                : DesignTokens.primary500,
                          ),
                          SizedBox(width: DesignTokens.space3),
                          Text(
                            t.home_createFromUrl,
                            style: TextStyle(
                              fontSize: DesignTokens.fontSizeBody,
                              color: isDark
                                  ? DesignTokens.darkTextPrimary
                                  : DesignTokens.gray700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'file',
                      height: 40,
                      child: Row(
                        children: [
                          Icon(
                            Icons.upload_file,
                            size: 18,
                            color: isDark
                                ? DesignTokens.darkPrimary500
                                : DesignTokens.primary500,
                          ),
                          SizedBox(width: DesignTokens.space3),
                          Text(
                            t.home_importFromFile,
                            style: TextStyle(
                              fontSize: DesignTokens.fontSizeBody,
                              color: isDark
                                  ? DesignTokens.darkTextPrimary
                                  : DesignTokens.gray700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) {
                    if (value == 'new') {
                      _showNewNoteDialog(context);
                    } else if (value == 'url') {
                      _showUrlInputDialog(context);
                    } else if (value == 'file') {
                      _showImportFileDialog(context);
                    }
                  },
                ),
              ],
            ),
          ),
          Divider(
            color: isDark
                ? DesignTokens.darkBorder.withValues(alpha: 0.3)
                : DesignTokens.gray200,
            height: 1,
          ),
          Expanded(
            child: Consumer2<NotesProvider, CategoryProvider>(
              builder: (context, provider, dirProvider, _) {
                if (provider.isLoading) {
                  return ListView.builder(
                    padding: EdgeInsets.all(DesignTokens.space4),
                    itemCount: 5,
                    itemBuilder: (context, index) => NoteCardSkeleton(),
                  );
                }

                final notes = _getFilteredNotes(provider, dirProvider);

                if (notes.isEmpty) {
                  return EmptyNotesState(onCreateNew: () => _createNewNote());
                }

                return Stack(
                  children: [
                    ListView.builder(
                      padding: EdgeInsets.all(DesignTokens.space4),
                      itemCount: notes.length,
                      itemBuilder: (context, index) {
                        final note = notes[index];

                        return AnimatedSize(
                          key: ValueKey('note_${note.id}'),
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          alignment: Alignment.topCenter,
                          child: AnimatedOpacity(
                            opacity: _isDeletingNoteId == note.id ? 0.0 : 1.0,
                            duration: const Duration(milliseconds: 300),
                            child: Slidable(
                              key: ValueKey(note.id),
                              endActionPane: ActionPane(
                                motion: const BehindMotion(),
                                extentRatio: 0.25,
                                children: [
                                  SlidableAction(
                                    onPressed: (ctx) =>
                                        _confirmDeleteNote(note),
                                    backgroundColor: DesignTokens.error,
                                    foregroundColor: Colors.white,
                                    icon: Icons.delete_rounded,
                                    label: t.common_delete,
                                    borderRadius: BorderRadius.circular(
                                      DesignTokens.radiusLG,
                                    ),
                                    spacing: 8,
                                  ),
                                ],
                              ),
                              child: NoteCard(
                                note: note,
                                isSelected: _selectedNote?.id == note.id,
                                isSelectionMode: _isSelectionMode,
                                isMultiSelected: _selectedNoteIds.contains(
                                  note.id,
                                ),
                                onTap: () => _isSelectionMode
                                    ? _toggleNoteSelection(note)
                                    : _selectNote(note),
                                onFavoriteToggle: () => _toggleFavorite(note),
                                onDelete: _isSelectionMode
                                    ? null
                                    : () => _confirmDeleteNote(note),
                                onLongPress: _isSelectionMode
                                    ? null
                                    : () => _showNoteContextMenu(note),
                                onSelectionToggle: _isSelectionMode
                                    ? () => _toggleNoteSelection(note)
                                    : null,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    if (_isSelectionMode && _selectedNoteIds.isNotEmpty)
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: _buildBatchActionBar(isDark),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentArea(bool isDark) {
    if (_selectedNote == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.note_alt_outlined,
              size: 64,
              color: isDark
                  ? DesignTokens.darkTextSecondary.withValues(alpha: 0.5)
                  : DesignTokens.gray300,
            ),
            SizedBox(height: DesignTokens.space6),
            Text(
              t.home_selectNoteToStart,
              style: TextStyle(
                fontSize: DesignTokens.fontSizeH3,
                color: isDark
                    ? DesignTokens.darkTextSecondary
                    : DesignTokens.gray500,
              ),
            ),
          ],
        ),
      );
    }

    return EditorScreen(note: _selectedNote, isEmbedded: true);
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: EdgeInsets.all(DesignTokens.space4),
      itemCount: 5,
      itemBuilder: (context, index) => NoteCardSkeleton(),
    );
  }

  List<NotePreview> _getFilteredNotes(
    NotesProvider provider,
    CategoryProvider? dirProvider,
  ) {
    List<NotePreview> notes = provider.previews;

    // 收藏过滤
    if (_selectedNavIndex == 2) {
      notes = notes.where((n) => n.isFavorite).toList();
    }

    // 分类过滤（仅当导航选中"目录"时）
    if (_selectedNavIndex == 1 && dirProvider != null) {
      final selectedDir = dirProvider.selectedCategory;
      if (selectedDir != null && selectedDir.id != allNotesCategoryId) {
        final allDirIds = dirProvider.getAllDescendantCategoryIds(
          selectedDir.id,
        );
        notes = notes.where((n) => allDirIds.contains(n.category)).toList();
      }
    }

    // 搜索过滤
    if (provider.searchQuery.isNotEmpty) {
      notes = notes
          .where(
            (n) => n.title.toLowerCase().contains(
              provider.searchQuery.toLowerCase(),
            ),
          )
          .toList();
    }

    return notes;
  }

  void _onNavItemSelected(int index) {
    if (index == 3) {
      _navigateToSettings();
      return;
    }

    setState(() {
      _selectedNavIndex = index;
      _selectedNote = null;
    });
  }

  void _selectNote(NotePreview preview) {
    if (_selectedNote?.id == preview.id) {
      setState(() => _selectedNote = null);
    } else {
      context.read<NotesProvider>().getFullNote(preview.id).then((note) {
        if (note != null && mounted) {
          setState(() => _selectedNote = note);
        }
      });
    }
  }

  Future<void> _handleNoteTapFromCici(Note note) async {
    final fullNote = await context.read<NotesProvider>().getFullNote(note.id);
    if (fullNote != null && mounted) {
      setState(() {
        _selectedNote = fullNote;
        _isAIPanelOpen = false;
      });
    }
  }

  Future<void> _openNote(NotePreview preview) async {
    final notesProvider = context.read<NotesProvider>();
    final fullNote = await notesProvider.getFullNote(preview.id);
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

  void _editNote(Note note) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditorScreen(note: note, startInEditMode: true),
      ),
    );
  }

  void _createNewNote() {
    final directoryProvider = context.read<CategoryProvider>();
    String? category;

    // 只有当在"目录"导航页时，才使用选中的分类作为默认分类
    if (_selectedNavIndex == 1) {
      final selectedDir = directoryProvider.selectedCategory;
      if (selectedDir != null && !selectedDir.isVirtual) {
        category = selectedDir.id;
      }
    }
    // 其他页面（首页、收藏）新建笔记默认不指定分类

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditorScreen(initialCategory: category),
      ),
    );
  }

  void _showNewNoteDialog(BuildContext context) {
    final t = Translations.of(context);
    final directoryProvider = context.read<CategoryProvider>();
    String? category;

    // 只有当在"目录"导航页时，才使用选中的分类作为默认分类
    if (_selectedNavIndex == 1) {
      final selectedDir = directoryProvider.selectedCategory;
      if (selectedDir != null && !selectedDir.isVirtual) {
        category = selectedDir.id;
      }
    }
    // 其他页面（首页、收藏）新建笔记默认不指定分类

    NoteFormat selectedFormat = NoteFormat.markdown;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(DesignTokens.radiusLG),
            ),
            backgroundColor: isDarkMode
                ? DesignTokens.darkSurface
                : Colors.white,
            child: Container(
              width: 350,
              padding: EdgeInsets.all(DesignTokens.space6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.dialog_selectNoteFormat,
                    style: TextStyle(
                      fontSize: DesignTokens.fontSizeH3,
                      fontWeight: DesignTokens.fontWeightSemiBold,
                      color: isDarkMode
                          ? DesignTokens.darkTextPrimary
                          : DesignTokens.gray900,
                    ),
                  ),
                  SizedBox(height: DesignTokens.space6),
                  FormatOptionWidget(
                    format: NoteFormat.markdown,
                    icon: Icons.text_fields,
                    title: 'Markdown',
                    description: t.dialog_markdownDescription,
                    isSelected: selectedFormat == NoteFormat.markdown,
                    onTap: () =>
                        setState(() => selectedFormat = NoteFormat.markdown),
                    isDarkMode: isDarkMode,
                  ),
                  SizedBox(height: DesignTokens.space3),
                  FormatOptionWidget(
                    format: NoteFormat.plainText,
                    icon: Icons.note,
                    title: t.dialog_plainText,
                    description: t.dialog_plainTextDescription,
                    isSelected: selectedFormat == NoteFormat.plainText,
                    onTap: () =>
                        setState(() => selectedFormat = NoteFormat.plainText),
                    isDarkMode: isDarkMode,
                  ),
                  SizedBox(height: DesignTokens.space3),
                  FormatOptionWidget(
                    format: NoteFormat.richText,
                    icon: Icons.text_fields,
                    title: t.dialog_richText,
                    description: t.dialog_richTextDescription,
                    isSelected: selectedFormat == NoteFormat.richText,
                    onTap: () =>
                        setState(() => selectedFormat = NoteFormat.richText),
                    isDarkMode: isDarkMode,
                  ),
                  SizedBox(height: DesignTokens.space3),
                  FormatOptionWidget(
                    format: NoteFormat.code,
                    icon: Icons.code,
                    title: t.dialog_code,
                    description: t.dialog_codeDescription,
                    isSelected: selectedFormat == NoteFormat.code,
                    onTap: () =>
                        setState(() => selectedFormat = NoteFormat.code),
                    isDarkMode: isDarkMode,
                    enabled: false,
                  ),
                  SizedBox(height: DesignTokens.space6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: Text(
                          t.common_cancel,
                          style: TextStyle(
                            fontSize: DesignTokens.fontSizeBody,
                            color: isDarkMode
                                ? DesignTokens.darkTextSecondary
                                : DesignTokens.gray500,
                          ),
                        ),
                      ),
                      SizedBox(width: DesignTokens.space2),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          Navigator.push(
                            this.context,
                            MaterialPageRoute(
                              builder: (context) => EditorScreen(
                                initialCategory: category,
                                initialFormat: selectedFormat,
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: DesignTokens.primary500,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              DesignTokens.radiusSM,
                            ),
                          ),
                        ),
                        child: Text(t.common_create),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showImportFileDialog(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          'txt',
          'md',
          'markdown',
          'html',
          'htm',
          'py',
          'js',
          'ts',
          'java',
          'dart',
          'go',
          'rs',
          'c',
          'cpp',
          'h',
          'hpp',
          'cs',
          'swift',
          'rb',
          'php',
          'sql',
          'sh',
          'bash',
          'json',
          'yaml',
          'yml',
          'xml',
          'css',
          'scss',
          'sass',
        ],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = File(result.files.first.path!);
        if (!context.mounted) return;
        final notesProvider = context.read<NotesProvider>();

        final noteId = await notesProvider.importNoteFromFile(file);

        if (noteId != null) {
          if (!context.mounted) return;
          SnackBarHelper.showWithDuration(
            context,
            t.dialog_noteImportSuccess,
            duration: const Duration(seconds: 2),
          );
        } else {
          if (!context.mounted) return;
          SnackBarHelper.showWithDuration(
            context,
            t.dialog_importFailedUnsupported,
            duration: const Duration(seconds: 2),
          );
        }
      }
    } catch (e) {
      debugPrint('File import error: $e');
      if (!context.mounted) return;
      SnackBarHelper.showWithDuration(
        context,
        t.dialog_importFailed(error: e),
        duration: const Duration(seconds: 2),
      );
    }
  }

  void _toggleFavorite(NotePreview preview) {
    context.read<NotesProvider>().toggleFavorite(preview.id);
  }

  void _confirmDeleteNote(NotePreview preview) {
    final t = Translations.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.common_confirmDelete),
        content: Text(
          '确定删除笔记 "${preview.title.isEmpty ? t.editor_untitledNote : preview.title}" 吗？',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(t.common_cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: DesignTokens.error,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _deleteNote(preview);
            },
            child: Text(t.common_delete, style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteNote(NotePreview preview) async {
    setState(() => _isDeletingNoteId = preview.id);

    await context.read<NotesProvider>().deleteNote(preview.id);

    await Future.delayed(const Duration(milliseconds: 300));

    if (mounted && _selectedNote?.id == preview.id) {
      setState(() => _selectedNote = null);
    }
    if (mounted) {
      setState(() => _isDeletingNoteId = null);
      SnackBarHelper.show(context, t.home_noteMovedToTrash);
    }
  }

  void _showNoteContextMenu(NotePreview preview) {
    final t = Translations.of(context);
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(DesignTokens.radiusLG),
        ),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.edit, color: DesignTokens.primary500),
              title: Text(t.common_edit),
              onTap: () async {
                Navigator.pop(ctx);
                final fullNote = await context
                    .read<NotesProvider>()
                    .getFullNote(preview.id);
                if (fullNote != null && mounted) {
                  _editNote(fullNote);
                }
              },
            ),
            ListTile(
              leading: Icon(
                preview.isFavorite ? Icons.star : Icons.star_border,
                color: DesignTokens.accent500,
              ),
              title: Text(
                preview.isFavorite ? t.home_unfavorite : t.home_favorite,
              ),
              onTap: () {
                Navigator.pop(ctx);
                _toggleFavorite(preview);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete_rounded, color: DesignTokens.error),
              title: Text(
                t.common_delete,
                style: TextStyle(color: DesignTokens.error),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _confirmDeleteNote(preview);
              },
            ),
            ListTile(
              leading: Icon(Icons.share_rounded, color: DesignTokens.info),
              title: Text(t.home_share),
              onTap: () {
                Navigator.pop(ctx);
                SnackBarHelper.show(context, t.home_shareComingSoon);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedNoteIds.clear();
      }
    });
  }

  void _toggleNoteSelection(NotePreview preview) {
    setState(() {
      if (_selectedNoteIds.contains(preview.id)) {
        _selectedNoteIds.remove(preview.id);
      } else {
        _selectedNoteIds.add(preview.id);
      }
    });
  }

  void _batchDeleteNotes() {
    if (_selectedNoteIds.isEmpty) return;
    final t = Translations.of(context);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.home_confirmBatchDelete),
        content: Text('确定删除已选中的 ${_selectedNoteIds.length} 个笔记吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(t.common_cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: DesignTokens.error,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _performBatchDelete();
            },
            child: Text(t.common_delete, style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _performBatchDelete() {
    final provider = context.read<NotesProvider>();
    final count = _selectedNoteIds.length;

    for (final id in _selectedNoteIds) {
      provider.deleteNote(id);
      if (_selectedNote?.id == id) {
        _selectedNote = null;
      }
    }

    _toggleSelectionMode();

    SnackBarHelper.showWithDuration(
      context,
      '已删除 $count 个笔记',
      duration: const Duration(seconds: 2),
    );
  }

  Widget _buildBatchActionBar(bool isDark) {
    return Container(
      padding: EdgeInsets.all(DesignTokens.space4),
      decoration: BoxDecoration(
        color: isDark ? DesignTokens.darkSurface : Colors.white,
        boxShadow: DesignTokens.shadowMD,
        border: Border(
          top: BorderSide(
            color: isDark ? DesignTokens.darkBorder : DesignTokens.gray200,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Text(
              '已选中 ${_selectedNoteIds.length} 个笔记',
              style: TextStyle(
                fontSize: DesignTokens.fontSizeBody,
                color: isDark
                    ? DesignTokens.darkTextPrimary
                    : DesignTokens.gray900,
              ),
            ),
            Spacer(),
            ElevatedButton.icon(
              icon: Icon(Icons.delete_rounded, size: 16),
              label: Text(t.common_delete),
              style: ElevatedButton.styleFrom(
                backgroundColor: DesignTokens.error,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: DesignTokens.space6,
                  vertical: DesignTokens.space3,
                ),
              ),
              onPressed: _batchDeleteNotes,
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToSettings() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => const SettingsDialog(),
    );
  }

  void _showAIBottomSheet() {
    setState(() => _isAIPanelOpen = true);
  }

  void _openSearchDialog() {
    showDialog(
      context: context,
      builder: (context) =>
          SearchDialog(notesProvider: context.read<NotesProvider>()),
    );
  }

  Future<void> _showTrashDialog() async {
    final provider = context.read<NotesProvider>();
    await provider.refreshTrashNotes();

    if (!mounted) return;
    final t = Translations.of(context);

    showDialog(
      context: context,
      builder: (ctx) => Consumer<NotesProvider>(
        builder: (context, provider, _) {
          final trashNotes = provider.getTrashNotes();
          final isDark = Theme.of(context).brightness == Brightness.dark;

          return StatefulBuilder(
            builder: (context, setState) => AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.archive, color: DesignTokens.error),
                  SizedBox(width: DesignTokens.space2),
                  Text(t.home_trashTitle),
                  if (trashNotes.isNotEmpty)
                    Container(
                      margin: EdgeInsets.only(left: DesignTokens.space2),
                      padding: EdgeInsets.symmetric(
                        horizontal: DesignTokens.space2,
                        vertical: DesignTokens.space1,
                      ),
                      decoration: BoxDecoration(
                        color: DesignTokens.error.withValues(
                          alpha: isDark ? 0.6 : 0.1,
                        ),
                        borderRadius: BorderRadius.circular(
                          DesignTokens.radiusXS,
                        ),
                      ),
                      child: Text(
                        '${trashNotes.length}',
                        style: TextStyle(
                          fontSize: DesignTokens.fontSizeCaption,
                          color: DesignTokens.error,
                        ),
                      ),
                    ),
                ],
              ),
              content: trashNotes.isEmpty
                  ? Padding(
                      padding: EdgeInsets.all(DesignTokens.space8),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.delete_outline,
                            size: 48,
                            color: DesignTokens.gray400,
                          ),
                          SizedBox(height: DesignTokens.space4),
                          Text(
                            t.home_trashEmpty,
                            style: TextStyle(color: DesignTokens.gray500),
                          ),
                        ],
                      ),
                    )
                  : SizedBox(
                      width: double.maxFinite,
                      height: 400,
                      child: ListView.builder(
                        itemCount: trashNotes.length,
                        itemBuilder: (context, index) {
                          final note = trashNotes[index];
                          final daysInTrash = note.deletedAt != null
                              ? DateTime.now()
                                    .difference(note.deletedAt!)
                                    .inDays
                              : 0;

                          return Container(
                            margin: EdgeInsets.only(
                              bottom: DesignTokens.space2,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? DesignTokens.darkSurface
                                  : DesignTokens.gray50,
                              borderRadius: BorderRadius.circular(
                                DesignTokens.radiusMD,
                              ),
                              border: Border.all(
                                color: DesignTokens.error.withValues(
                                  alpha: isDark ? 0.7 : 0.3,
                                ),
                              ),
                            ),
                            child: ListTile(
                              title: Text(
                                note.title.isEmpty
                                    ? t.card_untitledNote
                                    : note.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text('$daysInTrash天前删除'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      Icons.restore_rounded,
                                      color: DesignTokens.primary500,
                                    ),
                                    onPressed: () async {
                                      await provider.restoreFromTrash(note.id);
                                      await provider.refreshTrashNotes();
                                      setState(() {});
                                      if (context.mounted) {
                                        SnackBarHelper.show(
                                          context,
                                          t.home_noteRestored,
                                        );
                                      }
                                    },
                                    tooltip: t.home_restore,
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      Icons.delete_forever_rounded,
                                      color: DesignTokens.error,
                                    ),
                                    onPressed: () async {
                                      await provider.permanentlyDelete(note.id);
                                      await provider.refreshTrashNotes();
                                      setState(() {});
                                      if (context.mounted) {
                                        SnackBarHelper.show(
                                          context,
                                          t.home_notePermanentlyDeleted,
                                        );
                                      }
                                    },
                                    tooltip: t.home_permanentlyDelete,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
              actions: [
                if (trashNotes.isNotEmpty)
                  TextButton(
                    onPressed: () =>
                        _confirmEmptyTrash(ctx, provider, setState),
                    child: Text(
                      t.home_emptyTrashTitle,
                      style: TextStyle(color: DesignTokens.error),
                    ),
                  ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(t.common_close),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _confirmEmptyTrash(
    BuildContext ctx,
    NotesProvider provider,
    StateSetter setState,
  ) {
    final t = Translations.of(ctx);
    final trashCount = provider.getTrashNotes().length;
    showDialog(
      context: ctx,
      builder: (dialogCtx) => AlertDialog(
        title: Text(t.home_emptyTrashTitle),
        content: Text('确定清空回收站中的 $trashCount 个笔记吗？此操作不可恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text(t.common_cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: DesignTokens.error,
            ),
            onPressed: () async {
              await provider.emptyTrash();
              await provider.refreshTrashNotes();
              setState(() {});
              if (!dialogCtx.mounted) return;
              Navigator.pop(dialogCtx);
              SnackBarHelper.show(ctx, t.home_trashEmptied);
            },
            child: Text(t.common_clear, style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showThemeQuickSwitch(BuildContext context) {
    final t = Translations.of(context);
    final themeProvider = context.read<ThemeProvider>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.home_switchTheme),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildQuickThemeOption(
              ctx,
              themeProvider,
              ThemeMode.system,
              t.common_followSystem,
              Icons.brightness_auto,
            ),
            _buildQuickThemeOption(
              ctx,
              themeProvider,
              ThemeMode.light,
              t.common_lightMode,
              Icons.light_mode,
            ),
            _buildQuickThemeOption(
              ctx,
              themeProvider,
              ThemeMode.dark,
              t.common_darkMode,
              Icons.dark_mode,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickThemeOption(
    BuildContext context,
    ThemeProvider provider,
    ThemeMode mode,
    String title,
    IconData icon,
  ) {
    final isSelected = provider.themeMode == mode;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final selectedColor = isDark
        ? DesignTokens.primary200
        : Theme.of(context).primaryColor;

    return ListTile(
      leading: Icon(icon, color: isSelected ? selectedColor : null),
      title: Text(title),
      trailing: isSelected ? Icon(Icons.check, color: selectedColor) : null,
      onTap: () {
        provider.setThemeMode(mode);
        Navigator.pop(context);
      },
    );
  }

  Widget _buildTabletDrawer(bool isDark) {
    final t = Translations.of(context);
    return Drawer(
      width: 250,
      child: Container(
        color: isDark ? DesignTokens.darkSurface : Colors.white,
        child: Column(
          children: [
            Container(
              height: 80,
              padding: EdgeInsets.symmetric(horizontal: DesignTokens.space6),
              child: Row(
                children: [
                  Image.asset(
                    'assets/images/app_icon@200h.png',
                    width: 32,
                    height: 32,
                  ),
                  SizedBox(width: DesignTokens.space3),
                  Text(
                    'OpenNote',
                    style: TextStyle(
                      fontSize: DesignTokens.fontSizeH2,
                      fontWeight: DesignTokens.fontWeightSemiBold,
                      color: isDark
                          ? DesignTokens.darkTextPrimary
                          : DesignTokens.gray900,
                    ),
                  ),
                ],
              ),
            ),
            Divider(
              color: isDark ? DesignTokens.darkBorder : DesignTokens.gray200,
              height: 1,
            ),
            Expanded(
              child: Column(
                children: [
                  _buildDrawerNavItem(Icons.home, t.home_home, 0, isDark),
                  _buildDrawerNavItem(Icons.note, t.home_note, 1, isDark),
                  _buildDrawerNavItem(Icons.star, t.home_favorites, 2, isDark),
                ],
              ),
            ),
            Divider(
              color: isDark ? DesignTokens.darkBorder : DesignTokens.gray200,
              height: 1,
            ),
            Container(
              padding: EdgeInsets.all(DesignTokens.space4),
              child: Column(
                children: [
                  _buildDrawerThemeToggle(isDark),
                  SizedBox(height: DesignTokens.space2),
                  _buildDrawerSettingsButton(isDark),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerNavItem(
    IconData icon,
    String label,
    int index,
    bool isDark,
  ) {
    final isSelected = _selectedNavIndex == index;

    return InkWell(
      onTap: () {
        _onNavItemSelected(index);
        Navigator.of(context).pop();
      },
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: DesignTokens.space6,
          vertical: DesignTokens.space4,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark
                    ? DesignTokens.darkPrimary700.withValues(alpha: 0.2)
                    : DesignTokens.primary100)
              : Colors.transparent,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected
                  ? (isDark
                        ? DesignTokens.darkPrimary500
                        : DesignTokens.primary500)
                  : (isDark
                        ? DesignTokens.darkTextSecondary
                        : DesignTokens.gray500),
            ),
            SizedBox(width: DesignTokens.space4),
            Text(
              label,
              style: TextStyle(
                fontSize: DesignTokens.fontSizeBody,
                fontWeight: isSelected
                    ? DesignTokens.fontWeightSemiBold
                    : DesignTokens.fontWeightRegular,
                color: isSelected
                    ? (isDark
                          ? DesignTokens.darkPrimary500
                          : DesignTokens.primary500)
                    : (isDark
                          ? DesignTokens.darkTextPrimary
                          : DesignTokens.gray700),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerThemeToggle(bool isDark) {
    final themeProvider = context.watch<ThemeProvider>();

    return InkWell(
      onTap: () {
        final newMode = isDark ? ThemeMode.light : ThemeMode.dark;
        themeProvider.setThemeMode(newMode);
        Navigator.of(context).pop();
      },
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: DesignTokens.space6,
          vertical: DesignTokens.space4,
        ),
        child: Row(
          children: [
            Icon(
              isDark ? Icons.light_mode : Icons.dark_mode,
              size: 20,
              color: isDark
                  ? DesignTokens.darkTextSecondary
                  : DesignTokens.gray500,
            ),
            SizedBox(width: DesignTokens.space4),
            Text(
              isDark ? t.home_switchToLight : t.home_switchToDark,
              style: TextStyle(
                fontSize: DesignTokens.fontSizeBody,
                fontWeight: DesignTokens.fontWeightRegular,
                color: isDark
                    ? DesignTokens.darkTextPrimary
                    : DesignTokens.gray700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerSettingsButton(bool isDark) {
    return InkWell(
      onTap: () {
        Navigator.of(context).pop();
        _navigateToSettings();
      },
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: DesignTokens.space6,
          vertical: DesignTokens.space4,
        ),
        child: Row(
          children: [
            Icon(
              Icons.settings,
              size: 20,
              color: isDark
                  ? DesignTokens.darkTextSecondary
                  : DesignTokens.gray500,
            ),
            SizedBox(width: DesignTokens.space4),
            Text(
              t.settings_title,
              style: TextStyle(
                fontSize: DesignTokens.fontSizeBody,
                fontWeight: DesignTokens.fontWeightRegular,
                color: isDark
                    ? DesignTokens.darkTextPrimary
                    : DesignTokens.gray700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
