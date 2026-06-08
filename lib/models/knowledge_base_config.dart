// Copyright (c) 2026 litongshuai
// SPDX-License-Identifier: MIT OR Apache-2.0

enum EmbeddingModelVersion { fp16, q8, q4 }

enum DownloadStatus { notStarted, downloading, completed, failed }

class KnowledgeBaseConfig {
  final bool isEnabled;
  final EmbeddingModelVersion modelVersion;
  final String modelPath;
  final bool isModelDownloaded;
  final DownloadStatus downloadStatus;
  final double downloadProgress;
  final String? lastError;
  final int chunkSize;
  final int chunkOverlap;
  final int indexCacheSize;
  final double searchThreshold;
  final int indexedNotesCount;
  final int totalVectors;
  final DateTime? lastIndexedAt;

  static const String modelName = 'EmbeddingGemma-300M';
  static const int vectorDimensions = 3584;

  const KnowledgeBaseConfig({
    this.isEnabled = false,
    this.modelVersion = EmbeddingModelVersion.q8,
    this.modelPath = '',
    this.isModelDownloaded = false,
    this.downloadStatus = DownloadStatus.notStarted,
    this.downloadProgress = 0.0,
    this.lastError,
    this.chunkSize = 500,
    this.chunkOverlap = 50,
    this.indexCacheSize = 5000,
    this.searchThreshold = 0.5,
    this.indexedNotesCount = 0,
    this.totalVectors = 0,
    this.lastIndexedAt,
  });

  int get modelSizeMB {
    switch (modelVersion) {
      case EmbeddingModelVersion.fp16:
        return 617;
      case EmbeddingModelVersion.q8:
        return 309;
      case EmbeddingModelVersion.q4:
        return 197;
    }
  }

  String get modelSizeLabel {
    switch (modelVersion) {
      case EmbeddingModelVersion.fp16:
        return 'FP16 (~617MB)';
      case EmbeddingModelVersion.q8:
        return 'Q8 (~309MB)';
      case EmbeddingModelVersion.q4:
        return 'Q4 (~197MB)';
    }
  }

  String get modelFileName {
    switch (modelVersion) {
      case EmbeddingModelVersion.fp16:
        return 'model_fp16.onnx';
      case EmbeddingModelVersion.q8:
        return 'model_quantized.onnx';
      case EmbeddingModelVersion.q4:
        return 'model_q4.onnx';
    }
  }

  KnowledgeBaseConfig copyWith({
    bool? isEnabled,
    EmbeddingModelVersion? modelVersion,
    String? modelPath,
    bool? isModelDownloaded,
    DownloadStatus? downloadStatus,
    double? downloadProgress,
    String? lastError,
    int? chunkSize,
    int? chunkOverlap,
    int? indexCacheSize,
    double? searchThreshold,
    int? indexedNotesCount,
    int? totalVectors,
    DateTime? lastIndexedAt,
  }) {
    return KnowledgeBaseConfig(
      isEnabled: isEnabled ?? this.isEnabled,
      modelVersion: modelVersion ?? this.modelVersion,
      modelPath: modelPath ?? this.modelPath,
      isModelDownloaded: isModelDownloaded ?? this.isModelDownloaded,
      downloadStatus: downloadStatus ?? this.downloadStatus,
      downloadProgress: downloadProgress ?? this.downloadProgress,
      lastError: lastError ?? this.lastError,
      chunkSize: chunkSize ?? this.chunkSize,
      chunkOverlap: chunkOverlap ?? this.chunkOverlap,
      indexCacheSize: indexCacheSize ?? this.indexCacheSize,
      searchThreshold: searchThreshold ?? this.searchThreshold,
      indexedNotesCount: indexedNotesCount ?? this.indexedNotesCount,
      totalVectors: totalVectors ?? this.totalVectors,
      lastIndexedAt: lastIndexedAt ?? this.lastIndexedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'isEnabled': isEnabled,
      'modelVersion': modelVersion.name,
      'modelPath': modelPath,
      'isModelDownloaded': isModelDownloaded,
      'downloadStatus': downloadStatus.name,
      'downloadProgress': downloadProgress,
      'lastError': lastError,
      'chunkSize': chunkSize,
      'chunkOverlap': chunkOverlap,
      'indexCacheSize': indexCacheSize,
      'searchThreshold': searchThreshold,
      'indexedNotesCount': indexedNotesCount,
      'totalVectors': totalVectors,
      'lastIndexedAt': lastIndexedAt?.toIso8601String(),
    };
  }

  factory KnowledgeBaseConfig.fromMap(Map<String, dynamic> map) {
    return KnowledgeBaseConfig(
      isEnabled: map['isEnabled'] ?? false,
      modelVersion: _parseVersion(map['modelVersion']),
      modelPath: map['modelPath'] ?? '',
      isModelDownloaded: map['isModelDownloaded'] ?? false,
      downloadStatus: _parseDownloadStatus(map['downloadStatus']),
      downloadProgress: (map['downloadProgress'] ?? 0.0).toDouble(),
      lastError: map['lastError'],
      chunkSize: map['chunkSize'] ?? 500,
      chunkOverlap: map['chunkOverlap'] ?? 50,
      indexCacheSize: map['indexCacheSize'] ?? 5000,
      searchThreshold: (map['searchThreshold'] ?? 0.5).toDouble(),
      indexedNotesCount: map['indexedNotesCount'] ?? 0,
      totalVectors: map['totalVectors'] ?? 0,
      lastIndexedAt: map['lastIndexedAt'] != null
          ? DateTime.parse(map['lastIndexedAt'])
          : null,
    );
  }

  static EmbeddingModelVersion _parseVersion(dynamic v) {
    if (v == null) return EmbeddingModelVersion.q8;
    return EmbeddingModelVersion.values.firstWhere(
      (e) => e.name == v,
      orElse: () => EmbeddingModelVersion.q8,
    );
  }

  static DownloadStatus _parseDownloadStatus(dynamic v) {
    if (v == null) return DownloadStatus.notStarted;
    return DownloadStatus.values.firstWhere(
      (e) => e.name == v,
      orElse: () => DownloadStatus.notStarted,
    );
  }

  static const KnowledgeBaseConfig defaultConfig = KnowledgeBaseConfig();
}
