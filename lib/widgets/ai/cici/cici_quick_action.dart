// Copyright (c) 2026 litongshuai
// SPDX-License-Identifier: MIT OR Apache-2.0

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'cici_design_tokens.dart';

class CiciQuickAction extends StatelessWidget {
  final String label;
  final String iconPath;
  final VoidCallback? onTap;

  const CiciQuickAction({
    super.key,
    required this.label,
    required this.iconPath,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
          borderRadius: BorderRadius.circular(CiciDesignTokens.radiusFull),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 10,
              height: 10,
              child: SvgPicture.asset(iconPath, width: 10, height: 10),
            ),
            const SizedBox(width: CiciDesignTokens.spaceXs),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: CiciDesignTokens.getColor(
                  context,
                  CiciDesignTokens.text,
                  CiciDesignTokens.darkText,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CiciQuickActionRow extends StatelessWidget {
  final List<CiciQuickActionData> actions;

  const CiciQuickActionRow({super.key, required this.actions});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // If content fits, use Row directly; otherwise wrap in scrollable
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(actions.length, (index) {
              final isLast = index == actions.length - 1;
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CiciQuickAction(
                    label: actions[index].label,
                    iconPath: actions[index].iconPath,
                    onTap: actions[index].onTap,
                  ),
                  if (!isLast) const SizedBox(width: CiciDesignTokens.spaceSm),
                ],
              );
            }),
          ),
        );
      },
    );
  }
}

class CiciQuickActionData {
  final String label;
  final String iconPath;
  final VoidCallback? onTap;

  const CiciQuickActionData({
    required this.label,
    required this.iconPath,
    this.onTap,
  });
}
