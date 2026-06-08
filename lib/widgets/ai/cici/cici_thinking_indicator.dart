// Copyright (c) 2026 litongshuai
// SPDX-License-Identifier: MIT OR Apache-2.0

import 'package:flutter/material.dart';
import '../../../l10n/strings.g.dart';
import 'cici_design_tokens.dart';
import 'shimmer_text.dart';

class CiciThinkingIndicator extends StatefulWidget {
  final String thinkingContent;

  const CiciThinkingIndicator({super.key, required this.thinkingContent});

  @override
  State<CiciThinkingIndicator> createState() => _CiciThinkingIndicatorState();
}

class _CiciThinkingIndicatorState extends State<CiciThinkingIndicator>
    with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();

  @override
  void didUpdateWidget(CiciThinkingIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.thinkingContent != oldWidget.thinkingContent) {
      // 滚动到最新内容
      Future.microtask(() {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOutCubic,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark
        ? CiciDesignTokens.darkCardBg.withValues(alpha: 0.5)
        : const Color(0xFFF8F9FA);
    final textColor = isDark
        ? CiciDesignTokens.darkGray
        : CiciDesignTokens.gray;

    // 只显示最新 100 字符，滚动过去的丢弃
    final displayContent = widget.thinkingContent.length > 100
        ? '...${widget.thinkingContent.substring(widget.thinkingContent.length - 100)}'
        : widget.thinkingContent;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            decoration: BoxDecoration(
              color: bgColor.withValues(alpha: 0),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // const Text('', style: TextStyle(fontSize: 12)),
                // const SizedBox(width: 2),
                ShimmerText(
                  text: t.ai_thinking,
                  style: TextStyle(
                    fontSize: 11,
                    color: textColor,
                    fontWeight: FontWeight.w500,
                  ),
                  shimmering: true,
                  baseColor: textColor,
                  shimmerColor: Colors.white,
                  duration: const Duration(milliseconds: 1500),
                ),
                const SizedBox(width: 4),
                SizedBox(
                  width: 160,
                  height: 16,
                  child: ShaderMask(
                    shaderCallback: (bounds) {
                      return LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        stops: const [0.0, 0.15, 0.8, 1.0],
                        colors: [
                          Colors.transparent,
                          Colors.white,
                          Colors.white,
                          Colors.transparent,
                        ],
                      ).createShader(bounds);
                    },
                    blendMode: BlendMode.dstIn,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      controller: _scrollController,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          displayContent,
                          style: TextStyle(
                            fontSize: 10,
                            color: textColor.withValues(alpha: 0.4),
                            height: 1.0,
                          ),
                          maxLines: 1,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
