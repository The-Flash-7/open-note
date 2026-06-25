// Copyright (c) 2026 litongshuai
// SPDX-License-Identifier: MIT OR Apache-2.0

import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../models/knowledge_base_config.dart';
import '../models/note.dart';
import '../services/config_service.dart';
import '../services/embedding_model_downloader.dart';
import '../services/python_service_manager.dart';
import '../services/embedding_service_status.dart';
import '../providers/notes_provider.dart';
import '../config/knowledge_config.dart';
import '../l10n/strings.g.dart';

class KnowledgeBaseProvider extends ChangeNotifier {
  final ConfigService _configService = ConfigService();
  final PythonServiceManager _pythonService = PythonServiceManager();
  KnowledgeBaseConfig _config = KnowledgeBaseConfig.defaultConfig;
  bool _isDownloading = false;
  bool _isVerifying = false;
  bool _isPythonServiceRunning = false;

  // Translation reference (injected from UI)
  Translations? _t;

  void setTranslations(Translations t) {
    _t = t;
  }

  String _tr(String key, [String fallback = '']) {
    switch (key) {
      case 'serviceJustStarted':
        return _t?.kb_serviceJustStarted ?? fallback;
      case 'chromaDbInitializing':
        return _t?.kb_chromaDbInitializing ?? fallback;
      case 'loadingEmbeddingModel':
        return _t?.kb_loadingEmbeddingModel ?? fallback;
      case 'knowledgeBaseReady':
        return _t?.kb_knowledgeBaseReady ?? fallback;
      case 'chromaDbInitFailed':
        return _t?.kb_chromaDbInitFailed ?? fallback;
      case 'modelLoadFailed':
        return _t?.kb_modelLoadFailed ?? fallback;
      case 'serviceInitError':
        return _t?.kb_serviceInitError ?? fallback;
      case 'vectorServiceNotRunning':
        return _t?.kb_vectorServiceNotRunning ?? fallback;
      case 'serviceNotStarted':
        return _t?.kb_serviceNotStarted ?? fallback;
      case 'cannotFetchStatus':
        return _t?.kb_cannotFetchStatus ?? fallback;
      case 'serviceConnectionFailed':
        return _t?.kb_serviceConnectionFailed ?? fallback;
      case 'vectorServicePrepareFailed':
        return _t?.kb_vectorServicePrepareFailed ?? fallback;
      case 'vectorServicePrepareError':
        return _t?.kb_vectorServicePrepareError ?? fallback;
      case 'vectorServiceStartFailed':
        return _t?.kb_vectorServiceStartFailed ?? fallback;
      case 'vectorServiceError':
        return _t?.kb_vectorServiceError ?? fallback;
      case 'serviceAlreadyRunning':
        return _t?.kb_serviceAlreadyRunning ?? fallback;
      case 'serviceStarted':
        return _t?.kb_serviceStarted ?? fallback;
      case 'serviceStartFailedPython':
        return _t?.kb_serviceStartFailedPython ?? fallback;
      case 'directoryNotExist':
        return _t?.kb_directoryNotExist ?? fallback;
      case 'missingModelFile':
        return _t?.kb_missingModelFile ?? fallback;
      case 'missingTokenizer':
        return _t?.kb_missingTokenizer ?? fallback;
      case 'modelFileSizeAbnormal':
        return _t?.kb_modelFileSizeAbnormal ?? fallback;
      case 'knowledgeBaseNotReady':
        return _t?.kb_knowledgeBaseNotReady ?? fallback;
      case 'vectorServiceStartFailedIndex':
        return _t?.kb_vectorServiceStartFailedIndex ?? fallback;
      case 'healthCheckFailed':
        return _t?.kb_healthCheckFailed ?? fallback;
      default:
        return fallback;
    }
  }

  // Python 服务初始化状态
  bool _isPreparingService = false;
  bool _isStartingService = false;
  bool _isStoppingService = false;
  bool _isRestartingService = false;
  String? _serviceError;

  // Embedding 服务详细状态（从 /api/service/status 获取）
  EmbeddingServiceState _embeddingServiceState =
      EmbeddingServiceState.unreachable;
  String _embeddingServiceMessage = '';
  ServiceComponents _embeddingServiceComponents = ServiceComponents();
  String? _embeddingServiceErrorDetail;
  int? _embeddingServiceUptimeSeconds;
  bool _pollingActive = false;

