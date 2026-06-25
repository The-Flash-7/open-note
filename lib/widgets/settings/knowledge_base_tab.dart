// Copyright (c) 2026 litongshuai
// SPDX-License-Identifier: MIT OR Apache-2.0

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/strings.g.dart';
import '../../models/knowledge_base_config.dart';
import '../../providers/knowledge_base_provider.dart';
import '../../providers/notes_provider.dart';
import '../../theme/design_tokens.dart';
import '../../utils/snackbar_helper.dart';
import '../../services/embedding_service_status.dart';

class KnowledgeBaseTab extends StatefulWidget {
  const KnowledgeBaseTab({super.key});

  @override
  State<KnowledgeBaseTab> createState() => _KnowledgeBaseTabState();
}

class _KnowledgeBaseTabState extends State<KnowledgeBaseTab>
    with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _modelCardKey = GlobalKey();
  final GlobalKey _toggleCardKey = GlobalKey();
  final GlobalKey _statsCardKey = GlobalKey();
  late AnimationController _highlightController;

  bool _showErrorDetails = false;

  @override
  void initState() {
    super.initState();
    _highlightController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    // 页面打开时同步索引统计
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncIndexStats();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 注入 Translations 到 Provider（必须在 initState 之后调用）
    final t = Translations.of(context);
    context.read<KnowledgeBaseProvider>().setTranslations(t);
  }

  Future<void> _syncIndexStats() async {
    if (!mounted) return;
    final kbProvider = context.read<KnowledgeBaseProvider>();
    final notesProvider = context.read<NotesProvider>();

    if (kbProvider.isEnabled) {
      await kbProvider.refreshEmbeddingServiceStatus();
      if (!mounted) return;
    }

    if (kbProvider.isFullyReady) {
      await kbProvider.refreshIndexStats(notesProvider);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _highlightController.dispose();
    super.dispose();
  }

  void _scrollToModelCardAndHighlight() {
    final context = _modelCardKey.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );

      _highlightController.forward(from: 0.0);
      Future.delayed(const Duration(milliseconds: 2000), () {
        if (mounted) {
          _highlightController.reverse();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<KnowledgeBaseProvider>(
      builder: (context, kbProvider, _) {
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatusCard(context, kbProvider, isDark),
              const SizedBox(height: 16),
              _buildToggleCard(context, kbProvider, isDark),
              const SizedBox(height: 16),
              _buildModelCard(context, kbProvider, isDark),
              const SizedBox(height: 16),
              _buildIndexSettingsCard(context, kbProvider, isDark),
              const SizedBox(height: 16),
              _buildIndexStatsCard(context, kbProvider, isDark),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusCard(
    BuildContext context,
    KnowledgeBaseProvider provider,
    bool isDark,
  ) {
    // True readiness = config enabled + model downloaded + service running + fully ready
    final isFullyReady = provider.isFullyReady;

    // Case 0: Knowledge base disabled - show "not enabled" prompt immediately
    if (!provider.isEnabled) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark
              ? DesignTokens.darkErrorBackground.withValues(alpha: 0.3)
              : DesignTokens.errorBackground,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              Icons.info_outline,
              color: DesignTokens.error,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.kb_knowledgeBaseNotEnabled,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? DesignTokens.darkTextPrimary
                          : DesignTokens.gray900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    t.kb_enableKnowledgeBaseVectorization,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark
                          ? DesignTokens.darkTextSecondary
                          : DesignTokens.gray500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Case 0.5: Knowledge base enabled but service is basicReady - show "service not started"
    if (provider.isEnabled &&
        provider.embeddingServiceState == EmbeddingServiceState.basicReady &&
        !provider.isServiceInitializing) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark
              ? DesignTokens.darkErrorBackground.withValues(alpha: 0.3)
              : DesignTokens.errorBackground,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              Icons.warning_amber_outlined,
              color: DesignTokens.warning500,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '知识库服务未启动',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? DesignTokens.darkTextPrimary
                          : DesignTokens.gray900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '请开启知识库或重启服务',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark
                          ? DesignTokens.darkTextSecondary
                          : DesignTokens.gray500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Case 1: Service is preparing, starting or stopping
    if (provider.isServiceInitializing) {
      final statusText = provider.isPreparingService
          ? t.kb_preparingService
          : provider.isStoppingService
          ? t.kb_stoppingService
          : t.kb_startingService;
      return _buildInitializingCard(isDark, statusText, statusText, null);
    }

    // Case 2: Python service is running but polling hasn't gotten first result yet
    // This is the transition state between "starting" and "initializingDb/ready"
    if (provider.isPythonServiceRunning &&
        provider.embeddingServiceState == EmbeddingServiceState.unreachable &&
        !provider.isEmbeddingServiceInitializing) {
      return _buildInitializingCard(
        isDark,
        t.kb_startingService,
        t.kb_startingService,
        null,
      );
    }

    // Case 3: Embedding service is initializing (polling got a response, still loading)
    if (provider.isEmbeddingServiceInitializing) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark
              ? DesignTokens.primary500.withValues(alpha: 0.1)
              : DesignTokens.primary500.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    provider.embeddingServiceState ==
                            EmbeddingServiceState.initializingDb
                        ? t.kb_startingService
                        : provider.embeddingServiceState ==
                              EmbeddingServiceState.loadingModel
                        ? t.kb_localModelLoaded
                        : t.kb_startingService,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? DesignTokens.darkTextPrimary
                          : DesignTokens.gray900,
                    ),
                  ),
                  if (provider.embeddingServiceMessage.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      provider.embeddingServiceMessage,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark
                            ? DesignTokens.darkTextSecondary
                            : DesignTokens.gray500,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  _buildComponentStatus(
                    isDark,
                    'ChromaDB',
                    provider.embeddingServiceComponents.chromaDb,
                  ),
                  _buildComponentStatus(
                    isDark,
                    t.kb_embeddingModel,
                    provider.embeddingServiceComponents.embeddingModel,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Case 4: Error state
    if (provider.hasEmbeddingServiceError && !isFullyReady) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark
              ? DesignTokens.darkErrorBackground.withValues(alpha: 0.3)
              : DesignTokens.errorBackground,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.error_outline,
                  color: DesignTokens.error500,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    provider.embeddingServiceMessage.isEmpty
                        ? t.kb_rebuildFailedHealthCheck
                        : provider.embeddingServiceMessage,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? DesignTokens.darkTextPrimary
                          : DesignTokens.gray900,
                    ),
                  ),
                ),
                IconButton(
                  icon: provider.isRestartingService
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh, size: 20),
                  onPressed: provider.isRestartingService
                      ? null
                      : () => provider.restartPythonService(),
                  tooltip: t.common_retry,
                ),
              ],
            ),
            if (provider.embeddingServiceErrorDetail != null) ...[
              const SizedBox(height: 8),
              Text(
                provider.embeddingServiceErrorDetail!,
                style: TextStyle(fontSize: 13, color: DesignTokens.error500),
              ),
            ],
            const SizedBox(height: 8),
            _buildComponentStatus(
              isDark,
              'ChromaDB',
              provider.embeddingServiceComponents.chromaDb,
            ),
            _buildComponentStatus(
              isDark,
              t.kb_embeddingModel,
              provider.embeddingServiceComponents.embeddingModel,
            ),
          ],
        ),
      );
    }

    // Case 5: Fully ready or disabled
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isFullyReady
            ? (isDark
                  ? DesignTokens.darkSuccessBackground.withValues(alpha: 0.3)
                  : DesignTokens.successBackground)
            : (isDark
                  ? DesignTokens.darkErrorBackground.withValues(alpha: 0.3)
                  : DesignTokens.errorBackground),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            isFullyReady ? Icons.check_circle_outline : Icons.info_outline,
            color: isFullyReady ? DesignTokens.success : DesignTokens.error,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isFullyReady
                      ? t.kb_knowledgeBaseReady
                      : t.kb_knowledgeBaseNotEnabled,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? DesignTokens.darkTextPrimary
                        : DesignTokens.gray900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isFullyReady
                      ? provider.embeddingServiceStatusDisplayText
                      : t.kb_enableKnowledgeBaseVectorization,
                  style: TextStyle(
                    fontSize: 13,
                    color: isFullyReady
                        ? DesignTokens.success500
                        : (isDark
                              ? DesignTokens.darkTextSecondary
                              : DesignTokens.gray500),
                  ),
                ),
                if (isFullyReady &&
                    provider.embeddingServiceUptimeSeconds != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${t.kb_serviceRunning}: ${_formatUptime(provider.embeddingServiceUptimeSeconds!)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? DesignTokens.darkTextSecondary
                          : DesignTokens.gray500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInitializingCard(
    bool isDark,
    String title,
    String subtitle,
    VoidCallback? onRetry,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? DesignTokens.primary500.withValues(alpha: 0.1)
            : DesignTokens.primary500.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? DesignTokens.darkTextPrimary
                        : DesignTokens.gray900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark
                        ? DesignTokens.darkTextSecondary
                        : DesignTokens.gray500,
                  ),
                ),
              ],
            ),
          ),
          if (onRetry != null) ...[
            IconButton(
              icon: const Icon(Icons.refresh, size: 20),
              onPressed: onRetry,
              tooltip: t.common_retry,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildComponentStatus(
    bool isDark,
    String name,
    ComponentStatus status,
  ) {
    final color = _componentStatusColor(status);
    final icon = _componentStatusIcon(status);
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            '$name: ${status.label}',
            style: TextStyle(
              fontSize: 12,
              color: isDark
                  ? DesignTokens.darkTextSecondary
                  : DesignTokens.gray500,
            ),
          ),
        ],
      ),
    );
  }

  Color _componentStatusColor(ComponentStatus status) {
    switch (status) {
      case ComponentStatus.initialized:
      case ComponentStatus.loaded:
        return DesignTokens.success;
      case ComponentStatus.initializing:
      case ComponentStatus.loading:
        return DesignTokens.primary500;
      case ComponentStatus.failed:
        return DesignTokens.error500;
      case ComponentStatus.notConfigured:
        return DesignTokens.warning500;
      default:
        return DesignTokens.gray400;
    }
  }

  IconData _componentStatusIcon(ComponentStatus status) {
    switch (status) {
      case ComponentStatus.initialized:
      case ComponentStatus.loaded:
        return Icons.check_circle;
      case ComponentStatus.initializing:
      case ComponentStatus.loading:
        return Icons.hourglass_empty;
      case ComponentStatus.failed:
        return Icons.error;
      case ComponentStatus.notConfigured:
        return Icons.info;
      default:
        return Icons.circle;
    }
  }

  String _formatUptime(int seconds) {
    final minutes = (seconds / 60).ceil();
    if (minutes < 60) return '$minutes分钟';
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    return '$hours小时${mins > 0 ? '$mins分钟' : ''}';
  }

  Widget _buildToggleCard(
    BuildContext context,
    KnowledgeBaseProvider provider,
    bool isDark,
  ) {
    return _SectionCard(
      key: _toggleCardKey,
      title: t.kb_enableToggle,
      isDark: isDark,
      child: SwitchListTile(
        title: Text(t.kb_enableKnowledgeBase),
        subtitle: Text(
          t.kb_autoVectorIndexing,
          style: TextStyle(
            fontSize: 12,
            color: isDark
                ? DesignTokens.darkTextSecondary
                : DesignTokens.gray500,
          ),
        ),
        value: provider.isEnabled,
        onChanged: (value) {
          if (value && !provider.isModelDownloaded) {
            _scrollToModelCardAndHighlight();
          } else {
            provider.toggleEnabled(value);
          }
        },
        activeThumbColor: DesignTokens.primary500,
      ),
    );
  }

  Widget _buildModelCard(
    BuildContext context,
    KnowledgeBaseProvider provider,
    bool isDark,
  ) {
    final config = provider.config;
    return AnimatedBuilder(
      animation: _highlightController,
      builder: (context, child) {
        final highlight = _highlightController.value;
        return _SectionCard(
          key: _modelCardKey,
          title: t.kb_embeddingModel,
          isDark: isDark,
          highlightBorder: highlight,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildModelInfoRow(
                t.kb_model,
                KnowledgeBaseConfig.modelName,
                isDark,
              ),
              _buildModelInfoRow(
                t.kb_vectorDimensions,
                '${KnowledgeBaseConfig.vectorDimensions}',
                isDark,
              ),
              const SizedBox(height: 12),
              _buildModelInfoRow(t.kb_downloadSource, t.kb_modelscope, isDark),
              const SizedBox(height: 12),
              Text(
                t.kb_modelVersion,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              RadioGroup<EmbeddingModelVersion>(
                groupValue: config.modelVersion,
                onChanged: (v) {
                  if (v != null) {
                    final notesProvider = context.read<NotesProvider>();
                    provider.selectModelVersion(
                      v,
                      notesProvider: notesProvider,
                    );
                  }
                },
                child: Column(
                  children: EmbeddingModelVersion.values
                      .map(
                        (version) => RadioListTile<EmbeddingModelVersion>(
                          title: Text(version.name.toUpperCase()),
                          subtitle: Text(
                            version == EmbeddingModelVersion.fp16
                                ? '~617MB · ${t.kb_highestPrecision}'
                                : version == EmbeddingModelVersion.q8
                                ? '~309MB · ${t.kb_balancedRecommended}'
                                : '~197MB · ${t.kb_lightweightMode}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          value: version,
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(height: 12),
              _buildModelInfoRow(
                t.kb_status,
                config.isModelDownloaded ? t.kb_downloaded : t.kb_notDownloaded,
                isDark,
                valueColor: config.isModelDownloaded
                    ? DesignTokens.success500
                    : DesignTokens.error500,
              ),
              _buildModelInfoRow(
                t.kb_path,
                config.modelPath.isNotEmpty ? config.modelPath : '-',
                isDark,
              ),
              if (config.lastError != null &&
                  provider.downloadStatus == DownloadStatus.failed) ...[
                const SizedBox(height: 8),
                Text(
                  '${'错误'}: ${config.lastError}',
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              ],
              const SizedBox(height: 12),
              // 下载进度条（条件显示）
              if (provider.downloadStatus == DownloadStatus.downloading) ...[
                LinearProgressIndicator(
                  value: config.downloadProgress,
                  backgroundColor: isDark
                      ? DesignTokens.darkBorder
                      : DesignTokens.gray200,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    DesignTokens.primary500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  provider.isVerifying
                      ? t.kb_verifyingFile
                      : t.kb_downloading(
                          progress: (config.downloadProgress * 100)
                              .toStringAsFixed(1),
                        ),
                  style: TextStyle(
                    fontSize: 12,
                    color: DesignTokens.primary500,
                  ),
                ),
                const SizedBox(height: 8),
              ],
              // 警告语（常驻显示）
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark
                      ? DesignTokens.warning500.withValues(alpha: 0.1)
                      : DesignTokens.warning500.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDark
                        ? DesignTokens.warning500.withValues(alpha: 0.3)
                        : DesignTokens.warning500.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: DesignTokens.warning500,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        t.kb_switchModelWarning,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? DesignTokens.darkTextSecondary
                              : DesignTokens.gray500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed:
                        config.isModelDownloaded ||
                            provider.downloadStatus ==
                                DownloadStatus.downloading
                        ? null
                        : () => provider.downloadModel(
                            version: config.modelVersion,
                          ),
                    icon: const Icon(Icons.download, size: 18),
                    label: Text(t.kb_downloadModel),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: DesignTokens.primary500,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () => provider.selectLocalModelPath(),
                    icon: const Icon(Icons.folder_open, size: 18),
                    label: Text(t.kb_selectLocalPath),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildIndexSettingsCard(
    BuildContext context,
    KnowledgeBaseProvider provider,
    bool isDark,
  ) {
    final config = provider.config;
    return _SectionCard(
      title: t.kb_indexSettings,
      isDark: isDark,
      child: Column(
        children: [
          _buildSliderRow(
            t.kb_chunkSize,
            config.chunkSize,
            100,
            1000,
            'tokens',
            (v) {
              final notesProvider = context.read<NotesProvider>();
              provider.updateChunkSize(v.toInt(), notesProvider);
            },
            isDark,
          ),
          const SizedBox(height: 12),
          _buildSliderRow(
            t.kb_chunkOverlap,
            config.chunkOverlap,
            0,
            200,
            'tokens',
            (v) {
              final notesProvider = context.read<NotesProvider>();
              provider.updateChunkOverlap(v.toInt(), notesProvider);
            },
            isDark,
          ),
          const SizedBox(height: 12),
          _buildSliderRow(
            t.kb_cacheSize,
            config.indexCacheSize,
            1000,
            20000,
            '条',
            (v) => provider.updateIndexCacheSize(v.toInt()),
            isDark,
          ),
          // const SizedBox(height: 12),
          // _buildDoubleSliderRow('搜索阈值', config.searchThreshold, 0.1, 0.9, (v) {
          //   provider.updateSearchThreshold(v);
          // }, isDark),
        ],
      ),
    );
  }

  Widget _buildIndexStatsCard(
    BuildContext context,
    KnowledgeBaseProvider provider,
    bool isDark,
  ) {
    final config = provider.config;
    return Consumer<NotesProvider>(
      builder: (context, notesProvider, _) {
        final totalNotes = notesProvider.allPreviews.length;

        // UI 优先原则：知识库未启用 → 显示"知识库未启用"
        if (!provider.isEnabled) {
          return _SectionCard(
            key: _statsCardKey,
            title: t.kb_indexStats,
            isDark: isDark,
            child: Text(
              t.kb_knowledgeBaseNotEnabledPrompt,
              style: TextStyle(
                fontSize: 13,
                color: isDark
                    ? DesignTokens.darkTextSecondary
                    : DesignTokens.gray500,
              ),
            ),
          );
        }

        // 服务正在初始化
        if (provider.isServiceInitializing) {
          return _SectionCard(
            key: _statsCardKey,
            title: t.kb_indexStats,
            isDark: isDark,
            child: Column(
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 12),
                Text(
                  provider.isPreparingService
                      ? t.kb_preparingPythonService
                      : t.kb_startingPythonService,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: DesignTokens.primary500,
                  ),
                ),
              ],
            ),
          );
        }

        // 服务启动失败
        if (provider.serviceError != null && !provider.isPythonServiceRunning) {
          return _SectionCard(
            key: _statsCardKey,
            title: t.kb_indexStats,
            isDark: isDark,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? DesignTokens.darkErrorBackground.withValues(alpha: 0.3)
                    : DesignTokens.errorBackground.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: DesignTokens.error500, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: DesignTokens.error500,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          t.kb_rebuildFailedPythonService,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: DesignTokens.error500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    provider.serviceError!,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? DesignTokens.darkTextSecondary
                          : DesignTokens.gray500,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return _SectionCard(
          key: _statsCardKey,
          title: t.kb_indexStats,
          isDark: isDark,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildModelInfoRow(
                t.kb_indexedNotes,
                '${config.indexedNotesCount} / $totalNotes ${'条'}',
                isDark,
              ),
              _buildModelInfoRow(
                t.kb_totalVectors,
                '${config.totalVectors} ${'条'}',
                isDark,
              ),
              _buildModelInfoRow(
                t.kb_lastUpdate,
                config.lastIndexedAt != null
                    ? _formatDate(config.lastIndexedAt!)
                    : t.kb_notIndexed,
                isDark,
              ),

              // 重建索引进度展示
              if (provider.isRebuildingIndex) ...[
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: provider.rebuildTotal > 0
                      ? provider.rebuildProgress / provider.rebuildTotal
                      : 0.0,
                  backgroundColor: isDark
                      ? DesignTokens.darkBorder
                      : DesignTokens.gray200,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    DesignTokens.primary500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  t.kb_indexingProgress(
                    progress: provider.rebuildProgress,
                    total: provider.rebuildTotal,
                  ),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: DesignTokens.primary500,
                  ),
                ),
              ],

              // 重建完成结果展示
              if (!provider.isRebuildingIndex &&
                  provider.rebuildSuccessCount + provider.rebuildFailedCount >
                      0) ...[
                const SizedBox(height: 12),
                _buildRebuildResultCard(provider, isDark),
              ],

              // 有未索引笔记时的提示（不显示进度条，避免误导）
              if (config.indexedNotesCount < totalNotes &&
                  !provider.isRebuildingIndex) ...[
                const SizedBox(height: 8),
                Text(
                  t.kb_unindexedNotesPrompt(
                    count: totalNotes - config.indexedNotesCount,
                  ),
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? DesignTokens.darkTextSecondary
                        : DesignTokens.gray500,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed:
                        provider.isFullyReady &&
                            !provider.isRebuildingIndex &&
                            !provider.isServiceInitializing
                        ? () => _confirmRebuildIndex(
                            context,
                            provider,
                            notesProvider,
                          )
                        : null,
                    icon: const Icon(Icons.refresh, size: 18),
                    label: Text(t.kb_rebuildIndex),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed:
                        config.totalVectors > 0 &&
                            provider.isFullyReady &&
                            !provider.isRebuildingIndex &&
                            !provider.isServiceInitializing
                        ? () => _confirmClearIndex(
                            context,
                            provider,
                            notesProvider,
                          )
                        : null,
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: Text(t.kb_clearIndex),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: DesignTokens.error500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRebuildResultCard(KnowledgeBaseProvider provider, bool isDark) {
    final hasFailures = provider.rebuildFailedCount > 0;
    final allFailed =
        provider.rebuildSuccessCount == 0 && provider.rebuildFailedCount > 0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: allFailed
            ? (isDark
                  ? DesignTokens.darkErrorBackground.withValues(alpha: 0.3)
                  : DesignTokens.errorBackground.withValues(alpha: 0.3))
            : hasFailures
            ? (isDark
                  ? Colors.orange.withValues(alpha: 0.1)
                  : Colors.orange.withValues(alpha: 0.1))
            : (isDark
                  ? DesignTokens.darkSuccessBackground.withValues(alpha: 0.3)
                  : DesignTokens.successBackground.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: allFailed
              ? DesignTokens.error500
              : hasFailures
              ? Colors.orange
              : DesignTokens.success500,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                allFailed
                    ? Icons.error_outline
                    : hasFailures
                    ? Icons.warning_amber
                    : Icons.check_circle_outline,
                color: allFailed
                    ? DesignTokens.error500
                    : hasFailures
                    ? Colors.orange
                    : DesignTokens.success500,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  allFailed
                      ? t.kb_indexFailedAll(count: provider.rebuildFailedCount)
                      : hasFailures
                      ? t.kb_indexCompleteWithFailures(
                          success: provider.rebuildSuccessCount,
                          failed: provider.rebuildFailedCount,
                        )
                      : t.kb_indexComplete(count: provider.rebuildSuccessCount),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: allFailed
                        ? DesignTokens.error500
                        : hasFailures
                        ? Colors.orange
                        : DesignTokens.success500,
                  ),
                ),
              ),
            ],
          ),

          // 错误详情展开
          if (hasFailures) ...[
            const SizedBox(height: 8),
            InkWell(
              onTap: () {
                setState(() {
                  _showErrorDetails = !_showErrorDetails;
                });
              },
              child: Row(
                children: [
                  Icon(
                    _showErrorDetails ? Icons.expand_more : Icons.chevron_right,
                    size: 18,
                    color: isDark
                        ? DesignTokens.darkTextSecondary
                        : DesignTokens.gray500,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _showErrorDetails
                        ? t.kb_collapseErrorDetails
                        : t.kb_viewErrorDetails(
                            count: provider.rebuildFailedCount,
                          ),
                    style: TextStyle(
                      fontSize: 12,
                      color: DesignTokens.primary500,
                    ),
                  ),
                ],
              ),
            ),
            if (_showErrorDetails) ...[
              const SizedBox(height: 8),
              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.black26
                      : Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: provider.rebuildErrors.map((error) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(
                          '• ${error.noteTitle}: ${error.error}',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark
                                ? DesignTokens.darkTextSecondary
                                : DesignTokens.gray500,
                            fontFamily: 'monospace',
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildModelInfoRow(
    String label,
    String value,
    bool isDark, {
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isDark
                  ? DesignTokens.darkTextSecondary
                  : DesignTokens.gray500,
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                color:
                    valueColor ??
                    (isDark
                        ? DesignTokens.darkTextPrimary
                        : DesignTokens.gray900),
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliderRow(
    String label,
    int value,
    int min,
    int max,
    String unit,
    void Function(int) onChanged,
    bool isDark,
  ) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(label, style: const TextStyle(fontSize: 13)),
        ),
        Expanded(
          child: Slider(
            value: value.toDouble(),
            min: min.toDouble(),
            max: max.toDouble(),
            divisions: (max - min) ~/ 50,
            onChanged: (v) => onChanged(v.toInt()),
            activeColor: DesignTokens.primary500,
          ),
        ),
        SizedBox(
          width: 80,
          child: Text(
            '$value $unit',
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _confirmClearIndex(
    BuildContext context,
    KnowledgeBaseProvider provider,
    NotesProvider notesProvider,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.kb_confirmClearIndex),
        content: Text(t.kb_confirmClearIndexContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(t.common_cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: DesignTokens.error500,
            ),
            child: Text(t.common_clear),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      provider.clearIndex(notesProvider);
    }
  }

  Future<void> _confirmRebuildIndex(
    BuildContext context,
    KnowledgeBaseProvider provider,
    NotesProvider notesProvider,
  ) async {
    final totalNotes = notesProvider.allNotes.length;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.kb_confirmRebuildIndex),
        content: Text(t.kb_unindexedNotesPrompt(count: totalNotes)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(t.common_cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(t.kb_startRebuild),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await provider.rebuildIndex(notesProvider);

        // 重建完成，不显示 SnackBar
        // 失败信息已在索引统计卡片中展示（错误详情区域）
      } catch (e) {
        // 捕获重建索引过程中的未预期异常
        if (!context.mounted) return;
        String errorMessage = t.kb_rebuildFailed;
        final errorStr = e.toString();

        if (errorStr.contains('Python 服务启动失败')) {
          errorMessage = t.kb_rebuildFailedPythonService;
        } else if (errorStr.contains('知识库未就绪')) {
          errorMessage = t.kb_rebuildFailedNotReady;
        } else if (errorStr.contains('健康检查失败')) {
          errorMessage = t.kb_rebuildFailedHealthCheck;
        } else {
          errorMessage = '${t.kb_rebuildFailed}: $errorStr';
        }

        SnackBarHelper.showWithDuration(
          context,
          errorMessage,
          duration: const Duration(seconds: 5),
        );
      }
    }
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  final bool isDark;
  final double highlightBorder;

  const _SectionCard({
    super.key,
    required this.title,
    required this.child,
    required this.isDark,
    this.highlightBorder = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? DesignTokens.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: highlightBorder > 0
              ? DesignTokens.error500.withValues(alpha: highlightBorder)
              : (isDark ? DesignTokens.darkBorder : DesignTokens.gray200),
          width: highlightBorder > 0 ? 2 : 1,
        ),
        boxShadow: highlightBorder > 0
            ? [
                BoxShadow(
                  color: DesignTokens.error500.withValues(
                    alpha: highlightBorder * 0.3,
                  ),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? DesignTokens.darkTextPrimary
                  : DesignTokens.gray900,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
