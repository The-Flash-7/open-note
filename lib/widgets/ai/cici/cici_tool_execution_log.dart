// Copyright (c) 2026 litongshuai
// SPDX-License-Identifier: MIT OR Apache-2.0

import 'package:flutter/material.dart';
import '../../../l10n/strings.g.dart';
import '../../../models/chat_message.dart';
import 'cici_design_tokens.dart';
import 'shimmer_text.dart';

class CiciToolExecutionLog extends StatefulWidget {
  final List<ToolExecutionEntry> entries;
  final Map<String, int> categoryStats;
  final bool isProcessing;
  final bool initialExpanded;
  final ValueChanged<List<ToolExecutionEntry>>? onToggleExpand;

  const CiciToolExecutionLog({
    super.key,
    required this.entries,
    this.categoryStats = const {},
    this.isProcessing = false,
    this.initialExpanded = true,
    this.onToggleExpand,
  });

  static String getToolCategory(String toolName) {
    switch (toolName) {
      case 'note_search':
      case 'note_read':
      case 'note_search_by_title':
      case 'note_list_recent':
      case 'note_list_categories':
      case 'note_list_tags':
      case 'note_list_by_category':
      case 'note_qa':
      case 'note_get_format':
      case 'note_open':
        return '探索';
      case 'note_edit_info':
      case 'note_edit_content':
      case 'note_rewrite':
      case 'note_merge':
        return '编辑';
      case 'note_create':
        return '写入';
      case 'note_delete':
        return '删除';
      case 'note_summarize':
      case 'note_extract_keywords':
        return '总结';
      case 'note_create_from_url':
        return '提取';
      default:
        return '处理';
    }
  }

  static Map<String, int> generateCategoryStats(
    List<ToolExecutionEntry> entries,
  ) {
    final stats = <String, int>{};
    for (final entry in entries) {
      if (entry.status == ToolStatus.completed) {
        final category = getToolCategory(entry.toolName);
        stats[category] = (stats[category] ?? 0) + 1;
      }
    }
    return stats;
  }

  @override
  State<CiciToolExecutionLog> createState() => _CiciToolExecutionLogState();
}

class _CiciToolExecutionLogState extends State<CiciToolExecutionLog> {
  bool _isGroupExpanded = true;

  @override
  void initState() {
    super.initState();
    _isGroupExpanded = widget.initialExpanded;
  }

  @override
  void didUpdateWidget(CiciToolExecutionLog oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialExpanded != oldWidget.initialExpanded) {
      _isGroupExpanded = widget.initialExpanded;
    }
  }

  void _toggleGroup() {
    setState(() {
      _isGroupExpanded = !_isGroupExpanded;
    });
    widget.onToggleExpand?.call(
      widget.entries
          .map((e) => e.copyWith(isExpanded: _isGroupExpanded))
          .toList(),
    );
  }

  void _toggleEntry(int index) {
    setState(() {
      widget.entries[index].isExpanded = !widget.entries[index].isExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark
        ? CiciDesignTokens.darkGray
        : CiciDesignTokens.gray;
    final labelColor = isDark
        ? CiciDesignTokens.darkGray.withValues(alpha: 0.6)
        : CiciDesignTokens.gray.withValues(alpha: 0.6);
    final detailTextColor = isDark
        ? CiciDesignTokens.darkGray.withValues(alpha: 0.5)
        : CiciDesignTokens.gray.withValues(alpha: 0.5);

    final isCancelled = widget.entries.any(
      (e) => e.status == ToolStatus.cancelled,
    );

    final isInProgress =
        !isCancelled &&
        (widget.isProcessing ||
            widget.entries.any((e) => e.status == ToolStatus.calling));

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: _toggleGroup,
            child: Row(
              children: [
                ShimmerText(
                  text: isCancelled
                      ? t.ai_toolTerminated
                      : (isInProgress ? t.ai_toolInProgress : t.ai_toolCompleted),
                  style: TextStyle(
                    fontSize: 11,
                    color: titleColor,
                    fontWeight: FontWeight.w500,
                  ),
                  shimmering: isInProgress,
                  baseColor: titleColor,
                  shimmerColor: Colors.white,
                  duration: const Duration(milliseconds: 1500),
                ),
                const SizedBox(width: 4),
                Icon(
                  _isGroupExpanded
                      ? Icons.keyboard_arrow_down
                      : Icons.keyboard_arrow_right,
                  size: 16,
                  color: titleColor,
                ),
              ],
            ),
          ),
          if (_isGroupExpanded) ...[
            const SizedBox(height: 6),
            ...widget.entries.asMap().entries.map((entry) {
              final index = entry.key;
              final exec = entry.value;
              final isCalling = exec.status == ToolStatus.calling;
              return Padding(
                padding: const EdgeInsets.only(left: 20, bottom: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: exec.details.isNotEmpty
                          ? () => _toggleEntry(index)
                          : null,
                      child: Row(
                        children: [
                          if (isCalling)
                            const SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(
                                strokeWidth: 1.5,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.grey,
                                ),
                              ),
                            ),
                          if (exec.status == ToolStatus.completed)
                            const Icon(
                              Icons.check_circle,
                              size: 12,
                              color: Colors.green,
                            ),
                          if (exec.status == ToolStatus.failed)
                            const Icon(
                              Icons.cancel,
                              size: 12,
                              color: Colors.red,
                            ),
                          const SizedBox(width: 6),
                          Text(
                            exec.statusLabel,
                            style: TextStyle(fontSize: 11, color: labelColor),
                          ),
                          if (exec.details.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Icon(
                              exec.isExpanded
                                  ? Icons.keyboard_arrow_down
                                  : Icons.keyboard_arrow_right,
                              size: 14,
                              color: detailTextColor,
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (exec.isExpanded && exec.details.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      ...exec.details.map(
                        (detail) => Padding(
                          padding: const EdgeInsets.only(left: 24, top: 2),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 180),
                            child: Text(
                              '• $detail',
                              style: TextStyle(
                                fontSize: 10,
                                color: detailTextColor,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }),
          ],
          if (widget.categoryStats.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: widget.categoryStats.entries.map((e) {
                return _CategoryStatBadge(category: e.key, count: e.value);
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _CategoryStatBadge extends StatelessWidget {
  final String category;
  final int count;

  const _CategoryStatBadge({required this.category, required this.count});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark
        ? CiciDesignTokens.darkBorder.withValues(alpha: 0.5)
        : CiciDesignTokens.border;
    final textColor = isDark
        ? CiciDesignTokens.darkGray
        : CiciDesignTokens.gray;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: borderColor, width: 0.5),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.label_outline,
            size: 10,
            color: textColor.withValues(alpha: 0.6),
          ),
          const SizedBox(width: 3),
          Text(
            '$category $count 次',
            style: TextStyle(
              fontSize: 10,
              color: textColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