  // Embedding 服务状态 getters
  EmbeddingServiceState get embeddingServiceState => _embeddingServiceState;
  String get embeddingServiceMessage => _embeddingServiceMessage;
  ServiceComponents get embeddingServiceComponents =>
      _embeddingServiceComponents;
  String? get embeddingServiceErrorDetail => _embeddingServiceErrorDetail;
  int? get embeddingServiceUptimeSeconds => _embeddingServiceUptimeSeconds;

  // Computed state getters
  bool get isEmbeddingServiceInitializing =>
      _embeddingServiceState == EmbeddingServiceState.starting ||
      _embeddingServiceState == EmbeddingServiceState.initializingDb ||
      _embeddingServiceState == EmbeddingServiceState.loadingModel;

  // Whether polling is still active (service started but not yet fully ready/errored)
  bool get isEmbeddingServicePolling => _pollingActive;

  // True ready = config enabled + service running + embedding service fully ready
  bool get isFullyReady =>
      _config.isEnabled &&
      _isPythonServiceRunning &&
      _embeddingServiceState == EmbeddingServiceState.ready;

  bool get hasEmbeddingServiceError =>
      _embeddingServiceState == EmbeddingServiceState.errorDbInit ||
      _embeddingServiceState == EmbeddingServiceState.errorModelLoad ||
      _embeddingServiceState == EmbeddingServiceState.errorGeneral;

String get embeddingServiceStatusDisplayText {
  switch (_embeddingServiceState) {
    case EmbeddingServiceState.starting:
      return _tr('serviceJustStarted', '服务刚启动，准备初始化...');
    case EmbeddingServiceState.initializingDb:
      return _tr('chromaDbInitializing', '正在初始化 ChromaDB 数据库...');
    case EmbeddingServiceState.loadingModel:
      return _tr('loadingEmbeddingModel', '正在加载 Embedding AI 模型...');
    case EmbeddingServiceState.ready:
      return _tr('knowledgeBaseReady', '知识库已就绪');
    case EmbeddingServiceState.basicReady:
      return _tr('basicServiceReady', '基础服务已就绪，知识库服务未启动');
    case EmbeddingServiceState.errorDbInit:
      return '${_tr('chromaDbInitFailed', 'ChromaDB 初始化失败')}: $_embeddingServiceErrorDetail';
    case EmbeddingServiceState.errorModelLoad:
      return '${_tr('modelLoadFailed', '嵌入模型加载失败')}: $_embeddingServiceErrorDetail';
    case EmbeddingServiceState.errorGeneral:
      return '${_tr('serviceInitError', '服务初始化异常')}: $_embeddingServiceErrorDetail';
    case EmbeddingServiceState.unreachable:
      return _tr('vectorServiceNotRunning', '向量服务未运行');
  }
}

  Future<bool> _refreshPythonServiceRunning() async {
    final running = await _pythonService.refreshRunningState();
    _isPythonServiceRunning = running;
    return running;
  }

  bool _applyPortOccupiedErrorIfNeeded() {
    final result = _pythonService.lastServiceCheckResult;
    if (result?.isPortOccupiedByOtherService != true) return false;

    final port = result?.port ?? 8765;
    final pid = result?.pid?.toString() ?? _tr('unknown', '未知');
    _embeddingServiceState = EmbeddingServiceState.errorGeneral;
    _embeddingServiceMessage =
        _t?.kb_portOccupied(port: port) ?? '端口 $port 已被其他程序占用';
    _embeddingServiceErrorDetail =
        _t?.kb_portOccupiedDetail(pid: pid) ?? '请关闭占用该端口的程序后重试。进程 PID：$pid';
    return true;
  }

  // 状态轮询
  Future<void> refreshEmbeddingServiceStatus() async {
    final running = await _refreshPythonServiceRunning();
    if (!running) {
      if (!_applyPortOccupiedErrorIfNeeded()) {
        _embeddingServiceState = EmbeddingServiceState.unreachable;
        _embeddingServiceMessage = _tr('serviceNotStarted', '服务未启动');
      }
      notifyListeners();
      return;
    }

    try {
      final status = await _pythonService.fetchServiceStatus();
      if (status != null) {
        _embeddingServiceState = status.state;
        _embeddingServiceMessage = status.message;
        _embeddingServiceComponents = status.components;
        _embeddingServiceErrorDetail = status.errorDetail;
        _embeddingServiceUptimeSeconds = status.uptimeSeconds;
        if (status.state == EmbeddingServiceState.ready) {
          _serviceError = null;
        }
      } else {
        _embeddingServiceState = EmbeddingServiceState.unreachable;
        _embeddingServiceMessage = _tr('cannotFetchStatus', '无法获取服务状态');
      }
    } catch (e) {
      _embeddingServiceState = EmbeddingServiceState.unreachable;
      _embeddingServiceMessage = _tr('serviceConnectionFailed', '服务连接失败');
    }
    notifyListeners();
  }

