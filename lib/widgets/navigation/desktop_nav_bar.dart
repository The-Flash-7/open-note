// Copyright (c) 2026 litongshuai
// SPDX-License-Identifier: MIT OR Apache-2.0

import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import '../../theme/design_tokens.dart';
import '../../providers/theme_provider.dart';
import '../../l10n/strings.g.dart';

class DesktopNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int)? onItemSelected;
  final List<NavItemData> items;
  final VoidCallback? onSettingsTap;
  final VoidCallback? onThemeToggle;

  const DesktopNavBar({
    super.key,
    this.selectedIndex = 0,
    this.onItemSelected,
    this.items = const [],
    this.onSettingsTap,
    this.onThemeToggle,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: DesignTokens.navBarWidthDesktop,
      height: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? DesignTokens.darkSurface : Colors.white,
        border: Border(
          right: BorderSide(
            color: isDark
                ? DesignTokens.darkBorder.withValues(alpha: 0.3)
                : DesignTokens.gray200,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          SizedBox(height: DesignTokens.space6),
          Expanded(
            child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                return _buildNavItem(index, items[index], isDark);
              },
            ),
          ),
          if (onThemeToggle != null)
            Padding(
              padding: EdgeInsets.all(DesignTokens.space4),
              child: _buildThemeToggleButton(isDark),
            ),
          if (onSettingsTap != null)
            Padding(
              padding: EdgeInsets.all(DesignTokens.space4),
              child: _buildSettingsButton(isDark),
            ),
        ],
      ),
    );
  }

  Widget _buildThemeToggleButton(bool isDark) {
    return RepaintBoundary(
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return GestureDetector(
            onTap: onThemeToggle,
            child: Container(
              height: 40,
              alignment: Alignment.center,
              child: Icon(
                _getThemeIcon(themeProvider.themeMode),
                size: DesignTokens.iconSizeNavigation,
                color: isDark
                    ? DesignTokens.darkPrimary500
                    : DesignTokens.primary500,
              ),
            ),
          );
        },
      ),
    );
  }

  IconData _getThemeIcon(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return Icons.light_mode;
      case ThemeMode.dark:
        return Icons.dark_mode;
      default:
        return Icons.brightness_auto;
    }
  }

  Widget _buildSettingsButton(bool isDark) {
    return RepaintBoundary(
      child: GestureDetector(
        onTap: onSettingsTap,
        child: Container(
          height: 40,
          alignment: Alignment.center,
          child: Icon(
            Icons.settings,
            size: DesignTokens.iconSizeNavigation,
            color: isDark
                ? DesignTokens.darkPrimary500
                : DesignTokens.primary500,
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, NavItemData item, bool isDark) {
    final isSelected = index == selectedIndex;

    return RepaintBoundary(
      child: GestureDetector(
        onTap: () => onItemSelected?.call(index),
        child: AnimatedContainer(
          duration: DesignTokens.durationFast,
          curve: DesignTokens.curveStandard,
          margin: EdgeInsets.symmetric(
            horizontal: DesignTokens.space4,
            vertical: DesignTokens.space1,
          ),
          height: 40,
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark
                      ? DesignTokens.darkPrimary700.withValues(alpha: 0.3)
                      : DesignTokens.primary50)
                : (isDark
                      ? DesignTokens.darkBackground.withValues(alpha: 0.1)
                      : DesignTokens.gray100),
            borderRadius: BorderRadius.circular(DesignTokens.radiusMD),
          ),
          child: Center(
            child: Icon(
              item.icon,
              size: DesignTokens.iconSizeNavigation,
              color: isSelected
                  ? (isDark
                        ? DesignTokens.darkPrimary500
                        : DesignTokens.primary500)
                  : (isDark
                        ? DesignTokens.darkTextSecondary
                        : DesignTokens.gray500),
            ),
          ),
        ),
      ),
    );
  }
}

class NavItemData {
  final IconData icon;
  final String label;
  final String? route;

  const NavItemData({required this.icon, required this.label, this.route});
}

class TopBar extends StatelessWidget {
  final String? title;
  final Widget? leading;
  final List<Widget>? actions;
  final VoidCallback? onSearchTap;
  final VoidCallback? onAIButtonTap;
  final VoidCallback? onMenuTap;
  final bool showAIButton;

  const TopBar({
    super.key,
    this.title,
    this.leading,
    this.actions,
    this.onSearchTap,
    this.onAIButtonTap,
    this.onMenuTap,
    this.showAIButton = true,
  });

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final localLeading = leading;
    final localTitle = title;

    // macOS: 包装拖拽功能
    Widget topBarContent = Container(
      height: DesignTokens.topBarHeight,
      padding: EdgeInsets.symmetric(horizontal: DesignTokens.space6),
      decoration: BoxDecoration(
        color: isDark ? DesignTokens.darkSurface : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? DesignTokens.darkBorder.withValues(alpha: 0.3)
                : DesignTokens.gray200,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Tablet布局：汉堡菜单按钮
          if (onMenuTap != null)
            IconButton(
              icon: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isDark
                      ? DesignTokens.darkPrimary700.withValues(alpha: 0.3)
                      : DesignTokens.primary50,
                  borderRadius: BorderRadius.circular(DesignTokens.radiusMD),
                ),
                child: Icon(
                  Icons.menu,
                  size: 16,
                  color: isDark
                      ? DesignTokens.darkPrimary500
                      : DesignTokens.primary500,
                ),
              ),
              onPressed: onMenuTap,
              tooltip: t.navigation_menu,
            ),
          if (onMenuTap != null) SizedBox(width: DesignTokens.space2),
          // macOS: 左侧预留空间给原生按钮
          if (Platform.isMacOS) SizedBox(width: 70),
          ?localLeading,
          Image.asset('assets/images/app_icon@200h.png', width: 28, height: 28),
          SizedBox(width: DesignTokens.space3),
          if (localTitle != null)
            Text(
              localTitle,
              style: TextStyle(
                fontSize: DesignTokens.fontSizeH3,
                fontWeight: DesignTokens.fontWeightSemiBold,
                color: isDark
                    ? DesignTokens.darkTextPrimary
                    : DesignTokens.gray900,
              ),
            ),
          Spacer(),
          if (onSearchTap != null)
            GestureDetector(
              onTap: onSearchTap,
              child: Container(
                width: 160,
                height: 28,
                decoration: BoxDecoration(
                  color: isDark ? DesignTokens.darkSurface : Colors.white,
                  borderRadius: BorderRadius.circular(DesignTokens.radiusSM),
                  border: Border.all(
                    color: isDark
                        ? DesignTokens.darkBorder.withValues(alpha: 0.5)
                        : DesignTokens.gray300,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    SizedBox(width: DesignTokens.space2),
                    Icon(
                      Icons.search,
                      size: 14,
                      color: isDark
                          ? DesignTokens.darkTextSecondary
                          : DesignTokens.gray400,
                    ),
                    SizedBox(width: DesignTokens.space1),
                    Text(
                      t.navigation_search,
                      style: TextStyle(
                        fontSize: DesignTokens.fontSizeCaption,
                        color: isDark
                            ? DesignTokens.darkTextSecondary
                            : DesignTokens.gray400,
                      ),
                    ),
                    Spacer(),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: DesignTokens.space2,
                        vertical: DesignTokens.space1,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? DesignTokens.darkBackground.withValues(alpha: 0.3)
                            : DesignTokens.gray100,
                        borderRadius: BorderRadius.circular(
                          DesignTokens.radiusXS,
                        ),
                      ),
                      child: Text(
                        Platform.isMacOS ? '⌘⇧F' : 'Ctrl+Shift+F',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: DesignTokens.fontWeightMedium,
                          color: isDark
                              ? DesignTokens.darkTextSecondary.withValues(
                                  alpha: 0.7,
                                )
                              : DesignTokens.gray500,
                        ),
                      ),
                    ),
                    SizedBox(width: DesignTokens.space2),
                  ],
                ),
              ),
            ),
          SizedBox(width: DesignTokens.space4),
          if (showAIButton)
            GestureDetector(
              onTap: onAIButtonTap,
              child: Image.asset(
                'assets/images/ai-assistant-panel/ai-assistant-dialogue-bubble.png',
                width: 26,
                height: 26,
              ),
            ),
          if (actions != null) ...actions!,
        ],
      ),
    );

    // macOS: 包装拖拽功能（原生按钮区域不响应拖拽）
    if (Platform.isMacOS) {
      return GestureDetector(
        onPanStart: (_) => windowManager.startDragging(),
        onDoubleTap: () async {
          if (await windowManager.isMaximized()) {
            await windowManager.unmaximize();
          } else {
            await windowManager.maximize();
          }
        },
        child: topBarContent,
      );
    }

    return topBarContent;
  }
}

