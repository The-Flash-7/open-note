// lib/providers/media_import_provider.dart
import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../services/media/download_stats.dart';
import '../services/media/gpu_capability.dart';
import '../services/media/media_downloader.dart';
import '../services/media/media_import_service.dart';
import '../services/media/media_import_settings.dart';
import '../services/media/media_tool_service.dart';
import '../services/media/tool_update_service.dart';
import '../services/media/process_runner.dart';
import '../services/media/transcript_formatter.dart';
import '../services/media/whisper_model_service.dart';
import '../services/media/whisper_runner.dart';

enum MediaImportStep { source, envCheck, confirm, processing, done }

enum ImportSourceKind { url, file }

/// ffmpeg 新下载资产无法运行（装前可执行验证失败）。
class ToolBinaryInvalidException implements Exception {
  const ToolBinaryInvalidException();
  @override
  String toString() => '下载的引擎文件无法运行，已保留当前版本';
}

class MediaImportProvider extends ChangeNotifier {
  final MediaToolService toolService;
  final WhisperModelService modelService;
  final MediaDownloader downloader;
  final MediaImportSettings settings = MediaImportSettings();
  final Future<String> Function(String prompt)? callAI;
  final Future<ProcessRunResult> Function(String, List<String>) installerRunner;
  final Future<String?> Function() brewPathResolver;
  final Future<String?> Function() wingetPathResolver;
  final ToolUpdateService updateService;
  final DateTime Function() clock;
  /// whisper 资产解析注入点（测试隔离网络；null 走 GitHub releases 真实解析）。
  final Future<({String url, String build})> Function()? whisperAssetResolver;
  /// Windows 专属安装链路（CUDA 回退）的平台覆写（测试注入）。
  final bool? isWindowsOverride;
  /// GPU 能力探测器覆写（测试注入；null 走 nvidia-smi/Mac 恒 metal 默认实现）。
  final GpuCapabilityDetector? gpuDetector;
  /// Mac 平台守卫覆写（测试注入；null 走 Platform.isMacOS）。
  final bool? isMacOverride;

  MediaImportProvider({
    MediaToolService? toolService,
    WhisperModelService? modelService,
    MediaDownloader? downloader,
    this.callAI,
    Future<ProcessRunResult> Function(String, List<String>)? installerRunner,
    Future<String?> Function()? brewPathResolver,
    Future<String?> Function()? wingetPathResolver,
    ToolUpdateService? updateService,
    DateTime Function()? clock,
    this.whisperAssetResolver,
    this.isWindowsOverride,
    this.gpuDetector,
    this.isMacOverride,
  }) : toolService = toolService ?? _defaultToolService(),
       modelService = modelService ?? WhisperModelService(),
       downloader = downloader ?? MediaDownloader(),
       installerRunner = installerRunner ?? _defaultInstallerRunner,
       brewPathResolver = brewPathResolver ?? _defaultBrewPathResolver,
       wingetPathResolver = wingetPathResolver ?? _defaultWingetPathResolver,
        updateService = updateService ?? ToolUpdateService(),
        clock = clock ?? DateTime.now {
    // fire-and-forget：从持久化恢复「可更新」徽标（跨重启不丢，见 checkToolUpdates）
    unawaited(_restoreUpdateAvailable());
    // 构造时恢复 Mac Metal 黑名单命中缓存（toolStatuses 就绪后的刷新兜底）
    unawaited(refreshWhisperMetalState());
  }

  /// 默认工具服务：接 SharedPreferences 验证缓存（yt-dlp 等 spawn 慢的二进制免重复验证）。
  static MediaToolService _defaultToolService() {
    final s = MediaImportSettings();
    return MediaToolService(
      cacheReader: s.readVerifyCache,
      cacheWriter: s.writeVerifyCache,
    );
  }

  MediaImportStep step = MediaImportStep.source;
  ImportSourceKind sourceKind = ImportSourceKind.url;
  String urlInput = '';
  File? pickedFile;

  final Map<MediaToolKind, MediaToolStatus> toolStatuses = {};
  final Map<MediaToolKind, bool> toolDownloading = {};
  final Map<MediaToolKind, bool> toolFinishing = {};
  final Map<MediaToolKind, bool> toolInstalling = {};
  final Map<MediaToolKind, bool> toolUninstalling = {};
  final Map<MediaToolKind, String?> updateAvailableVersion = {};
  final Map<MediaToolKind, bool> updateChecking = {};
  // 非阻断系统提示（经 ToolStatusRow.systemHint 渲染），如「更新未生效」
  final Map<MediaToolKind, String> toolHints = {};
  Timer? _updateCheckTimer;
  bool modelDeleting = false;
  final Map<MediaToolKind, DownloadStatus> toolDownloadStatus = {};
  final Map<String, DownloadSpeedTracker> _downloadTrackers = {};

  WhisperModelTier recommendedTier = WhisperModelTier.medium;
  WhisperModelTier selectedTier = WhisperModelTier.medium;
  final Set<WhisperModelTier> downloadedTiers = {};
  bool modelDownloading = false;
  DownloadStatus modelDownloadStatus = const DownloadStatus();
  DownloadSpeedTracker? _modelTracker;

  MediaImportPhase? phase;
  double? phaseProgress;
  String? errorMessage;
  String? errorDetail;
  bool aiUnavailable = false;

  MediaImportResult? result;
  String? resultNoteId;

  /// 当次转换实际使用的内容优化档（confirmAndStart 时捕获）。
  /// raw 档不调用 AI，完成页不应显示「AI 格式化未完成」。
  ContentPolishLevel donePolishLevel = ContentPolishLevel.structured;

  CancelToken? _downloadCancel;
  Process? _activeInstaller;
  MediaImportService? _activeService;
  bool _busy = false;
  // CUDA 包安装后校验失败回退 CPU 的单次守卫（防递归重装）
  bool _whisperFallbackBusy = false;
  /// Mac Metal 探测进行中（UI 置灰依据之一）。
  bool metalProbeRunning = false;
  /// 当前 whisper 版本的 Metal 不可用黑名单命中缓存（null=未命中）。
  String? whisperMetalUnavailableVersion;
  bool _metalProbeBusy = false;
  Process? _metalProbeProcess;