  Future<void> startEmbeddingServiceStatusPolling() async {
    if (_pollingActive) return;
    _pollingActive = true;
    _pollingLoop();
  }

Future<void> _pollingLoop() async {
  while (_pollingActive && isEnabled) {
    await refreshEmbeddingServiceStatus();

    if (_embeddingServiceState == EmbeddingServiceState.ready ||
        _embeddingServiceState == EmbeddingServiceState.basicReady ||
        hasEmbeddingServiceError) {
      _pollingActive = false;
      notifyListeners();
      return;
    }

    await Future.delayed(const Duration(milliseconds: 500));
  }
}

  void stopEmbeddingServiceStatusPolling() {
    _pollingActive = false;
    _embeddingServiceState = EmbeddingServiceState.unreachable;
    _embeddingServiceMessage = '';
    _embeddingServiceComponents = ServiceComponents();
    _embeddingServiceErrorDetail = null;
    _embeddingServiceUptimeSeconds = null;
    notifyListeners();
  }

  // 重建索引进度跟踪
  bool _isRebuildingIndex = false;
  int _rebuildProgress = 0;
  int _rebuildTotal = 0;
  int _rebuildSuccessCount = 0;
  int _rebuildFailedCount = 0;
  final List<RebuildError> _rebuildErrors = [];

  KnowledgeBaseConfig get config => _config;
  bool get isEnabled => _config.isEnabled;
  bool get isModelDownloaded => _config.isModelDownloaded;
  bool get isReady => _config.isEnabled && _config.isModelDownloaded;
  double get downloadProgress => _config.downloadProgress;
  DownloadStatus get downloadStatus => _config.downloadStatus;
  bool get isVerifying => _isVerifying;
  bool get isPythonServiceRunning => _isPythonServiceRunning;

  // 初始化状态 getters
  bool get isPreparingService => _isPreparingService;
  bool get isStartingService => _isStartingService;
  bool get isStoppingService => _isStoppingService;
  bool get isRestartingService => _isRestartingService;
  bool get isServiceInitializing =>
      _isPreparingService || _isStartingService || _isStoppingService;
  String? get serviceError => _serviceError;

  Future<void> loadConfig() async {
    _config = await _configService.loadKnowledgeBaseConfig();

    // 同步到全局配置
    await KnowledgeConfig.instance.setSearchThreshold(_config.searchThreshold);
    await KnowledgeConfig.instance.setChunkSize(_config.chunkSize);
    await KnowledgeConfig.instance.setChunkOverlap(_config.chunkOverlap);
    await KnowledgeConfig.instance.setIndexCacheSize(_config.indexCacheSize);

    // 检查模型文件是否存在（SHA256 校验延迟到 startPythonService 中执行）
    if (_config.modelPath.isNotEmpty) {
      final exists = await EmbeddingModelDownloader.isModelExists(
        _config.modelVersion,
      );

      final modelDir = await EmbeddingModelDownloader.getDefaultModelPath(
        _config.modelVersion,
      );
      _config = _config.copyWith(
        isModelDownloaded: exists,
        modelPath: modelDir,
        lastError: null,
      );
      await _configService.setModelDownloaded(exists);
      await _configService.setModelPath(modelDir);
      await _configService.setLastError(null);
    }

    notifyListeners();
  }

  Future<void> toggleEnabled(bool enabled) async {
    await _configService.setKnowledgeBaseEnabled(enabled);
    _config = _config.copyWith(isEnabled: enabled);
    final running = await _refreshPythonServiceRunning();
    notifyListeners();

    if (enabled && isReady && running) {
      debugPrint('知识库已启用，启动知识库服务...');
      
      // 开启知识库：调用 /api/knowledge-base/start
      final appDir = await getApplicationSupportDirectory();
      final chromaDataDir = '${appDir.path}/chroma_db';
      
      final success = await _pythonService.startKnowledgeBase(
        modelDir: _config.modelPath,
        dataDir: chromaDataDir,
      );
      
      if (success) {
        debugPrint('KnowledgeBase: 知识库服务已启动');
        startEmbeddingServiceStatusPolling();
      } else {
        _serviceError = '知识库服务启动失败';
        debugPrint('KnowledgeBase: 知识库服务启动失败');
      }
    } else if (!enabled) {
      debugPrint('知识库已关闭，停止知识库服务...');
      stopEmbeddingServiceStatusPolling();
      
      if (running) {
        // 关闭知识库：调用 /api/knowledge-base/stop
        final success = await _pythonService.stopKnowledgeBase();
        if (success) {
          debugPrint('KnowledgeBase: 知识库服务已停止');
        } else {
          debugPrint('KnowledgeBase: 知识库服务停止失败');
        }
      }
    }
  }

