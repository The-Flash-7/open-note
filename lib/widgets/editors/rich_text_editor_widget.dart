// Copyright (c) 2026 litongshuai
// SPDX-License-Identifier: MIT OR Apache-2.0

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

import '../../l10n/strings.g.dart';
import '../../theme/design_tokens.dart';

class RichTextEditorWidget extends StatefulWidget {
  final String content;
  final Function(String) onChanged;
  final bool isDarkMode;

  const RichTextEditorWidget({
    super.key,
    required this.content,
    required this.onChanged,
    this.isDarkMode = false,
  });

  @override
  State<RichTextEditorWidget> createState() => _RichTextEditorWidgetState();
}

class _RichTextEditorWidgetState extends State<RichTextEditorWidget> {
  late QuillController _controller;
  late FocusNode _focusNode;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _initializeController();

    _controller.document.changes.listen((change) {
      if (_isInitialized && mounted) {
        final deltaJson = jsonEncode(_controller.document.toDelta().toJson());
        widget.onChanged(deltaJson);
      }
    });
  }

  void _initializeController() {
    try {
      if (widget.content.isEmpty) {
        _controller = QuillController.basic();
      } else {
        final deltaJson = jsonDecode(widget.content);
        _controller = QuillController(
          document: Document.fromJson(deltaJson),
          selection: const TextSelection.collapsed(offset: 0),
        );
      }
      _isInitialized = true;
    } catch (e) {
      debugPrint('Failed to parse Quill Delta: $e');
      _controller = QuillController.basic();
      _controller.document.insert(0, widget.content);
      _isInitialized = true;
    }
  }

  @override
  void didUpdateWidget(RichTextEditorWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.content != widget.content) {
      _updateControllerContent();
    }
  }

  void _updateControllerContent() {
    try {
      if (widget.content.isEmpty) {
        _controller.clear();
      } else {
        final deltaJson = jsonDecode(widget.content);
        _controller.document = Document.fromJson(deltaJson);
      }
    } catch (e) {
      _controller.clear();
      _controller.document.insert(0, widget.content);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  String getCurrentDeltaJson() {
    if (!_isInitialized) {
      return '';
    }

    final deltaJson = _controller.document.toDelta().toJson();
    final content = jsonEncode(deltaJson);

    return content;
  }

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    if (!_isInitialized) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        QuillSimpleToolbar(
          controller: _controller,
          config: const QuillSimpleToolbarConfig(
            showAlignmentButtons: false,
            showBackgroundColorButton: false,
            showCenterAlignment: false,
            showClearFormat: true,
            showCodeBlock: true,
            showColorButton: false,
            showDirection: false,
            showFontFamily: false,
            showFontSize: false,
            showHeaderStyle: true,
            showIndent: false,
            showJustifyAlignment: false,
            showLeftAlignment: false,
            showLink: true,
            showListCheck: true,
            showListBullets: true,
            showListNumbers: true,
            showRedo: true,
            showRightAlignment: false,
            showSearchButton: false,
            showSmallButton: false,
            showStrikeThrough: true,
            showSubscript: false,
            showSuperscript: false,
            showUnderLineButton: true,
            showUndo: true,
            multiRowsDisplay: false,
            toolbarIconAlignment: WrapAlignment.start,
            toolbarIconCrossAlignment: WrapCrossAlignment.center,
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: QuillEditor(
            controller: _controller,
            focusNode: _focusNode,
            scrollController: ScrollController(),
            config: QuillEditorConfig(
              placeholder: t.editor_startWritingRichText,
              padding: EdgeInsets.zero,
              autoFocus: false,
              expands: true,
              minHeight: 200,
              scrollable: true,
              customStyles: DefaultStyles(
                paragraph: DefaultTextBlockStyle(
                  TextStyle(
                    fontSize: DesignTokens.fontSizeBody,
                    color: widget.isDarkMode
                        ? DesignTokens.darkTextPrimary
                        : DesignTokens.gray700,
                  ),
                  const HorizontalSpacing(0, 0),
                  const VerticalSpacing(6, 0),
                  const VerticalSpacing(0, 0),
                  null,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
