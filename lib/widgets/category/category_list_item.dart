// Copyright (c) 2026 litongshuai
// SPDX-License-Identifier: MIT OR Apache-2.0

import 'package:flutter/material.dart';
import '../../l10n/strings.g.dart';
import '../../models/category.dart';

class CategoryListItem extends StatelessWidget {
  final Category category;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onAddChild;
  final bool isTreeView;

  const CategoryListItem({
    super.key,
    required this.category,
    this.isSelected = false,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.onAddChild,
    this.isTreeView = true,
  });

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      child: Container(
        margin: isTreeView
            ? EdgeInsets.zero
            : EdgeInsets.symmetric(vertical: 2),
        padding: EdgeInsets.symmetric(horizontal: 8),
        decoration: isSelected
            ? BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6),
              )
            : null,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.folder,
              size: 18,
              color: Colors.blue.shade400.withValues(alpha: isDark ? 0.8 : 1.0),
            ),
            SizedBox(width: 8),
            Flexible(
              child: Text(
                category.name,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white : Colors.black,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (!category.isVirtual) ...[
              SizedBox(width: 4),
              IconButton(
                icon: Icon(Icons.edit, size: 14),
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(minWidth: 20, minHeight: 20),
                onPressed: onEdit,
                color: isDark ? Colors.white54 : Colors.black45,
                tooltip: t.category_renameTooltip,
              ),
              IconButton(
                icon: Icon(Icons.delete, size: 14),
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(minWidth: 20, minHeight: 20),
                onPressed: onDelete,
                color: isDark ? Colors.white54 : Colors.black45,
                tooltip: t.common_delete,
              ),
              if (category.level < 2)
                IconButton(
                  icon: Icon(Icons.add, size: 16),
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(minWidth: 20, minHeight: 20),
                  onPressed: onAddChild,
                  color: isDark ? Colors.white54 : Colors.black45,
                  tooltip: t.category_addChildTooltip,
                ),
            ],
          ],
        ),
      ),
    );
  }
}