  Future<void> selectModelVersion(
    EmbeddingModelVersion version, {
    NotesProvider? notesProvider,
  }) async {
    // 检查文件是否存在，存在则进行 SHA256 校验
    final exists = await EmbeddingModelDownloader.isModelExists(version);
    final isIntact = exists
        ? await EmbeddingModelDownloader.verifyModelIntegrity(version)
        : false;

    final modelDir = await EmbeddingModelDownloader.getDefaultModelPath(
      version,
    );

    if (isIntact) {
      final running = await _refreshPythonServiceRunning();
      // ★ 检查是否真的需要切换模型（路径相同则无需操作）
      final isSameModel =
          _config.isEnabled && running && _config.modelPath == modelDir;

      // 更新配置并持久化
      await _configService.setModelVersion(version);
      _config = _config.copyWith(
        modelVersion: version,
        isModelDownloaded: true,
        modelPath: modelDir,
        lastError: null,
      );
      await _configService.setModelPath(modelDir);
      await _configService.setModelDownloaded(true);
      await _configService.setLastError(null);

      if (_config.isEnabled) {
        if (!running) {
          // 服务未启动 → 启动向量服务
          debugPrint('知识库已启用但服务未运行，启动向量服务...');
          await startPythonService(modelPath: modelDir);
        } else if (!isSameModel) {
          // 服务已启动且模型不同 → 热切换模型
          debugPrint('服务正在运行，热切换模型...');
          final success = await _pythonService.switchModel(modelDir);
          if (success && notesProvider != null) {
            // 模型切换成功，清空并重建索引（复用用户点击重建索引的逻辑）
            debugPrint('模型切换成功，清空并重建索引...');
            await clearIndex(notesProvider);
            await rebuildIndex(notesProvider);
          } else if (!success) {
            _config = _config.copyWith(lastError: '模型切换失败');
            debugPrint('EmbeddingService: 模型切换失败');
          }
        }
        // else: 服务已运行且模型相同 → 无需任何操作
      }
    } else {
      // 模型未下载：只更新 UI 显示（临时），不持久化
      // 下次打开设置时会读取持久化的值（旧版本），自动回退
      // ★ 不更新 modelPath，保持为当前实际加载的模型路径，以便 isSameModel 判断正确
      _config = _config.copyWith(
        modelVersion: version,
        isModelDownloaded: false,
        lastError: '模型未下载，请先下载',
      );
    }

    notifyListeners();
  }

  Future<void> selectLocalModelPath() async {
    final result = await FilePicker.platform.getDirectoryPath();
    if (result == null) return;

    final validationResult = await _validateModelPath(result);
    if (!validationResult.isValid) {
      _config = _config.copyWith(
        modelPath: result,
        isModelDownloaded: false,
        lastError: validationResult.error,
      );
    } else {
      _config = _config.copyWith(
        modelPath: result,
        isModelDownloaded: true,
        lastError: null,
      );
    }
    await _configService.setModelPath(result);
    await _configService.setModelDownloaded(validationResult.isValid);
    notifyListeners();
  }