  /// GPU 能力探测器：默认接 settings 检测缓存与 nvidia-smi 探测（24h 节流）。
  late final GpuCapabilityDetector _gpuDetector = gpuDetector ??
      GpuCapabilityDetector(
        readCache: settings.gpuDetectCache,
        writeCache: settings.setGpuDetectCache,
        runProbe: _defaultGpuProbe,
        now: clock,
      );

  /// GPU 能力探测器只读访问：设置页 Tab 复用同一条缓存/节流链路
  /// （测试可经构造参数 gpuDetector 注入 fake）。
  GpuCapabilityDetector get gpuCapability => _gpuDetector;

  bool get _isWinFlow => isWindowsOverride ?? Platform.isWindows;

  static Future<ProcessRunResult> _defaultGpuProbe(
    String exe,
    List<String> args,
  ) async {
    final r = await Process.run(exe, args);
    return ProcessRunResult(
        r.exitCode, r.stdout.toString(), r.stderr.toString());
  }

  bool get busy => _busy;

  bool get operationInProgress =>
      _busy ||
      toolDownloading.values.any((v) => v) ||
      toolInstalling.values.any((v) => v) ||
      toolUninstalling.values.any((v) => v) ||
      toolFinishing.values.any((v) => v) ||
      modelDownloading ||
      modelDeleting;

  bool get transcriptionActive => _activeService != null;

  String pendingLanguage = 'auto';

  bool isToolRequired(MediaToolKind kind) =>
      kind != MediaToolKind.ytDlp || sourceKind == ImportSourceKind.url;

  bool get environmentReady =>
      MediaToolKind.values
          .where(isToolRequired)
          .every((k) => toolStatuses[k]?.ready ?? false) &&
      downloadedTiers.contains(selectedTier);

  void _notify() => notifyListeners();

  /// 构造后恢复持久化的更新标记（kindName 反序列化，非法 kind/值跳过）。
  Future<void> _restoreUpdateAvailable() async {
    try {
      final table = await settings.readUpdateAvailable();
      if (table.isEmpty) return;
      for (final entry in table.entries) {
        try {
          final kind = MediaToolKind.values.byName(entry.key);
          updateAvailableVersion.putIfAbsent(kind, () => entry.value);
        } catch (_) {
          // 未知 kind（枚举演进/脏数据）：跳过
        }
      }
      _notify();
    } catch (_) {
      // 恢复失败静默：下次检查会重建
    }
  }

  /// 将内存徽标整表落盘（与已存内容一致时跳过写入）。
  Future<void> _persistUpdateAvailable() async {
    try {
      final table = <String, String>{
        for (final e in updateAvailableVersion.entries)
          if (e.value != null) e.key.name: e.value!,
      };
      final stored = await settings.readUpdateAvailable();
      if (stored.length == table.length &&
          stored.entries.every((e) => table[e.key] == e.value)) {
        return;
      }
      await settings.writeUpdateAvailable(table);
    } catch (_) {
      // 持久化失败静默
    }
  }

  Future<void> startForUrl(String url) async {
    sourceKind = ImportSourceKind.url;
    urlInput = url;
    pickedFile = null;
    if (_enterConfirmIfReady()) return;
    step = MediaImportStep.envCheck;
    _notify();
    await checkEnvironment();
  }

  Future<void> startForFile(File f) async {
    sourceKind = ImportSourceKind.file;
    pickedFile = f;
    if (_enterConfirmIfReady()) return;
    step = MediaImportStep.envCheck;
    _notify();
    await checkEnvironment();
  }

  /// 环境已就绪（工具全 ready && 所选模型已下载）时跳过检测步骤直达确认页，
  /// 检测转为后台静默刷新（验证缓存使其近乎零成本）。
  bool _enterConfirmIfReady() {
    if (!environmentReady) return false;
    step = MediaImportStep.confirm;
    _notify();
    unawaited(checkEnvironment());
    return true;
  }

  Future<void> checkEnvironment({bool forceVerify = false}) async {
    _busy = true;
    errorMessage = null;
    errorDetail = null;
    _notify();
    try {
      for (final kind in MediaToolKind.values.where(isToolRequired)) {
        toolStatuses[kind] =
            await toolService.check(kind, forceVerify: forceVerify);
        _notify();
      }
      recommendedTier = await modelService.recommendTierForDevice();
      // 恢复用户持久化选择（历史版本未落盘时为 null -> 回退推荐档）
      selectedTier = await settings.whisperModelTier() ?? recommendedTier;
      downloadedTiers.clear();
      for (final t in WhisperModelTier.values) {
        if (await modelService.localModelFile(t) != null) {
          downloadedTiers.add(t);
        }
      }
      aiUnavailable = callAI == null;
    } catch (e) {
      errorMessage = '环境检查失败';
      errorDetail = e.toString();
    } finally {
      _busy = false;
      _notify();
      unawaited(refreshWhisperMetalState());
      // 环境检查完成点触发 Metal 实测（守卫幂等）：进入媒体设置的探测定点，
      // 同时覆盖装完/升级 whisper 后当次会话的探测（此前仅开关关→开触发）
      unawaited(ensureWhisperMetalProbe());
    }
  }

  /// 静默定时检查工具新版本（默认延迟 15s；到点时若操作进行中或环境尚未检测
  /// （toolStatuses 为空，如 splash 只调度未进入媒体 UI）则顺延 60s 重试，
  /// 避免会话内永不检查——24h 节流由 checkToolUpdates 内部兜底，重试零成本）。
  void scheduleUpdateCheck({Duration delay = const Duration(seconds: 15)}) {
    _updateCheckTimer?.cancel();
    _updateCheckTimer = Timer(delay, () {
      if (operationInProgress || toolStatuses.isEmpty) {
        scheduleUpdateCheck(delay: const Duration(seconds: 60));
        return;
      }
      checkToolUpdates();
    });
  }

