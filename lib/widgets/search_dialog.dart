// Copyright (c) 2026 litongshuai
// SPDX-License-Identifier: MIT OR Apache-2.0

import 'dart:convert';
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/strings.g.dart';
import '../models/note_preview.dart';
import '../providers/category_provider.dart';
import '../providers/notes_provider.dart';
import '../screens/editor_screen.dart';
import '../theme/design_tokens.dart';

class SearchDialog extends StatefulWidget {
  final NotesProvider notesProvider;

  const SearchDialog({super.key, required this.notesProvider});

  @override
  State<SearchDialog> createState() => _SearchDialogState();
}

class _SearchDialogState extends State<SearchDialog> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  final List<GlobalKey> _resultKeys = [];
  Timer? _debounceTimer;

  List<NotePreview> _searchResults = [];
  List<String> _searchHistory = [];
  Map<String, String> _categories = {};
  String? _selectedCategory;
  bool _isLoading = false;
  int _selectedIndex = 0;
  bool _showHistory = true;
  bool _canAutoSearch = false;

  @override
  void initState() {
    super.initState();
    _loadSearchHistory();
    _loadCategories();
    _searchFocusNode.requestFocus();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _scrollController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getString('search_history');
    if (historyJson != null) {
      try {
        final List<dynamic> decoded = jsonDecode(historyJson);
        setState(() {
          _searchHistory = decoded.cast<String>();
        });
      } catch (e) {
        _searchHistory = [];
      }
    }
  }

  Future<void> _saveSearchHistory(String query) async {
    if (query.trim().isEmpty) return;

    _searchHistory.remove(query);
    _searchHistory.insert(0, query);

    if (_searchHistory.length > 5) {
      _searchHistory = _searchHistory.sublist(0, 5);
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('search_history', jsonEncode(_searchHistory));
    setState(() {});
  }

  Future<void> _clearSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('search_history');
    setState(() {
      _searchHistory = [];
    });
  }

  Future<void> _removeSearchHistoryItem(String query) async {
    setState(() {
      _searchHistory.remove(query);
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('search_history', jsonEncode(_searchHistory));
  }

  Future<void> _loadCategories() async {
    final categories = await widget.notesProvider.getAllCategories();
    if (!mounted) return;
    final dirProvider = context.read<CategoryProvider>();
    setState(() {
      _categories = {
        for (final category in categories)
          category.id: dirProvider.categories
              .firstWhere((c) => c.id == category.id)
              .name,
      };
    });
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();

    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _showHistory = true;
        _selectedIndex = 0;
        _canAutoSearch = false;
      });
      return;
    }

    setState(() {
      _showHistory = false;
    });

    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      if (_canAutoSearch) {
        _performSearch(query);
      }
    });
  }

  void _performSearch(String query) async {
    // 使用 allPreviews 进行搜索（不需要完整 content）
    final allPreviews = widget.notesProvider.allPreviews;
    final queryLower = query.toLowerCase();

    List<NotePreview> results = allPreviews.where((preview) {
      final matchesQuery = preview.title.toLowerCase().contains(queryLower);
      final matchesCategory =
          _selectedCategory == null || preview.category == _selectedCategory;

      return matchesQuery && matchesCategory;
    }).toList();

    results.sort(
      (a, b) =>
          _calculateSearchScore(b, query) - _calculateSearchScore(a, query),
    );

    results = results.take(100).toList();

    setState(() {
      _searchResults = results;
      _isLoading = false;
      _selectedIndex = 0;
    });

    if (results.isNotEmpty) {
      _saveSearchHistory(query);
    }
  }

  int _calculateSearchScore(NotePreview preview, String query) {
    int score = 0;
    final queryLower = query.toLowerCase();

    if (preview.title.toLowerCase() == queryLower) score += 100;
    if (preview.title.toLowerCase().startsWith(queryLower)) score += 80;
    if (preview.title.toLowerCase().contains(queryLower)) score += 60;
    if (preview.updatedAt.isAfter(
      DateTime.now().subtract(const Duration(hours: 24)),
    )) {
      score += 10;
    }

    return score;
  }

  void _openNote(NotePreview preview) async {
    Navigator.of(context).pop();
    final notesProvider = widget.notesProvider;
    final fullNote = await notesProvider.getFullNote(preview.id);
    if (!mounted) return;
    if (fullNote != null) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => EditorScreen(note: fullNote)),
      );
    }
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.enter) {
        if (_searchResults.isNotEmpty && _selectedIndex >= 0) {
          _openNote(_searchResults[_selectedIndex]);
        } else {
          _forceSearch();
        }
      } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        if (_searchResults.isNotEmpty &&
            _selectedIndex < _searchResults.length - 1) {
          setState(() {
            _selectedIndex++;
          });
          _scrollToSelectedIndex();
        }
      } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        if (_selectedIndex > 0) {
          setState(() {
            _selectedIndex--;
          });
          _scrollToSelectedIndex();
        }
      } else if (event.logicalKey == LogicalKeyboardKey.escape) {
        Navigator.of(context).pop();
      } else if (event.logicalKey == LogicalKeyboardKey.backspace ||
          event.logicalKey == LogicalKeyboardKey.delete) {
        setState(() {
          _searchResults = [];
          _canAutoSearch = false;
        });
        _onSearchChanged(_searchController.text);
      } else {
        setState(() {
          _canAutoSearch = true;
        });
      }
    }
  }

  void _forceSearch() {
    final query = _searchController.text;
    if (query.isEmpty) return;
    _debounceTimer?.cancel();
    _canAutoSearch = false;
    _performSearch(query);
  }

  void _scrollToSelectedIndex() {
    if (_selectedIndex < 0 || _selectedIndex >= _resultKeys.length) return;

    final key = _resultKeys[_selectedIndex];
    final currentContext = key.currentContext;
    if (currentContext == null) return;

    Scrollable.ensureVisible(
      currentContext,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    // ignore: unused_local_variable
    final t = Translations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return KeyboardListener(
      focusNode: FocusNode(),
      onKeyEvent: _handleKeyEvent,
      child: Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusLG),
        ),
        elevation: 24,
        child: AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height - 100,
            ),
            child: Container(
              width: min(600, MediaQuery.of(context).size.width - 48),
              decoration: BoxDecoration(
                color: isDark ? DesignTokens.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(DesignTokens.radiusLG),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildSearchBox(isDark),
                  Divider(
                    height: 1,
                    color: isDark
                        ? DesignTokens.darkBorder.withValues(alpha: 0.3)
                        : DesignTokens.gray200,
                  ),
                  Flexible(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        minHeight: 48,
                        maxHeight: 520,
                      ),
                      child: _buildContentArea(isDark),
                    ),
                  ),
                  _buildBottomHints(isDark),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBox(bool isDark) {
    return Container(
      height: 48,
      padding: EdgeInsets.symmetric(horizontal: DesignTokens.space4),
      child: Row(
        children: [
          Icon(
            Icons.search,
            size: 20,
            color: isDark
                ? DesignTokens.darkTextSecondary
                : DesignTokens.gray400,
          ),
          SizedBox(width: DesignTokens.space3),
          Expanded(
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: t.search_placeholder,
                hintStyle: TextStyle(
                  fontSize: DesignTokens.fontSizeBody,
                  color: isDark
                      ? DesignTokens.darkTextSecondary
                      : DesignTokens.gray400,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              style: TextStyle(
                fontSize: DesignTokens.fontSizeBody,
                color: isDark
                    ? DesignTokens.darkTextPrimary
                    : DesignTokens.gray700,
              ),
            ),
          ),
          if (_categories.isNotEmpty)
            PopupMenuButton<String>(
              constraints: const BoxConstraints(maxHeight: 250),
              icon: Icon(
                Icons.filter_list,
                size: 18,
                color: isDark
                    ? DesignTokens.darkTextSecondary
                    : DesignTokens.gray400,
              ),
              tooltip: t.search_categoryFilter,
              initialValue: _selectedCategory,
              itemBuilder: (context) => [
                PopupMenuItem(value: null, child: Text(t.search_allCategories)),
                ..._categories.entries.map(
                  (entry) =>
                      PopupMenuItem(value: entry.key, child: Text(entry.value)),
                ),
              ],
              onSelected: (value) {
                setState(() {
                  _selectedCategory = value;
                  if (_searchController.text.isNotEmpty) {
                    _performSearch(_searchController.text);
                  }
                });
              },
            ),
          IconButton(
            icon: Icon(
              Icons.close,
              size: 18,
              color: isDark
                  ? DesignTokens.darkTextSecondary
                  : DesignTokens.gray400,
            ),
            onPressed: () => Navigator.of(context).pop(),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }

  Widget _buildContentArea(bool isDark) {
    if (_isLoading) {
      return SizedBox(
        height: 100,
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                DesignTokens.primary500,
              ),
            ),
          ),
        ),
      );
    }

    if (_showHistory) {
      return _buildHistoryList(isDark);
    }

    if (_searchController.text.isEmpty) {
      return SizedBox(
        height: 48,
        child: Center(
          child: Text(
            t.search_enterToSearch,
            style: TextStyle(
              fontSize: DesignTokens.fontSizeBody,
              color: isDark
                  ? DesignTokens.darkTextSecondary
                  : DesignTokens.gray400,
            ),
          ),
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return SizedBox(
        height: 100,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search_off,
                size: 48,
                color: isDark
                    ? DesignTokens.darkTextSecondary
                    : DesignTokens.gray400,
              ),
              SizedBox(height: DesignTokens.space3),
              Text(
                t.search_noResults,
                style: TextStyle(
                  fontSize: DesignTokens.fontSizeBody,
                  color: isDark
                      ? DesignTokens.darkTextSecondary
                      : DesignTokens.gray400,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return _buildSearchResults(isDark);
  }

  Widget _buildHistoryList(bool isDark) {
    if (_searchHistory.isEmpty) {
      return SizedBox(
        height: 48,
        child: Center(
          child: Text(
            t.search_noHistory,
            style: TextStyle(
              fontSize: DesignTokens.fontSizeBody,
              color: isDark
                  ? DesignTokens.darkTextSecondary
                  : DesignTokens.gray400,
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _searchHistory.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) return _buildHistoryHeader(isDark);
        return _buildHistoryItem(_searchHistory[index - 1], isDark);
      },
    );
  }

  Widget _buildHistoryHeader(bool isDark) {
    return Padding(
      padding: EdgeInsets.all(DesignTokens.space3),
      child: Row(
        children: [
          // Icon(
          //   Icons.history,
          //   size: 16,
          //   color: isDark
          //       ? DesignTokens.darkTextSecondary
          //       : DesignTokens.gray400,
          // ),
          // SizedBox(width: DesignTokens.space2),
          Text(
            t.search_recentSearches,
            style: TextStyle(
              fontSize: DesignTokens.fontSizeSmall,
              fontWeight: DesignTokens.fontWeightMedium,
              color: isDark
                  ? DesignTokens.darkTextSecondary
                  : DesignTokens.gray500,
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: _clearSearchHistory,
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: DesignTokens.space2),
              minimumSize: const Size(0, 0),
            ),
            child: Text(
              t.common_clear,
              style: TextStyle(
                fontSize: DesignTokens.fontSizeSmall,
                color: DesignTokens.primary500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(String query, bool isDark) {
    return ListTile(
      dense: true,
      leading: Icon(
        Icons.history,
        size: 16,
        color: isDark ? DesignTokens.darkTextSecondary : DesignTokens.gray400,
      ),
      title: Text(
        query,
        style: TextStyle(
          fontSize: DesignTokens.fontSizeBody,
          color: isDark ? DesignTokens.darkTextPrimary : DesignTokens.gray700,
        ),
      ),
      trailing: IconButton(
        icon: Icon(
          Icons.close,
          size: 16,
          color: isDark ? DesignTokens.darkTextSecondary : DesignTokens.gray400,
        ),
        onPressed: () => _removeSearchHistoryItem(query),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      ),
      onTap: () {
        _searchController.text = query;
        _debounceTimer?.cancel();
        setState(() {
          _searchResults = [];
          _showHistory = false;
        });
        _performSearch(query);
      },
    );
  }

  Widget _buildSearchResults(bool isDark) {
    while (_resultKeys.length < _searchResults.length) {
      _resultKeys.add(GlobalKey());
    }
    if (_resultKeys.length > _searchResults.length) {
      _resultKeys.removeRange(_searchResults.length, _resultKeys.length);
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const AlwaysScrollableScrollPhysics(),
      controller: _scrollController,
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final note = _searchResults[index];
        final isSelected = index == _selectedIndex;

        return Container(
          key: _resultKeys[index],
          child: _buildResultItem(note, index, isSelected, isDark),
        );
      },
    );
  }

  Widget _buildResultItem(
    NotePreview preview,
    int index,
    bool isSelected,
    bool isDark,
  ) {
    final query = _searchController.text;

    return InkWell(
      onTap: () => _openNote(preview),
      child: Container(
        padding: EdgeInsets.all(DesignTokens.space3),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark
                    ? DesignTokens.darkPrimary700.withValues(alpha: 0.3)
                    : DesignTokens.primary50)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(DesignTokens.radiusMD),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildHighlightedText(
                    preview.title.isEmpty
                        ? t.search_untitledNote
                        : preview.title,
                    query,
                    DesignTokens.fontSizeH3,
                    DesignTokens.fontWeightSemiBold,
                    isDark
                        ? DesignTokens.darkTextPrimary
                        : DesignTokens.gray900,
                    isDark,
                  ),
                ),
                if (preview.category != null && preview.category!.isNotEmpty)
                  Consumer<CategoryProvider>(
                    builder: (context, dirProvider, _) {
                      String categoryName = preview.category!;
                      try {
                        final dir = dirProvider.categories.firstWhere(
                          (d) => d.id == preview.category,
                        );
                        categoryName = dir.name;
                      } catch (e) {
                        categoryName = preview.category!;
                      }
                      return Container(
                        margin: EdgeInsets.only(left: DesignTokens.space2),
                        padding: EdgeInsets.symmetric(
                          horizontal: DesignTokens.space2,
                          vertical: DesignTokens.space1,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? DesignTokens.darkPrimary700.withValues(
                                  alpha: 0.3,
                                )
                              : DesignTokens.primary50,
                          borderRadius: BorderRadius.circular(
                            DesignTokens.radiusXS,
                          ),
                        ),
                        child: Text(
                          categoryName,
                          style: TextStyle(
                            fontSize: DesignTokens.fontSizeCaption,
                            color: isDark
                                ? DesignTokens.darkPrimary500
                                : DesignTokens.primary700,
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
            if (preview.tags.isNotEmpty) ...[
              SizedBox(height: DesignTokens.space2),
              Wrap(
                spacing: DesignTokens.space2,
                runSpacing: DesignTokens.space1,
                children: preview.tags
                    .take(3)
                    .map(
                      (tag) => Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: DesignTokens.space2,
                          vertical: DesignTokens.space1,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? DesignTokens.darkBackground
                              : DesignTokens.gray100,
                          borderRadius: BorderRadius.circular(
                            DesignTokens.radiusXS,
                          ),
                        ),
                        child: Text(
                          '#$tag',
                          style: TextStyle(
                            fontSize: DesignTokens.fontSizeCaption,
                            color: isDark
                                ? DesignTokens.darkTextSecondary
                                : DesignTokens.gray500,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
            SizedBox(height: DesignTokens.space2),
            _buildHighlightedText(
              preview.title,
              query,
              DesignTokens.fontSizeSmall,
              DesignTokens.fontWeightRegular,
              isDark ? DesignTokens.darkTextSecondary : DesignTokens.gray500,
              isDark,
              maxLines: 2,
            ),
            SizedBox(height: DesignTokens.space2),
            Text(
              _formatDate(preview.updatedAt),
              style: TextStyle(
                fontSize: DesignTokens.fontSizeCaption,
                color: isDark
                    ? DesignTokens.darkTextSecondary.withValues(alpha: 0.7)
                    : DesignTokens.gray400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHighlightedText(
    String text,
    String query,
    double fontSize,
    FontWeight fontWeight,
    Color normalColor,
    bool isDark, {
    int maxLines = 1,
  }) {
    if (query.isEmpty || text.isEmpty) {
      return Text(
        text,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: normalColor,
        ),
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
      );
    }

    final spans = <TextSpan>[];
    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();

    int start = 0;
    int index = lowerText.indexOf(lowerQuery);

    while (index != -1) {
      if (index > start) {
        spans.add(
          TextSpan(
            text: text.substring(start, index),
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: fontWeight,
              color: normalColor,
            ),
          ),
        );
      }

      spans.add(
        TextSpan(
          text: text.substring(index, index + query.length),
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: fontWeight,
            color: isDark
                ? DesignTokens.darkPrimary500
                : DesignTokens.primary700,
            background: Paint()
              ..color = isDark
                  ? DesignTokens.darkPrimary700.withValues(alpha: 0.3)
                  : DesignTokens.primary100,
          ),
        ),
      );

      start = index + query.length;
      index = lowerText.indexOf(lowerQuery, start);
    }

    if (start < text.length) {
      spans.add(
        TextSpan(
          text: text.substring(start),
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: fontWeight,
            color: normalColor,
          ),
        ),
      );
    }

    return RichText(
      text: TextSpan(children: spans),
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      if (diff.inHours == 0) {
        if (diff.inMinutes == 0) {
          return t.search_justNow;
        }
        return t.search_minutesAgo(count: diff.inMinutes);
      }
      return t.search_hoursAgo(count: diff.inHours);
    } else if (diff.inDays == 1) {
      return t.search_yesterday;
    } else if (diff.inDays < 7) {
      return t.search_daysAgo(count: diff.inDays);
    } else {
      return '${date.month}/${date.day}';
    }
  }

  Widget _buildBottomHints(bool isDark) {
    return Container(
      height: 32,
      padding: EdgeInsets.symmetric(horizontal: DesignTokens.space4),
      decoration: BoxDecoration(
        color: isDark ? DesignTokens.darkBackground : DesignTokens.gray50,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(DesignTokens.radiusLG),
          bottomRight: Radius.circular(DesignTokens.radiusLG),
        ),
      ),
      child: Row(
        children: [
          _buildHintItem(t.search_enterHint, t.search_open, isDark),
          SizedBox(width: DesignTokens.space3),
          _buildHintItem(t.search_navigateHint, t.search_navigate, isDark),
          SizedBox(width: DesignTokens.space3),
          _buildHintItem(t.search_escHint, t.search_closeHint, isDark),
        ],
      ),
    );
  }

  Widget _buildHintItem(String key, String action, bool isDark) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: DesignTokens.space2,
            vertical: DesignTokens.space1,
          ),
          decoration: BoxDecoration(
            color: isDark
                ? DesignTokens.darkBorder.withValues(alpha: 0.3)
                : DesignTokens.gray200,
            borderRadius: BorderRadius.circular(DesignTokens.radiusXS),
          ),
          child: Text(
            key,
            style: TextStyle(
              fontSize: DesignTokens.fontSizeCaption,
              fontWeight: DesignTokens.fontWeightMedium,
              color: isDark
                  ? DesignTokens.darkTextSecondary
                  : DesignTokens.gray500,
            ),
          ),
        ),
        SizedBox(width: DesignTokens.space1),
        Text(
          action,
          style: TextStyle(
            fontSize: DesignTokens.fontSizeCaption,
            color: isDark
                ? DesignTokens.darkTextSecondary
                : DesignTokens.gray500,
          ),
        ),
      ],
    );
  }
}