  Future<void> downloadModel({
    required EmbeddingModelVersion version,
    void Function(double progress, double speedMbps)? onProgress,
  }) async {
    if (_isDownloading) return;

    _isDownloading = true;

    // 立即清除错误状态并通知 UI
    _config = _config.copyWith(
      downloadStatus: DownloadStatus.downloading,
      downloadProgress: 0.0,
      lastError: null,
      modelVersion: version,
    );
    notifyListeners();

    // 异步持久化
    await _configService.setModelVersion(version);
    await _configService.setDownloadStatus(DownloadStatus.downloading);
    await _configService.setDownloadProgress(0.0);
    await _configService.setLastError(null);

    final modelDir = await EmbeddingModelDownloader.getDefaultModelPath(
      version,
    );
    _config = _config.copyWith(modelPath: modelDir);

    try {
      await EmbeddingModelDownloader.download(
        version: version,
        outputDir: modelDir,
        onProgress: (progress, speed) {
          _config = _config.copyWith(
            downloadProgress: progress,
            downloadStatus: DownloadStatus.downloading,
          );
          _configService.setDownloadProgress(progress);
          onProgress?.call(progress, speed);
          notifyListeners();
        },
      );

      // 下载完成（100%），开始校验
      _config = _config.copyWith(downloadProgress: 1.0);
      _isVerifying = true;
      notifyListeners();

      // 校验完成
      _isVerifying = false;
      _config = _config.copyWith(
        isModelDownloaded: true,
        downloadStatus: DownloadStatus.completed,
        downloadProgress: 1.0,
        lastError: null,
        modelPath: modelDir,
      );
      await _configService.setModelDownloaded(true);
      await _configService.setDownloadStatus(DownloadStatus.completed);
      await _configService.setModelPath(modelDir);
      await _configService.setLastError(null);
    } catch (e) {
      _isVerifying = false;
      _config = _config.copyWith(
        isModelDownloaded: false,
        downloadStatus: DownloadStatus.failed,
        lastError: e.toString(),
      );
      await _configService.setModelDownloaded(false);
      await _configService.setDownloadStatus(DownloadStatus.failed);
      await _configService.setLastError(e.toString());
    } finally {
      _isDownloading = false;
      notifyListeners();
    }
  }

  Future<ValidationResult> _validateModelPath(String path) async {
    final dir = Directory(path);
    if (!await dir.exists()) {
      return ValidationResult(
        isValid: false,
        error: _tr('directoryNotExist', '目录不存在'),
      );
    }

    final modelFile = File('$path/model.onnx');
    final tokenizerFile = File('$path/tokenizer.json');

    if (!await modelFile.exists()) {
      return ValidationResult(
        isValid: false,
        error: _tr('missingModelFile', '缺少模型文件: model.onnx'),
      );
    }
    if (!await tokenizerFile.exists()) {
      return ValidationResult(
        isValid: false,
        error: _tr('missingTokenizer', '缺少 tokenizer.json'),
      );
    }

    final fileSize = await modelFile.length();
    final expectedMinSize = _config.modelSizeMB * 1024 * 1024 * 0.8;
    if (fileSize < expectedMinSize) {
      return ValidationResult(
        isValid: false,
        error:
            '${_tr('modelFileSizeAbnormal', '模型文件大小异常')} (期望 ~${_config.modelSizeMB}MB, 实际 ${(fileSize / 1024 / 1024).toStringAsFixed(1)}MB)',
      );
    }

    return ValidationResult(isValid: true);
  }

  Future<void> clearIndex(NotesProvider? notesProvider) async {
    // 清空向量数据库中的所有向量
    if (notesProvider != null) {
      await notesProvider.vectorStore.clearAll();
    }

    _config = _config.copyWith(
      indexedNotesCount: 0,
      totalVectors: 0,
      lastIndexedAt: null,
    );
    await _configService.updateIndexStats(
      indexedNotesCount: 0,
      totalVectors: 0,
      lastIndexedAt: null,
    );
    notifyListeners();
  }

  Future<void> updateIndexStats({
    int? indexedNotesCount,
    int? totalVectors,
  }) async {
    _config = _config.copyWith(
      indexedNotesCount: indexedNotesCount,
      totalVectors: totalVectors,
    );
    notifyListeners();
  }

  Future<void> refreshIndexStats(NotesProvider notesProvider) async {
    try {
      final stats = await notesProvider.vectorStore.getStats();
      _config = _config.copyWith(
        indexedNotesCount: stats.uniqueNotes,
        totalVectors: stats.totalEntries,
        lastIndexedAt: _config.lastIndexedAt ?? DateTime.now(),
      );
      await _configService.updateIndexStats(
        indexedNotesCount: stats.uniqueNotes,
        totalVectors: stats.totalEntries,
        lastIndexedAt: _config.lastIndexedAt,
      );
      debugPrint(
        'KnowledgeBase: 索引统计已同步 - 笔记: ${stats.uniqueNotes}, 向量: ${stats.totalEntries}',
      );
      notifyListeners();
    } catch (e) {
      debugPrint('KnowledgeBase: 刷新索引统计失败: $e');
    }
  }

  Future<void> updateChunkSize(int size, [NotesProvider? notesProvider]) async {
    await _configService.updateChunkSize(size);
    _config = _config.copyWith(chunkSize: size);
    notesProvider?.setChunkConfig(size, _config.chunkOverlap);
    await KnowledgeConfig.instance.setChunkSize(size);
    notifyListeners();
  }

