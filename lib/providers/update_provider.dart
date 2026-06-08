// Copyright (c) 2026 litongshuai
// SPDX-License-Identifier: MIT OR Apache-2.0

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
  bool _autoCheckUpdate = true;

  UpdateState get state => _state;
  ReleaseInfo? get latestRelease => _latestRelease;
  double get downloadProgress => _downloadProgress;
  double get downloadSpeed => _downloadSpeed;
  String? get errorMessage => _errorMessage;
  String? get downloadedFilePath => _downloadedFilePath;
  bool get autoCheckUpdate => _autoCheckUpdate;
  bool get isDownloading => _state == UpdateState.downloading;

  Future<void> init() async {
    _autoCheckUpdate = await _updateService.getAutoCheckUpdate();
    notifyListeners();
  }

  Future<void> checkForUpdate() async {
    _state = UpdateState.checking;
    _errorMessage = null;
    _latestRelease = null;
    notifyListeners();

    try {
      final release = await _updateService.checkForUpdate();
      if (release != null) {
        _latestRelease = release;
        _state = UpdateState.updateAvailable;
      } else {
        _state = UpdateState.noUpdate;
      }
    } catch (e) {
      _state = UpdateState.error;
      _errorMessage = '检查更新失败: ${e.toString()}';
    }
    notifyListeners();
  }

  Future<void> downloadUpdate() async {
    if (_latestRelease == null) return;

    _state = UpdateState.downloading;
    _downloadProgress = 0.0;
    _downloadSpeed = 0.0;
    _errorMessage = null;
    _downloadedFilePath = null;
    notifyListeners();

    try {
      final path = await _updateService.downloadUpdate(_latestRelease!, (
        progress,
        speed,
      ) {
        _downloadProgress = progress;
        _downloadSpeed = speed;
        notifyListeners();
      });
      _downloadedFilePath = path;
      _state = UpdateState.downloadComplete;
      notifyListeners();
      await _updateService.openInstaller(path);
    } catch (e) {
      _state = UpdateState.error;
      _errorMessage = '下载失败: ${e.toString()}';
      notifyListeners();
    }
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
