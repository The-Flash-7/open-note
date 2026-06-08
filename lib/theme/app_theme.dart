// Copyright (c) 2026 litongshuai
// SPDX-License-Identifier: MIT OR Apache-2.0

import 'package:flutter/material.dart';
import 'design_tokens.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    fontFamily: 'NotoSansSC',
    colorScheme: AppColors.lightColorScheme,
    brightness: Brightness.light,

    appBarTheme: AppBarTheme(
      centerTitle: false,
      elevation: 0,
      backgroundColor: Colors.white,
      foregroundColor: DesignTokens.gray900,
      surfaceTintColor: Colors.white,
      shadowColor: DesignTokens.gray200,
      titleTextStyle: TextStyle(
        fontSize: DesignTokens.fontSizeH3,
        fontWeight: DesignTokens.fontWeightSemiBold,
        color: DesignTokens.gray900,
      ),
    ),

    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusLG),
        side: BorderSide.none,
      ),
      shadowColor: DesignTokens.gray200,
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: DesignTokens.primary500,
        foregroundColor: Colors.white,
        elevation: 0,
        shadowColor: DesignTokens.primary500.withValues(alpha: 0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusMD),
        ),
        minimumSize: Size(88, DesignTokens.buttonHeightStandard),
        padding: EdgeInsets.symmetric(
          horizontal: DesignTokens.space12,
          vertical: DesignTokens.space6,
        ),
        textStyle: TextStyle(
          fontSize: DesignTokens.fontSizeBody,
          fontWeight: DesignTokens.fontWeightSemiBold,
        ),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: DesignTokens.primary700,
        backgroundColor: DesignTokens.primary50,
        side: BorderSide(color: DesignTokens.primary200, width: 1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusMD),
        ),
        minimumSize: Size(88, DesignTokens.buttonHeightStandard),
        padding: EdgeInsets.symmetric(
          horizontal: DesignTokens.space12 - 1,
          vertical: DesignTokens.space6 - 1,
        ),
        textStyle: TextStyle(
          fontSize: DesignTokens.fontSizeBody,
          fontWeight: DesignTokens.fontWeightSemiBold,
        ),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: DesignTokens.primary500,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusMD),
        ),
        minimumSize: Size(48, DesignTokens.buttonHeightStandard),
        padding: EdgeInsets.symmetric(
          horizontal: DesignTokens.space6,
          vertical: DesignTokens.space4,
        ),
        textStyle: TextStyle(
          fontSize: DesignTokens.fontSizeBody,
          fontWeight: DesignTokens.fontWeightMedium,
        ),
      ),
    ),

    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: DesignTokens.gray500,
        backgroundColor: Colors.transparent,
        minimumSize: Size(40, 40),
        iconSize: DesignTokens.iconSizeStandard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusMD),
        ),
      ),
    ),

    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: DesignTokens.primary500,
      foregroundColor: Colors.white,
      elevation: 0,
      focusElevation: 0,
      hoverElevation: 0,
      highlightElevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusLG),
      ),
      sizeConstraints: BoxConstraints.tightFor(
        width: DesignTokens.aiButtonSize,
        height: DesignTokens.aiButtonSize,
      ),
      smallSizeConstraints: BoxConstraints.tightFor(width: 32, height: 32),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: DesignTokens.gray50,
      contentPadding: EdgeInsets.symmetric(
        horizontal: DesignTokens.space6,
        vertical: DesignTokens.space6 + 2,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusMD),
        borderSide: BorderSide(color: DesignTokens.gray200, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusMD),
        borderSide: BorderSide(color: DesignTokens.gray200, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusMD),
        borderSide: BorderSide(color: DesignTokens.primary500, width: 1),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusMD),
        borderSide: BorderSide(color: DesignTokens.error, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusMD),
        borderSide: BorderSide(color: DesignTokens.error, width: 2),
      ),
      hintStyle: TextStyle(
        fontSize: DesignTokens.fontSizeBody,
        fontWeight: DesignTokens.fontWeightRegular,
        color: DesignTokens.gray400,
      ),
      labelStyle: TextStyle(
        fontSize: DesignTokens.fontSizeBody,
        fontWeight: DesignTokens.fontWeightRegular,
        color: DesignTokens.gray500,
      ),
      errorStyle: TextStyle(
        fontSize: DesignTokens.fontSizeSmall,
        fontWeight: DesignTokens.fontWeightRegular,
        color: DesignTokens.error,
      ),
    ),

    textTheme: TextTheme(
      displayLarge: TextStyle(
        fontSize: DesignTokens.fontSizeDisplay,
        fontWeight: DesignTokens.fontWeightBold,
        color: DesignTokens.gray900,
        height: DesignTokens.lineHeightDisplay / DesignTokens.fontSizeDisplay,
      ),
      headlineLarge: TextStyle(
        fontSize: DesignTokens.fontSizeH1,
        fontWeight: DesignTokens.fontWeightSemiBold,
        color: DesignTokens.gray900,
        height: DesignTokens.lineHeightH1 / DesignTokens.fontSizeH1,
      ),
      headlineMedium: TextStyle(
        fontSize: DesignTokens.fontSizeH2,
        fontWeight: DesignTokens.fontWeightSemiBold,
        color: DesignTokens.gray900,
        height: DesignTokens.lineHeightH2 / DesignTokens.fontSizeH2,
      ),
      headlineSmall: TextStyle(
        fontSize: DesignTokens.fontSizeH3,
        fontWeight: DesignTokens.fontWeightSemiBold,
        color: DesignTokens.gray900,
        height: DesignTokens.lineHeightH3 / DesignTokens.fontSizeH3,
      ),
      bodyLarge: TextStyle(
        fontSize: DesignTokens.fontSizeBody,
        fontWeight: DesignTokens.fontWeightRegular,
        color: DesignTokens.gray700,
        height: DesignTokens.lineHeightBody / DesignTokens.fontSizeBody,
      ),
      bodyMedium: TextStyle(
        fontSize: DesignTokens.fontSizeBody,
        fontWeight: DesignTokens.fontWeightRegular,
        color: DesignTokens.gray700,
        height: DesignTokens.lineHeightBody / DesignTokens.fontSizeBody,
      ),
      bodySmall: TextStyle(
        fontSize: DesignTokens.fontSizeSmall,
        fontWeight: DesignTokens.fontWeightRegular,
        color: DesignTokens.gray500,
        height: DesignTokens.lineHeightSmall / DesignTokens.fontSizeSmall,
      ),
      labelLarge: TextStyle(
        fontSize: DesignTokens.fontSizeBody,
        fontWeight: DesignTokens.fontWeightMedium,
        color: DesignTokens.gray700,
      ),
      labelMedium: TextStyle(
        fontSize: DesignTokens.fontSizeSmall,
        fontWeight: DesignTokens.fontWeightMedium,
        color: DesignTokens.gray500,
      ),
      labelSmall: TextStyle(
        fontSize: DesignTokens.fontSizeCaption,
        fontWeight: DesignTokens.fontWeightRegular,
        color: DesignTokens.gray400,
        height: DesignTokens.lineHeightCaption / DesignTokens.fontSizeCaption,
      ),
    ),

    dividerTheme: DividerThemeData(
      color: DesignTokens.gray200,
      thickness: 1,
      space: DesignTokens.space8,
    ),

    chipTheme: ChipThemeData(
      backgroundColor: DesignTokens.primary100,
      selectedColor: DesignTokens.primary200,
      disabledColor: DesignTokens.gray100,
      color: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return DesignTokens.primary200;
        }
        return DesignTokens.primary100;
      }),
      labelStyle: TextStyle(
        fontSize: DesignTokens.fontSizeCaption,
        fontWeight: DesignTokens.fontWeightRegular,
        color: DesignTokens.primary700,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
      ),
      side: BorderSide.none,
      padding: EdgeInsets.symmetric(
        horizontal: DesignTokens.space4,
        vertical: DesignTokens.space1,
      ),
    ),

    snackBarTheme: SnackBarThemeData(
      backgroundColor: DesignTokens.primary200.withValues(alpha: 0.95),
      contentTextStyle: TextStyle(
        fontSize: DesignTokens.fontSizeBody,
        fontWeight: DesignTokens.fontWeightRegular,
        color: DesignTokens.gray50,
      ),
      behavior: SnackBarBehavior.floating,
      elevation: 0,
    ),

    expansionTileTheme: ExpansionTileThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusLG),
      ),
      expandedAlignment: Alignment.topLeft,
      childrenPadding: EdgeInsets.all(DesignTokens.space4),
    ),

    dialogTheme: DialogThemeData(
      backgroundColor: Colors.white,
      elevation: 0,
      shadowColor: DesignTokens.gray200,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusXL),
      ),
      titleTextStyle: TextStyle(
        fontSize: DesignTokens.fontSizeH3,
        fontWeight: DesignTokens.fontWeightSemiBold,
        color: DesignTokens.gray900,
      ),
      contentTextStyle: TextStyle(
        fontSize: DesignTokens.fontSizeBody,
        fontWeight: DesignTokens.fontWeightRegular,
        color: DesignTokens.gray500,
      ),
    ),

    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(DesignTokens.radius2XL),
        ),
      ),
      clipBehavior: Clip.antiAlias,
    ),

    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      elevation: 0,
      indicatorColor: DesignTokens.primary100,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return TextStyle(
            fontSize: DesignTokens.fontSizeCaption,
            fontWeight: DesignTokens.fontWeightMedium,
            color: DesignTokens.primary500,
          );
        }
        return TextStyle(
          fontSize: DesignTokens.fontSizeCaption,
          fontWeight: DesignTokens.fontWeightRegular,
          color: DesignTokens.gray500,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return IconThemeData(
            size: DesignTokens.iconSizeNavigation,
            color: DesignTokens.primary500,
          );
        }
        return IconThemeData(
          size: DesignTokens.iconSizeNavigation,
          color: DesignTokens.gray500,
        );
      }),
    ),

    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: Colors.white,
      elevation: 0,
      selectedIconTheme: IconThemeData(
        size: DesignTokens.iconSizeNavigation,
        color: DesignTokens.primary500,
      ),
      unselectedIconTheme: IconThemeData(
        size: DesignTokens.iconSizeNavigation,
        color: DesignTokens.gray500,
      ),
      selectedLabelTextStyle: TextStyle(
        fontSize: DesignTokens.fontSizeCaption,
        fontWeight: DesignTokens.fontWeightMedium,
        color: DesignTokens.primary500,
      ),
      unselectedLabelTextStyle: TextStyle(
        fontSize: DesignTokens.fontSizeCaption,
        fontWeight: DesignTokens.fontWeightRegular,
        color: DesignTokens.gray500,
      ),
      indicatorColor: DesignTokens.primary100,
    ),

    scaffoldBackgroundColor: DesignTokens.gray50,
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    fontFamily: 'NotoSansSC',
    colorScheme: AppColors.darkColorScheme,
    brightness: Brightness.dark,

    appBarTheme: AppBarTheme(
      centerTitle: false,
      elevation: 0,
      backgroundColor: DesignTokens.darkSurface,
      foregroundColor: DesignTokens.darkTextPrimary,
      surfaceTintColor: DesignTokens.darkSurface,
      shadowColor: DesignTokens.darkBorder,
      titleTextStyle: TextStyle(
        fontSize: DesignTokens.fontSizeH3,
        fontWeight: DesignTokens.fontWeightSemiBold,
        color: DesignTokens.darkTextPrimary,
      ),
    ),

    cardTheme: CardThemeData(
      color: DesignTokens.darkSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusLG),
        side: BorderSide.none,
      ),
      shadowColor: DesignTokens.darkBorder,
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: DesignTokens.darkPrimary500,
        foregroundColor: Colors.white,
        elevation: 0,
        shadowColor: DesignTokens.darkPrimary500.withValues(alpha: 0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusMD),
        ),
        minimumSize: Size(88, DesignTokens.buttonHeightStandard),
        padding: EdgeInsets.symmetric(
          horizontal: DesignTokens.space12,
          vertical: DesignTokens.space6,
        ),
        textStyle: TextStyle(
          fontSize: DesignTokens.fontSizeBody,
          fontWeight: DesignTokens.fontWeightSemiBold,
        ),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: DesignTokens.darkPrimary500,
        backgroundColor: DesignTokens.darkPrimary700.withValues(alpha: 0.2),
        side: BorderSide(
          color: DesignTokens.darkPrimary500.withValues(alpha: 0.5),
          width: 1,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusMD),
        ),
        minimumSize: Size(88, DesignTokens.buttonHeightStandard),
        padding: EdgeInsets.symmetric(
          horizontal: DesignTokens.space12 - 1,
          vertical: DesignTokens.space6 - 1,
        ),
        textStyle: TextStyle(
          fontSize: DesignTokens.fontSizeBody,
          fontWeight: DesignTokens.fontWeightSemiBold,
        ),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: DesignTokens.darkPrimary500,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusMD),
        ),
        minimumSize: Size(48, DesignTokens.buttonHeightStandard),
        padding: EdgeInsets.symmetric(
          horizontal: DesignTokens.space6,
          vertical: DesignTokens.space4,
        ),
        textStyle: TextStyle(
          fontSize: DesignTokens.fontSizeBody,
          fontWeight: DesignTokens.fontWeightMedium,
        ),
      ),
    ),

    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: DesignTokens.darkTextSecondary,
        backgroundColor: Colors.transparent,
        minimumSize: Size(40, 40),
        iconSize: DesignTokens.iconSizeStandard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusMD),
        ),
      ),
    ),

    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: DesignTokens.darkPrimary500,
      foregroundColor: Colors.white,
      elevation: 0,
      focusElevation: 0,
      hoverElevation: 0,
      highlightElevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusLG),
      ),
      sizeConstraints: BoxConstraints.tightFor(
        width: DesignTokens.aiButtonSize,
        height: DesignTokens.aiButtonSize,
      ),
      smallSizeConstraints: BoxConstraints.tightFor(width: 32, height: 32),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: DesignTokens.darkBackground,
      contentPadding: EdgeInsets.symmetric(
        horizontal: DesignTokens.space6,
        vertical: DesignTokens.space6 + 2,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusMD),
        borderSide: BorderSide(color: DesignTokens.darkBorder, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusMD),
        borderSide: BorderSide(color: DesignTokens.darkBorder, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusMD),
        borderSide: BorderSide(color: DesignTokens.darkPrimary500, width: 1),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusMD),
        borderSide: BorderSide(color: DesignTokens.error, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusMD),
        borderSide: BorderSide(color: DesignTokens.error, width: 2),
      ),
      hintStyle: TextStyle(
        fontSize: DesignTokens.fontSizeBody,
        fontWeight: DesignTokens.fontWeightRegular,
        color: DesignTokens.darkTextSecondary,
      ),
      labelStyle: TextStyle(
        fontSize: DesignTokens.fontSizeBody,
        fontWeight: DesignTokens.fontWeightRegular,
        color: DesignTokens.darkTextSecondary,
      ),
      errorStyle: TextStyle(
        fontSize: DesignTokens.fontSizeSmall,
        fontWeight: DesignTokens.fontWeightRegular,
        color: DesignTokens.error,
      ),
    ),

    textTheme: TextTheme(
      displayLarge: TextStyle(
        fontSize: DesignTokens.fontSizeDisplay,
        fontWeight: DesignTokens.fontWeightBold,
        color: DesignTokens.darkTextPrimary,
        height: DesignTokens.lineHeightDisplay / DesignTokens.fontSizeDisplay,
      ),
      headlineLarge: TextStyle(
        fontSize: DesignTokens.fontSizeH1,
        fontWeight: DesignTokens.fontWeightSemiBold,
        color: DesignTokens.darkTextPrimary,
        height: DesignTokens.lineHeightH1 / DesignTokens.fontSizeH1,
      ),
      headlineMedium: TextStyle(
        fontSize: DesignTokens.fontSizeH2,
        fontWeight: DesignTokens.fontWeightSemiBold,
        color: DesignTokens.darkTextPrimary,
        height: DesignTokens.lineHeightH2 / DesignTokens.fontSizeH2,
      ),
      headlineSmall: TextStyle(
        fontSize: DesignTokens.fontSizeH3,
        fontWeight: DesignTokens.fontWeightSemiBold,
        color: DesignTokens.darkTextPrimary,
        height: DesignTokens.lineHeightH3 / DesignTokens.fontSizeH3,
      ),
      bodyLarge: TextStyle(
        fontSize: DesignTokens.fontSizeBody,
        fontWeight: DesignTokens.fontWeightRegular,
        color: DesignTokens.darkTextPrimary,
        height: DesignTokens.lineHeightBody / DesignTokens.fontSizeBody,
      ),
      bodyMedium: TextStyle(
        fontSize: DesignTokens.fontSizeBody,
        fontWeight: DesignTokens.fontWeightRegular,
        color: DesignTokens.darkTextPrimary,
        height: DesignTokens.lineHeightBody / DesignTokens.fontSizeBody,
      ),
      bodySmall: TextStyle(
        fontSize: DesignTokens.fontSizeSmall,
        fontWeight: DesignTokens.fontWeightRegular,
        color: DesignTokens.darkTextSecondary,
        height: DesignTokens.lineHeightSmall / DesignTokens.fontSizeSmall,
      ),
      labelLarge: TextStyle(
        fontSize: DesignTokens.fontSizeBody,
        fontWeight: DesignTokens.fontWeightMedium,
        color: DesignTokens.darkTextPrimary,
      ),
      labelMedium: TextStyle(
        fontSize: DesignTokens.fontSizeSmall,
        fontWeight: DesignTokens.fontWeightMedium,
        color: DesignTokens.darkTextSecondary,
      ),
      labelSmall: TextStyle(
        fontSize: DesignTokens.fontSizeCaption,
        fontWeight: DesignTokens.fontWeightRegular,
        color: DesignTokens.darkTextSecondary,
        height: DesignTokens.lineHeightCaption / DesignTokens.fontSizeCaption,
      ),
    ),

    dividerTheme: DividerThemeData(
      color: DesignTokens.darkBorder,
      thickness: 1,
      space: DesignTokens.space8,
    ),

    chipTheme: ChipThemeData(
      backgroundColor: DesignTokens.darkPrimary700.withValues(alpha: 0.3),
      selectedColor: DesignTokens.darkPrimary700,
      disabledColor: DesignTokens.darkBackground,
      color: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return DesignTokens.darkPrimary700;
        }
        return DesignTokens.darkPrimary700.withValues(alpha: 0.3);
      }),
      labelStyle: TextStyle(
        fontSize: DesignTokens.fontSizeCaption,
        fontWeight: DesignTokens.fontWeightRegular,
        color: DesignTokens.darkPrimary500,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
      ),
      side: BorderSide.none,
      padding: EdgeInsets.symmetric(
        horizontal: DesignTokens.space4,
        vertical: DesignTokens.space1,
      ),
    ),

    snackBarTheme: SnackBarThemeData(
      backgroundColor: DesignTokens.darkPrimary700.withValues(alpha: 0.85),
      contentTextStyle: TextStyle(
        fontSize: DesignTokens.fontSizeBody,
        fontWeight: DesignTokens.fontWeightRegular,
        color: DesignTokens.darkTextPrimary,
      ),
      behavior: SnackBarBehavior.floating,
      elevation: 0,
    ),

    expansionTileTheme: ExpansionTileThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusLG),
      ),
      expandedAlignment: Alignment.topLeft,
      childrenPadding: EdgeInsets.all(DesignTokens.space4),
    ),

    dialogTheme: DialogThemeData(
      backgroundColor: DesignTokens.darkSurface,
      elevation: 0,
      shadowColor: DesignTokens.darkBorder,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusXL),
      ),
      titleTextStyle: TextStyle(
        fontSize: DesignTokens.fontSizeH3,
        fontWeight: DesignTokens.fontWeightSemiBold,
        color: DesignTokens.darkTextPrimary,
      ),
      contentTextStyle: TextStyle(
        fontSize: DesignTokens.fontSizeBody,
        fontWeight: DesignTokens.fontWeightRegular,
        color: DesignTokens.darkTextSecondary,
      ),
    ),

    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: DesignTokens.darkSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(DesignTokens.radius2XL),
        ),
      ),
      clipBehavior: Clip.antiAlias,
    ),

    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: DesignTokens.darkSurface,
      elevation: 0,
      indicatorColor: DesignTokens.darkPrimary700.withValues(alpha: 0.3),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return TextStyle(
            fontSize: DesignTokens.fontSizeCaption,
            fontWeight: DesignTokens.fontWeightMedium,
            color: DesignTokens.darkPrimary500,
          );
        }
        return TextStyle(
          fontSize: DesignTokens.fontSizeCaption,
          fontWeight: DesignTokens.fontWeightRegular,
          color: DesignTokens.darkTextSecondary,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return IconThemeData(
            size: DesignTokens.iconSizeNavigation,
            color: DesignTokens.darkPrimary500,
          );
        }
        return IconThemeData(
          size: DesignTokens.iconSizeNavigation,
          color: DesignTokens.darkTextSecondary,
        );
      }),
    ),

    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: DesignTokens.darkSurface,
      elevation: 0,
      selectedIconTheme: IconThemeData(
        size: DesignTokens.iconSizeNavigation,
        color: DesignTokens.darkPrimary500,
      ),
      unselectedIconTheme: IconThemeData(
        size: DesignTokens.iconSizeNavigation,
        color: DesignTokens.darkTextSecondary,
      ),
      selectedLabelTextStyle: TextStyle(
        fontSize: DesignTokens.fontSizeCaption,
        fontWeight: DesignTokens.fontWeightMedium,
        color: DesignTokens.darkPrimary500,
      ),
      unselectedLabelTextStyle: TextStyle(
        fontSize: DesignTokens.fontSizeCaption,
        fontWeight: DesignTokens.fontWeightRegular,
        color: DesignTokens.darkTextSecondary,
      ),
      indicatorColor: DesignTokens.darkPrimary700.withValues(alpha: 0.3),
    ),

    scaffoldBackgroundColor: DesignTokens.darkBackground,
  );
}