  /// 静默检查 appManaged 工具的新版本（24h 节流，全程不抛错）。
  Future<void> checkToolUpdates() async {
    try {
      final last = await settings.lastUpdateCheckAt();
      if (last != null &&
          clock().difference(last) < const Duration(hours: 24)) {
        return;
      }
      // 本轮至少实际 fetch 过一个 kind 才写 24h 节流时间戳：
      // 全部被跳过（无状态/非 appManaged/操作占用）时空转不烧节流预算
      var fetchedKinds = 0;
      var updateTableChanged = false;
      for (final kind in MediaToolKind.values) {
        if ((toolDownloading[kind] ?? false) ||
            (toolInstalling[kind] ?? false) ||
            (toolUninstalling[kind] ?? false)) {
          continue;
        }
        final st = toolStatuses[kind];
        if (st == null ||
            !st.ready ||
            st.source != MediaToolSource.appManaged) {
          continue;
        }
        try {
          updateChecking[kind] = true;
          _notify();
          final latest = await updateService.fetchLatestVersion(kind);
          fetchedKinds++; // 网络已探测（返回 null 也算），才允许写节流时间戳
          if (latest != null) {
            final stored = kind == MediaToolKind.whisperCli
                ? await settings.whisperCliSourceTag()
                : null;
            if (ToolUpdateService.hasUpdate(
              localVersion: st.version,
              remoteTag: latest,
              kind: kind,
              storedSourceTag: stored,
            )) {
              if (updateAvailableVersion[kind] != latest) {
                updateAvailableVersion[kind] = latest;
                updateTableChanged = true;
              }
            } else if (updateAvailableVersion.remove(kind) != null) {
              // 拉到最新且无更新：清掉过期徽标
              updateTableChanged = true;
            }
          }
        } catch (_) {
          // 单个工具检查失败不影响后续工具
        } finally {
          updateChecking[kind] = false;
          _notify();
        }
      }
      if (fetchedKinds > 0) {
        await settings.setLastUpdateCheckAt(clock());
      }
      if (updateTableChanged) {
        await _persistUpdateAvailable();
      }
    } catch (_) {
      // 更新检查绝不影响主流程
    }
  }

  void _markFinishing(MediaToolKind kind) {
    toolDownloading[kind] = false;
    toolFinishing[kind] = true;
    _notify();
  }

  /// 磁盘预检阈值分级：whisper Windows 资产现为 ~1.2GB CUDA 包，
  /// 下载 zip + 解压峰值 ~2.4GB，按 2.5GB 预留；其余单文件工具 200MB。
  static int diskNeedBytes(MediaToolKind kind) =>
      kind == MediaToolKind.whisperCli
          ? 2560 * 1024 * 1024
          : 200 * 1024 * 1024;

  Future<void> downloadTool(MediaToolKind kind) async {
    final installedBuild = await _downloadToolInternal(kind);
    // Windows：CUDA 包安装后自动重检失败（老驱动无法加载 ggml-cuda.dll 常见）
    // → 写 win:tag 黑名单并单次回退 CPU 重装；_whisperFallbackBusy 防递归。
    if (kind == MediaToolKind.whisperCli &&
        installedBuild == 'cuda' &&
        _isWinFlow &&
        !(toolStatuses[kind]?.ready ?? false)) {
      await _fallbackWhisperToCpuAfterFailedVerify();
    }
    unawaited(refreshWhisperMetalState());
  }

  Future<String?> _downloadToolInternal(MediaToolKind kind) async {
    // 操作占用守卫：下载/安装/finishing 收尾/卸载期间重复触发直接忽略
    //（防 finishing 窗口内重复点击「更新」造成二次下载/状态互踩）
    if ((toolDownloading[kind] ?? false) ||
        (toolInstalling[kind] ?? false) ||
        (toolFinishing[kind] ?? false) ||
        (toolUninstalling[kind] ?? false)) {
      return null;
    }
    // 先取检测到的更新 tag 再清徽标：ffmpeg「更新」按该具体 tag 下载
    final updateTag = updateAvailableVersion.remove(kind);
    final isUpdate = updateTag != null;
    // 1b 装后版本比对基线：更新前的本地版本
    final prevVersion = toolStatuses[kind]?.version;
    toolHints.remove(kind);
    toolDownloading[kind] = true;
    toolDownloadStatus[kind] = const DownloadStatus();
    _downloadTrackers['tool:${kind.name}'] = DownloadSpeedTracker();
    errorMessage = null;
    _notify();
    // 本次 whisper 安装实际落位的构建（cuda/cpu）；安装失败/非 whisper 为 null
    String? installedBuild;
    try {
      final dir = await toolService.toolDir(kind);
      // 磁盘空间预检：按工具分级阈值，不足直接阻止下载
      final free = await downloader.freeDiskBytes(dir);
      final needBytes = diskNeedBytes(kind);
      if (free != null && free < needBytes) {
        errorMessage = '磁盘空间不足';
        errorDetail =
            '需要约 ${needBytes ~/ (1024 * 1024)} MB，可用 '
            '${free ~/ (1024 * 1024)} MB';
        return null;
      }
      _downloadCancel = CancelToken();
      final binName = toolService.binaryName(kind);
      final dest = File('$dir/$binName');
      final isSingleFile = kind != MediaToolKind.whisperCli;
      if (isSingleFile) {
        final isFfmpeg = kind == MediaToolKind.ffmpeg;
        // 1a 装前可执行验证：ffmpeg 先下到 staging，验证通过才替换旧文件
        final target = isFfmpeg ? File('${dest.path}.staging') : dest;
        await downloader.download(
          kind == MediaToolKind.ytDlp
              ? MediaDownloader.ytDlpDirectUrl()
              : MediaDownloader.ffmpegDirectUrl(tag: updateTag),
          destFile: target,
          mode: await settings.downloadSource(),
          cancelToken: _downloadCancel,
          onProgress: (r, t) {
            if (t > 0) {
              toolDownloadStatus[kind] = _downloadTrackers['tool:${kind.name}']!
                  .tick(r, t);
              _notify();
            }
          },
        );
        _markFinishing(kind);
        if (isFfmpeg) {
          final runnable = await verifyDownloadedBinary(target);
          if (!runnable) {
            // 坏资产：不替换旧版本，清理临时文件，走下载失败错误路径
            try {
              if (await target.exists()) await target.delete();
            } catch (_) {}
            throw const ToolBinaryInvalidException();
          }
          if (await dest.exists()) {
            try {
              await dest.delete();
            } catch (_) {}
          }
          await target.rename(dest.path);
        } else if (!Platform.isWindows) {
          await Process.run('chmod', ['+x', dest.path]);
        }
      } else {
        final picked = await _resolveWhisperAssetUrl();
        final directUrl = picked.url;
        final archiveName = destNameOf(directUrl);
        final archive = File('$dir/$archiveName');
        await downloader.download(
          directUrl,
          destFile: archive,
          mode: await settings.downloadSource(),
          cancelToken: _downloadCancel,
          onProgress: (r, t) {
            if (t > 0) {
              toolDownloadStatus[kind] = _downloadTrackers['tool:${kind.name}']!
                  .tick(r, t);
              _notify();
            }
          },
        );
        _markFinishing(kind);
        final sourceTag = ToolUpdateService.whisperTagFromUrl(directUrl);
        if (sourceTag != null) {
          try {
            await settings.setWhisperCliSourceTag(sourceTag);
          } catch (_) {}
        }
        final extractDir =
            '$dir/_extract_${DateTime.now().millisecondsSinceEpoch}';
        await downloader.extract(archive, extractDir);
        final installed = await toolService.installExtractedBinary(
          extractDir,
          kind,
        );
        _deleteDirQuiet(Directory(extractDir));
        if (archive.path != dest.path && await archive.exists()) {
          try {
            await archive.delete();
          } catch (_) {}
        }
        if (installed == null) {
          throw Exception('安装包中未找到 $binName，请改用手动安装指引');
        }
        // 安装成功即记录本次构建（切换联动与 CUDA 回退判定的依据）
        installedBuild = picked.build;
        try {
          await settings.setWhisperBuild(picked.build);
        } catch (_) {}
      }
      toolStatuses[kind] =
          await toolService.check(kind, forceVerify: true);
      if (!(toolStatuses[kind]?.ready ?? false)) {
        errorMessage = '工具安装后校验未通过';
        errorDetail = null;
      } else {
        // 1b 装后版本比对：更新场景下版本未变化（下载源内容未变化）
        // → 徽标已清（内存开始时移除），落盘同步 + 非阻断提示
        final newVersion = toolStatuses[kind]?.version;
        if (isUpdate &&
            newVersion != null &&
            prevVersion != null &&
            newVersion == prevVersion) {
          toolHints[kind] = '更新未生效（下载源内容未变化），已保留当前版本';
        }
        // 更新/下载安装成功：徽标已清，同步落盘（下次启动不再误报）
        await _persistUpdateAvailable();
      }
    } on ToolBinaryInvalidException {
      errorMessage = '下载的引擎文件无法运行，已保留当前版本';
      errorDetail = null;
    } catch (e) {
      errorMessage = '工具下载/安装失败';
      errorDetail = e.toString();
    } finally {
      toolDownloading[kind] = false;
      toolFinishing[kind] = false;
      _downloadCancel = null;
      _downloadTrackers.remove('tool:${kind.name}');
      _notify();
    }
    return installedBuild;
  }

