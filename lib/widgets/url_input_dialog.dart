// Copyright (c) 2026 litongshuai
// SPDX-License-Identifier: MIT OR Apache-2.0

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/readability_service.dart';
import '../services/dart_scraper_service.dart';
import '../models/article_data.dart';
import '../models/note_data.dart';
import '../providers/settings_provider.dart';
import '../providers/tags_provider.dart';
import '../providers/category_provider.dart';
import '../utils/category_path_helper.dart';
import '../theme/design_tokens.dart';
import '../l10n/strings.g.dart';

class URLInputDialog extends StatefulWidget {
  final Function(NoteData) onSave;
  final String? initialUrl;

  const URLInputDialog({super.key, required this.onSave, this.initialUrl});

  @override
  State<URLInputDialog> createState() => _URLInputDialogState();
}

class _URLInputDialogState extends State<URLInputDialog> {
  final TextEditingController _urlController = TextEditingController();
  final ReadabilityService _readabilityService = ReadabilityService();
  final DartScraperService _scraperService = DartScraperService();
  bool _isLoading = false;
  bool _isInitializing = false;
  String? _errorMessage;
  ArticleData? _extractedData;
  NoteData? _initializedNote;

  @override
  void initState() {
    super.initState();
    if (widget.initialUrl != null && widget.initialUrl!.trim().isNotEmpty) {
      _urlController.text = widget.initialUrl!.trim();
      Future.delayed(const Duration(milliseconds: 100), () {
        _extractAndInitialize();
      });
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    _readabilityService.dispose();
    _scraperService.dispose();
    super.dispose();
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData('text/plain');
    if (data?.text != null && data!.text!.trim().isNotEmpty) {
      setState(() {
        _urlController.text = data.text!.trim();
        _errorMessage = null;
      });
    }
  }

  Future<void> _extractAndInitialize() async {
    String url = _urlController.text.trim();

    if (url.isEmpty) {
      setState(() => _errorMessage = t.dialog_enterUrl);
      return;
    }

    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
      _urlController.text = url;
    }

    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      setState(() => _errorMessage = t.dialog_invalidUrlFormat);
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _extractedData = null;
      _initializedNote = null;
    });

    try {
      ArticleData? articleData;

      articleData = await _readabilityService.extractFromUrl(url);

      if (articleData == null) {
        debugPrint('Readability提取失败，使用DartScraperService fallback');
        final scrapedData = await _scraperService.scrapeUrl(url);
        if (scrapedData != null) {
          articleData = ArticleData(
            title: scrapedData['title'] ?? 'Untitled',
            textContent: scrapedData['content'] ?? '',
            htmlContent: scrapedData['content'] ?? '',
            author: scrapedData['author'],
            publishDate: scrapedData['publish_date'],
            url: url,
          );
        }
      }

      if (articleData == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = t.dialog_extractFailed;
        });
        return;
      }

      setState(() {
        _isLoading = false;
        _extractedData = articleData;
      });

      await _initializeNoteWithAI(articleData);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = '提取失败: $e';
      });
    }
  }

  Future<void> _initializeNoteWithAI(ArticleData articleData) async {
    final settingsProvider = context.read<SettingsProvider>();
    if (!settingsProvider.hasActiveProvider) {
      setState(() {
        _initializedNote = NoteData(
          title: articleData.title,
          content: articleData.textContent,
          url: articleData.url,
        );
      });
      return;
    }

    setState(() => _isInitializing = true);

    try {
      final aiService = settingsProvider.aiService;
      final tagsProvider = context.read<TagsProvider>();
      final existingTags = tagsProvider.tags.map((tag) => tag.name).toList();

      // 获取分类路径列表
      final dirProvider = context.read<CategoryProvider>();
      final categoryPaths = CategoryPathHelper.generateCategoryPathsWithId(
        dirProvider,
      );

      final initializedData = await aiService.initializeNoteFromUrl(
        title: articleData.title,
        rawContent: articleData.textContent,
        author: articleData.author,
        publishDate: articleData.publishDate,
        modelOverride: null,
        existingTags: existingTags,
        categories: categoryPaths,
      );

      setState(() {
        _isInitializing = false;
        _initializedNote = NoteData(
          title: initializedData.containsKey('title')
              ? initializedData['title'] as String
              : articleData.title,
          content: initializedData['content'] as String,
          url: articleData.url,
          summary: initializedData['summary'] as String?,
          keywords: initializedData['keywords'] as List<String>?,
          category: initializedData['category'] as String?,
          categoryPath: initializedData['categoryPath'] as String?,
          tags: initializedData['tags'] as List<String>?,
        );
      });
    } catch (e) {
      debugPrint('AI初始化失败: $e');
      setState(() {
        _isInitializing = false;
        _initializedNote = NoteData(
          title: articleData.title,
          content: articleData.textContent,
          url: articleData.url,
        );
      });
    }
  }

  Widget _buildPreviewField(String label, String value, {int maxLines = 1}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labelColor = isDark
        ? DesignTokens.primary200
        : Theme.of(context).primaryColor;

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: labelColor,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              border: Border.all(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
              ),
              borderRadius: BorderRadius.circular(4),
            ),
            child: maxLines > 1
                ? ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: maxLines * 24.0),
                    child: SingleChildScrollView(
                      child: Text(
                        value,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  )
                : Text(
                    value,
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // 主题感知颜色
    final backgroundColor = isDark
        ? DesignTokens.primary200.withValues(alpha: 0.1)
        : Theme.of(context).primaryColor.withValues(alpha: 0.1);
    final borderColor = isDark
        ? DesignTokens.primary200.withValues(alpha: 0.3)
        : Theme.of(context).primaryColor.withValues(alpha: 0.3);
    final iconTextColor = isDark
        ? DesignTokens.primary200
        : Theme.of(context).primaryColor;

    return AlertDialog(
      title: Text(t.dialog_createFromUrl),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _urlController,
              enableInteractiveSelection: true,
              autofillHints: const [AutofillHints.url],
              decoration: InputDecoration(
                labelText: t.dialog_webUrl,
                hintText: t.dialog_urlHint,
                border: const OutlineInputBorder(),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.content_paste),
                      onPressed: _pasteFromClipboard,
                      tooltip: t.common_paste,
                    ),
                    IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _urlController.clear();
                        setState(() {
                          _errorMessage = null;
                          _extractedData = null;
                          _initializedNote = null;
                        });
                      },
                      tooltip: t.common_clear,
                    ),
                  ],
                ),
              ),
              onSubmitted: (_) => _extractAndInitialize(),
            ),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 16,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (_isLoading)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Center(
                  child: Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 8),
                      Text(t.dialog_extractingContent),
                    ],
                  ),
                ),
              ),
            if (_extractedData != null && !_isLoading)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Divider(),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          t.dialog_extractSuccess,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(color: Colors.green),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_extractedData!.title.isNotEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: backgroundColor,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: borderColor),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              t.editor_title,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _extractedData!.title,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    if (_isInitializing)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Center(
                          child: Column(
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 8),
                              Text(t.dialog_aiInitializing),
                            ],
                          ),
                        ),
                      ),
                    if (_initializedNote != null && !_isInitializing) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: backgroundColor,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: borderColor),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.auto_awesome,
                                  color: iconTextColor,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  t.dialog_noteAutoInitialized,
                                  style: TextStyle(
                                    color: iconTextColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            if (_initializedNote!.summary != null)
                              _buildPreviewField(
                                t.dialog_summary,
                                _initializedNote!.summary!,
                                maxLines: 3,
                              ),
                            if (_initializedNote!.keywords != null &&
                                _initializedNote!.keywords!.isNotEmpty)
                              _buildPreviewField(
                                t.dialog_keywords,
                                _initializedNote!.keywords!.join(', '),
                                maxLines: 2,
                              ),
                            if (_initializedNote!.categoryPath != null)
                              _buildPreviewField(
                                t.dialog_category,
                                _initializedNote!.categoryPath!,
                                maxLines: 1,
                              ),
                            if (_initializedNote!.tags != null &&
                                _initializedNote!.tags!.isNotEmpty)
                              _buildPreviewField(
                                t.dialog_tags,
                                _initializedNote!.tags!.join(', '),
                                maxLines: 2,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(t.common_cancel),
        ),
        if (!_isLoading && !_isInitializing && _extractedData == null)
          ElevatedButton.icon(
            onPressed: _extractAndInitialize,
            icon: const Icon(Icons.download),
            label: Text(t.dialog_extractContent),
          ),
        if (!_isLoading && !_isInitializing && _initializedNote != null)
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              widget.onSave(_initializedNote!);
            },
            icon: const Icon(Icons.save),
            label: Text(t.dialog_createNote),
          ),
      ],
    );
  }
}
