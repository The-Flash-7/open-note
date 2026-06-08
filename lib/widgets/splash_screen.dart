// Copyright (c) 2026 litongshuai
// SPDX-License-Identifier: MIT OR Apache-2.0

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';

import '../config/knowledge_config.dart';
import '../providers/theme_provider.dart';
import '../providers/notes_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/tags_provider.dart';
import '../providers/background_summary_provider.dart';
import '../providers/category_provider.dart';
import '../providers/knowledge_base_provider.dart';
import '../providers/memory_settings_provider.dart';
import '../providers/update_provider.dart';
import '../providers/language_provider.dart';
import '../services/note_service.dart';
import '../services/memory_extractor.dart';
import '../theme/design_tokens.dart';
import '../l10n/strings.g.dart';
import '../utils/global_search_handler.dart';
import '../utils/app_info.dart';
import '../screens/home_screen.dart';
import '../screens/editor_screen.dart';
import '../theme/app_theme.dart';
import '../widgets/new_note_dialog.dart';
import '../widgets/update_notification.dart';
import 'package:flutter_quill/flutter_quill.dart';

enum _SplashStatus { loading, ready, error }

class SplashApp extends StatelessWidget {
  const SplashApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const SplashScreen();
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  _SplashStatus _status = _SplashStatus.loading;
  String? _error;
  bool _showContent = false;
  bool _isFadingOut = false;

