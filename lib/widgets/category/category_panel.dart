// Copyright (c) 2026 litongshuai
// SPDX-License-Identifier: MIT OR Apache-2.0

import 'package:flutter/material.dart';
import 'package:flutter_simple_treeview/flutter_simple_treeview.dart';
import 'package:provider/provider.dart';
import '../../l10n/strings.g.dart';
import '../../models/category.dart';
import '../../providers/category_provider.dart';
import '../../theme/design_tokens.dart';
import 'category_list_item.dart';
import 'category_create_dialog.dart';
import 'category_edit_dialog.dart';
import 'category_delete_dialog.dart';

class CategoryPanel extends StatefulWidget {
  final double width;

  const CategoryPanel({super.key, this.width = 180});

  @override
  State<CategoryPanel> createState() => _CategoryPanelState();
}

class _CategoryPanelState extends State<CategoryPanel> {
  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: widget.width,
      constraints: BoxConstraints(
        minWidth: widget.width,
        maxWidth: widget.width,
      ),
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: EdgeInsets.all(DesignTokens.space6),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '分类管理',
                    style: TextStyle(
                      fontSize: DesignTokens.fontSizeH3,
                      fontWeight: DesignTokens.fontWeightSemiBold,
                      color: isDark
                          ? DesignTokens.darkTextPrimary
                          : DesignTokens.gray900,
                    ),
                  ),
                ),
                Consumer<CategoryProvider>(
                  builder: (context, provider, _) {
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? DesignTokens.darkPrimary700.withValues(
                                      alpha: 0.3,
                                    )
                                  : DesignTokens.primary50,
                              borderRadius: BorderRadius.circular(
                                DesignTokens.radiusMD,
                              ),
                            ),
                            child: Icon(
                              provider.isTreeViewMode
                                  ? Icons.view_list
                                  : Icons.account_tree,
                              size: 16,
                              color: isDark
                                  ? DesignTokens.darkPrimary500
                                  : DesignTokens.primary500,
                            ),
                          ),
                          onPressed: () {
                            provider.toggleViewMode();
                            setState(() {});
                          },
                          tooltip: provider.isTreeViewMode
                              ? t.category_flatViewTooltip
                              : t.category_treeViewTooltip,
                        ),
                        SizedBox(width: DesignTokens.space2),
                        IconButton(
                          icon: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? DesignTokens.darkPrimary700.withValues(
                                      alpha: 0.3,
                                    )
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
                          onPressed: () => _showCreateDialog(context),
                          tooltip: t.category_createNewTooltip,
                        ),
                      ],
                    );
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
          Expanded(child: _buildCategoryList(isDark)),
        ],
      ),
    );
  }

  Widget _buildCategoryList(bool isDark) {
    return Consumer<CategoryProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.categories.isEmpty) {
          return Center(
            child: Text(
              t.category_emptyState,
              style: TextStyle(
                color: isDark
                    ? DesignTokens.darkTextSecondary
                    : DesignTokens.gray500,
              ),
            ),
          );
        }

        if (provider.isTreeViewMode) {
          return _buildCategoryTree(provider, isDark);
        } else {
          return _buildCategoryFlatView(provider, isDark);
        }
      },
    );
  }

  Widget _buildCategoryTree(CategoryProvider provider, bool isDark) {
    // 只获取"所有笔记"虚拟分类作为唯一的根节点
    Category? allNotesDir;
    try {
      allNotesDir = provider.categories.firstWhere(
        (d) => d.id == allNotesCategoryId,
      );
    } catch (e) {
      allNotesDir = null;
    }

    if (allNotesDir == null) {
      return Center(
        child: Text(
          t.category_emptyState,
          style: TextStyle(
            color: isDark
                ? DesignTokens.darkTextSecondary
                : DesignTokens.gray500,
          ),
        ),
      );
    }

    final nodes = _buildCategoryTreeNodes([allNotesDir], provider, isDark);
    if (nodes.isEmpty) {
      return Center(
        child: Text(
          t.category_emptyState,
          style: TextStyle(
            color: isDark
                ? DesignTokens.darkTextSecondary
                : DesignTokens.gray500,
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(child: TreeView(nodes: nodes, indent: 20)),
    );
  }

  List<TreeNode> _buildCategoryTreeNodes(
    List<Category> directories,
    CategoryProvider provider,
    bool isDark,
  ) {
    if (directories.isEmpty) return [];

    return directories.map((dir) {
      List<Category> children;

      // 特殊处理："所有笔记"虚拟分类的子节点是所有一级目录
      if (dir.id == allNotesCategoryId) {
        children = provider.categories
            .where(
              (d) => d.parentId == null || d.parentId == allNotesCategoryId,
            )
            .where((d) => d.id != allNotesCategoryId)
            .toList();
      } else {
        children = provider.getChildCategories(dir.id);
      }

      final childNodes = children.isEmpty
          ? <TreeNode>[]
          : _buildCategoryTreeNodes(children, provider, isDark);

      return TreeNode(
        content: CategoryListItem(
          category: dir,
          isSelected: provider.selectedCategory?.id == dir.id,
          onTap: () => provider.selectCategory(dir),
          onEdit: dir.isVirtual ? null : () => _showEditDialog(context, dir),
          onDelete: dir.isVirtual
              ? null
              : () => _showDeleteDialog(context, dir),
          onAddChild: dir.isVirtual || dir.level >= 2
              ? null
              : () => _showCreateChildDialog(context, dir.id),
        ),
        children: childNodes.isEmpty ? null : childNodes,
      );
    }).toList();
  }

  Widget _buildCategoryFlatView(CategoryProvider provider, bool isDark) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SizedBox(
          width: constraints.maxWidth,
          child: ListView.builder(
            itemCount: provider.categories.length,
            itemBuilder: (context, index) {
              final dir = provider.categories[index];
              return CategoryListItem(
                category: dir,
                isSelected: provider.selectedCategory?.id == dir.id,
                onTap: () => provider.selectCategory(dir),
                onEdit: dir.isVirtual
                    ? null
                    : () => _showEditDialog(context, dir),
                onDelete: dir.isVirtual
                    ? null
                    : () => _showDeleteDialog(context, dir),
                isTreeView: false,
              );
            },
          ),
        );
      },
    );
  }

  void _showCreateDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => CategoryCreateDialog(
        parentId: null,
        onSave: (name) async {
          final provider = context.read<CategoryProvider>();
          await provider.createCategory(name, null);
          if (!ctx.mounted) return;
          Navigator.pop(ctx);
        },
      ),
    );
  }

  void _showCreateChildDialog(BuildContext context, String parentId) {
    showDialog(
      context: context,
      builder: (ctx) => CategoryCreateDialog(
        parentId: parentId,
        onSave: (name) async {
          final provider = context.read<CategoryProvider>();
          await provider.createCategory(name, parentId);
          if (!ctx.mounted) return;
          Navigator.pop(ctx);
        },
      ),
    );
  }

  void _showEditDialog(BuildContext context, Category category) {
    showDialog(
      context: context,
      builder: (ctx) => CategoryEditDialog(
        category: category,
        onSave: (newName) async {
          final provider = context.read<CategoryProvider>();
          await provider.updateCategoryName(category.id, newName);
          if (!ctx.mounted) return;
          Navigator.pop(ctx);
        },
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, Category category) {
    showDialog(
      context: context,
      builder: (ctx) => CategoryDeleteDialog(
        category: category,
        onConfirm: () async {
          final provider = context.read<CategoryProvider>();
          await provider.deleteCategory(category.id);
          if (!ctx.mounted) return;
          Navigator.pop(ctx);
        },
      ),
    );
  }
}
