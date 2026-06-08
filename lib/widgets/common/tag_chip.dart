// Copyright (c) 2026 litongshuai
// SPDX-License-Identifier: MIT OR Apache-2.0

import 'package:flutter/material.dart';
import '../../theme/design_tokens.dart';

class TagChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final bool showDelete;
  final double fontSize;

  const TagChip({
    super.key,
    required this.label,
    this.isSelected = false,
    this.onTap,
    this.onDelete,
    this.showDelete = false,
    this.fontSize = DesignTokens.fontSizeCaption,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final backgroundColor = _getBackgroundColor(isDark);
    final labelTextColor = _getTextColor(isDark);

    return RepaintBoundary(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: DesignTokens.durationFast,
          curve: DesignTokens.curveStandard,
          padding: EdgeInsets.symmetric(
            horizontal: DesignTokens.space4,
            vertical: DesignTokens.space1,
          ),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
            border: isSelected
                ? Border.all(color: DesignTokens.primary500, width: 1.5)
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: DesignTokens.fontWeightRegular,
                  color: labelTextColor,
                ),
              ),
              if (showDelete && onDelete != null) ...[
                SizedBox(width: DesignTokens.space2),
                GestureDetector(
                  onTap: onDelete,
                  child: Icon(
                    Icons.close,
                    size: fontSize + 2,
                    color: labelTextColor.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getBackgroundColor(bool isDark) {
    if (isSelected) {
      return isDark
          ? DesignTokens.darkPrimary700.withValues(alpha: 0.4)
          : DesignTokens.primary200;
    }

    return isDark
        ? DesignTokens.darkPrimary700.withValues(alpha: 0.2)
        : DesignTokens.primary100;
  }

  Color _getTextColor(bool isDark) {
    if (isSelected) {
      return isDark ? DesignTokens.darkPrimary500 : DesignTokens.primary700;
    }

    return isDark
        ? DesignTokens.darkPrimary500.withValues(alpha: 0.9)
        : DesignTokens.primary700;
  }
}

class TagChipList extends StatelessWidget {
  final List<String> tags;
  final Set<String>? selectedTags;
  final Function(String)? onTap;
  final Function(String)? onDelete;
  final bool showDelete;
  final bool wrap;
  final double spacing;

  const TagChipList({
    super.key,
    required this.tags,
    this.selectedTags,
    this.onTap,
    this.onDelete,
    this.showDelete = false,
    this.wrap = true,
    this.spacing = DesignTokens.space2,
  });

  @override
  Widget build(BuildContext context) {
    if (tags.isEmpty) {
      return const SizedBox.shrink();
    }

    final tagWidgets = tags.map((tag) {
      return TagChip(
        label: tag,
        isSelected: selectedTags?.contains(tag) ?? false,
        onTap: onTap != null ? () => onTap!(tag) : null,
        onDelete: onDelete != null ? () => onDelete!(tag) : null,
        showDelete: showDelete,
      );
    }).toList();

    if (wrap) {
      return Wrap(spacing: spacing, runSpacing: spacing, children: tagWidgets);
    }

    return Row(
      children: tagWidgets
          .map(
            (widget) => [
              widget,
              if (tags.indexOf(tagWidgets.indexOf(widget) as String) <
                  tags.length - 1)
                SizedBox(width: spacing),
            ],
          )
          .expand((e) => e)
          .toList(),
    );
  }
}
