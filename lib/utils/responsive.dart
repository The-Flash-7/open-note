// Copyright (c) 2026 litongshuai
// SPDX-License-Identifier: MIT OR Apache-2.0

import 'package:flutter/material.dart';
import '../theme/design_tokens.dart';

class Responsive {
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < DesignTokens.breakpointMobile;

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= DesignTokens.breakpointMobile &&
        width < DesignTokens.breakpointTablet;
  }

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= DesignTokens.breakpointTablet;

  static double screenWidth(BuildContext context) =>
      MediaQuery.of(context).size.width;

  static double screenHeight(BuildContext context) =>
      MediaQuery.of(context).size.height;

  static Orientation orientation(BuildContext context) =>
      MediaQuery.of(context).orientation;

  static bool isLandscape(BuildContext context) =>
      orientation(context) == Orientation.landscape;

  static bool isPortrait(BuildContext context) =>
      orientation(context) == Orientation.portrait;

  static double getNavigationWidth(BuildContext context) {
    if (isDesktop(context)) {
      return DesignTokens.navBarWidthDesktop;
    }
    return 0;
  }

  static double getNoteListWidth(BuildContext context) {
    if (isDesktop(context)) {
      return DesignTokens.noteListWidthDesktop;
    }
    if (isTablet(context)) {
      return 200;
    }
    return screenWidth(context);
  }

  static bool shouldShowBottomNavigation(BuildContext context) =>
      isMobile(context);

  static bool shouldShowSideNavigation(BuildContext context) =>
      isDesktop(context);

  static EdgeInsets getScreenPadding(BuildContext context) {
    if (isMobile(context)) {
      return EdgeInsets.all(DesignTokens.space4);
    }
    return EdgeInsets.all(DesignTokens.space8);
  }

  static double getCardSpacing(BuildContext context) {
    if (isMobile(context)) {
      return DesignTokens.space4;
    }
    return DesignTokens.space6;
  }

  static int getCrossAxisCount(BuildContext context) {
    if (isMobile(context)) {
      return 1;
    }
    if (isTablet(context)) {
      return 2;
    }
    return 3;
  }

  static Widget value({
    required BuildContext context,
    required Widget mobile,
    Widget? tablet,
    Widget? desktop,
  }) {
    if (isDesktop(context)) {
      return desktop ?? tablet ?? mobile;
    }
    if (isTablet(context)) {
      return tablet ?? mobile;
    }
    return mobile;
  }

  static T conditionalValue<T>({
    required BuildContext context,
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    if (isDesktop(context)) {
      return desktop ?? tablet ?? mobile;
    }
    if (isTablet(context)) {
      return tablet ?? mobile;
    }
    return mobile;
  }

  static LayoutMode getLayoutMode(BuildContext context) {
    if (isDesktop(context)) {
      return LayoutMode.desktop;
    }
    if (isTablet(context)) {
      return LayoutMode.tablet;
    }
    return LayoutMode.mobile;
  }
}

enum LayoutMode { mobile, tablet, desktop }

class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, LayoutMode layoutMode) builder;

  const ResponsiveBuilder({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    return builder(context, Responsive.getLayoutMode(context));
  }
}

class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    return Responsive.value(
      context: context,
      mobile: mobile,
      tablet: tablet,
      desktop: desktop,
    );
  }
}
