// Copyright (c) 2026 litongshuai
// SPDX-License-Identifier: MIT OR Apache-2.0

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../l10n/strings.g.dart';
import 'cici_design_tokens.dart';

class CiciInput extends StatefulWidget {
  final String? placeholder;
  final VoidCallback? onSend;
  final VoidCallback? onStop;
  final ValueChanged<String>? onSubmit;
  final TextEditingController? controller;
  final FocusNode? focusNode;

  const CiciInput({
    super.key,
    this.placeholder,
    this.onSend,
    this.onStop,
    this.onSubmit,
    this.controller,
    this.focusNode,
  });

  @override
  State<CiciInput> createState() => _CiciInputState();
}

class _CiciInputState extends State<CiciInput> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  late FocusNode _keyboardFocusNode;
  bool _isFocused = false;
  bool _isHovering = false;

  void _onFocusChange() {
    if (mounted) {
      setState(() => _isFocused = _focusNode.hasFocus);
    }
  }

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _focusNode = widget.focusNode ?? FocusNode();
    _keyboardFocusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(CiciInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      if (oldWidget.controller == null) _controller.dispose();
      _controller = widget.controller ?? TextEditingController();
    }
    if (widget.focusNode != oldWidget.focusNode) {
      _focusNode.removeListener(_onFocusChange);
      if (oldWidget.focusNode == null) _focusNode.dispose();
      _focusNode = widget.focusNode ?? FocusNode();
      _focusNode.addListener(_onFocusChange);
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    if (widget.controller == null) _controller.dispose();
    if (widget.focusNode == null) _focusNode.dispose();
    _keyboardFocusNode.dispose();
    super.dispose();
  }

  void _handleSend() {
    if (_controller.text.isNotEmpty) {
      widget.onSubmit?.call(_controller.text);
      widget.onSend?.call();
      _controller.clear();
    }
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.enter) {
      final isShiftPressed = HardwareKeyboard.instance.isShiftPressed;
      if (!isShiftPressed && _controller.text.isNotEmpty) {
        _handleSend();
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: Container(
        constraints: const BoxConstraints(minHeight: 48, maxHeight: 100),
        decoration: BoxDecoration(
          color: CiciDesignTokens.getColor(
            context,
            CiciDesignTokens.white,
            CiciDesignTokens.darkCardBg,
          ),
          border: Border.all(
            color: _isFocused
                ? CiciDesignTokens.getColor(
                    context,
                    CiciDesignTokens.border,
                    CiciDesignTokens.darkBorder,
                  )
                : _isHovering
                ? CiciDesignTokens.primaryHover
                : CiciDesignTokens.getColor(
                    context,
                    CiciDesignTokens.border,
                    CiciDesignTokens.darkBorder,
                  ),
          ),
          borderRadius: BorderRadius.circular(CiciDesignTokens.radiusXl),
          boxShadow: CiciDesignTokens.getShadow(
            context,
            CiciDesignTokens.shadowCard,
            CiciDesignTokens.shadowDarkCard,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Theme(
                data: Theme.of(
                  context,
                ).copyWith(hoverColor: Colors.transparent),
                child: Focus(
                  onKeyEvent: _handleKeyEvent,
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    maxLines: null,
                    minLines: 1,
                    keyboardType: TextInputType.multiline,
                    expands: false,
                    textAlignVertical: TextAlignVertical.center,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.2,
                      color: CiciDesignTokens.getColor(
                        context,
                        CiciDesignTokens.text,
                        CiciDesignTokens.darkText,
                      ),
                    ),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText:
                          widget.placeholder ?? t.ai_inputDefaultPlaceholder,
                      hintStyle: TextStyle(
                        fontSize: 14,
                        color: CiciDesignTokens.getColor(
                          context,
                          CiciDesignTokens.gray,
                          CiciDesignTokens.darkGray,
                        ),
                        height: 1.2,
                      ),
                      contentPadding: const EdgeInsets.only(
                        left: 5,
                        top: 10,
                        bottom: 10,
                      ),
                    ),
                    cursorColor: CiciDesignTokens.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: CiciDesignTokens.spaceSm),
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Tooltip(
                message: widget.onStop != null ? t.common_stop : t.common_send,
                child: GestureDetector(
                  onTap: widget.onStop ?? _handleSend,
                  child: Container(
                    width: CiciDesignTokens.sendBtnSize,
                    height: CiciDesignTokens.sendBtnSize,
                    decoration: BoxDecoration(
                      color: widget.onStop != null
                          ? const Color(0xFFEF4444)
                          : CiciDesignTokens.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(
                        widget.onStop != null
                            ? Icons.stop
                            : Icons.arrow_forward,
                        size: 16,
                        color: CiciDesignTokens.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
