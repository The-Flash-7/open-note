// Copyright (c) 2026 litongshuai
// SPDX-License-Identifier: MIT OR Apache-2.0

/// Embedding service detailed status model
class EmbeddingServiceStatus {
  final EmbeddingServiceState state;
  final String message;
  final ServiceComponents components;
  final DateTime? startTime;
  final int? uptimeSeconds;
  final String? errorDetail;

  EmbeddingServiceStatus({
    required this.state,
    required this.message,
    required this.components,
    this.startTime,
    this.uptimeSeconds,
    this.errorDetail,
  });

  factory EmbeddingServiceStatus.fromJson(Map<String, dynamic> json) {
    return EmbeddingServiceStatus(
      state: _parseState(json['state'] as String? ?? ''),
      message: json['message'] as String? ?? '',
      components: ServiceComponents.fromJson(
        (json['components'] as Map<String, dynamic>?) ?? {},
      ),
      startTime: json['start_time'] != null
          ? DateTime.tryParse(json['start_time'] as String)
          : null,
      uptimeSeconds: json['uptime_seconds'] as int?,
      errorDetail: json['error_detail'] as String?,
    );
  }

  static EmbeddingServiceState _parseState(String state) {
    switch (state) {
      case 'starting':
        return EmbeddingServiceState.starting;
      case 'initializing_db':
        return EmbeddingServiceState.initializingDb;
      case 'loading_model':
        return EmbeddingServiceState.loadingModel;
      case 'ready':
        return EmbeddingServiceState.ready;
      case 'error_db_init':
        return EmbeddingServiceState.errorDbInit;
      case 'error_model_load':
        return EmbeddingServiceState.errorModelLoad;
      case 'error_general':
        return EmbeddingServiceState.errorGeneral;
      default:
        return EmbeddingServiceState.unreachable;
    }
  }

  bool get isReady => state == EmbeddingServiceState.ready;
  bool get isInitializing =>
      state == EmbeddingServiceState.starting ||
      state == EmbeddingServiceState.initializingDb ||
      state == EmbeddingServiceState.loadingModel;
  bool get hasError =>
      state == EmbeddingServiceState.errorDbInit ||
      state == EmbeddingServiceState.errorModelLoad ||
      state == EmbeddingServiceState.errorGeneral;
}

enum EmbeddingServiceState {
  starting,
  initializingDb,
  loadingModel,
  ready,
  errorDbInit,
  errorModelLoad,
  errorGeneral,
  unreachable;

  String get label {
    switch (this) {
      case EmbeddingServiceState.starting:
        return '服务刚启动';
      case EmbeddingServiceState.initializingDb:
        return '正在初始化数据库';
      case EmbeddingServiceState.loadingModel:
        return '正在加载 AI 模型';
      case EmbeddingServiceState.ready:
        return '服务已就绪';
      case EmbeddingServiceState.errorDbInit:
        return '数据库初始化失败';
      case EmbeddingServiceState.errorModelLoad:
        return '模型加载失败';
      case EmbeddingServiceState.errorGeneral:
        return '服务异常';
      case EmbeddingServiceState.unreachable:
        return '服务不可达';
    }
  }
}

enum ComponentStatus {
  pending,
  initializing,
  initialized,
  loading,
  loaded,
  failed,
  notConfigured;

  String get label {
    switch (this) {
      case ComponentStatus.pending:
        return '等待中';
      case ComponentStatus.initializing:
        return '初始化中';
      case ComponentStatus.initialized:
        return '已初始化';
      case ComponentStatus.loading:
        return '加载中';
      case ComponentStatus.loaded:
        return '已加载';
      case ComponentStatus.failed:
        return '失败';
      case ComponentStatus.notConfigured:
        return '未配置';
    }
  }
}

class ServiceComponents {
  final ComponentStatus chromaDb;
  final ComponentStatus embeddingModel;

  ServiceComponents({
    this.chromaDb = ComponentStatus.pending,
    this.embeddingModel = ComponentStatus.pending,
  });

  factory ServiceComponents.fromJson(Map<String, dynamic> json) {
    return ServiceComponents(
      chromaDb: _parseComponent(json['chroma_db'] as String?),
      embeddingModel: _parseComponent(json['embedding_model'] as String?),
    );
  }

  static ComponentStatus _parseComponent(String? value) {
    switch (value) {
      case 'initializing':
        return ComponentStatus.initializing;
      case 'initialized':
        return ComponentStatus.initialized;
      case 'loading':
        return ComponentStatus.loading;
      case 'loaded':
        return ComponentStatus.loaded;
      case 'failed':
        return ComponentStatus.failed;
      case 'not_configured':
        return ComponentStatus.notConfigured;
      default:
        return ComponentStatus.pending;
    }
  }
}