  /// CUDA 包安装后校验失败的自动回退：按本次 release tag 记入 GPU 不可用
  /// 黑名单（下次选包强制 CPU），随后重走一次下载安装；守卫位防递归。
  Future<void> _fallbackWhisperToCpuAfterFailedVerify() async {
    if (_whisperFallbackBusy) return;
    final tag = await settings.whisperCliSourceTag();
    if (tag != null) {
      try {
        await settings.markGpuUnavailable(
          gpuUnavailableKeyWin(tag),
          'CUDA 版安装校验失败（驱动可能过旧）',
        );
      } catch (_) {}
    }
    _whisperFallbackBusy = true;
    try {
      await _downloadToolInternal(MediaToolKind.whisperCli);
      if (toolStatuses[MediaToolKind.whisperCli]?.ready ?? false) {
        toolHints[MediaToolKind.whisperCli] =
            'CUDA 版启动失败（驱动可能过旧），已回退 CPU 版';
        _notify();
      }
    } finally {
      _whisperFallbackBusy = false;
    }
  }

  /// 设置页 GPU 加速开关：写设置后按已装构建联动重装。
  /// 仅 appManaged（便携版）参与包选择；systemPath（winget/brew）只写设置；
  /// 构建记录 unknown（旧版本升级用户）不自动重装，提示重下后生效。
  Future<void> setWhisperGpuEnabled(bool v) async {
    await settings.setWhisperGpu(v);
    // 打开开关时主动触发 Metal 实测（守卫幂等；黑名单/OK 缓存防重复探测）
    if (v) unawaited(ensureWhisperMetalProbe());
    final st = toolStatuses[MediaToolKind.whisperCli];
    if (st == null || st.source != MediaToolSource.appManaged) {
      return;
    }
    final stored = await settings.whisperBuild();
    if (stored == null) {
      toolHints[MediaToolKind.whisperCli] = '重新下载引擎后生效';
      _notify();
      return;
    }
    // 期望构建仅 Windows 流随开关切换（cuda/cpu）；Mac 无包选择（brew/便携
    // 同款构建，Metal 内置），开关只在运行层生效，恒按 cpu 比对不触发重装
    final expected = _isWinFlow ? expectedWhisperBuild(useGpu: v) : 'cpu';
    if (!reinstallNeeded(stored, expected)) {
      return;
    }
    await downloadTool(MediaToolKind.whisperCli);
    // 提示在下载完成后设置：downloadTool 开头会清 toolHints。
    // 仅当本次实际落位构建与期望一致时提示「正在切换」；下载内部触发
    // CUDA 校验失败自动回退（落位 cpu≠期望 cuda）时保留回退文案不被覆写
    if (expected == (await settings.whisperBuild()) &&
        (toolStatuses[MediaToolKind.whisperCli]?.ready ?? false)) {
      toolHints[MediaToolKind.whisperCli] =
          v ? '正在切换 CUDA 版本' : '正在切换 CPU 版本';
      _notify();
    }
  }

  /// GPU 开关对应的期望引擎构建（Windows 安装层选包依据）。
  static String expectedWhisperBuild({required bool useGpu}) =>
      useGpu ? 'cuda' : 'cpu';

