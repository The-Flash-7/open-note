// Copyright (c) 2026 litongshuai
// SPDX-License-Identifier: MIT OR Apache-2.0

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../services/update_service.dart';
import '../models/release_info.dart';

enum UpdateState {
  idle,
  checking,
  noUpdate,
  updateAvailable,
  downloading,
  downloadComplete,
  error,
}

class UpdateProvider extends ChangeNotifier {
  final UpdateService _updateService = UpdateService();

  UpdateState _state = UpdateState.idle;
  ReleaseInfo? _latestRelease;
  double _downloadProgress = 0.0;
  double _downloadSpeed = 0.0;
  String? _errorMessage;
  String? _downloadedFilePath;
  int _downloadedBytes = 0;
  int _downloadTotalBytes = 0;
  CancelToken? _downloadCancelToken;
  bool _autoCheckUpdate = true;
  int _notificationNonce = 0;

  UpdateState get state => _state;
  ReleaseInfo? get latestRelease => _latestRelease;
  double get downloadProgress => _downloadProgress;
  double get downloadSpeed => _downloadSpeed;
  String? get errorMessage => _errorMessage;
  String? get downloadedFilePath => _downloadedFilePath;
  int get downloadedBytes => _downloadedBytes;
  int get downloadTotalBytes => _downloadTotalBytes;
  bool get hasKnownDownloadSize => _downloadTotalBytes > 0;
  bool get autoCheckUpdate => _autoCheckUpdate;
  bool get isDownloading => _state == UpdateState.downloading;
  int get notificationNonce => _notificationNonce;

  Future<void> init() async {
    _autoCheckUpdate = await _updateService.getAutoCheckUpdate();
    notifyListeners();
  }

  Future<void> checkForUpdate() async {
    debugPrint('[UpdateProvider] 开始检查更新');
    _state = UpdateState.checking;
    _errorMessage = null;
    _latestRelease = null;
    notifyListeners();

    try {
      final release = await _updateService.checkForUpdate();
      if (release != null) {
        _latestRelease = release;
        _state = UpdateState.updateAvailable;
        _notificationNonce++;
        debugPrint('[UpdateProvider] 发现新版本: ${release.version}');
      } else {
        _state = UpdateState.noUpdate;
        debugPrint('[UpdateProvider] 当前已是最新版本');
      }
    } catch (e) {
      _state = UpdateState.error;
      _errorMessage = '检查更新失败: ${e.toString()}';
      debugPrint('[UpdateProvider] 检查更新异常: $e');
    }
    notifyListeners();
  }

  Future<void> downloadUpdate() async {
    if (_latestRelease == null) return;

    debugPrint('[UpdateProvider] 开始下载更新: ${_latestRelease!.downloadUrl}');
    _state = UpdateState.downloading;
    _downloadProgress = 0.0;
    _downloadSpeed = 0.0;
    _downloadedBytes = 0;
    _downloadTotalBytes = 0;
    _errorMessage = null;
    _downloadedFilePath = null;
    _downloadCancelToken = CancelToken();
    notifyListeners();

    try {
      final path = await _updateService.downloadUpdate(_latestRelease!, (
        progress,
        speed,
        received,
        total,
      ) {
        _downloadProgress = progress;
        _downloadSpeed = speed;
        _downloadedBytes = received;
        _downloadTotalBytes = total;
        notifyListeners();
      }, cancelToken: _downloadCancelToken);
      _downloadedFilePath = path;
      _state = UpdateState.downloadComplete;
      debugPrint('[UpdateProvider] 更新下载完成: $path');
      notifyListeners();
      await _updateService.openInstaller(path);
      debugPrint('[UpdateProvider] 已打开安装器: $path');
    } catch (e) {
      if (e is DioException && CancelToken.isCancel(e)) {
        _state = UpdateState.idle;
        _latestRelease = null;
        _errorMessage = '下载已取消';
        debugPrint('[UpdateProvider] 下载已取消');
      } else {
        _state = UpdateState.error;
        _errorMessage = '下载失败: ${e.toString()}';
        debugPrint('[UpdateProvider] 下载更新失败: $e');
      }
      notifyListeners();
    } finally {
      _downloadCancelToken = null;
    }
  }

  void cancelDownload() {
    _downloadCancelToken?.cancel('cancelled by user');
  }

  Future<void> skipVersion() async {
    if (_latestRelease != null) {
      await _updateService.skipVersion(_latestRelease!.version);
      _latestRelease = null;
      _state = UpdateState.idle;
      notifyListeners();
    }
  }

  Future<void> dismissUpdate() async {
    _latestRelease = null;
    _state = UpdateState.idle;
    notifyListeners();
  }

  Future<void> setAutoCheckUpdate(bool value) async {
    await _updateService.setAutoCheckUpdate(value);
    _autoCheckUpdate = value;
    notifyListeners();
  }

  Future<List<String>> getSkippedVersions() async {
    return await _updateService.getSkippedVersions();
  }

  Future<void> removeSkippedVersion(String version) async {
    await _updateService.removeSkippedVersion(version);
    notifyListeners();
  }

  void resetState() {
    if (_state != UpdateState.downloading) {
      _state = UpdateState.idle;
      _errorMessage = null;
      _latestRelease = null;
      notifyListeners();
    }
  }
}