  Future<void> updateChunkOverlap(
    int overlap, [
    NotesProvider? notesProvider,
  ]) async {
    await _configService.updateChunkOverlap(overlap);
    _config = _config.copyWith(chunkOverlap: overlap);
    notesProvider?.setChunkConfig(_config.chunkSize, overlap);
    await KnowledgeConfig.instance.setChunkOverlap(overlap);
    notifyListeners();
  }

  Future<void> updateIndexCacheSize(int size) async {
    await _configService.updateIndexCacheSize(size);
    _config = _config.copyWith(indexCacheSize: size);
    await KnowledgeConfig.instance.setIndexCacheSize(size);
    notifyListeners();
  }

  Future<void> updateSearchThreshold(double threshold) async {
    await _configService.updateSearchThreshold(threshold);
    _config = _config.copyWith(searchThreshold: threshold);
    await KnowledgeConfig.instance.setSearchThreshold(threshold);
    notifyListeners();
  }

  Future<bool> preparePythonService({
    void Function(String status, double progress)? onProgress,
  }) async {
    _isPreparingService = true;
    _serviceError = null;
    notifyListeners();

    try {
      final success = await _pythonService.prepareService(
        onProgress: onProgress,
      );
      if (!success) {
        _serviceError = _tr('vectorServicePrepareFailed', '向量服务准备失败');
      }
      return success;
    } catch (e) {
      _serviceError = '${_tr('vectorServicePrepareError', '向量服务准备异常')}: $e';
      rethrow;
    } finally {
      _isPreparingService = false;
      notifyListeners();
    }
  }

  Future<bool> startPythonService({
    required String modelPath,
    void Function(bool success, String message)? onResult,
  }) async {
    final running = await _refreshPythonServiceRunning();
    if (running) {
      onResult?.call(true, _tr('serviceAlreadyRunning', '服务已在运行'));
      return true;
    }

    _isStartingService = true;
    _serviceError = null;
    notifyListeners();

    try {
      final success = await _pythonService.start(
        modelDir: modelPath,
        timeout: const Duration(seconds: 30),
      );

      _isPythonServiceRunning = success;

      if (success) {
        debugPrint('KnowledgeBase: Python 服务已启动 (${_pythonService.baseUrl})');
        startEmbeddingServiceStatusPolling();
        onResult?.call(true, _tr('serviceStarted', '服务已启动'));
      } else {
        final portOccupied = _applyPortOccupiedErrorIfNeeded();
        _serviceError = portOccupied
            ? _embeddingServiceMessage
            : _tr('vectorServiceStartFailed', '向量服务启动失败，请检查模型配置');
        debugPrint('KnowledgeBase: Python 服务启动失败');
        onResult?.call(
          false,
          portOccupied
              ? _embeddingServiceMessage
              : _tr('serviceStartFailedPython', '服务启动失败，请检查 Python 环境和依赖'),
        );
      }

      return success;
    } catch (e) {
      _serviceError = '${_tr('vectorServiceError', '向量服务异常')}: $e';
      rethrow;
    } finally {
      _isStartingService = false;
      notifyListeners();
    }
  }

