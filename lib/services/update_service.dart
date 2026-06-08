// Copyright (c) 2026 litongshuai
// SPDX-License-Identifier: MIT OR Apache-2.0

import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import '../models/release_info.dart';
import '../utils/app_info.dart';

class UpdateService {
  static const String _githubOwner = 'The-Flash-7';
  static const String _githubRepo = 'open-note';
  static const String _releasesUrl =
      'https://api.github.com/repos/$_githubOwner/$_githubRepo/releases';
  static const String _skippedVersionsKey = 'skipped_update_versions';
  static const String _autoUpdateKey = 'auto_check_update';

  static const int _maxRetries = 3;

  Future<ReleaseInfo?> checkForUpdate() async {
    try {
      final dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 30),
          headers: {'Accept': 'application/vnd.github.v3+json'},
        ),
      );

      final response = await dio.get(_releasesUrl);
      if (response.statusCode != 200) return null;

      final releases = response.data as List<dynamic>;
      if (releases.isEmpty) return null;

      final appInfo = AppInfo.instance;
      final localVersion = appInfo.version;
      final assetExt = appInfo.downloadAssetExtension;

      for (final release in releases) {
        final isPrerelease = release['prerelease'] as bool? ?? false;
        if (isPrerelease) continue;

        final releaseInfo = ReleaseInfo.fromJson(
          release as Map<String, dynamic>,
          assetExt,
        );
        if (_isNewer(releaseInfo.version, localVersion) &&
            !await isVersionSkipped(releaseInfo.version)) {
          return releaseInfo;
        }
      }

      return null;
    } catch (e) {
      debugPrint('检查更新失败: $e');
      return null;
    }
  }

  bool _isNewer(String remote, String local) {
    try {
      final remoteParts = remote.split('.').map(int.parse).toList();
      final localParts = local.split('.').map(int.parse).toList();

      for (int i = 0; i < 3; i++) {
        final r = i < remoteParts.length ? remoteParts[i] : 0;
        final l = i < localParts.length ? localParts[i] : 0;
        if (r > l) return true;
        if (r < l) return false;
      }
      return false;
    } catch (_) {
      return remote != local;
    }
  }

  Future<List<String>> getSkippedVersions() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_skippedVersionsKey) ?? [];
  }

  Future<bool> isVersionSkipped(String version) async {
    final skipped = await getSkippedVersions();
    return skipped.contains(version);
  }

  Future<void> skipVersion(String version) async {
    final prefs = await SharedPreferences.getInstance();
    final skipped = await getSkippedVersions();
    if (!skipped.contains(version)) {
      skipped.add(version);
      await prefs.setStringList(_skippedVersionsKey, skipped);
    }
  }

  Future<void> removeSkippedVersion(String version) async {
    final prefs = await SharedPreferences.getInstance();
    final skipped = await getSkippedVersions();
    skipped.remove(version);
    await prefs.setStringList(_skippedVersionsKey, skipped);
  }

  Future<bool> getAutoCheckUpdate() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_autoUpdateKey) ?? true;
  }

  Future<void> setAutoCheckUpdate(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoUpdateKey, value);
  }

  Future<String> downloadUpdate(
    ReleaseInfo release,
    void Function(double progress, double speedMbps)? onProgress,
  ) async {
    final dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(hours: 2),
        sendTimeout: const Duration(seconds: 60),
        validateStatus: (status) => status != null && status < 500,
      ),
    );

    final downloadsDir = await _getDownloadsDirectory();
    final assetExt = AppInfo.instance.downloadAssetExtension;
    final fileName = _extractFileName(release.downloadUrl, assetExt);
    final outputPath = '$downloadsDir/$fileName';

    int attempt = 0;
    Exception? lastError;

    while (attempt <= _maxRetries) {
      try {
        if (attempt > 0) {
          await Future.delayed(Duration(seconds: attempt * 3));
        }

        final startTime = DateTime.now();
        await dio.download(
          release.downloadUrl,
          outputPath,
          onReceiveProgress: (received, total) {
            if (total > 0) {
              final progress = received / total;
              final elapsed = DateTime.now().difference(startTime).inSeconds;
              final speedMbps = elapsed > 0
                  ? (received / elapsed / 1024 / 1024)
                  : 0.0;
              onProgress?.call(progress, speedMbps);
            }
          },
        );
        return outputPath;
      } catch (e) {
        lastError = e is Exception ? e : Exception(e.toString());
        attempt++;
      }
    }

    throw lastError ?? Exception('下载失败');
  }

  String _extractFileName(String url, String ext) {
    try {
      final uri = Uri.parse(url);
      final pathSegments = uri.pathSegments;
      if (pathSegments.isNotEmpty) {
        return pathSegments.last;
      }
    } catch (_) {}
    return 'OpenNote-update.$ext';
  }

  Future<String> _getDownloadsDirectory() async {
    try {
      final dir = await getDownloadsDirectory();
      if (dir != null) return dir.path;
    } catch (_) {}

    if (Platform.isMacOS || Platform.isLinux) {
      return '${Platform.environment['HOME']}/Downloads';
    } else if (Platform.isWindows) {
      return '${Platform.environment['USERPROFILE']}\\Downloads';
    }
    return '/tmp';
  }

  Future<void> openInstaller(String filePath) async {
    if (Platform.isMacOS) {
      await Process.run('open', [filePath]);
    } else if (Platform.isWindows) {
      await Process.run(filePath, []);
    } else if (Platform.isLinux) {
      if (filePath.endsWith('.deb')) {
        await Process.run('sudo', ['dpkg', '-i', filePath]);
      } else {
        await Process.run('xdg-open', [filePath]);
      }
    }
  }
}
