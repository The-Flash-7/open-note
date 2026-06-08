// Copyright (c) 2026 litongshuai
// SPDX-License-Identifier: MIT OR Apache-2.0

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'cici_design_tokens.dart';

class CiciAvatar extends StatelessWidget {
  final double size;

  const CiciAvatar({super.key, this.size = CiciDesignTokens.avatarSize});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final avatarPath = isDark
        ? 'assets/images/ai-assistant-panel/cici-avatar-dark.jpg'
        : 'assets/images/ai-assistant-panel/cici-avatar-light.jpg';

    return ClipRRect(
      borderRadius: BorderRadius.circular(size / 2),
      child: Image.asset(
        avatarPath,
        width: size,
        height: size,
        fit: BoxFit.cover,
      ),
    );
  }
}

class CiciHeroImage extends StatelessWidget {
  const CiciHeroImage({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: CiciDesignTokens.heroWidth,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: 0,
            right: 0,
            child: Opacity(
              opacity: 0.8,
              child: SvgPicture.asset(
                'assets/svg/cici-bg-bubbles.svg',
                width: 240,
              ),
            ),
          ),
          Image.asset(
            'assets/images/ai-assistant-panel/cici-hero.png',
            width: CiciDesignTokens.heroWidth,
          ),
        ],
      ),
    );
  }
}
