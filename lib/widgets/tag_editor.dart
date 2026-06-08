// Copyright (c) 2026 litongshuai
// SPDX-License-Identifier: MIT OR Apache-2.0

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/strings.g.dart';
import '../models/tag.dart';
import '../providers/tags_provider.dart';
import '../theme/design_tokens.dart';

class TagEditor extends StatefulWidget {
  final List<String> selectedTags;
  final Function(List<String>) onTagsChanged;

  const TagEditor({
    super.key,
    required this.selectedTags,
    required this.onTagsChanged,
  });

  @override
  State<TagEditor> createState() => _TagEditorState();
}

class _TagEditorState extends State<TagEditor> {
  final TextEditingController _newTagController = TextEditingController();
  bool _isAddingTag = false;
  bool _showAvailableTags = false;

  @override
  void dispose() {
    _newTagController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    return Consumer<TagsProvider>(
      builder: (context, tagsProvider, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  Icons.label_outline,
                  size: 18,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
                const SizedBox(width: 8),
                Text(
                  t.tag_sectionTitle,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                // 已选中的标签
                ...widget.selectedTags.map((tagName) {
                  return _buildSelectedTagChip(tagName);
                }),
                // 添加按钮
                _buildAddButton(context, tagsProvider),
              ],
            ),
            // 展开的可选标签列表
            if (_showAvailableTags)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          t.tag_availableTagsTitle,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        TextButton(
                          onPressed: () =>
                              setState(() => _showAvailableTags = false),
                          child: Text(
                            t.common_collapse,
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (tagsProvider.tags.isEmpty)
                      Text(
                        t.tag_noTagsEmpty,
                        style: Theme.of(context).textTheme.bodySmall,
                      )
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: tagsProvider.tags
                            .where(
                              (tag) => !widget.selectedTags.contains(tag.name),
                            )
                            .map((tag) => _buildAvailableTagChip(tag))
                            .toList(),
                      ),
                    const SizedBox(height: 8),
                    // 创建新标签
                    if (_isAddingTag)
                      _buildNewTagInput(context, tagsProvider)
                    else
                      TextButton.icon(
                        icon: const Icon(Icons.add, size: 16),
                        label: Text(
                          t.tag_createNew,
                          style: TextStyle(fontSize: 12),
                        ),
                        onPressed: () => setState(() => _isAddingTag = true),
                      ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildSelectedTagChip(String tagName) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Chip(
      label: Text(
        tagName,
        style: TextStyle(
          fontSize: 12,
          color: isDark ? DesignTokens.darkPrimary500 : DesignTokens.primary700,
        ),
      ),
      backgroundColor: isDark
          ? DesignTokens.darkPrimary700.withValues(alpha: 0.2)
          : DesignTokens.primary100,
      deleteIcon: Icon(
        Icons.close,
        size: 14,
        color: isDark ? DesignTokens.darkPrimary500 : DesignTokens.primary700,
      ),
      onDeleted: () => _removeTag(tagName),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
    );
  }

  Widget _buildAvailableTagChip(Tag tag) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final chipColor = isDark
        ? DesignTokens.darkPrimary500
        : DesignTokens.primary700;

    return GestureDetector(
      onTap: () => _addTag(tag.name),
      child: Chip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add, size: 14, color: chipColor),
            const SizedBox(width: 2),
            Text(tag.name, style: TextStyle(fontSize: 12, color: chipColor)),
          ],
        ),
        backgroundColor: Colors.transparent,
        side: BorderSide(color: chipColor),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
      ),
    );
  }

  Widget _buildAddButton(BuildContext context, TagsProvider tagsProvider) {
    if (_isAddingTag && !_showAvailableTags) {
      return _buildNewTagInput(context, tagsProvider);
    }

    return ActionChip(
      avatar: const Icon(Icons.add, size: 16),
      label: Text(t.tag_addTag, style: TextStyle(fontSize: 12)),
      onPressed: () {
        setState(() {
          _showAvailableTags = true;
          _isAddingTag = false;
        });
      },
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _buildNewTagInput(BuildContext context, TagsProvider tagsProvider) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 120,
          height: 32,
          child: TextField(
            controller: _newTagController,
            autofocus: true,
            decoration: InputDecoration(
              hintText: t.tag_nameHint,
              hintStyle: const TextStyle(fontSize: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 8,
              ),
              isDense: true,
            ),
            style: const TextStyle(fontSize: 12),
            onSubmitted: (_) => _createNewTag(context, tagsProvider),
          ),
        ),
        const SizedBox(width: 4),
        IconButton(
          icon: const Icon(Icons.check, size: 18),
          onPressed: () => _createNewTag(context, tagsProvider),
          tooltip: t.tag_confirmTooltip,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        ),
        IconButton(
          icon: const Icon(Icons.close, size: 18),
          onPressed: () {
            setState(() {
              _isAddingTag = false;
              _newTagController.clear();
            });
          },
          tooltip: t.common_cancel,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        ),
      ],
    );
  }

  void _addTag(String tagName) {
    final newTags = List<String>.from(widget.selectedTags);
    if (!newTags.contains(tagName)) {
      newTags.add(tagName);
      widget.onTagsChanged(newTags);
    }
  }

  void _removeTag(String tagName) {
    final newTags = List<String>.from(widget.selectedTags);
    newTags.remove(tagName);
    widget.onTagsChanged(newTags);
  }

  Future<void> _createNewTag(
    BuildContext context,
    TagsProvider tagsProvider,
  ) async {
    final tagName = _newTagController.text.trim();
    if (tagName.isEmpty) {
      setState(() {
        _isAddingTag = false;
        _newTagController.clear();
      });
      return;
    }

    final existingTag = tagsProvider.getTagByName(tagName);
    if (existingTag != null) {
      _addTag(existingTag.name);
      setState(() {
        _isAddingTag = false;
        _newTagController.clear();
      });
      return;
    }

    // 直接创建标签，不再选择颜色
    final tag = await tagsProvider.createTag(tagName);
    if (tag != null) {
      _addTag(tag.name);
    }

    if (mounted) {
      setState(() {
        _isAddingTag = false;
        _newTagController.clear();
      });
    }
  }
}