  Future<bool> startPythonServiceBasic({
    bool kbEnabled = false,
    NotesProvider? notesProvider,
  }) async {
    final running = await _refreshPythonServiceRunning();
    if (running) {
      debugPrint('KnowledgeBase: Python 服务已在运行，跳过启动');
      
      // 如果知识库已开启，调用 /api/knowledge-base/start
      if (kbEnabled && _config.modelPath.isNotEmpty) {
        final appDir = await getApplicationSupportDirectory();
        final chromaDataDir = '${appDir.path}/chroma_db';
        
        final kbSuccess = await _pythonService.startKnowledgeBase(
          modelDir: _config.modelPath,
          dataDir: chromaDataDir,
        );
        
        if (kbSuccess) {
          startEmbeddingServiceStatusPolling();
          if (notesProvider != null) {
            notesProvider.setKnowledgeBaseModelPath(
              _config.modelPath,
              serviceUrl: _pythonService.baseUrl,
            );
            notesProvider.setChunkConfig(_config.chunkSize, _config.chunkOverlap);
            debugPrint('KnowledgeBase: 知识库服务已配置到 NotesProvider');
          }
        }
      }
      return true;
    }

    _isStartingService = true;
    _serviceError = null;
    notifyListeners();

    try {
      debugPrint('KnowledgeBase: 正在启动基础服务（不加载模型）...');
      
      final success = await _pythonService.start(
        timeout: const Duration(seconds: 30),
        kbEnabled: false,  // 不传递 kbEnabled，基础服务不初始化
      );

      _isPythonServiceRunning = success;

      if (success) {
        debugPrint('KnowledgeBase: Python 基础服务已启动 (${_pythonService.baseUrl})');
        
        // 如果知识库已开启，调用 /api/knowledge-base/start
        if (kbEnabled && _config.modelPath.isNotEmpty) {
          final appDir = await getApplicationSupportDirectory();
          final chromaDataDir = '${appDir.path}/chroma_db';
          
          final kbSuccess = await _pythonService.startKnowledgeBase(
            modelDir: _config.modelPath,
            dataDir: chromaDataDir,
          );
          
          if (kbSuccess) {
            startEmbeddingServiceStatusPolling();
            if (notesProvider != null) {
              notesProvider.setKnowledgeBaseModelPath(
                _config.modelPath,
                serviceUrl: _pythonService.baseUrl,
              );
              notesProvider.setChunkConfig(_config.chunkSize, _config.chunkOverlap);
              debugPrint('KnowledgeBase: 知识库服务已配置到 NotesProvider');
            }
          } else {
            debugPrint('KnowledgeBase: 知识库服务启动失败');
          }
        }
      } else {
        final portOccupied = _applyPortOccupiedErrorIfNeeded();
        _serviceError = portOccupied
            ? _embeddingServiceMessage
            : _tr('vectorServiceStartFailed', '向量服务启动失败');
        debugPrint('KnowledgeBase: Python 基础服务启动失败');
      }

      return success;
    } catch (e) {
      _serviceError = '${_tr('vectorServiceError', '向量服务异常')}: $e';
      debugPrint('KnowledgeBase: 基础服务启动异常: $e');
      return false;
    } finally {
      _isStartingService = false;
      notifyListeners();
    }
  }

  Future<void> rebuildIndex(NotesProvider notesProvider) async {
    if (!isReady) {
      throw Exception(_tr('knowledgeBaseNotReady', '知识库未就绪，请先下载模型并启用知识库'));
    }

    // 初始化进度状态
    _isRebuildingIndex = true;
    _rebuildProgress = 0;
    _rebuildSuccessCount = 0;
    _rebuildFailedCount = 0;
    _rebuildErrors.clear();
    notifyListeners();

    try {
      // 确保 Python 服务已启动
      final running = await _refreshPythonServiceRunning();
      if (!running) {
        debugPrint('KnowledgeBase: Python 服务未运行，正在启动...');
        final serviceStarted = await _pythonService.start(
          modelDir: _config.modelPath,
          timeout: const Duration(seconds: 30),
        );

        if (!serviceStarted) {
          throw Exception(
            _tr('vectorServiceStartFailedIndex', '向量服务启动失败，无法进行索引'),
          );
        }
        _isPythonServiceRunning = true;
        debugPrint('KnowledgeBase: Python 服务已启动');
      }

      // 等待服务就绪
      final healthStatus = await _pythonService.getEmbeddingStatus();
      if (healthStatus == null) {
        throw Exception(_tr('healthCheckFailed', '向量服务健康检查失败，服务可能未正常启动'));
      }
      debugPrint('KnowledgeBase: Python 服务健康检查通过');

      final vectorStore = notesProvider.vectorStore;

      // 使用 NoteService 获取全部笔记，而非过滤后的列表
      final allNotes = await _getAllNotes(notesProvider);
      _rebuildTotal = allNotes.length;
      notifyListeners();

      debugPrint('KnowledgeBase: 开始重建索引，共 ${allNotes.length} 条笔记');

      // 清空旧索引
      await clearIndex(notesProvider);

      for (int i = 0; i < allNotes.length; i++) {
        final note = allNotes[i];
        try {
          await vectorStore.indexNote(
            note,
            chunkSize: _config.chunkSize,
            chunkOverlap: _config.chunkOverlap,
          );
          _rebuildSuccessCount++;
          debugPrint(
            'KnowledgeBase: 索引成功 [${i + 1}/${allNotes.length}] ${note.title}',
          );
        } catch (e) {
          _rebuildFailedCount++;
          _rebuildErrors.add(
            RebuildError(
              noteTitle: note.title.isNotEmpty ? note.title : '无标题笔记',
              error: e.toString(),
            ),
          );
          debugPrint(
            'KnowledgeBase: 索引失败 [${i + 1}/${allNotes.length}] ${note.title}: $e',
          );
        }

        _rebuildProgress = i + 1;
        notifyListeners();
      }

      final finalStats = await vectorStore.getStats();
      _config = _config.copyWith(
        indexedNotesCount: _rebuildSuccessCount,
        totalVectors: finalStats.totalEntries,
        lastIndexedAt: DateTime.now(),
      );
      await _configService.updateIndexStats(
        indexedNotesCount: _rebuildSuccessCount,
        totalVectors: finalStats.totalEntries,
        lastIndexedAt: _config.lastIndexedAt,
      );

      debugPrint(
        'KnowledgeBase: 重建索引完成: 成功 $_rebuildSuccessCount 条, 失败 $_rebuildFailedCount 条',
      );
    } catch (e) {
      debugPrint('KnowledgeBase: 重建索引异常: $e');
      _rebuildFailedCount++; // 系统级错误也计入失败数
      _rebuildErrors.add(RebuildError(noteTitle: '系统错误', error: e.toString()));
    } finally {
      _isRebuildingIndex = false;
      notifyListeners();
    }
  }

