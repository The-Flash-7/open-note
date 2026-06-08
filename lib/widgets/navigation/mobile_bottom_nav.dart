// Copyright (c) 2026 litongshuai
// SPDX-License-Identifier: MIT OR Apache-2.0

import 'package:flutter/material.dart';
import '../../theme/design_tokens.dart';

class MobileBottomNav extends StatelessWidget {
  final int selectedIndex;
  final Function(int)? onItemSelected;
  final List<NavItem> items;
  final VoidCallback? onAIButtonTap;

  const MobileBottomNav({
    super.key,
    this.selectedIndex = 0,
    this.onItemSelected,
    this.items = const [],
    this.onAIButtonTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: DesignTokens.bottomNavHeightMobile,
      decoration: BoxDecoration(
        color: isDark ? DesignTokens.darkSurface : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark
                ? DesignTokens.darkBorder.withValues(alpha: 0.3)
                : DesignTokens.gray200,
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;

          if (item.label == 'AI') {
            return _buildAIButton();
          }

          return _buildNavItem(index, item, isDark);
        }).toList(),
      ),
    );
  }

  Widget _buildNavItem(int index, NavItem item, bool isDark) {
    final isSelected = index == selectedIndex;

    return GestureDetector(
      onTap: () => onItemSelected?.call(index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              item.icon,
              size: DesignTokens.iconSizeNavigation,
              color: isSelected
                  ? DesignTokens.primary500
                  : (isDark
                        ? DesignTokens.darkTextSecondary
                        : DesignTokens.gray500),
            ),
            SizedBox(height: DesignTokens.space1),
            Text(
              item.label,
              style: TextStyle(
                fontSize: DesignTokens.fontSizeCaption,
                fontWeight: isSelected
                    ? DesignTokens.fontWeightMedium
                    : DesignTokens.fontWeightRegular,
                color: isSelected
                    ? DesignTokens.primary500
                    : (isDark
                          ? DesignTokens.darkTextSecondary
                          : DesignTokens.gray500),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAIButton() {
    return GestureDetector(
      onTap: onAIButtonTap,
      child: SizedBox(
        width: 64,
        child: Transform.translate(
          offset: Offset(0, -8),
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: DesignTokens.gradientPrimary,
              borderRadius: BorderRadius.circular(16),
              boxShadow: DesignTokens.shadowPrimary,
            ),
            child: Center(
              child: Icon(Icons.auto_awesome, color: Colors.white, size: 18),
            ),
          ),
        ),
      ),
    );
  }
}

class NavItem {
  final IconData icon;
  final String label;
  final String? route;

  const NavItem({required this.icon, required this.label, this.route});
}

class MobileHomeHeader extends StatelessWidget {
  const MobileHomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      padding: EdgeInsets.symmetric(horizontal: DesignTokens.space6),
      decoration: BoxDecoration(gradient: DesignTokens.gradientNav),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Image.asset('assets/images/app_icon@200h.png', width: 36, height: 36),
        ],
      ),
    );
  }
}