  /// 已装构建与期望不一致时需重装；无构建记录（unknown）不自动重装。
  static bool reinstallNeeded(String? stored, String expected) =>
      stored != null && stored != expected;

  /// whisper 运行层 GPU 决策纯函数：开关 ∧ Metal 能力 ∧ 版本黑名单未命中
  /// → 允许 GPU（返回 false 不加 -ng）。
  /// - 版本未知（null/'ready' 旧探测缓存）→ 键无法构造 → 不禁 GPU
  ///   （Metal 崩溃后仍有 -ng 重试兜底）。
  /// - Windows（cuda）运行层不禁 GPU：构建已由安装层选定，CUDA 构建缺省
  ///   启用加速；Metal 崩溃重试特征仅匹配 Metal，对 Windows 无副作用。
  /// - 无能力（none）→ 禁 GPU。
  static bool whisperNoGpuDecision({
    required bool gpuEnabled,
    required GpuKind kind,
    String? installedVersion,
    Set<String> unavailableKeys = const {},
  }) {
    if (!gpuEnabled) return true;
    switch (kind) {
      case GpuKind.metal:
        final v = installedVersion;
        if (v == null || v.isEmpty || v == 'ready') return false;
        return unavailableKeys.contains(gpuUnavailableKeyMac(v));
      case GpuKind.cuda:
        return false;
      case GpuKind.none:
        return true;
    }
  }

  /// whisper 运行层 GPU 决策（Mac Metal 语义）：开关 ∧ 能力==metal ∧
  /// 黑名单未命中 mac:版本 → 允许 GPU。版本取 toolStatuses 已探明的真实
  /// 版本号；未知（'ready'/null 旧缓存）视为键 miss → 不禁 GPU（Metal
  /// 崩溃兜底仍在）。Windows 语义见 [whisperNoGpuDecision]。
  Future<bool> resolveWhisperNoGpu() async {
    final kind = (await _gpuDetector.detect()).kind;
    return whisperNoGpuDecision(
      gpuEnabled: await settings.whisperGpu(),
      kind: kind,
      installedVersion: toolStatuses[MediaToolKind.whisperCli]?.version,
      unavailableKeys: (await settings.gpuUnavailableVersions()).keys.toSet(),
    );
  }

  /// Mac Metal 崩溃 → CPU 重试成功后的黑名单写入（版本升级后键自然不命中）。
  /// 版本未知（'ready'/null）无法构造键：跳过记录，下次仍走 Metal 崩溃兜底。
  Future<void> _markWhisperMetalUnavailable() async {
    final version = toolStatuses[MediaToolKind.whisperCli]?.version;
    if (version == null || version == 'ready') return;
    try {
      await settings.markGpuUnavailable(
        gpuUnavailableKeyMac(version),
        'Metal 后端转录崩溃，已自动降级 CPU',
      );
    } catch (_) {
      // 黑名单写入失败不影响转录结果：下次会话重试路径依旧
    }
    unawaited(refreshWhisperMetalState());
  }

  /// 依据黑名单与当前 whisper 版本刷新 Mac Metal 不可用缓存；变化时 notify。
  Future<void> refreshWhisperMetalState() async {
    final version = toolStatuses[MediaToolKind.whisperCli]?.version;
    String? hit;
    if (version != null && version != 'ready') {
      final keys = (await settings.gpuUnavailableVersions()).keys;
      hit = keys.contains(gpuUnavailableKeyMac(version)) ? version : null;
    }
    if (whisperMetalUnavailableVersion != hit) {
      whisperMetalUnavailableVersion = hit;
      _notify();
    }
  }

  /// Mac Metal 实测探测：守卫链全过时用 1 秒合成音频实际跑一次转录，
  /// 以 onGpuFallback 是否触发判定（复用运行时崩溃特征识别，不另造匹配）。
  /// 崩溃→写黑名单 mac:版本；成功→写 OK 缓存；其他异常/超时→乐观不动。
  Future<void> ensureWhisperMetalProbe() async {
    if (!(isMacOverride ?? Platform.isMacOS)) return;
    if (operationInProgress || _metalProbeBusy) return;
    _metalProbeBusy = true;
    metalProbeRunning = true;
    _notify();
    Directory? tmpDir;
    try {
      final st = toolStatuses[MediaToolKind.whisperCli];
      final version = st?.version;
      if (st == null ||
          !st.ready ||
          st.path == null ||
          version == null ||
          version == 'ready') {
        return;
      }
      if (!await settings.whisperGpu()) return;
      if ((await settings.gpuUnavailableVersions())
          .containsKey(gpuUnavailableKeyMac(version))) {
        return;
      }
      if ((await settings.metalOkVersions()).containsKey(version)) return;
      File? model;
      for (final tier in WhisperModelTier.values) {
        final f = await modelService.localModelFile(tier);
        if (f != null) {
          model = f;
          break;
        }
      }
      if (model == null) return;

      tmpDir = await Directory.systemTemp.createTemp('metal_probe');
      final wav = File('${tmpDir.path}/probe.wav');
      await wav.writeAsBytes(metalProbeWavBytes(), flush: true);
      var gpuFailed = false;
      try {
        await WhisperRunner()
            .transcribe(
          whisperCliPath: st.path!,
          model: model,
          wav: wav,
          onStarted: (proc) => _metalProbeProcess = proc,
          onGpuFallback: () => gpuFailed = true,
        )
            .timeout(const Duration(seconds: 60));
        if (gpuFailed) {
          await _markWhisperMetalUnavailable();
        } else {
          try {
            await settings.markMetalOk(version);
          } catch (_) {}
        }
      } on TimeoutException {
        // 超时不定论：不写黑名单不写 OK
      } catch (e) {
        // onGpuFallback 仅在 CPU 重试成功时触发；重试也失败时异常带的是
        // 重试 stderr——复用运行时崩溃特征识别（不另造匹配），
        // Metal 确实坏则黑名单照写
        if (gpuFailed ||
            (e is WhisperException &&
                WhisperRunner.looksLikeGpuFailure(0, e.stderr ?? ''))) {
          await _markWhisperMetalUnavailable();
        }
        // 其余异常乐观不动（模型损坏等环境问题不应误置灰）
      }
    } catch (_) {
      // 基础设施异常（临时目录创建失败等）：乐观不动
    } finally {
      try {
        _metalProbeProcess?.kill();
      } catch (_) {}
      _metalProbeProcess = null;
      try {
        tmpDir?.delete(recursive: true);
      } catch (_) {}
      _metalProbeBusy = false;
      metalProbeRunning = false;
      await refreshWhisperMetalState();
      _notify();
    }
  }

