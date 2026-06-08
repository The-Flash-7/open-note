// Copyright (c) 2026 litongshuai
// SPDX-License-Identifier: MIT OR Apache-2.0

import 'package:flutter/material.dart';
import '../../theme/design_tokens.dart';

class AIFloatingIcon extends StatefulWidget {
  final double size;
  final bool isAnimating;
  final VoidCallback? onTap;

  const AIFloatingIcon({
    super.key,
    this.size = 32.0,
    this.isAnimating = false,
    this.onTap,
  });

  @override
  State<AIFloatingIcon> createState() => _AIFloatingIconState();
}

class _AIFloatingIconState extends State<AIFloatingIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    if (widget.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(AIFloatingIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isAnimating != oldWidget.isAnimating) {
      if (widget.isAnimating) {
        _controller.repeat();
      } else {
        _controller.stop();
        _controller.reset();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: GestureDetector(
        onTap: widget.onTap,
        child: RotationTransition(
          turns: _controller,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              gradient: DesignTokens.gradientPrimary,
              borderRadius: BorderRadius.circular(widget.size / 2),
              boxShadow: widget.isAnimating
                  ? DesignTokens.shadowDarkPrimary
                  : DesignTokens.shadowPrimary,
            ),
            child: Center(
              child: Icon(
                Icons.auto_awesome,
                color: Colors.white,
                size: widget.size * 0.56,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
