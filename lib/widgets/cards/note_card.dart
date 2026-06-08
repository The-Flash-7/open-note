// Copyright (c) 2026 litongshuai
// SPDX-License-Identifier: MIT OR Apache-2.0

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/strings.g.dart';
import '../../theme/design_tokens.dart';
import '../../models/note_preview.dart';
import '../../models/note.dart';
import '../../models/category.dart';
import '../../providers/category_provider.dart';
import '../common/tag_chip.dart';

class NoteCard extends StatefulWidget {
  final NotePreview note;
  final bool isSelected;
  final bool isSelectionMode;
  final bool isMultiSelected;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onFavoriteToggle;
  final VoidCallback? onLongPress;
  final VoidCallback? onSelectionToggle;

  const NoteCard({
    super.key,
    required this.note,
    this.isSelected = false,
    this.isSelectionMode = false,
    this.isMultiSelected = false,
    this.onTap,
    this.onDelete,
    this.onFavoriteToggle,
    this.onLongPress,
    this.onSelectionToggle,
  });

  @override
  State<NoteCard> createState() => _NoteCardState();
}

class _NoteCardState extends State<NoteCard> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return RepaintBoundary(
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovering = true),
        onExit: (_) => setState(() => _isHovering = false),
        child: GestureDetector(
          onTap: widget.onTap,
          onLongPress: widget.onLongPress,
          child: AnimatedContainer(
            duration: DesignTokens.durationFast,
            curve: DesignTokens.curveStandard,
            margin: EdgeInsets.only(
              bottom: DesignTokens.space4,
              left: widget.isSelectionMode ? DesignTokens.space2 : 0,
              right: widget.isSelectionMode ? DesignTokens.space2 : 0,
            ),
            decoration: BoxDecoration(
              color: isDark ? DesignTokens.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(DesignTokens.radiusLG),
              boxShadow: widget.isSelected || widget.isMultiSelected
                  ? DesignTokens.shadowPrimary
                  : DesignTokens.shadowSM,
              border: _getBorder(isDark),
            ),
            child: Stack(
              children: [
                Positioned(
                  bottom: 8,
                  right: 12,
                  child: Opacity(
                    opacity: isDark ? 0.15 : 0.12,
                    child: Text(
                      _getFormatText(widget.note.format),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: _getFormatColor(widget.note.format, isDark),
                        height: 1,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: DesignTokens.space3,
                  right: DesignTokens.space3,
                  child: widget.isSelectionMode
                      ? GestureDetector(
                          onTap: widget.onSelectionToggle,
                          child: Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: widget.isMultiSelected
                                  ? DesignTokens.primary500
                                  : Colors.transparent,
                              border: Border.all(
                                color: widget.isMultiSelected
                                    ? DesignTokens.primary500
                                    : (isDark
                                          ? DesignTokens.darkBorder
                                          : DesignTokens.gray300),
                                width: 2,
                              ),
                            ),
                            child: widget.isMultiSelected
                                ? Icon(
                                    Icons.check,
                                    size: 14,
                                    color: Colors.white,
                                  )
                                : null,
                          ),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (widget.onFavoriteToggle != null)
                              IconButton(
                                icon: Icon(
                                  widget.note.isFavorite
                                      ? Icons.star
                                      : Icons.star_border,
                                  size: 16,
                                ),
                                color: widget.note.isFavorite
                                    ? DesignTokens.accent500
                                    : (isDark
                                          ? DesignTokens.darkTextSecondary
                                          : DesignTokens.gray500),
                                onPressed: widget.onFavoriteToggle,
                                padding: EdgeInsets.zero,
                                constraints: BoxConstraints(
                                  minWidth: 28,
                                  minHeight: 28,
                                ),
                                tooltip: widget.note.isFavorite
                                    ? t.card_unfavoriteTooltip
                                    : t.card_favoriteTooltip,
                              ),
                            if (widget.onDelete != null)
                              IconButton(
                                icon: Icon(Icons.delete, size: 16),
                                color: DesignTokens.error,
                                onPressed: widget.onDelete,
                                padding: EdgeInsets.zero,
                                constraints: BoxConstraints(
                                  minWidth: 28,
                                  minHeight: 28,
                                ),
                                tooltip: t.card_deleteTooltip,
                              ),
                          ],
                        ),
                ),
                Padding(
                  padding: EdgeInsets.all(DesignTokens.space6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(context, isDark),
                      SizedBox(height: DesignTokens.space3),
                      _buildSummary(context, isDark),
                      if (widget.note.tags.isNotEmpty) ...[
                        SizedBox(height: DesignTokens.space3),
                        TagChipList(
                          tags: widget.note.tags.take(3).toList(),
                          spacing: DesignTokens.space2,
                        ),
                      ],
                      SizedBox(height: DesignTokens.space3),
                      _buildFooter(context, isDark),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Border _getBorder(bool isDark) {
    // 选中状态：2px primary500
    if (widget.isSelected) {
      return Border.all(color: DesignTokens.primary500, width: 2);
    }

    // 多选状态：2px primary500
    if (widget.isMultiSelected) {
      return Border.all(color: DesignTokens.primary500, width: 2);
    }

    // hover状态：2px primary400（比选中时淡一级）
    if (_isHovering) {
      return Border.all(color: DesignTokens.primary400, width: 2);
    }

    // 未选中状态：2px 背景色（不明显）
    return Border.all(
      color: isDark ? DesignTokens.darkSurface : Colors.white,
      width: 2,
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Row(
      children: [
        Expanded(
          child: Text(
            widget.note.title.isEmpty ? t.card_untitledNote : widget.note.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: DesignTokens.fontSizeH3,
              fontWeight: DesignTokens.fontWeightSemiBold,
              color: isDark
                  ? DesignTokens.darkTextPrimary
                  : DesignTokens.gray900,
            ),
          ),
        ),
        SizedBox(width: 90),
      ],
    );
  }

  Widget _buildSummary(BuildContext context, bool isDark) {
    // 优先使用 summary，其次使用 contentPreview
    final summary = widget.note.summary ?? widget.note.contentPreview ?? '';
    if (summary.isEmpty) {
      return const SizedBox.shrink();
    }

    return Text(
      summary,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: DesignTokens.fontSizeSmall,
        fontWeight: DesignTokens.fontWeightRegular,
        color: isDark ? DesignTokens.darkTextSecondary : DesignTokens.gray500,
        height: 18 / DesignTokens.fontSizeSmall,
      ),
    );
  }

  Widget _buildFooter(BuildContext context, bool isDark) {
    return Row(
      children: [
        if (widget.note.category != null && widget.note.category!.isNotEmpty)
          Consumer<CategoryProvider>(
            builder: (context, dirProvider, _) {
              // 根据id查找分类名称
              Category? directory;
              try {
                directory = dirProvider.categories.firstWhere(
                  (d) => d.id == widget.note.category,
                );
              } catch (e) {
                directory = null;
              }
              final categoryName = directory?.name ?? widget.note.category!;

              return Container(
                padding: EdgeInsets.symmetric(
                  horizontal: DesignTokens.space2,
                  vertical: DesignTokens.space1,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? DesignTokens.darkBorder.withValues(alpha: 0.3)
                      : DesignTokens.gray100,
                  borderRadius: BorderRadius.circular(DesignTokens.radiusXS),
                ),
                child: Text(
                  categoryName,
                  style: TextStyle(
                    fontSize: DesignTokens.fontSizeCaption,
                    color: isDark
                        ? DesignTokens.darkTextSecondary
                        : DesignTokens.gray500,
                  ),
                ),
              );
            },
          ),
        SizedBox(width: DesignTokens.space3),
        Icon(
          Icons.schedule,
          size: 12,
          color: isDark ? DesignTokens.darkTextSecondary : DesignTokens.gray400,
        ),
        SizedBox(width: DesignTokens.space1),
        Text(
          _formatDate(widget.note.updatedAt),
          style: TextStyle(
            fontSize: DesignTokens.fontSizeCaption,
            color: isDark
                ? DesignTokens.darkTextSecondary
                : DesignTokens.gray400,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      if (diff.inHours == 0) {
        if (diff.inMinutes == 0) {
          return t.card_justNow;
        }
        return t.card_minutesAgo(minutes: diff.inMinutes);
      }
      return t.card_hoursAgo(hours: diff.inHours);
    } else if (diff.inDays == 1) {
      return t.card_yesterday;
    } else if (diff.inDays < 7) {
      return t.card_daysAgo(days: diff.inDays);
    } else {
      return '${date.month}/${date.day}';
    }
  }

  Color _getFormatColor(NoteFormat format, bool isDark) {
    switch (format) {
      case NoteFormat.markdown:
        return DesignTokens.primary500;
      case NoteFormat.richText:
        return const Color(0xFF3b82f6);
      case NoteFormat.plainText:
        return isDark ? DesignTokens.gray400 : DesignTokens.gray500;
      case NoteFormat.code:
        return const Color(0xFFa855f7);
    }
  }

  String _getFormatText(NoteFormat format) {
    switch (format) {
      case NoteFormat.markdown:
        return 'MD';
      case NoteFormat.richText:
        return 'RTX';
      case NoteFormat.plainText:
        return 'TXT';
      case NoteFormat.code:
        return 'CODE';
    }
  }
}