  /// 1a 装前可执行验证：mac/linux `chmod +x` 后执行 `-version`（超时 5s），
  /// windows 复制到同目录临时 `.exe` 再探测（PE 必须以 .exe 结尾才能启动）。
  /// 退出码非 0 / 超时 / 被系统杀死 / 无法执行 → false（视为坏资产）。
  Future<bool> verifyDownloadedBinary(File f) async {
    File probe = f;
    if (!Platform.isWindows) {
      try {
        await Process.run('chmod', ['+x', f.path]);
      } catch (_) {}
    } else {
      probe = File('${f.path}.verify.exe');
      try {
        await f.copy(probe.path);
      } catch (_) {
        return false;
      }
    }
    try {
      final r = await installerRunner(probe.path, const ['-version'])
          .timeout(const Duration(seconds: 5));
      return r.exitCode == 0;
    } catch (_) {
      return false;
    } finally {
      if (probe.path != f.path) {
        try {
          await probe.delete();
        } catch (_) {}
      }
    }
  }

  /// 一键自动安装（macOS=brew / Windows=winget，仅 whisperCli 支持）。
  Future<void> autoInstallTool(MediaToolKind kind) async {
    final pkgPath = await _resolvePkgManagerPath();
    final plan = MediaToolService.autoInstallPlan(
      kind,
      brewPath: pkgPath,
      wingetPath: pkgPath,
      isMac: Platform.isMacOS,
      isWin: Platform.isWindows,
    );
    if (plan == null) {
      // Windows：winget 缺失时自动降级便携版下载（whisperCli 链路完整：
      // zip 下载+解压+dll 平铺）。下载期间 UI 进度条自解释；downloadTool
      // 开头会清 toolHints，故提示必须在其完成后设置。提示仅在安装就绪
      // 后展示——静默 return 或下载失败时不显示误导性提示，失败信息
      // 由 errorMessage/errorDetail 覆盖。
      if (Platform.isWindows) {
        await downloadTool(kind);
        if (toolStatuses[kind]?.ready ?? false) {
          toolHints[kind] = '未检测到 winget（应用安装程序），已自动改用便携版下载';
        }
        return;
      }
      errorMessage = '无法自动安装';
      errorDetail = Platform.isMacOS
          ? '未检测到 Homebrew，请按指引手动安装（终端执行 brew install whisper.cpp）'
          : '当前平台不支持自动安装，请按指引手动安装';
      _notify();
      return;
    }
    toolInstalling[kind] = true;
    errorMessage = null;
    errorDetail = null;
    _notify();
    try {
      final r = await installerRunner(plan.executable, plan.args);
      if (r.exitCode != 0) {
        errorMessage = '自动安装失败';
        errorDetail = (r.stderr.trim().isNotEmpty ? r.stderr : r.stdout).trim();
        return;
      }
      toolStatuses[kind] =
          await toolService.check(kind, forceVerify: true);
    } catch (e) {
      errorMessage = '自动安装失败';
      errorDetail = e.toString();
    } finally {
      toolInstalling[kind] = false;
      _activeInstaller = null;
      _notify();
    }
  }

  /// 卸载计划：mac 走 brew（ffmpeg/yt-dlp/whisper.cpp），windows 仅 whisper-cli 走 winget。
  static InstallerPlan? uninstallPlan(
    MediaToolKind kind, {
    String? brewPath,
    String? wingetPath,
    required bool isMac,
    required bool isWin,
  }) {
    if (isMac) {
      if (brewPath == null || brewPath.isEmpty) return null;
      final name = switch (kind) {
        MediaToolKind.ffmpeg => 'ffmpeg',
        MediaToolKind.ytDlp => 'yt-dlp',
        // 与安装计划一致：brew 公式名为 whisper.cpp
        MediaToolKind.whisperCli => 'whisper.cpp',
      };
      return InstallerPlan(brewPath, ['uninstall', '-q', name]);
    }
    if (isWin && kind == MediaToolKind.whisperCli) {
      if (wingetPath == null || wingetPath.isEmpty) return null;
      return InstallerPlan(wingetPath, [
        'uninstall', '--id', 'ggml.whisper-cpp', '-e', '--disable-interactivity',
      ]);
    }
    return null;
  }

  /// 当前平台包管理器绝对路径（mac=brew / win=winget，其余 null）。
  Future<String?> _resolvePkgManagerPath() async {
    if (Platform.isMacOS) return brewPathResolver();
    if (Platform.isWindows) return wingetPathResolver();
    return null;
  }

  Future<void> uninstallTool(MediaToolKind kind) async {
    final status = toolStatuses[kind];
    if (status == null || !status.ready) return;
    if ((toolDownloading[kind] ?? false) ||
        (toolInstalling[kind] ?? false) ||
        (toolFinishing[kind] ?? false)) {
      return;
    }
    toolUninstalling[kind] = true;
    errorMessage = null;
    errorDetail = null;
    _notify();
    try {
      if (status.source == MediaToolSource.appManaged) {
        // 同步删除：FakeAsync（widget 测试）下 dart:io 异步方法无法完成
        final dir = Directory(await toolService.toolDir(kind));
        if (dir.existsSync()) dir.deleteSync(recursive: true);
      } else {
        final pkgPath = await _resolvePkgManagerPath();
        final plan = uninstallPlan(
          kind,
          brewPath: pkgPath,
          wingetPath: pkgPath,
          isMac: Platform.isMacOS,
          isWin: Platform.isWindows,
        );
        if (plan == null) {
          errorMessage = '无法自动卸载';
          errorDetail = Platform.isWindows
              ? '未检测到 winget（应用安装程序），请使用对应包管理器卸载；'
                  '可从 Microsoft Store 安装“应用安装程序 (App Installer)”后重试'
              : '请使用对应包管理器卸载';
          return;
        }
        final r = await installerRunner(plan.executable, plan.args);
        if (r.exitCode != 0) {
          errorMessage = '自动卸载失败';
          errorDetail =
              (r.stderr.trim().isNotEmpty ? r.stderr : r.stdout).trim();
          return;
        }
      }
      toolStatuses[kind] =
          await toolService.check(kind, forceVerify: true);
      // 卸载成功：清徽标并落盘（旧版本已不存在，更新提示失效）
      updateAvailableVersion.remove(kind);
      await _persistUpdateAvailable();
    } catch (e) {
      errorMessage = '卸载失败';
      errorDetail = e.toString();
    } finally {
      toolUninstalling[kind] = false;
      _activeInstaller = null;
      _notify();
    }
  }

