// Copyright (c) 2026 litongshuai
// SPDX-License-Identifier: MIT OR Apache-2.0

import 'package:flutter/material.dart';

class DesignTokens {
  static const primary700 = Color(0xFF059669);
  static const primary500 = Color(0xFF10b981);
  static const primary400 = Color(0xFF34d399);
  static const primary200 = Color(0xFF6ee7b7);
  static const primary100 = Color(0xFFa7f3d0);
  static const primary50 = Color(0xFFecfdf5);

  static const accent500 = Color(0xFFf59e0b);
  static const accent400 = Color(0xFFfbbf24);
  static const accent100 = Color(0xFFfef3c7);

  static const gray900 = Color(0xFF111827);
  static const gray700 = Color(0xFF374151);
  static const gray500 = Color(0xFF6b7280);
  static const gray400 = Color(0xFF9ca3af);
  static const gray300 = Color(0xFFd1d5db);
  static const gray200 = Color(0xFFe5e7eb);
  static const gray100 = Color(0xFFf3f4f6);
  static const gray50 = Color(0xFFf9fafb);

  static const success = Color(0xFF10b981);
  static const warning = Color(0xFFf59e0b);
  static const error = Color(0xFFef4444);
  static const info = Color(0xFF3b82f6);

  static const success500 = Color(0xFF10b981);
  static const success700 = Color(0xFF059669);
  static const successBackground = Color(0xFFd1fae5);
  static const darkSuccessBackground = Color(0xFF065f46);

  static const warning500 = Color(0xFFf59e0b);
  static const warningBackground = Color(0xFFfef3c7);
  static const darkWarningBackground = Color(0xFF78350f);

  static const error500 = Color(0xFFef4444);
  static const error700 = Color(0xFFdc2626);
  static const errorBackground = Color(0xFFfee2e2);
  static const darkErrorBackground = Color(0xFF7f1d1d);

  static const darkPrimary500 = Color(0xFF34d399);
  static const darkPrimary700 = Color(0xFF10b981);
  static const darkBackground = Color(0xFF0f172a);
  static const darkSurface = Color(0xFF1e293b);
  static const darkBorder = Color(0xFF334155);
  static const darkTextPrimary = Color(0xFFd1d5db);
  static const darkTextSecondary = Color(0xFF94a3b8);

  static const radiusXS = 2.0;
  static const radiusSM = 4.0;
  static const radiusMD = 8.0;
  static const radiusLG = 12.0;
  static const radiusXL = 16.0;
  static const radius2XL = 24.0;
  static const radiusFull = 999.0;

  static List<BoxShadow> shadowSM = [
    BoxShadow(
      color: Color.fromRGBO(0, 0, 0, 0.06),
      blurRadius: 3,
      offset: Offset(0, 1),
    ),
    BoxShadow(
      color: Color.fromRGBO(0, 0, 0, 0.04),
      blurRadius: 2,
      offset: Offset(0, 1),
    ),
  ];

  static List<BoxShadow> shadowMD = [
    BoxShadow(
      color: Color.fromRGBO(0, 0, 0, 0.04),
      blurRadius: 6,
      offset: Offset(0, 4),
    ),
    BoxShadow(
      color: Color.fromRGBO(0, 0, 0, 0.02),
      blurRadius: 4,
      offset: Offset(0, 2),
    ),
  ];

  static List<BoxShadow> shadowLG = [
    BoxShadow(
      color: Color.fromRGBO(0, 0, 0, 0.05),
      blurRadius: 15,
      offset: Offset(0, 10),
    ),
    BoxShadow(
      color: Color.fromRGBO(0, 0, 0, 0.02),
      blurRadius: 6,
      offset: Offset(0, 4),
    ),
  ];

  static List<BoxShadow> shadowXL = [
    BoxShadow(
      color: Color.fromRGBO(0, 0, 0, 0.06),
      blurRadius: 25,
      offset: Offset(0, 20),
    ),
    BoxShadow(
      color: Color.fromRGBO(0, 0, 0, 0.03),
      blurRadius: 10,
      offset: Offset(0, 10),
    ),
  ];

