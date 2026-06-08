// Copyright (c) 2026 litongshuai
// SPDX-License-Identifier: MIT OR Apache-2.0

import 'package:flutter/material.dart';

class CiciDesignTokens {
  // 亮色模式颜色
  static const Color primary = Color(0xFF00C389);
  static const Color primaryHover = Color(0xFF00a876);
  static const Color userBubble = Color(0xFFE8F9F2);
  static const Color pageBg = Color(0xFFF5FAF8);
  static const Color gray = Color(0xFF8A949E);
  static const Color text = Color(0xFF1A1A1A);
  static const Color white = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE5E7EB);
  static const Color tagBg = Color(0xFFE8F9F2);

  // 暗色模式颜色
  static const Color darkPrimary = Color(0xFF00C389); // 保持不变（AI特征色）
  static const Color darkPrimaryHover = Color(0xFF00a876); // 保持不变
  static const Color darkUserBubble = Color(0xFF064e3b); // 深绿色背景
  static const Color darkPageBg = Color(0xFF1e293b); // 跟随应用darkSurface
  static const Color darkGray = Color(0xFF94a3b8); // 跟随应用darkTextSecondary
  static const Color darkText = Color(0xFFd1d5db); // 跟随应用darkTextPrimary
  static const Color darkCardBg = Color(0xFF0f172a); // 跟随应用darkBackground
  static const Color darkBorder = Color(0xFF334155); // 跟随应用darkBorder
  static const Color darkTagBg = Color(0xFF064e3b); // 深绿色标签背景

  // 动态获取颜色方法
  static Color getColor(
    BuildContext context,
    Color lightColor,
    Color darkColor,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? darkColor : lightColor;
  }

  // 亮色模式阴影
  static const List<BoxShadow> shadowCard = [
    BoxShadow(
      color: Color.fromRGBO(0, 0, 0, 0.05),
      blurRadius: 6,
      offset: Offset(0, 2),
    ),
  ];

  static const List<BoxShadow> shadowBubble = [
    BoxShadow(
      color: Color.fromRGBO(0, 0, 0, 0.03),
      blurRadius: 3,
      offset: Offset(0, 1),
    ),
  ];

  static const List<BoxShadow> shadowFocus = [
    BoxShadow(
      color: Color.fromRGBO(0, 195, 137, 0.08),
      blurRadius: 2,
      offset: Offset(0, 0),
    ),
  ];

  // 暗色模式阴影
  static const List<BoxShadow> shadowDarkCard = [
    BoxShadow(
      color: Color.fromRGBO(0, 0, 0, 0.3),
      blurRadius: 6,
      offset: Offset(0, 2),
    ),
  ];

  static const List<BoxShadow> shadowDarkBubble = [
    BoxShadow(
      color: Color.fromRGBO(0, 0, 0, 0.2),
      blurRadius: 3,
      offset: Offset(0, 1),
    ),
  ];

  // 动态获取阴影方法
  static List<BoxShadow> getShadow(
    BuildContext context,
    List<BoxShadow> lightShadow,
    List<BoxShadow> darkShadow,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? darkShadow : lightShadow;
  }

  static const double fontSizeH1 = 20.0;
  static const double fontSizeH2 = 14.0;
  static const double fontSizeBody = 12.0;
  static const double fontSizeCaption = 10.0;

  static const FontWeight fontWeightBold = FontWeight.w700;
  static const FontWeight fontWeightMedium = FontWeight.w500;
  static const FontWeight fontWeightRegular = FontWeight.w400;

  static const double radiusSm = 6.0;
  static const double radiusMd = 10.0;
  static const double radiusLg = 14.0;
  static const double radiusXl = 20.0;
  static const double radiusFull = 9999.0;

  static const double spaceXs = 3.0;
  static const double spaceSm = 6.0;
  static const double spaceMd = 10.0;
  static const double spaceLg = 14.0;
  static const double spaceXl = 20.0;
  static const double space2xl = 24.0;
  static const double space3xl = 32.0;

  static const double panelWidth = 400.0;
  static const double avatarSize = 32.0;
  static const double sendBtnSize = 32.0;
  static const double heroWidth = 80.0;
}