  ThemeProvider? _themeProvider;
  NotesProvider? _notesProvider;
  SettingsProvider? _settingsProvider;
  TagsProvider? _tagsProvider;
  BackgroundSummaryProvider? _backgroundSummaryProvider;
  CategoryProvider? _categoryProvider;
  KnowledgeBaseProvider? _knowledgeBaseProvider;
  MemorySettingsProvider? _memoryProvider;
  UpdateProvider? _updateProvider;
  LanguageProvider? _languageProvider;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() => _showContent = true);
    });
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _initialize();
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  static const _minSplashDuration = Duration(milliseconds: 1800);

  Future<void> _yieldFrame() async {
    await Future.delayed(const Duration(milliseconds: 8));
    await Future.delayed(Duration.zero);
  }

  Future<void> _initialize() async {
    final startTime = DateTime.now();
    try {
      await _yieldFrame();
      final noteService = NoteService();
      await noteService.init();

      await _yieldFrame();
      final memoryExtractor = MemoryExtractor();
      await memoryExtractor.init();

      await _yieldFrame();
      _themeProvider = ThemeProvider();
      await _themeProvider!.loadThemeMode();

      await _yieldFrame();
      _settingsProvider = SettingsProvider();
      await _settingsProvider!.loadSettings();

      await _yieldFrame();
      _categoryProvider = CategoryProvider();
      await _categoryProvider!.init();

      await _yieldFrame();
      await KnowledgeConfig.instance.load();

      await _yieldFrame();
      _memoryProvider = MemorySettingsProvider(
        settingsProvider: _settingsProvider,
      );

      await _yieldFrame();
      _notesProvider = NotesProvider();
      _notesProvider!.setMemorySettingsProvider(_memoryProvider!);
      _notesProvider!.setCategoryProvider(_categoryProvider!);
      _notesProvider!.setAIService(_settingsProvider!.aiService);

      await _yieldFrame();
      _tagsProvider = TagsProvider();
      await _tagsProvider!.loadTags();

      await _yieldFrame();
      _knowledgeBaseProvider = KnowledgeBaseProvider();
      await _knowledgeBaseProvider!.loadConfig();

      await _yieldFrame();
      _backgroundSummaryProvider = BackgroundSummaryProvider();
      _backgroundSummaryProvider!.setProviders(
        _notesProvider!,
        _settingsProvider!.aiService,
      );

      await _yieldFrame();
      _updateProvider = UpdateProvider();
      await _updateProvider!.init();

      await _yieldFrame();
      _languageProvider = await LanguageProvider.create();

      // 注入用户语言设置到 NotesProvider
      if (_languageProvider!.locale != null && _notesProvider != null) {
        _notesProvider!.setUserLanguage(_languageProvider!.locale!);
      }

      // 注册语言变化回调，用户修改设置中的语言时实时更新 Agent
      _languageProvider!.onLanguageChanged((locale) {
        _notesProvider?.setUserLanguage(locale);
      });

      await _yieldFrame();
      await windowManager.show();
      await windowManager.focus();

      final elapsed = DateTime.now().difference(startTime);
      //避免启动页一闪而过
      if (elapsed < _minSplashDuration) {
        final remaining = _minSplashDuration - elapsed;
        debugPrint(
          'SplashScreen: 初始化耗时 ${elapsed.inMilliseconds}ms，等待 ${remaining.inMilliseconds}ms 后显示主页',
        );
        await Future.delayed(remaining);
      } else {
        debugPrint('SplashScreen: 初始化耗时 ${elapsed.inMilliseconds}ms，直接进入主页');
      }

      if (mounted) {
        setState(() => _isFadingOut = true);
        await Future.delayed(const Duration(milliseconds: 200));
        if (mounted) {
          setState(() => _status = _SplashStatus.ready);
        }
      }
    } catch (e, stack) {
      debugPrint('SplashScreen 初始化失败: $e\n$stack');
      if (mounted) {
        setState(() {
          _status = _SplashStatus.error;
          _error = e.toString();
        });
      }
    }
  }

  Future<String> _getVersionString() async {
    final info = AppInfo.instance;
    return 'v${info.version}';
  }

  Future<void> _retry() async {
    setState(() {
      _status = _SplashStatus.loading;
      _error = null;
    });
    await _initialize();
  }

  @override
  Widget build(BuildContext context) {
    if (_status == _SplashStatus.ready) {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: _themeProvider!),
          ChangeNotifierProvider.value(value: _notesProvider!),
          ChangeNotifierProvider.value(value: _settingsProvider!),
          ChangeNotifierProvider.value(value: _tagsProvider!),
          ChangeNotifierProvider.value(value: _backgroundSummaryProvider!),
          ChangeNotifierProvider.value(value: _categoryProvider!),
          ChangeNotifierProvider.value(value: _knowledgeBaseProvider!),
          ChangeNotifierProvider.value(value: _memoryProvider!),
          ChangeNotifierProvider.value(value: _updateProvider!),
          ChangeNotifierProvider.value(value: _languageProvider!),
        ],
        child: const _HomeApp(),
      );
    }

    return MaterialApp(
      title: 'OpenNote',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: [FlutterQuillLocalizations.delegate],
      theme: _lightTheme(),
      darkTheme: _darkTheme(),
      themeMode: ThemeMode.system,
      home: Scaffold(
        body: AnimatedOpacity(
          opacity: _isFadingOut ? 0.0 : 1.0,
          duration: const Duration(milliseconds: 300),
          child: AnimatedSwitcher(
            duration: DesignTokens.durationNormal,
            child: _status == _SplashStatus.error
                ? _buildErrorPage()
                : _buildLoadingPage(),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingPage() {
    final isDark = MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    final primaryColor = isDark
        ? DesignTokens.darkPrimary500
        : DesignTokens.primary500;

    return Container(
      key: const ValueKey('loading'),
      color: isDark ? DesignTokens.darkSurface : Colors.white,
      child: Center(
        child: AnimatedOpacity(
          opacity: _showContent ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 600),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/images/app_icon@200h.png',
                width: 72,
                height: 72,
              ),
              const SizedBox(height: 24),
              _SplashSweepText(
                text: 'OpenNote',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: DesignTokens.fontWeightSemiBold,
                  letterSpacing: 2,
                ),
                primaryColor: primaryColor,
                textColor: isDark ? Colors.white : DesignTokens.gray900,
              ),
              const SizedBox(height: 40),
              FutureBuilder<String>(
                future: _getVersionString(),
                builder: (context, snapshot) {
                  return Text(
                    snapshot.data ?? '',
                    style: TextStyle(
                      fontSize: DesignTokens.fontSizeCaption,
                      color: isDark
                          ? DesignTokens.darkTextSecondary
                          : DesignTokens.gray400,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorPage() {
    final t = Translations.of(context);
    final isDark = MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    final primaryColor = isDark
        ? DesignTokens.darkPrimary500
        : DesignTokens.primary500;

    return Container(
      key: const ValueKey('error'),
      color: isDark ? DesignTokens.darkSurface : Colors.white,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: DesignTokens.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: DesignTokens.error,
                size: 32,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              t.splash_startFailed,
              style: TextStyle(
                fontSize: 20,
                fontWeight: DesignTokens.fontWeightSemiBold,
                color: isDark
                    ? DesignTokens.darkTextPrimary
                    : DesignTokens.gray900,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48),
              child: Text(
                _error ?? '未知错误',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: DesignTokens.fontSizeSmall,
                  color: isDark
                      ? DesignTokens.darkTextSecondary
                      : DesignTokens.gray500,
                ),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _retry,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(DesignTokens.radiusMD),
                ),
              ),
              child: Text(
                t.common_retry,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  ThemeData _lightTheme() => ThemeData(
    useMaterial3: true,
    fontFamily: 'NotoSansSC',
    scaffoldBackgroundColor: Colors.white,
  );

  ThemeData _darkTheme() => ThemeData(
    useMaterial3: true,
    fontFamily: 'NotoSansSC',
    scaffoldBackgroundColor: DesignTokens.darkSurface,
    colorScheme: ColorScheme.dark(
      primary: DesignTokens.darkPrimary500,
      surface: DesignTokens.darkSurface,
    ),
  );
}

class _SplashSweepText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final Color primaryColor;
  final Color textColor;

  const _SplashSweepText({
    required this.text,
    required this.style,
    required this.primaryColor,
    required this.textColor,
  });

  @override
  State<_SplashSweepText> createState() => _SplashSweepTextState();
}

class _SplashSweepTextState extends State<_SplashSweepText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final pos = _controller.value;
        final sweepWidth = 0.25;
        final start = (pos - sweepWidth).clamp(0.0, 1.0);
        final center = pos.clamp(0.0, 1.0);
        final end = (pos + sweepWidth).clamp(0.0, 1.0);

        return ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (Rect bounds) {
            return LinearGradient(
              begin: Alignment(-1.0, 0.0),
              end: Alignment(1.0, 0.0),
              colors: [
                widget.primaryColor,
                widget.textColor,
                widget.primaryColor,
              ],
              stops: [start, center, end],
            ).createShader(bounds);
          },
          child: Text(widget.text, style: widget.style),
        );
      },
    );
  }
}

class _HomeApp extends StatefulWidget {
  const _HomeApp();

  @override
  State<_HomeApp> createState() => _HomeAppState();
}

class _HomeAppState extends State<_HomeApp>
    with WidgetsBindingObserver, WindowListener {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    windowManager.addListener(this);
    windowManager.setPreventClose(true);
    _scheduleAutoUpdateCheck();
  }

  void _scheduleAutoUpdateCheck() {
    Future.delayed(const Duration(seconds: 30), () {
      if (!mounted) return;
      final updateProvider = context.read<UpdateProvider>();
      if (updateProvider.autoCheckUpdate) {
        updateProvider.checkForUpdate();
      }
    });
  }

  @override
  void onWindowClose() async {
    debugPrint('MyApp.onWindowClose() 被调用!');
    try {
      final kbProvider = context.read<KnowledgeBaseProvider>();
      kbProvider.stopPythonServiceSync();
    } catch (e) {
      debugPrint('停止 Python 服务失败: $e');
    }
    exit(0);
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    context.read<BackgroundSummaryProvider>().onAppStateChanged(state);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: GlobalSearchHandler.navigatorKey,
      title: 'OpenNote',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: [FlutterQuillLocalizations.delegate],
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: context.watch<ThemeProvider>().themeMode,
      builder: (context, child) {
        return Focus(
          autofocus: true,
          onKeyEvent: (FocusNode node, KeyEvent event) {
            if (event is KeyDownEvent) {
              final isMacOS = Platform.isMacOS;
              final hardwareKeyboard = HardwareKeyboard.instance;
              final key = event.logicalKey;

              final searchMatch = isMacOS
                  ? (hardwareKeyboard.isMetaPressed &&
                        hardwareKeyboard.isShiftPressed &&
                        key == LogicalKeyboardKey.keyF)
                  : (hardwareKeyboard.isControlPressed &&
                        hardwareKeyboard.isShiftPressed &&
                        key == LogicalKeyboardKey.keyF);

              final importMatch = isMacOS
                  ? (hardwareKeyboard.isMetaPressed &&
                        key == LogicalKeyboardKey.keyO)
                  : (hardwareKeyboard.isControlPressed &&
                        key == LogicalKeyboardKey.keyO);

              if (searchMatch) {
                GlobalSearchHandler.openSearchDialog();
                return KeyEventResult.handled;
              } else if (importMatch) {
                final ctx = GlobalSearchHandler.navigatorKey.currentContext;
                if (ctx != null) {
                  showDialog(
                    context: ctx,
                    builder: (context) => NewNoteDialog(
                      onBlankNoteCreated: (format) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                EditorScreen(initialFormat: format),
                          ),
                        );
                      },
                      onFileNoteCreated: null,
                    ),
                  );
                }
                return KeyEventResult.handled;
              }
            }
            return KeyEventResult.ignored;
          },
          child: Stack(children: [child!, const UpdateNotification()]),
        );
      },
      home: const HomeScreen(),
    );
  }
}