  /// 获取全部笔记（非过滤列表）
  Future<List<Note>> _getAllNotes(NotesProvider notesProvider) async {
    // 使用 allPreviews 获取全部笔记预览，然后按需加载完整内容
    final allPreviews = notesProvider.allPreviews;
    final notes = <Note>[];
    for (final preview in allPreviews) {
      final fullNote = await notesProvider.getFullNote(preview.id);
      if (fullNote != null) {
        notes.add(fullNote);
      }
    }
    return notes;
  }

  Future<void> stopPythonService() async {
    _isStoppingService = true;
    notifyListeners();

    try {
      stopEmbeddingServiceStatusPolling();
      await _pythonService.stop();
      _isPythonServiceRunning = await _pythonService.refreshRunningState();
      debugPrint('KnowledgeBase: Python 服务已停止');
    } finally {
      _isStoppingService = false;
      notifyListeners();
    }
  }

  /// 同步停止 Python 服务（用于 dispose）
  void stopPythonServiceSync() {
    debugPrint(
      'KnowledgeBase.stopPythonServiceSync: _isPythonServiceRunning=$_isPythonServiceRunning',
    );

    _isStoppingService = true;
    stopEmbeddingServiceStatusPolling();
    _pythonService.stopSync();
    _isPythonServiceRunning = false;
    _isStoppingService = false;
    debugPrint('KnowledgeBase: Python 服务已停止（同步）');
  }

  /// 智能重启/启动向量服务
  /// - 如果服务未启动 → 直接启动
  /// - 如果服务已启动但报错 → 调用 Python 服务的 /api/service/restart 接口
  Future<void> restartPythonService() async {
    if (!_config.isEnabled || _config.modelPath.isEmpty) return;

    // 设置重启中状态（UI 显示 loading）
    _isRestartingService = true;
    _embeddingServiceErrorDetail = null;
    notifyListeners();

    try {
      bool success;

      final running = await _refreshPythonServiceRunning();
      if (!running) {
        // 服务未启动 → 直接启动
        debugPrint('KnowledgeBase: 向量服务未运行，正在启动...');
        success = await startPythonService(modelPath: _config.modelPath);
      } else {
        // 服务已启动但可能处于错误状态 → 调用内部重启接口
        debugPrint('KnowledgeBase: 向量服务正在运行，请求内部重启...');
        success = await _pythonService.restartService();

        if (success) {
          // 重启成功后刷新状态
          await refreshEmbeddingServiceStatus();
        }
      }

      if (!success) {
        _embeddingServiceState = EmbeddingServiceState.errorGeneral;
        _embeddingServiceMessage = _tr('serviceStartupFailed', '服务启动失败');
      }
    } catch (e) {
      _embeddingServiceState = EmbeddingServiceState.errorGeneral;
      _embeddingServiceMessage =
          '${_tr('serviceConnectionFailed', '服务连接失败')}: $e';
    } finally {
      _isRestartingService = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    stopPythonServiceSync();
    super.dispose();
  }

  String get pythonServiceUrl => _pythonService.baseUrl;

  // 重建索引进度跟踪 getters
  bool get isRebuildingIndex => _isRebuildingIndex;
  int get rebuildProgress => _rebuildProgress;
  int get rebuildTotal => _rebuildTotal;
  int get rebuildSuccessCount => _rebuildSuccessCount;
  int get rebuildFailedCount => _rebuildFailedCount;
  List<RebuildError> get rebuildErrors => List.unmodifiable(_rebuildErrors);
}

class ValidationResult {
  final bool isValid;
  final String? error;

  ValidationResult({required this.isValid, this.error});
}

class RebuildError {
  final String noteTitle;
  final String error;

  RebuildError({required this.noteTitle, required this.error});

  @override
  String toString() => '$noteTitle: $error';
}
