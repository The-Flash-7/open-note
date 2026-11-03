// lib/services/media/media_import_settings.dart
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'media_downloader.dart';
import 'transcript_formatter.dart';
import 'whisper_model_service.dart';

/// 视频转笔记用户偏好（下载源 / 完成后删除源文件）。
class MediaImportSettings {
  static const _kSource = 'media_import_download_source';
  static const _kDelete = 'media_import_delete_source_after';
  static const _kTimestamps = 'media_import_include_timestamps';
  static const _kPolish = 'media_import_polish_level';
  static const _kVerifyCache = 'media_tool_verify_cache';
  static const _kLastUpdateCheckAt = 'media_tool_last_update_check_at';
  static const _kWhisperSourceTag = 'media_tool_whisper_cli_source_tag';
  static const _kUpdateAvailable = 'media_tool_update_available';
  static const _kWhisperGpu = 'media_whisper_gpu';
  static const _kGpuUnavailable = 'media_gpu_unavailable_versions';
  static const _kWhisperBuild = 'media_tool_whisper_build';
  static const _kGpuDetectCache = 'media_gpu_detect_cache';
  static const _kMetalOk = 'media_metal_ok_versions';
  static const _kModelTier = 'media_whisper_model_tier';

  /// 识别模型档（用户手动选择后持久化；null 表示从未选择，回退推荐档）。
  Future<WhisperModelTier?> whisperModelTier() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kModelTier);
    if (raw == null) return null;
    try {
      return WhisperModelTier.values.byName(raw);
    } catch (_) {
      return null; // 枚举演进/脏数据
    }
  }

  Future<void> setWhisperModelTier(WhisperModelTier tier) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kModelTier, tier.name);
  }

  /// 工具验证缓存（kind -> JSON 条目），避免每次检测 spawn 慢二进制。
  Future<Map<String, String>> readVerifyCache() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kVerifyCache);
    if (raw == null) return {};
    try {
      return Map<String, String>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return {};
    }
  }

  Future<void> writeVerifyCache(Map<String, String> cache) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kVerifyCache, jsonEncode(cache));
  }

  Future<MediaDownloadSourceMode> downloadSource() async {
    final prefs = await SharedPreferences.getInstance();
    return MediaDownloadSourceMode.values.firstWhere(
      (m) => m.name == prefs.getString(_kSource),
      orElse: () => MediaDownloadSourceMode.mirror,
    );
  }

  Future<void> setDownloadSource(MediaDownloadSourceMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kSource, mode.name);
  }

  Future<bool> deleteSourceAfter() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kDelete) ?? true;
  }

  Future<void> setDeleteSourceAfter(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kDelete, v);
  }

  /// 笔记中是否保留关键时间戳（默认 false）。
  Future<bool> includeTimestamps() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kTimestamps) ?? false;
  }

  Future<void> setIncludeTimestamps(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kTimestamps, v);
  }

  /// 内容优化强度（默认 structured 结构格式化，按 name 解析兼容未知值）。
  Future<ContentPolishLevel> polishLevel() async {
    final prefs = await SharedPreferences.getInstance();
    return ContentPolishLevel.values.firstWhere(
      (l) => l.name == prefs.getString(_kPolish),
      orElse: () => ContentPolishLevel.structured,
    );
  }

  Future<void> setPolishLevel(ContentPolishLevel level) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kPolish, level.name);
  }

  /// 上次工具新版本检查时间（毫秒时间戳），用于 24h 节流。
  Future<DateTime?> lastUpdateCheckAt() async {
    final prefs = await SharedPreferences.getInstance();
    final ms = prefs.getInt(_kLastUpdateCheckAt);
    if (ms == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(ms);
  }

  Future<void> setLastUpdateCheckAt(DateTime t) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kLastUpdateCheckAt, t.millisecondsSinceEpoch);
  }

  /// whisper-cli 安装包来源 release tag（作为版本比较基线；null 表示无基线）。
  Future<String?> whisperCliSourceTag() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kWhisperSourceTag);
  }

  Future<void> setWhisperCliSourceTag(String? tag) async {
    final prefs = await SharedPreferences.getInstance();
    if (tag == null || tag.isEmpty) {
      await prefs.remove(_kWhisperSourceTag);
    } else {
      await prefs.setString(_kWhisperSourceTag, tag);
    }
  }

  /// 持久化的工具新版本标记（kindName -> release tag），跨重启恢复徽标。
  Future<Map<String, String>> readUpdateAvailable() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kUpdateAvailable);
    if (raw == null) return {};
    try {
      return Map<String, String>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return {};
    }
  }

  Future<void> writeUpdateAvailable(Map<String, String> table) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (table.isEmpty) {
        await prefs.remove(_kUpdateAvailable);
      } else {
        await prefs.setString(_kUpdateAvailable, jsonEncode(table));
      }
    } catch (_) {
      // 持久化失败静默：徽标是辅助信息，不阻塞主流程
    }
  }

  /// GPU 加速总开关（默认开启；无能力环境由 UI 禁灰，能力探测不在此判断）。
  Future<bool> whisperGpu() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kWhisperGpu) ?? true;
  }

  Future<void> setWhisperGpu(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kWhisperGpu, v);
  }

  /// GPU 不可用缓存（键 `平台:标识` → 原因摘要），命中后该平台+版本直接走 CPU。
  Future<Map<String, String>> gpuUnavailableVersions() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kGpuUnavailable);
    if (raw == null) return {};
    try {
      return Map<String, String>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return {};
    }
  }

  /// 追加一条不可用记录（保留既有键，仅覆盖同键值）。
  Future<void> markGpuUnavailable(String key, String reason) async {
    final table = await gpuUnavailableVersions();
    table[key] = reason;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kGpuUnavailable, jsonEncode(table));
  }

  /// 已装 whisper 构建（`cpu` / `cuda`）；null 表示 unknown（不参与切换联动）。
  Future<String?> whisperBuild() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kWhisperBuild);
  }

  Future<void> setWhisperBuild(String build) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kWhisperBuild, build);
  }

  /// GPU 能力探测缓存（含 atMs 时间戳，24h 节流复测）；null 表示从未探测。
  Future<Map<String, dynamic>?> gpuDetectCache() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kGpuDetectCache);
    if (raw == null) return null;
    try {
      return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return null;
    }
  }

  Future<void> setGpuDetectCache(Map<String, dynamic> cache) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kGpuDetectCache, jsonEncode(cache));
  }

  /// Metal 实测可用缓存（版本 → 时间戳字符串）：命中后同版本不再重复探测。
  /// 与黑名单表分离：黑名单语义是「禁 GPU」，OK 表是「已实测可用」。
  Future<Map<String, String>> metalOkVersions() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kMetalOk);
    if (raw == null) return {};
    try {
      return Map<String, String>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return {};
    }
  }

  /// 追加一条 Metal 可用记录（同键覆盖）。
  Future<void> markMetalOk(String version) async {
    final table = await metalOkVersions();
    table[version] = DateTime.now().millisecondsSinceEpoch.toString();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kMetalOk, jsonEncode(table));
  }
}
