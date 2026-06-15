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

      debugPrint('[UpdateService] 检查更新: $_releasesUrl');
      final response = await dio.get(_releasesUrl);
      debugPrint('[UpdateService] GitHub Releases HTTP ${response.statusCode}');
      if (response.statusCode != 200) return null;

      final releases = response.data as List<dynamic>;
      debugPrint('[UpdateService] 获取到 ${releases.length} 个 release');
      if (releases.isEmpty) return null;

      final appInfo = AppInfo.instance;
      final localVersion = appInfo.version;
      final assetExt = appInfo.downloadAssetExtension;
      final assetKeywords = appInfo.downloadAssetKeywords;
      debugPrint(
        '[UpdateService] 本地版本: $localVersion, 目标资源扩展名: $assetExt, 资源关键词: ${assetKeywords.join(',')}',
      );

      for (final release in releases) {
        final releaseMap = release as Map<String, dynamic>;
        final tagName = releaseMap['tag_name'] as String? ?? '';
        final isPrerelease = releaseMap['prerelease'] as bool? ?? false;
        final assets = (releaseMap['assets'] as List<dynamic>?) ?? [];
        debugPrint(
          '[UpdateService] 检查 release: tag=$tagName, prerelease=$isPrerelease, assets=${assets.length}',
        );

        if (isPrerelease) {
          debugPrint('[UpdateService] 跳过预发布版本: $tagName');
          continue;
        }

        for (final asset in assets) {
          final assetMap = asset as Map<String, dynamic>;
          debugPrint('[UpdateService] 资源: ${assetMap['name']}');
        }

        final releaseInfo = ReleaseInfo.fromJson(
          releaseMap,
          assetExt,
          assetKeywords: assetKeywords,
        );
        final newer = _isNewer(releaseInfo.version, localVersion);
        final skipped = await isVersionSkipped(releaseInfo.version);
        debugPrint(
          '[UpdateService] 远端版本: ${releaseInfo.version}, newer=$newer, skipped=$skipped, downloadUrl=${releaseInfo.downloadUrl}',
        );

        if (newer && !skipped) {
          debugPrint('[UpdateService] 发现可用更新: ${releaseInfo.version}');
          return releaseInfo;
        }
      }

      debugPrint('[UpdateService] 未发现可用更新');
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
    void Function(double progress, double speedMbps, int received, int total)?
    onProgress, {
    CancelToken? cancelToken,
  }) async {
    final dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(hours: 2),
        sendTimeout: const Duration(seconds: 60),
        validateStatus: (status) => status == 200 || status == 206,
        followRedirects: true,
      ),
    );

    final downloadsDir = await _getDownloadsDirectory();
    final assetExt = AppInfo.instance.downloadAssetExtension;
    final fileName = _extractFileName(release.downloadUrl, assetExt);
    final outputPath = '$downloadsDir/$fileName';
    debugPrint('[UpdateService] 下载更新文件: ${release.downloadUrl} -> $outputPath');

    int attempt = 0;
    Exception? lastError;

    while (attempt <= _maxRetries) {
      try {
        if (attempt > 0) {
          await Future.delayed(Duration(seconds: attempt * 3));
        }

        final startTime = DateTime.now();
        final response = await dio.download(
          release.downloadUrl,
          outputPath,
          cancelToken: cancelToken,
          onReceiveProgress: (received, total) {
            final progress = total > 0 ? received / total : 0.0;
            final elapsed = DateTime.now().difference(startTime).inSeconds;
            final speedMbps = elapsed > 0
                ? (received / elapsed / 1024 / 1024)
                : 0.0;
            onProgress?.call(progress, speedMbps, received, total);
          },
        );
        debugPrint(
          '[UpdateService] 下载响应: status=${response.statusCode}, content-type=${response.headers.value('content-type')}, content-length=${response.headers.value('content-length')}',
        );
        await _validateDownloadedInstaller(outputPath, assetExt);
        return outputPath;
      } catch (e) {
        if (e is DioException && CancelToken.isCancel(e)) {
          try {
            final file = File(outputPath);
            if (await file.exists()) await file.delete();
          } catch (_) {}
          rethrow;
        }
        lastError = e is Exception ? e : Exception(e.toString());
        attempt++;
      }
    }

    throw lastError ?? Exception('下载失败');
  }

  Future<void> _validateDownloadedInstaller(String filePath, String ext) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('下载文件不存在: $filePath');
    }

    final size = await file.length();
    debugPrint('[UpdateService] 下载文件大小: $size bytes, ext=$ext');
    const minInstallerSize = 1024 * 1024;
    if (size < minInstallerSize) {
      final bytes = await file
          .openRead(0, size < 512 ? size : 512)
          .fold<List<int>>(
            <int>[],
            (previous, element) => previous..addAll(element),
          );
      final preview = String.fromCharCodes(bytes).trimLeft().toLowerCase();
      if (preview.startsWith('<!doctype') ||
          preview.startsWith('<html') ||
          preview.startsWith('{') ||
          preview.startsWith('<?xml')) {
        throw Exception('下载内容不是有效安装包，可能是错误响应页面');
      }
      throw Exception('下载文件异常过小: ${(size / 1024).toStringAsFixed(1)} KB');
    }
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
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('安装包不存在: $filePath');
    }

    ProcessResult? result;
    if (Platform.isMacOS) {
      result = await Process.run('open', [filePath]);
    } else if (Platform.isWindows) {
      result = await Process.run(filePath, []);
    } else if (Platform.isLinux) {
      if (filePath.endsWith('.deb')) {
        result = await Process.run('xdg-open', [filePath]);
      } else {
        result = await Process.run('xdg-open', [filePath]);
      }
    }

    if (result != null) {
      debugPrint(
        '[UpdateService] 打开安装器结果: exitCode=${result.exitCode}, stderr=${result.stderr}',
      );
      if (result.exitCode != 0) {
        throw Exception('打开安装器失败: ${result.stderr}');
      }
    }
  }
}
