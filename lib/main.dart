// Copyright (c) 2026 litongshuai
// SPDX-License-Identifier: MIT OR Apache-2.0

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';

import 'services/python_service_manager.dart';
import 'widgets/splash_screen.dart';
import 'widgets/cli_install_dialog.dart';
import 'utils/global_search_handler.dart';
import 'utils/app_info.dart';
import 'l10n/strings.g.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await AppInfo.init();

  LocaleSettings.useDeviceLocale();

  await windowManager.ensureInitialized();

  WindowOptions windowOptions = WindowOptions(
    size: Size(1280, 900),
    minimumSize: Size(1024, 768),
    center: true,
    backgroundColor: Colors.white,
    titleBarStyle: Platform.isMacOS
        ? TitleBarStyle.hidden
        : TitleBarStyle.normal,
  );

  windowManager.waitUntilReadyToShow(windowOptions, () async {
    // 窗口显示由 SplashScreen 初始化完成后控制
  });

  // 注册 Ctrl+C (SIGINT) 信号处理
  ProcessSignal.sigint.watch().listen((_) {
    debugPrint('收到 Ctrl+C 信号，正在清理...');
    try {
      PythonServiceManager().stopSync();
      debugPrint('Python 服务已停止');
    } catch (e) {
      debugPrint('停止 Python 服务失败: $e');
    }
    exit(0);
  });

  runApp(TranslationProvider(child: const SplashApp()));

  // 注册 CLI 安装 MethodChannel（macOS 菜单栏触发）
  const MethodChannel('cli_installer').setMethodCallHandler((call) async {
    if (call.method == 'triggerInstallCLI') {
      final context = GlobalSearchHandler.navigatorKey.currentContext;
      if (context != null && context.mounted) {
        showDialog(context: context, builder: (_) => const CLIInstallDialog());
      }
    }
  });
}