  Future<void> deleteModel(WhisperModelTier tier) async {
    if (_activeService != null) {
      errorMessage = '转录进行中，无法删除模型';
      _notify();
      return;
    }
    if (modelDeleting || !downloadedTiers.contains(tier)) return;
    modelDeleting = true;
    _notify();
    try {
      final info = WhisperModelService.infoFor(tier);
      final f = File('${await modelService.modelsDir()}/${info.fileName}');
      if (f.existsSync()) f.deleteSync();
      downloadedTiers.remove(tier);
    } catch (e) {
      errorMessage = '删除模型失败';
      errorDetail = e.toString();
    } finally {
      modelDeleting = false;
      _notify();
    }
  }

  static Future<ProcessRunResult> _defaultInstallerRunner(
    String executable,
    List<String> args,
  ) async {
    final process = await Process.start(executable, args);
    final sbOut = StringBuffer();
    final sbErr = StringBuffer();
    process.stdout.transform(utf8.decoder).listen(sbOut.write);
    process.stderr.transform(utf8.decoder).listen(sbErr.write);
    final code = await process.exitCode;
    return ProcessRunResult(code, _tailOf(sbOut), _tailOf(sbErr));
  }

  static String _tailOf(StringBuffer sb) {
    final s = sb.toString();
    return s.length > 2000 ? s.substring(s.length - 2000) : s;
  }

  static Future<String?> _defaultBrewPathResolver() async {
    for (final path in MediaToolService.brewCandidatePaths()) {
      if (File(path).existsSync()) return path;
    }
    return null;
  }

  static Future<String?> _defaultWingetPathResolver() async {
    for (final path in MediaToolService.wingetCandidatePaths()) {
      if (File(path).existsSync()) return path;
    }
    return null;
  }

  /// 模型下载失败的手动兜底提示：提示浏览器下载 + 模型目录 + 文件名保持。
  static String buildModelManualHint({
    required String fileName,
    required String modelsDir,
  }) =>
      '\n手动下载：用浏览器打开上方链接，下载后放入模型目录并将文件名保持为 '
      '$fileName，然后点「重新检测」即可自动识别'
      '\n模型目录：$modelsDir';

  Future<void> downloadSelectedModel() async {
    modelDownloading = true;
    modelDownloadStatus = const DownloadStatus();
    _modelTracker = DownloadSpeedTracker();
    errorMessage = null;
    _notify();
    // fileName 在 try 外先取：catch 中 info 变量不可达
    final fileName = WhisperModelService.infoFor(selectedTier).fileName;
    try {
      final info = WhisperModelService.infoFor(selectedTier);
      final modelsDir = await modelService.modelsDir();
      // 磁盘空间预检：按所选模型标称大小估算
      final free = await downloader.freeDiskBytes(modelsDir);
      final needBytes = info.downloadSizeBytes;
      if (free != null && free < needBytes) {
        errorMessage = '磁盘空间不足';
        errorDetail =
            '需要约 ${needBytes ~/ 1024 / 1024} MB，可用 '
            '${free ~/ 1024 / 1024} MB';
        return;
      }
      _downloadCancel = CancelToken();
      await downloader.download(
        WhisperModelService.modelUrl(info, mirror: false).toString(),
        destFile: File('$modelsDir/${info.fileName}'),
        mode: await settings.downloadSource(),
        cancelToken: _downloadCancel,
        onProgress: (r, t) {
          if (t > 0) {
            modelDownloadStatus = _modelTracker!.tick(r, t);
            _notify();
          }
        },
      );
      downloadedTiers.add(selectedTier);
    } catch (e) {
      errorMessage = '模型下载失败';
      // modelsDir 在 catch 中重新 await（try 内变量可能未达）
      String modelsDir;
      try {
        modelsDir = await modelService.modelsDir();
      } catch (_) {
        modelsDir = '（获取失败）';
      }
      errorDetail =
          '$e${buildModelManualHint(fileName: fileName, modelsDir: modelsDir)}';
    } finally {
      modelDownloading = false;
      _downloadCancel = null;
      _modelTracker = null;
      _notify();
    }
  }

