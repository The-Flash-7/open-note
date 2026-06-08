// Copyright (c) 2026 litongshuai
// SPDX-License-Identifier: MIT OR Apache-2.0

import 'package:flutter/material.dart';
import 'package:markdown_editor_plus/markdown_editor_plus.dart';
import '../../l10n/strings.g.dart';
import '../../theme/design_tokens.dart';

class MarkdownEditorWidget extends StatefulWidget {
  final String content;
  final Function(String) onChanged;
  final bool isPreview;
  final bool isDarkMode;

  const MarkdownEditorWidget({
    super.key,
    required this.content,
    required this.onChanged,
    this.isPreview = false,
    this.isDarkMode = false,
  });

  @override
  State<MarkdownEditorWidget> createState() => _MarkdownEditorWidgetState();
}

class _MarkdownEditorWidgetState extends State<MarkdownEditorWidget> {
  late TextEditingController _controller;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.content);
    _focusNode = FocusNode();
  }

  @override
  void didUpdateWidget(MarkdownEditorWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.content != widget.content &&
        _controller.text != widget.content) {
      _controller.text = widget.content;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    return MarkdownField(
      controller: _controller,
      focusNode: _focusNode,
      onChanged: widget.onChanged,
      emojiConvert: false,
      maxLines: null,
      minLines: 10,
      decoration: InputDecoration(
        hintText: t.editor_startWritingMarkdown,
        hintStyle: TextStyle(
          fontSize: DesignTokens.fontSizeBody,
          color: DesignTokens.gray400,
        ),
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        contentPadding: EdgeInsets.zero,
        fillColor: Colors.transparent,
        hoverColor: Colors.transparent,
      ),
      style: TextStyle(
        fontSize: DesignTokens.fontSizeBody,
        color: widget.isDarkMode
            ? DesignTokens.darkTextPrimary
            : DesignTokens.gray700,
      ),
    );
  }
}
