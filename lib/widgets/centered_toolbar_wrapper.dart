// Copyright (c) 2026 litongshuai
// SPDX-License-Identifier: MIT OR Apache-2.0

import 'package:flutter/material.dart';
import 'package:markdown_editor_plus/src/toolbar.dart';
import '../l10n/strings.g.dart';

class CenteredToolbarWrapper extends StatelessWidget {
  final TextEditingController controller;
  final Toolbar toolbar;
  final Color? toolbarBackground;
  final VoidCallback? unfocus;

  const CenteredToolbarWrapper({
    super.key,
    required this.controller,
    required this.toolbar,
    this.toolbarBackground,
    this.unfocus,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 45,
      color: toolbarBackground ?? Theme.of(context).cardColor,
      child: Center(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: _buildToolbarButtons(context),
        ),
      ),
    );
  }

  Widget _buildToolbarButtons(BuildContext context) {
    final t = Translations.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ToolbarButton(
          icon: Icons.format_bold,
          tooltip: t.toolbar_bold,
          onPressed: () => toolbar.action('**', '**'),
        ),
        _ToolbarButton(
          icon: Icons.format_italic,
          tooltip: t.toolbar_italic,
          onPressed: () => toolbar.action('_', '_'),
        ),
        _ToolbarButton(
          icon: Icons.format_strikethrough,
          tooltip: t.toolbar_strikethrough,
          onPressed: () => toolbar.action('~~', '~~'),
        ),
        const SizedBox(width: 8),
        _ToolbarButton(
          icon: Icons.text_fields,
          tooltip: t.toolbar_heading1,
          onPressed: () => _insertAtLineStart('# '),
        ),
        _ToolbarButton(
          icon: Icons.text_fields,
          tooltip: t.toolbar_heading2,
          size: 18,
          onPressed: () => _insertAtLineStart('## '),
        ),
        _ToolbarButton(
          icon: Icons.text_fields,
          tooltip: t.toolbar_heading3,
          size: 16,
          onPressed: () => _insertAtLineStart('### '),
        ),
        const SizedBox(width: 8),
        _ToolbarButton(
          icon: Icons.code,
          tooltip: t.toolbar_code,
          onPressed: () => toolbar.action('`', '`'),
        ),
        _ToolbarButton(
          icon: Icons.format_quote,
          tooltip: t.toolbar_quote,
          onPressed: () => _insertAtLineStart('> '),
        ),
        const SizedBox(width: 8),
        _ToolbarButton(
          icon: Icons.format_list_bulleted,
          tooltip: t.toolbar_list,
          onPressed: () => _insertAtLineStart('- '),
        ),
        _ToolbarButton(
          icon: Icons.format_list_numbered,
          tooltip: t.toolbar_numberedList,
          onPressed: () => _insertAtLineStart('1. '),
        ),
        _ToolbarButton(
          icon: Icons.check_box_outlined,
          tooltip: t.toolbar_todo,
          onPressed: () => _insertAtLineStart('- [ ] '),
        ),
        const SizedBox(width: 8),
        _ToolbarButton(
          icon: Icons.link,
          tooltip: t.toolbar_link,
          onPressed: () => toolbar.action('[', '](url)'),
        ),
        _ToolbarButton(
          icon: Icons.image,
          tooltip: t.toolbar_image,
          onPressed: () => toolbar.action('![', '](url)'),
        ),
        const SizedBox(width: 8),
        _ToolbarButton(
          icon: Icons.horizontal_rule,
          tooltip: t.toolbar_divider,
          onPressed: () => _insertText('\n---\n'),
        ),
        _ToolbarButton(
          icon: Icons.table_chart,
          tooltip: t.toolbar_table,
          onPressed: () => _insertText(
            '\n| 列1 | 列2 | 列3 |\n|---|---|---|\n| 内容 | 内容 | 内容 |\n',
          ),
        ),
      ],
    );
  }

  void _insertAtLineStart(String prefix) {
    toolbar.bringEditorToFocus?.call();

    final text = controller.text;
    final selection = controller.selection;
    final startOffset = selection.baseOffset;

    int lineStart = 0;
    for (int i = startOffset - 1; i >= 0; i--) {
      if (text[i] == '\n') {
        lineStart = i + 1;
        break;
      }
    }

    controller.value = TextEditingValue(
      text: text.substring(0, lineStart) + prefix + text.substring(lineStart),
      selection: TextSelection.collapsed(offset: startOffset + prefix.length),
    );
  }

  void _insertText(String text) {
    toolbar.bringEditorToFocus?.call();

    final currentText = controller.text;
    final selection = controller.selection;
    final insertOffset = selection.baseOffset;

    controller.value = TextEditingValue(
      text:
          currentText.substring(0, insertOffset) +
          text +
          currentText.substring(insertOffset),
      selection: TextSelection.collapsed(offset: insertOffset + text.length),
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final double size;

  const _ToolbarButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.size = 20,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, size: size),
        ),
      ),
    );
  }
}