  /// 解析本次 whisper 安装包：useGpu = GPU 开关 ∧ 能力（Windows==cuda），
  /// 再按 release tag 黑名单逐 release 强制回 CPU 选包。
  /// 返回直链与本次构建（cuda/cpu，按实际选中资产）。
  Future<({String url, String build})> _resolveWhisperAssetUrl() async {
    final override = whisperAssetResolver;
    if (override != null) return override();
    final gpuOn = await settings.whisperGpu();
    final capable = !_isWinFlow ||
        (await _gpuDetector.detect()).kind == GpuKind.cuda;
    final useGpu = gpuOn && capable;
    final unavailableKeys =
        (await settings.gpuUnavailableVersions()).keys.toSet();
    final candidates = MediaDownloader.whisperApiCandidates(
      MediaDownloader.whisperReleasesApiUrl(),
      mode: await settings.downloadSource(),
    );
    final dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
    ));
    Object? lastError;
    for (final url in candidates) {
      final List<dynamic> releases;
      try {
        final resp = await dio.get<dynamic>(
          url,
          options: Options(headers: {'Accept': 'application/vnd.github+json'}),
        );
        if (resp.statusCode != 200) {
          lastError = Exception('HTTP ${resp.statusCode}');
          continue;
        }
        releases = (resp.data as List?) ?? const [];
      } catch (e) {
        lastError = e;
        continue;
      }
      final picked = pickWhisperDownloadUrl(
        releases,
        preferCuda: useGpu,
        gpuUnavailableKeys: unavailableKeys,
      );
      if (picked != null) return picked;
      throw Exception('当前平台暂无 whisper.cpp 预编译包，请查看安装指引手动安装');
    }
    throw Exception(
        '无法获取 whisper.cpp 版本列表（已尝试 GitHub 直连与 gh-proxy 镜像）：$lastError');
  }

  /// release 列表选包纯函数：preferCuda 时 cuda 层优先；黑名单命中
  /// `win:tag` 的 release 强制按 CPU 选。build 取自实际选中资产名。
  static ({String url, String build})? pickWhisperDownloadUrl(
    List<dynamic> releases, {
    required bool preferCuda,
    required Set<String> gpuUnavailableKeys,
    bool? isWindows,
    bool? isMac,
    bool? isArm,
  }) {
    for (final release in releases) {
      final map = release as Map;
      final tag = map['tag_name']?.toString() ?? '';
      final assets = ((map['assets'] as List?) ?? const [])
          .map((a) => (a as Map)['name'].toString())
          .toList();
      final prefer = preferCuda &&
          !gpuUnavailableKeys.contains(gpuUnavailableKeyWin(tag));
      final asset = MediaDownloader.pickWhisperAsset(
        assets,
        isWindows: isWindows ?? Platform.isWindows,
        isMac: isMac ?? Platform.isMacOS,
        isArm: isArm ?? _isArmHost,
        preferCuda: prefer,
      );
      if (asset != null) {
        return (
          url: 'https://github.com/ggml-org/whisper.cpp/releases/download/'
              '$tag/$asset',
          build: asset.contains('cuda') ? 'cuda' : 'cpu',
        );
      }
    }
    return null;
  }

  /// Dart 进程真实架构（Rosetta 下 x64 进程选 x64 包恰好正确）。
  static bool get _isArmHost {
    if (Platform.isMacOS || Platform.isLinux) {
      return switch (Abi.current()) {
        Abi.macosArm64 || Abi.linuxArm64 => true,
        _ => false,
      };
    }
    return false;
  }

  static String destNameOf(String url) {
    final clean = url.split('?').first;
    return clean.substring(clean.lastIndexOf('/') + 1);
  }

  void _deleteDirQuiet(Directory dir) {
    try {
      dir.deleteSync(recursive: true);
    } catch (_) {}
  }

  void gotoConfirm() {
    step = MediaImportStep.confirm;
    notifyListeners();
  }

  void selectTier(WhisperModelTier tier) {
    selectedTier = tier;
    // fire-and-forget：选择即持久化，跨会话恢复（checkEnvironment 恢复）
    unawaited(settings.setWhisperModelTier(tier));
    notifyListeners();
  }

  Future<void> startProcessing({
    String language = 'auto',
    required Future<String?> Function(MediaImportResult result) saveNote,
  }) async {
    pendingLanguage = language;
    step = MediaImportStep.processing;
    notifyListeners();
    await confirmAndStart(saveNote: saveNote);
  }

  Future<void> confirmAndStart({
    required Future<String?> Function(MediaImportResult result) saveNote,
    Future<MediaImportResult> Function(MediaImportService, MediaImportRequest)?
    runOverride,
    bool waitCompletion = true,
  }) async {
    step = MediaImportStep.processing;
    phase = null;
    phaseProgress = null;
    errorMessage = null;
    errorDetail = null;
    result = null;
    resultNoteId = null;
    _notify();

    final hasAI = callAI != null;
    final formatter = hasAI ? TranscriptFormatter(callAI!) : null;
    final includeTs = await settings.includeTimestamps();
    final polish = await settings.polishLevel();
    donePolishLevel = polish;
    final service = MediaImportService(
      toolService: toolService,
      modelService: modelService,
      formatter: formatter,
      resolveNoGpu: resolveWhisperNoGpu,
      onGpuFallback: () => unawaited(_markWhisperMetalUnavailable()),
    );
    _activeService = service;

    final request = MediaImportRequest(
      url: sourceKind == ImportSourceKind.url ? urlInput : null,
      localFile: sourceKind == ImportSourceKind.file ? pickedFile : null,
      tier: selectedTier,
      language: pendingLanguage,
      deleteSourceAfter: await settings.deleteSourceAfter(),
    );

    Future<void> doRun() async {
      try {
        final r = runOverride != null
            ? await runOverride(service, request)
            : await service.run(
                request,
                includeTimestamps: includeTs,
                polishLevel: polish,
                onProgress: (p, v) {
                  phase = p;
                  phaseProgress = v;
                  _notify();
                },
              );
        result = r;
        resultNoteId = await saveNote(r);
        step = MediaImportStep.done;
      } on MediaImportException catch (e) {
        if (e.message == MediaImportException.cancelledMessage) {
          reset();
        } else {
          errorMessage = e.message;
          errorDetail = e.detail;
        }
      } catch (e) {
        errorMessage = '转换失败';
        var detail = e.toString();
        // Windows CUDA 构建运行期转录崩溃：追加引导式兜底指引
        //（不自动重装——1.2GB 重下载过重，明确取舍见设计 §三）
        if (e is WhisperException &&
            (await settings.whisperBuild()) == 'cuda') {
          detail += '\n可在设置关闭 GPU 加速后重新下载引擎（CPU 版）';
        }
        errorDetail = detail;
      } finally {
        _activeService = null;
        _notify();
      }
    }

    if (waitCompletion) {
      await doRun();
    } else {
      unawaited(doRun());
    }
  }

  void cancel() {
    _downloadCancel?.cancel();
    _activeService?.cancel();
    _activeInstaller?.kill();
  }

  @override
  void dispose() {
    _updateCheckTimer?.cancel();
    super.dispose();
  }

  void reset() {
    step = MediaImportStep.source;
    urlInput = '';
    pickedFile = null;
    phase = null;
    phaseProgress = null;
    errorMessage = null;
    errorDetail = null;
    result = null;
    resultNoteId = null;
    _notify();
  }
}
