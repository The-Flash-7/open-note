// Copyright (c) 2026 litongshuai
// SPDX-License-Identifier: MIT OR Apache-2.0

import 'dart:ffi';
import 'dart:io';
import 'package:package_info_plus/package_info_plus.dart';

class AppInfo {
  static AppInfo? _instance;
  PackageInfo? _packageInfo;

  String? _version;
  String? _buildNumber;
  String? _platform;
  String? _arch;

  static Future<AppInfo> init() async {
    final info = AppInfo();
    await info._load();
    _instance = info;
    return info;
  }

  static AppInfo get instance {
    if (_instance == null) {
      throw StateError('AppInfo 尚未初始化，请先调用 AppInfo.init()');
    }
    return _instance!;
  }

  Future<void> _load() async {
    _packageInfo = await PackageInfo.fromPlatform();
    _version = _packageInfo!.version;
    _buildNumber = _packageInfo!.buildNumber;
    _platform = _getPlatform();
    _arch = _getArchitecture();
  }

  String get version => _version ?? 'unknown';
  String get buildNumber => _buildNumber ?? '1';
  String get platform => _platform ?? 'unknown';
  String get arch => _arch ?? 'unknown';

  String get fullVersionString => 'v$version ($buildNumber)';
  String get platformArchString => '$platform $arch';

  String _getPlatform() {
    if (Platform.isMacOS) return 'macOS';
    if (Platform.isWindows) return 'Windows';
    if (Platform.isLinux) return 'Linux';
    return 'Unknown';
  }

  String _getArchitecture() {
    final abi = Abi.current().toString();
    if (abi.contains('arm64') || abi.contains('aarch64')) {
      return Platform.isMacOS ? 'Apple Silicon' : 'aarch64';
    }
    return 'x86_64';
  }

  String get downloadAssetExtension {
    if (Platform.isMacOS) return 'dmg';
    if (Platform.isWindows) return 'exe';
    if (Platform.isLinux) return 'deb';
    return 'dmg';
  }
}
