// Copyright (c) 2026 litongshuai
// SPDX-License-Identifier: MIT OR Apache-2.0

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../../l10n/strings.g.dart';
import 'cici_design_tokens.dart';
import 'cici_avatar.dart';

enum MessageType { user, assistant }

class CiciMessageBubble extends StatefulWidget {
  final MessageType type;
  final String? text;
  final String? time;
  final bool showStatus;
  final Widget? content;
  final String? copyableText;
  final VoidCallback? onCopy;
  final bool showUndo;
  final VoidCallback? onUndo;

  const CiciMessageBubble({
    super.key,
    required this.type,
    this.text,
    this.time,
    this.showStatus = false,
    this.content,
    this.copyableText,
    this.onCopy,
    this.showUndo = false,
    this.onUndo,
  });

  @override
  State<CiciMessageBubble> createState() => _CiciMessageBubbleState();

  static Widget buildMarkdown(BuildContext context, String data) {
    if (data.isEmpty) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = CiciDesignTokens.getColor(
      context,
      CiciDesignTokens.text,
      CiciDesignTokens.darkText,
    );
    final codeBgColor = isDark
        ? const Color(0xFF1e293b)
        : const Color(0xFFF5F5F5);
    final codeTextColor = isDark
        ? const Color(0xFFe2e8f0)
        : const Color(0xFF24292e);
    final linkColor = CiciDesignTokens.getColor(
      context,
      CiciDesignTokens.primary,
      CiciDesignTokens.darkPrimary,
    );

    return MarkdownBody(
      data: data,
      styleSheet: MarkdownStyleSheet(
        p: TextStyle(
          fontSize: CiciDesignTokens.fontSizeBody,
          color: textColor,
          height: 1.7,
        ),
        strong: TextStyle(fontWeight: FontWeight.bold, color: textColor),
        em: TextStyle(fontStyle: FontStyle.italic, color: textColor),
        code: TextStyle(
          fontSize: CiciDesignTokens.fontSizeCaption,
          fontFamily: 'JetBrainsMono',
          backgroundColor: codeBgColor,
          color: codeTextColor,
        ),
        a: TextStyle(color: linkColor, decoration: TextDecoration.underline),
        blockquote: TextStyle(
          fontSize: CiciDesignTokens.fontSizeBody,
          color: textColor.withValues(alpha: 0.7),
          fontStyle: FontStyle.italic,
        ),
        h1: TextStyle(
          fontSize: CiciDesignTokens.fontSizeH1,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
        h2: TextStyle(
          fontSize: CiciDesignTokens.fontSizeH2,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
        h3: TextStyle(
          fontSize: CiciDesignTokens.fontSizeBody,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
        listBullet: TextStyle(
          color: textColor,
          fontSize: CiciDesignTokens.fontSizeBody,
        ),
        blockquoteDecoration: BoxDecoration(
          border: Border(
            left: BorderSide(color: textColor.withValues(alpha: 0.3), width: 3),
          ),
        ),
      ),
    );
  }
}

class _CiciMessageBubbleState extends State<CiciMessageBubble> {
  bool _isHovered = false;
  bool _isCopied = false;

  Future<void> _copyToClipboard() async {
    final textToCopy = widget.copyableText ?? widget.text ?? '';
    if (textToCopy.isEmpty) return;

    await Clipboard.setData(ClipboardData(text: textToCopy));
    widget.onCopy?.call();

    if (!mounted) return;
    setState(() => _isCopied = true);
  }

  @override
  Widget build(BuildContext context) {
    final bubble = widget.type == MessageType.user
        ? _buildUserBubble(context)
        : _buildAssistantBubble(context);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() {
        _isHovered = false;
        _isCopied = false;
      }),
      child: bubble,
    );
  }

  Widget _buildCopyButton() {
    final t = Translations.of(context);
    return Tooltip(
      message: _isCopied ? t.ai_messageCopied : t.ai_copyMessage,
      child: AnimatedOpacity(
        opacity: _isHovered ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 200),
        child: InkWell(
          onTap: _copyToClipboard,
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.all(2),
            child: Icon(
              _isCopied ? Icons.check : Icons.copy_outlined,
              size: 14,
              color: CiciDesignTokens.getColor(
                context,
                CiciDesignTokens.gray,
                CiciDesignTokens.darkGray,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUndoButton() {
    final t = Translations.of(context);
    return Tooltip(
      message: t.ai_undoMessage,
      child: AnimatedOpacity(
        opacity: _isHovered ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 200),
        child: InkWell(
          onTap: widget.onUndo,
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.all(2),
            child: Icon(
              Icons.replay,
              size: 14,
              color: CiciDesignTokens.getColor(
                context,
                CiciDesignTokens.gray,
                CiciDesignTokens.darkGray,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserBubble(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              // // 双对勾在气泡外侧左下角，底部对齐
              // if (widget.showStatus) ...[
              //   SizedBox(
              //     width: 14,
              //     height: 14,
              //     child: SvgPicture.asset('assets/svg/double-check.svg'),
              //   ),
              //   const SizedBox(width: 6),
              // ],
              Container(
                constraints: const BoxConstraints(maxWidth: 280),
                padding: const EdgeInsets.symmetric(
                  horizontal: CiciDesignTokens.spaceLg,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: CiciDesignTokens.getColor(
                    context,
                    CiciDesignTokens.userBubble,
                    CiciDesignTokens.darkUserBubble,
                  ),
                  borderRadius: BorderRadius.circular(
                    CiciDesignTokens.radiusMd,
                  ).copyWith(bottomRight: const Radius.circular(4)),
                  boxShadow: CiciDesignTokens.getShadow(
                    context,
                    CiciDesignTokens.shadowBubble,
                    CiciDesignTokens.shadowDarkBubble,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.text != null)
                      Text(
                        widget.text!,
                        style: TextStyle(
                          fontSize: CiciDesignTokens.fontSizeBody,
                          color: CiciDesignTokens.getColor(
                            context,
                            CiciDesignTokens.text,
                            CiciDesignTokens.darkText,
                          ),
                          height: 1.7,
                        ),
                      ),
                    // if (widget.time != null)
                    //   Padding(
                    //     padding: const EdgeInsets.only(top: 4),
                    //     child: Text(
                    //       widget.time!,
                    //       style: TextStyle(
                    //         fontSize: CiciDesignTokens.fontSizeCaption,
                    //         color: CiciDesignTokens.getColor(
                    //           context,
                    //           CiciDesignTokens.gray,
                    //           CiciDesignTokens.darkGray,
                    //         ),
                    //       ),
                    //     ),
                    //   ),
                  ],
                ),
              ),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedOpacity(
                opacity: _isHovered ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.time != null) ...[
                      Padding(
                        padding: const EdgeInsets.only(top: 2, right: 4),
                        child: Text(
                          widget.time!,
                          style: TextStyle(
                            fontSize: CiciDesignTokens.fontSizeCaption,
                            color: CiciDesignTokens.getColor(
                              context,
                              CiciDesignTokens.gray,
                              CiciDesignTokens.darkGray,
                            ),
                          ),
                        ),
                      ),
                    ],
                    if (widget.showUndo) ...[
                      Padding(
                        padding: const EdgeInsets.only(top: 2, right: 4),
                        child: _buildUndoButton(),
                      ),
                    ],
                    if (widget.showStatus) ...[
                      Padding(
                        padding: const EdgeInsets.only(top: 2, right: 4),
                        child: _buildCopyButton(),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAssistantBubble(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const CiciAvatar(),
          const SizedBox(width: CiciDesignTokens.spaceMd),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 280),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: CiciDesignTokens.spaceLg,
                vertical: 14,
              ),
              decoration: BoxDecoration(
                color: CiciDesignTokens.getColor(
                  context,
                  CiciDesignTokens.white,
                  CiciDesignTokens.darkCardBg,
                ),
                border: Border.all(
                  color: CiciDesignTokens.getColor(
                    context,
                    CiciDesignTokens.border,
                    CiciDesignTokens.darkBorder,
                  ),
                ),
                borderRadius: BorderRadius.circular(
                  CiciDesignTokens.radiusMd,
                ).copyWith(bottomLeft: const Radius.circular(4)),
                boxShadow: CiciDesignTokens.getShadow(
                  context,
                  CiciDesignTokens.shadowCard,
                  CiciDesignTokens.shadowDarkCard,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  widget.content ??
                      (widget.text != null
                          ? _buildMarkdownContent(context, widget.text!)
                          : const SizedBox.shrink()),
                  if (widget.time != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildCopyButton(),
                          Text(
                            widget.time!,
                            style: TextStyle(
                              fontSize: CiciDesignTokens.fontSizeCaption,
                              color: CiciDesignTokens.getColor(
                                context,
                                CiciDesignTokens.gray,
                                CiciDesignTokens.darkGray,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMarkdownContent(BuildContext context, String data) {
    return IntrinsicWidth(
      child: CiciMessageBubble.buildMarkdown(context, data),
    );
  }
}
