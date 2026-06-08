// Copyright (c) 2026 litongshuai
// SPDX-License-Identifier: MIT OR Apache-2.0

import 'package:flutter/material.dart';
import '../../theme/design_tokens.dart';

class SkeletonLoader extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const SkeletonLoader({
    super.key,
    this.width = double.infinity,
    required this.height,
    this.borderRadius = DesignTokens.radiusMD,
  });

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat();

    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            color: isDark
                ? DesignTokens.darkBorder.withValues(alpha: 
                    0.3 + _animation.value * 0.2,
                  )
                : DesignTokens.gray100.withValues(alpha: 
                    0.7 + _animation.value * 0.2,
                  ),
          ),
        );
      },
    );
  }
}

class NoteCardSkeleton extends StatelessWidget {
  const NoteCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: EdgeInsets.only(bottom: DesignTokens.space4),
      padding: EdgeInsets.all(DesignTokens.space6),
      decoration: BoxDecoration(
        color: isDark ? DesignTokens.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(DesignTokens.radiusLG),
        boxShadow: DesignTokens.shadowSM,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SkeletonLoader(
                width: 150,
                height: 16,
                borderRadius: DesignTokens.radiusXS,
              ),
              Spacer(),
              SkeletonLoader(
                width: 28,
                height: 28,
                borderRadius: DesignTokens.radiusSM,
              ),
            ],
          ),
          SizedBox(height: DesignTokens.space3),
          SkeletonLoader(
            width: double.infinity,
            height: 14,
            borderRadius: DesignTokens.radiusXS,
          ),
          SizedBox(height: DesignTokens.space2),
          SkeletonLoader(
            width: double.infinity * 0.8,
            height: 14,
            borderRadius: DesignTokens.radiusXS,
          ),
          SizedBox(height: DesignTokens.space3),
          Row(
            children: [
              SkeletonLoader(
                width: 40,
                height: 20,
                borderRadius: DesignTokens.radiusFull,
              ),
              SizedBox(width: DesignTokens.space2),
              SkeletonLoader(
                width: 50,
                height: 20,
                borderRadius: DesignTokens.radiusFull,
              ),
              SizedBox(width: DesignTokens.space2),
              SkeletonLoader(
                width: 35,
                height: 20,
                borderRadius: DesignTokens.radiusFull,
              ),
            ],
          ),
          SizedBox(height: DesignTokens.space3),
          Row(
            children: [
              SkeletonLoader(
                width: 12,
                height: 12,
                borderRadius: DesignTokens.radiusXS,
              ),
              SizedBox(width: DesignTokens.space1),
              SkeletonLoader(
                width: 80,
                height: 10,
                borderRadius: DesignTokens.radiusXS,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class AISummarySkeleton extends StatelessWidget {
  const AISummarySkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.all(DesignTokens.space6),
      decoration: BoxDecoration(
        gradient: isDark
            ? DesignTokens.gradientDarkAI
            : DesignTokens.gradientAI,
        borderRadius: BorderRadius.circular(DesignTokens.radiusLG),
        border: Border.all(
          color: isDark
              ? DesignTokens.darkPrimary700.withValues(alpha: 0.5)
              : DesignTokens.primary200,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SkeletonLoader(
                width: 20,
                height: 20,
                borderRadius: DesignTokens.radiusSM,
              ),
              SizedBox(width: DesignTokens.space3),
              SkeletonLoader(
                width: 60,
                height: 14,
                borderRadius: DesignTokens.radiusXS,
              ),
              Spacer(),
              SkeletonLoader(
                width: 60,
                height: 28,
                borderRadius: DesignTokens.radiusSM,
              ),
            ],
          ),
          SizedBox(height: DesignTokens.space4),
          SkeletonLoader(
            width: double.infinity,
            height: 14,
            borderRadius: DesignTokens.radiusXS,
          ),
          SizedBox(height: DesignTokens.space2),
          SkeletonLoader(
            width: double.infinity * 0.7,
            height: 14,
            borderRadius: DesignTokens.radiusXS,
          ),
          SizedBox(height: DesignTokens.space4),
          Row(
            children: [
              SkeletonLoader(
                width: 50,
                height: 12,
                borderRadius: DesignTokens.radiusXS,
              ),
              SizedBox(width: DesignTokens.space2),
              SkeletonLoader(
                width: 40,
                height: 20,
                borderRadius: DesignTokens.radiusFull,
              ),
              SizedBox(width: DesignTokens.space2),
              SkeletonLoader(
                width: 45,
                height: 20,
                borderRadius: DesignTokens.radiusFull,
              ),
              SizedBox(width: DesignTokens.space2),
              SkeletonLoader(
                width: 35,
                height: 20,
                borderRadius: DesignTokens.radiusFull,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