  static List<BoxShadow> shadowPrimary = [
    BoxShadow(
      color: Color.fromRGBO(16, 185, 129, 0.15),
      blurRadius: 12,
      offset: Offset(0, 2),
    ),
  ];

  static List<BoxShadow> shadowDarkPrimary = [
    BoxShadow(
      color: Color.fromRGBO(52, 211, 153, 0.2),
      blurRadius: 12,
      offset: Offset(0, 0),
    ),
  ];

  static const space1 = 2.0;
  static const space2 = 4.0;
  static const space3 = 6.0;
  static const space4 = 8.0;
  static const space5 = 10.0;
  static const space6 = 12.0;
  static const space8 = 16.0;
  static const space10 = 20.0;
  static const space12 = 24.0;
  static const space16 = 32.0;
  static const space20 = 40.0;
  static const space24 = 48.0;

  static const fontSizeDisplay = 28.0;
  static const fontSizeH1 = 24.0;
  static const fontSizeH2 = 20.0;
  static const fontSizeH3 = 18.0;
  static const fontSizeBody = 14.0;
  static const fontSizeSmall = 12.0;
  static const fontSizeCaption = 10.0;

  static const lineHeightDisplay = 36.0;
  static const lineHeightH1 = 32.0;
  static const lineHeightH2 = 28.0;
  static const lineHeightH3 = 24.0;
  static const lineHeightBody = 22.0;
  static const lineHeightSmall = 18.0;
  static const lineHeightCaption = 14.0;

  static const fontWeightRegular = FontWeight.w400;
  static const fontWeightMedium = FontWeight.w500;
  static const fontWeightSemiBold = FontWeight.w600;
  static const fontWeightBold = FontWeight.w700;

  static const gradientPrimary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary500, primary700],
    stops: [0.0, 1.0],
  );

  static const gradientNav = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [primary500, primary700],
    stops: [0.0, 1.0],
  );

  static const gradientAI = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFf0fdf4), primary50],
    stops: [0.0, 1.0],
  );

  static const gradientDarkPrimary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary700, Color(0xFF047857)],
    stops: [0.0, 1.0],
  );

  static const gradientDarkNav = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF065f46), Color(0xFF064e3b)],
    stops: [0.0, 1.0],
  );

  static const gradientDarkAI = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF064e3b), Color(0xFF065f46)],
    stops: [0.0, 1.0],
  );

  static const iconSizeSmall = 16.0;
  static const iconSizeStandard = 20.0;
  static const iconSizeNavigation = 24.0;
  static const iconSizeLarge = 32.0;
  static const iconSizeXL = 48.0;

  static const buttonHeightStandard = 40.0;
  static const buttonHeightSmall = 32.0;

  static const inputHeightStandard = 48.0;
  static const inputHeightSmall = 40.0;

  static const navBarWidthDesktop = 64.0;
  static const bottomNavHeightMobile = 64.0;
  static const topBarHeight = 48.0;

  static const noteListWidthDesktop = 280.0;
  static const noteListWidthDesktopMax = 400.0;

  static const noteListWidthTablet = 260.0;
  static const noteListWidthTabletMax = 400.0;

  static const breakpointMobile = 768.0;
  static const breakpointTablet = 1024.0;

  static const logoSizeDesktop = 36.0;
  static const logoSizeMobile = 48.0;

  static const aiButtonSize = 32.0;
  static const aiPanelWidthDesktop = 320.0;

  static const durationFast = Duration(milliseconds: 150);
  static const durationNormal = Duration(milliseconds: 300);
  static const durationSlow = Duration(milliseconds: 500);

  static const curveStandard = Curves.easeInOut;
  static const curveEnter = Curves.easeOut;
  static const curveExit = Curves.easeIn;
}