class NoteListPanel extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final VoidCallback? onCreateNew;

  const NoteListPanel({
    super.key,
    this.title = '所有笔记',
    this.children = const [],
    this.onCreateNew,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: DesignTokens.noteListWidthDesktop,
      decoration: BoxDecoration(
        color: isDark ? DesignTokens.darkSurface : Colors.white,
        border: Border(
          right: BorderSide(
            color: isDark
                ? DesignTokens.darkBorder.withValues(alpha: 0.3)
                : DesignTokens.gray200,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(DesignTokens.space6),
            child: Row(
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: DesignTokens.fontSizeH3,
                    fontWeight: DesignTokens.fontWeightSemiBold,
                    color: isDark
                        ? DesignTokens.darkTextPrimary
                        : DesignTokens.gray900,
                  ),
                ),
                Spacer(),
                GestureDetector(
                  onTap: onCreateNew,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isDark
                          ? DesignTokens.darkPrimary700.withValues(alpha: 0.3)
                          : DesignTokens.primary50,
                      borderRadius: BorderRadius.circular(
                        DesignTokens.radiusMD,
                      ),
                    ),
                    child: Icon(
                      Icons.add,
                      size: 16,
                      color: isDark
                          ? DesignTokens.darkPrimary500
                          : DesignTokens.primary500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(
            color: isDark
                ? DesignTokens.darkBorder.withValues(alpha: 0.3)
                : DesignTokens.gray200,
            height: 1,
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.all(DesignTokens.space4),
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}
