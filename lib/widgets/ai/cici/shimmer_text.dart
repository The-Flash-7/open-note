// Copyright (c) 2026 litongshuai
// SPDX-License-Identifier: MIT OR Apache-2.0

import 'package:flutter/material.dart';
import '../../../theme/design_tokens.dart';

class ShimmerText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final bool shimmering;
  final Color baseColor;
  final Color shimmerColor;
  final Duration duration;

  const ShimmerText({
    super.key,
    required this.text,
    this.style,
    this.shimmering = false,
    this.baseColor = DesignTokens.gray500,
    this.shimmerColor = DesignTokens.gray50,
    this.duration = const Duration(milliseconds: 1500),
  });

  @override
  State<ShimmerText> createState() => _ShimmerTextState();
}

class _ShimmerTextState extends State<ShimmerText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);
    _animation = Tween<double>(
      begin: -2.0,
      end: 2.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    if (widget.shimmering) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(ShimmerText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.shimmering != oldWidget.shimmering) {
      if (widget.shimmering) {
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
    if (!widget.shimmering) {
      return Text(widget.text, style: widget.style);
    }

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment(_animation.value, 0),
              end: Alignment(_animation.value + 1, 0),
              colors: [
                widget.baseColor,
                widget.shimmerColor,
                widget.shimmerColor,
                widget.baseColor,
                // widget.baseColor.withValues(alpha: 0.4),
                // widget.shimmerColor.withValues(alpha: 0.2),
                // widget.shimmerColor.withValues(alpha: 0.2),
                // widget.baseColor.withValues(alpha: 0.4),
              ],
              stops: const [0.0, 0.2, 0.8, 1.0],
            ).createShader(bounds);
            // return RadialGradient(
            //   center: Alignment(_animation.value, 0),
            //   radius: 0.8,
            //   colors: [
            //     widget.shimmerColor.withValues(alpha: 1.0),
            //     widget.baseColor.withValues(alpha: 0.4),
            //   ],
            //   stops: const [0.0, 1.0],
            // ).createShader(bounds);
          },
          child: Text(widget.text, style: widget.style),
        );
      },
    );
  }
}
