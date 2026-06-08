// Copyright (c) 2026 litongshuai
// SPDX-License-Identifier: MIT OR Apache-2.0

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/strings.g.dart';
import '../../models/category.dart';
import '../../providers/notes_provider.dart';
import '../../theme/design_tokens.dart';

class CategoryDeleteDialog extends StatelessWidget {
  final Category category;
  final VoidCallback onConfirm;

  const CategoryDeleteDialog({
    super.key,
    required this.category,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final notesProvider = context.read<NotesProvider>();

    // 计算该分类下的笔记数量
    final notesCount = notesProvider.notes
        .where((n) => n.category == category.id)
        .length;

    return AlertDialog(
      backgroundColor: isDark ? DesignTokens.darkSurface : Colors.white,
      title: Text(
        t.category_deleteTitle,
        style: TextStyle(
          color: isDark ? DesignTokens.darkTextPrimary : DesignTokens.gray900,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.category_deleteConfirm(name: category.name),
            style: TextStyle(
              color: isDark
                  ? DesignTokens.darkTextPrimary
                  : DesignTokens.gray900,
            ),
          ),
          const SizedBox(height: DesignTokens.space4),
          if (notesCount > 0)
            Container(
              padding: const EdgeInsets.all(DesignTokens.space4),
              decoration: BoxDecoration(
                color: isDark
                    ? DesignTokens.errorBackground.withValues(alpha: 0.2)
                    : DesignTokens.errorBackground,
                borderRadius: BorderRadius.circular(DesignTokens.radiusMD),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber,
                    size: 20,
                    color: DesignTokens.error,
                  ),
                  const SizedBox(width: DesignTokens.space2),
                  Expanded(
                    child: Text(
                      t.category_deleteWarning(count: notesCount),
                      style: TextStyle(
                        fontSize: DesignTokens.fontSizeSmall,
                        color: DesignTokens.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            t.common_cancel,
            style: TextStyle(
              color: isDark
                  ? DesignTokens.darkTextSecondary
                  : DesignTokens.gray500,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: onConfirm,
          style: ElevatedButton.styleFrom(
            backgroundColor: DesignTokens.error,
            foregroundColor: Colors.white,
          ),
          child: Text(t.common_delete),
        ),
      ],
    );
  }
}
