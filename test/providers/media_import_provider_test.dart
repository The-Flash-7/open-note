import 'dart:async';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:dio/dio.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_note/providers/media_import_provider.dart';
import 'package:open_note/services/media/gpu_capability.dart';
import 'package:open_note/services/media/media_downloader.dart';
import 'package:open_note/services/media/media_import_service.dart';
import 'package:open_note/services/media/media_import_settings.dart';
import 'package:open_note/services/media/media_tool_service.dart';
import 'package:open_note/services/media/tool_update_service.dart';
import 'package:open_note/services/media/whisper_model_service.dart';
import 'package:open_note/services/media/whisper_runner.dart';
import 'package:open_note/services/media/process_runner.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _ReadyToolService extends MediaToolService {
  int checkCount = 0;
  _ReadyToolService(Future<String> Function() base)
    : super(resolveBaseDir: base);
  @override
  Future<MediaToolStatus> check(MediaToolKind kind,
      {bool forceVerify = false}) async {
    checkCount++;
    return MediaToolStatus(
      kind: kind,
      ready: true,
      path: 'fake',
      version: '1',
      source: MediaToolSource.appManaged,
    );
  }
}

class _GatedCheckToolService extends _ReadyToolService {
  Completer<void>? checkGate;
  _GatedCheckToolService(super.base);

  @override
  Future<MediaToolStatus> check(MediaToolKind kind,
      {bool forceVerify = false}) async {
    if (checkGate != null) await checkGate!.future;
    return super.check(kind);
  }
}

class _AllModelsService extends WhisperModelService {
  _AllModelsService(Future<String> Function() base)
    : super(resolveBaseDir: base);
  @override
  Future<WhisperModelTier> recommendTierForDevice() async =>
      WhisperModelTier.largeV3Turbo;
  @override
  Future<File?> localModelFile(WhisperModelTier tier) async => File('m.bin');
}

class _NoModelsService extends WhisperModelService {
  _NoModelsService(Future<String> Function() base)
      : super(resolveBaseDir: base);
  @override
  Future<File?> localModelFile(WhisperModelTier tier) async => null;
}

/// operationInProgress 恒真（守卫「操作进行中跳过」用）。
class _BusyProbeProvider extends MediaImportProvider {
  _BusyProbeProvider(
      {required super.toolService, required super.modelService});
  @override
  bool get operationInProgress => true;
}

class _SystemToolService extends _ReadyToolService {
  _SystemToolService(super.base);
  @override
  Future<MediaToolStatus> check(MediaToolKind kind,
      {bool forceVerify = false}) async {
    checkCount++;
    return MediaToolStatus(
      kind: kind, ready: true, path: '/usr/bin/${kind.name}',
      version: '1', source: MediaToolSource.systemPath);
  }
}

class _RealAllModelsService extends WhisperModelService {
  _RealAllModelsService(Future<String> Function() base) : super(resolveBaseDir: base);
  @override
  Future<WhisperModelTier> recommendTierForDevice() async => WhisperModelTier.base;
  // localModelFile 用真实实现（基于 modelsDir 文件存在性）
}

/// whisperCli 指向假 cli 脚本（真实 WhisperRunner 进程执行），
/// 其余工具指向不存在路径（.wav 输入经 ProcessException 透传）。
class _WhisperScriptToolService extends MediaToolService {
  final String whisperPath;
  _WhisperScriptToolService(this.whisperPath, Future<String> Function() base)
      : super(resolveBaseDir: base);
  @override
  Future<MediaToolStatus> check(MediaToolKind kind,
      {bool forceVerify = false}) async {
    if (kind == MediaToolKind.whisperCli) {
      return MediaToolStatus(
        kind: kind,
        ready: true,
        path: whisperPath,
        version: '1.9.5',
        source: MediaToolSource.appManaged,
      );
    }
    return MediaToolStatus(
      kind: kind,
      ready: true,
      path: '/nonexistent/${kind.name}',
      version: '1',
      source: MediaToolSource.appManaged,
    );
  }
}

/// 生成假 whisper-cli 脚本：无 `-ng` 时输出 Metal 崩溃特征并退出 1；
/// 带 `-ng` 时写转录 json 并退出 0（每次调用向 [logPath] 追加 ng=0/1）。
Future<File> _writeFakeWhisperCli(Directory dir, String logPath) async {
  final script = File('${dir.path}/whisper-cli-fake.sh');
  await script.writeAsString('''
#!/bin/sh
prefix=""
has_ng=0
prev=""
for a in "\$@"; do
  [ "\$prev" = "-of" ] && prefix="\$a"
  [ "\$a" = "-ng" ] && has_ng=1
  prev="\$a"
done
echo "ng=\$has_ng" >> '$logPath'
if [ "\$has_ng" = "1" ]; then
  echo '{"transcription":[{"offsets":{"from":0,"to":1000},"text":" hi"}],"result":{"language":"en"}}' > "\$prefix.json"
  exit 0
fi
echo "ggml_metal_init: error: cannot run the operation" >&2
exit 1
''');
  await Process.run('chmod', ['+x', script.path]);
  return script;
}

/// 变体：无论 -ng 与否都成功（模拟 Metal 正常版本）。
Future<File> _writeFakeWhisperCliOk(Directory dir, String logPath) async {
  final script = File('${dir.path}/whisper-cli-ok.sh');
  await script.writeAsString('''
#!/bin/sh
prefix=""
prev=""
for a in "\$@"; do
  [ "\$prev" = "-of" ] && prefix="\$a"
  prev="\$a"
done
echo "run" >> '$logPath'
echo '{"transcription":[{"offsets":{"from":0,"to":1000},"text":" hi"}],"result":{"language":"en"}}' > "\$prefix.json"
exit 0
''');
  await Process.run('chmod', ['+x', script.path]);
  return script;
}

/// 变体：Metal 崩且 CPU 重试也失败（无 -ng 与带 -ng 都退出 1）。
Future<File> _writeFakeWhisperCliAlwaysFail(Directory dir, String logPath) async {
  final script = File('${dir.path}/whisper-cli-fail.sh');
  await script.writeAsString('''
#!/bin/sh
echo "invoked" >> '$logPath'
echo "ggml_metal_init: error: cannot run the operation" >&2
exit 1
''');
  await Process.run('chmod', ['+x', script.path]);
  return script;
}

/// 排空 checkEnvironment 完成点自动触发的探测（触发为 unawaited，
/// 同步置位 metalProbeRunning，须等其收尾后再断言/清理）。
Future<void> drainMetalProbe(MediaImportProvider p) async {
  while (p.metalProbeRunning) {
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
}

/// 手术式清除探测落盘缓存（黑名单/OK 表），保留开关等其余预置键。
Future<void> clearMetalProbeCaches() async {
  final sp = await SharedPreferences.getInstance();
  await sp.remove('media_gpu_unavailable_versions');
  await sp.remove('media_metal_ok_versions');
}

/// path_provider mock 到指定目录（confirmAndStart/probe 真实执行 service.run 时用）。
void mockPathProviderTo(Directory dir) {
  const channel = MethodChannel('plugins.flutter.io/path_provider');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (call) async => dir.path);
  addTearDown(() =>
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null));
}

void main() {
  late Directory tmp;
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues(<String, Object>{});
    tmp = Directory.systemTemp.createTempSync('vtn_prov');
  });
  tearDown(() => tmp.deleteSync(recursive: true));

  MediaImportProvider makeProvider() => MediaImportProvider(
    toolService: _ReadyToolService(() async => tmp.path),
    modelService: _AllModelsService(() async => tmp.path),
  );

  test('startForFile -> envCheck 且环境就绪', () async {
    final p = makeProvider();
    await p.startForFile(File('${tmp.path}/a.mp4'));
    expect(p.step, MediaImportStep.envCheck);
    expect(p.toolStatuses[MediaToolKind.ffmpeg]!.ready, isTrue);
    expect(p.toolStatuses[MediaToolKind.ytDlp], isNull);
    expect(p.recommendedTier, WhisperModelTier.largeV3Turbo);
    expect(p.selectedTier, WhisperModelTier.largeV3Turbo);
    expect(p.environmentReady, isTrue);
  });

  test('checkEnvironment 恢复持久化模型档，未存档时回退推荐档', () async {
    // 预置用户手动选择的历史档：恢复应优先于推荐档
    SharedPreferences.setMockInitialValues(
        <String, Object>{'media_whisper_model_tier': 'base'});
    final p = makeProvider();
    await p.checkEnvironment();
    await drainMetalProbe(p);
    expect(p.recommendedTier, WhisperModelTier.largeV3Turbo);
    expect(p.selectedTier, WhisperModelTier.base,
        reason: '已持久化的用户选择应覆盖推荐档');
  });

  test('checkEnvironment 无持久化档 -> selectedTier==recommendedTier', () async {
    final p = makeProvider();
    await p.checkEnvironment();
    await drainMetalProbe(p);
    expect(p.selectedTier, p.recommendedTier);
    expect(p.selectedTier, WhisperModelTier.largeV3Turbo);
  });

  test('selectTier 落盘 media_whisper_model_tier（跨会话恢复依据）', () async {
    final p = makeProvider();
    p.selectTier(WhisperModelTier.base);
    await Future<void>.delayed(const Duration(milliseconds: 5));
    final sp = await SharedPreferences.getInstance();
    expect(sp.getString('media_whisper_model_tier'), 'base');
  });

  test('URL 来源时 yt-dlp 必检', () async {
    final p = makeProvider();
    await p.startForUrl('https://example.com/v');
    expect(p.toolStatuses[MediaToolKind.ytDlp], isNotNull);
  });

  test('confirmAndStart 成功后 done 且回调拿到结果', () async {
    final p = makeProvider();
    await p.startForFile(File('${tmp.path}/a.mp4'));
    MediaImportResult? captured;
    await p.confirmAndStart(
      runOverride: (_, _) async {
        await Future.delayed(const Duration(milliseconds: 10));
        return const MediaImportResult(
          markdown: '# ok',
          title: 'T',
          formattedByAI: true,
        );
      },
      saveNote: (r) async {
        captured = r;
        return 'note-1';
      },
    );
    expect(p.step, MediaImportStep.done);
    expect(p.resultNoteId, 'note-1');
    expect(captured!.markdown, '# ok');
  });

  test('confirmAndStart 失败写入 errorMessage', () async {
    final p = makeProvider();
    await p.startForFile(File('${tmp.path}/a.mp4'));
    await p.confirmAndStart(
      runOverride: (_, _) async =>
          throw const MediaImportException('boom', 'detail'),
      saveNote: (r) async => null,
    );
    expect(p.errorMessage, 'boom');
    expect(p.errorDetail, 'detail');
    expect(p.step, isNot(MediaImportStep.done));
  });

  test('cancel 终止处理', () async {
    final p = makeProvider();
    await p.startForFile(File('${tmp.path}/a.mp4'));
    await p.confirmAndStart(
      runOverride: (_, _) async {
        await Future.delayed(const Duration(seconds: 5));
        throw StateError('should not reach');
      },
      saveNote: (r) async => null,
      waitCompletion: false,
    );
    p.cancel();
    await Future.delayed(const Duration(milliseconds: 50));
    expect(p.step, isNot(MediaImportStep.done));
  });

  group('autoInstallTool（一键自动安装）', () {
    test('成功后重新检测、清除安装中状态、无错误', () async {
      final tools = _ReadyToolService(() async => tmp.path);
      final p = MediaImportProvider(
        toolService: tools,
        modelService: _AllModelsService(() async => tmp.path),
        installerRunner: (exe, args) async =>
            const ProcessRunResult(0, 'Pouring whisper-cpp', ''),
        brewPathResolver: () async => '/fake/brew',
      );
      await p.startForFile(File('${tmp.path}/a.mp4'));
      final before = tools.checkCount;

      await p.autoInstallTool(MediaToolKind.whisperCli);

      expect(tools.checkCount, greaterThan(before));
      expect(p.toolInstalling[MediaToolKind.whisperCli] ?? false, isFalse);
      expect(p.errorMessage, isNull);
      expect(p.toolStatuses[MediaToolKind.whisperCli]!.ready, isTrue);
    });

    test('安装进程非零退出时写入 errorMessage/errorDetail', () async {
      final p = MediaImportProvider(
        toolService: _ReadyToolService(() async => tmp.path),
        modelService: _AllModelsService(() async => tmp.path),
        installerRunner: (exe, args) async =>
            const ProcessRunResult(1, '', 'Error: formula unavailable'),
        brewPathResolver: () async => '/fake/brew',
      );
      await p.startForFile(File('${tmp.path}/a.mp4'));

      await p.autoInstallTool(MediaToolKind.whisperCli);

      expect(p.errorMessage, '自动安装失败');
      expect(p.errorDetail, contains('formula unavailable'));
      expect(p.toolInstalling[MediaToolKind.whisperCli] ?? false, isFalse);
    });

    test('brew 缺失（plan 为 null）时提示并回退指引', () async {
      final p = MediaImportProvider(
        toolService: _ReadyToolService(() async => tmp.path),
        modelService: _AllModelsService(() async => tmp.path),
        installerRunner: (exe, args) async => const ProcessRunResult(0, '', ''),
        brewPathResolver: () async => null,
      );
      await p.startForFile(File('${tmp.path}/a.mp4'));

      await p.autoInstallTool(MediaToolKind.whisperCli);

      expect(p.errorMessage, '无法自动安装');
      expect(p.errorDetail, contains('Homebrew'));
    });
  });

  group('下载进度状态（速度/百分比/ETA）', () {
    test('downloadTool 进度回调更新 toolDownloadStatus', () async {
      final fake = _HangingDownloader();
      final p = MediaImportProvider(
        toolService: _ReadyToolService(() async => tmp.path),
        modelService: _AllModelsService(() async => tmp.path),
        downloader: fake,
      );
      await p.startForFile(File('${tmp.path}/a.mp4'));

      final run = p.downloadTool(MediaToolKind.ytDlp);
      await fake.started.future;
      await Future.delayed(Duration.zero);

      expect(p.toolDownloading[MediaToolKind.ytDlp] ?? false, isTrue);
      final st = p.toolDownloadStatus[MediaToolKind.ytDlp];
      expect(st, isNotNull);
      expect(st!.progress, closeTo(0.5, 1e-9));
      expect(st.speedBps, 0);
      expect(st.etaSeconds, isNull);

      fake.release.complete();
      await run;
      expect(p.toolDownloading[MediaToolKind.ytDlp] ?? false, isFalse);
    });

    test('downloadSelectedModel 进度回调更新 modelDownloadStatus', () async {
      final fake = _HangingDownloader();
      final p = MediaImportProvider(
        toolService: _ReadyToolService(() async => tmp.path),
        modelService: _AllModelsService(() async => tmp.path),
        downloader: fake,
      );
      await p.startForFile(File('${tmp.path}/a.mp4'));
      p.downloadedTiers.clear();

      final run = p.downloadSelectedModel();
      await fake.started.future;
      await Future.delayed(Duration.zero);

      expect(p.modelDownloadStatus.progress, closeTo(0.5, 1e-9));

      fake.release.complete();
      await run;
    });

    test('工具下载完成后进入 安装中 状态，检测完成后退出', () async {
      final tools = _GatedCheckToolService(() async => tmp.path);
      final fake = _HangingDownloader();
      final p = MediaImportProvider(
        toolService: tools,
        modelService: _AllModelsService(() async => tmp.path),
        downloader: fake,
      );
      await p.startForFile(File('${tmp.path}/a.mp4'));
      tools.checkGate = Completer<void>();

      final run = p.downloadTool(MediaToolKind.ytDlp);
      await fake.started.future;
      expect(p.toolFinishing[MediaToolKind.ytDlp] ?? false, isFalse);

      fake.release.complete();
      await Future.delayed(const Duration(milliseconds: 20));
      expect(p.toolDownloading[MediaToolKind.ytDlp] ?? false, isFalse);
      expect(p.toolFinishing[MediaToolKind.ytDlp] ?? false, isTrue);

      // finishing 窗口内重复点击「更新」：守卫直接 return，不二次下载
      unawaited(p.downloadTool(MediaToolKind.ytDlp));
      await Future<void>.delayed(Duration.zero);
      expect(fake.downloadCount, 1);
      expect(p.toolDownloading[MediaToolKind.ytDlp] ?? false, isFalse);
      expect(p.toolFinishing[MediaToolKind.ytDlp] ?? false, isTrue);

      tools.checkGate!.complete();
      await run;
      expect(p.toolFinishing[MediaToolKind.ytDlp] ?? false, isFalse);
      expect(p.toolStatuses[MediaToolKind.ytDlp]!.ready, isTrue);
    });
  });

  group('operationInProgress 统一判定', () {
    test('覆盖 _busy/finishing 窗口，空闲时为 false', () async {
      final tools = _GatedCheckToolService(() async => tmp.path);
      final fake = _HangingDownloader();
      final p = MediaImportProvider(
        toolService: tools,
        modelService: _AllModelsService(() async => tmp.path),
        downloader: fake,
      );
      // _busy 窗口：挂起 checkEnvironment 期间判定为进行中
      tools.checkGate = Completer<void>();
      final start = p.startForFile(File('${tmp.path}/a.mp4'));
      await Future.delayed(const Duration(milliseconds: 20));
      expect(p.operationInProgress, isTrue); // checkEnvironment 进行中(_busy)
      tools.checkGate!.complete();
      await start;
      expect(p.operationInProgress, isFalse);

      // finishing 窗口：下载收尾（gated check 挂起）判定为进行中
      tools.checkGate = Completer<void>();
      final run = p.downloadTool(MediaToolKind.ytDlp);
      await fake.started.future;
      fake.release.complete();
      await Future.delayed(const Duration(milliseconds: 20));
      expect(p.toolFinishing[MediaToolKind.ytDlp] ?? false, isTrue);
      expect(p.operationInProgress, isTrue); // finishing 窗口
      tools.checkGate!.complete();
      await run;
      expect(p.operationInProgress, isFalse);
    });
  });

  group('uninstallPlan 纯函数', () {
    test('mac 有 brew：三种工具都有 brew uninstall 计划', () {
      final ffmpegPlan = MediaImportProvider.uninstallPlan(MediaToolKind.ffmpeg,
          brewPath: '/opt/homebrew/bin/brew', isMac: true, isWin: false);
      expect(ffmpegPlan!.executable, '/opt/homebrew/bin/brew');
      expect(ffmpegPlan.args, ['uninstall', '-q', 'ffmpeg']);
      expect(
          MediaImportProvider.uninstallPlan(MediaToolKind.whisperCli,
              brewPath: '/brew', isMac: true, isWin: false)!.args
              .last, 'whisper.cpp');
    });
    test('mac 无 brew / linux：返回 null', () {
      expect(
          MediaImportProvider.uninstallPlan(MediaToolKind.ffmpeg,
              brewPath: null, isMac: true, isWin: false), isNull);
      expect(
          MediaImportProvider.uninstallPlan(MediaToolKind.ffmpeg,
              brewPath: '/brew', isMac: false, isWin: false), isNull);
    });
    test('windows：仅 whisper-cli 有 winget 计划（需绝对路径）', () {
      const winget = r'C:\Users\a\AppData\Local\Microsoft\WindowsApps\winget.exe';
      final plan = MediaImportProvider.uninstallPlan(MediaToolKind.whisperCli,
          wingetPath: winget, isMac: false, isWin: true);
      expect(plan!.executable, winget);
      expect(plan.args.first, 'uninstall');
      expect(plan.args.join(' '), contains('ggml.whisper-cpp'));
      expect(
          MediaImportProvider.uninstallPlan(MediaToolKind.ffmpeg,
              wingetPath: winget, isMac: false, isWin: true), isNull);
    });
    test('windows：wingetPath 为空 -> null（回退指引）', () {
      expect(
          MediaImportProvider.uninstallPlan(MediaToolKind.whisperCli,
              wingetPath: null, isMac: false, isWin: true), isNull);
      expect(
          MediaImportProvider.uninstallPlan(MediaToolKind.whisperCli,
              wingetPath: '', isMac: false, isWin: true), isNull);
    });
  });

  group('uninstallTool / deleteModel', () {
    test('appManaged：删除 toolDir 内容并重查', () async {
      final tools = _ReadyToolService(() async => tmp.path);
      final p = MediaImportProvider(
          toolService: tools, modelService: _AllModelsService(() async => tmp.path));
      await p.startForFile(File('${tmp.path}/a.mp4'));
      final bin = File(
          '${await tools.toolDir(MediaToolKind.whisperCli)}/${tools.binaryName(MediaToolKind.whisperCli)}');
      await bin.create(recursive: true);
      await p.uninstallTool(MediaToolKind.whisperCli);
      expect(bin.existsSync(), isFalse);
      expect(p.errorMessage, isNull);
      expect(p.toolUninstalling[MediaToolKind.whisperCli] ?? false, isFalse);
    });

    test('uninstallTool 进行中 operationInProgress 为 true', () async {
      final tools = _GatedCheckToolService(() async => tmp.path);
      final p = MediaImportProvider(
        toolService: tools,
        modelService: _AllModelsService(() async => tmp.path),
      );
      await p.startForFile(File('${tmp.path}/a.mp4'));
      tools.checkGate = Completer<void>();

      final run = p.uninstallTool(MediaToolKind.ffmpeg);
      for (var i = 0;
          i < 100 && !(p.toolUninstalling[MediaToolKind.ffmpeg] ?? false);
          i++) {
        await Future.delayed(const Duration(milliseconds: 5));
      }
      expect(p.toolUninstalling[MediaToolKind.ffmpeg] ?? false, isTrue);
      expect(p.operationInProgress, isTrue);

      tools.checkGate!.complete();
      await run;
      expect(p.toolUninstalling[MediaToolKind.ffmpeg] ?? false, isFalse);
      expect(p.operationInProgress, isFalse);
    });

    test('systemPath：mac 调 brew uninstall，失败写 errorMessage', () async {
      String? capturedExe; List<String>? capturedArgs;
      final sysTool = _SystemToolService(() async => tmp.path);
      final p = MediaImportProvider(
        toolService: sysTool,
        modelService: _AllModelsService(() async => tmp.path),
        installerRunner: (exe, args) async {
          capturedExe = exe; capturedArgs = args;
          return const ProcessRunResult(1, '', 'No such keg');
        },
        brewPathResolver: () async => '/fake/brew',
      );
      await p.startForFile(File('${tmp.path}/a.mp4'));
      await p.uninstallTool(MediaToolKind.ffmpeg);
      expect(capturedExe, '/fake/brew');
      expect(capturedArgs, containsAll(['uninstall', '-q', 'ffmpeg']));
      expect(p.errorMessage, '自动卸载失败');
      expect(p.errorDetail, contains('No such keg'));
    });

    test('deleteModel：删除文件并移出 downloadedTiers；转录中阻止', () async {
      final models = _RealAllModelsService(() async => tmp.path);
      final p = MediaImportProvider(
          toolService: _ReadyToolService(() async => tmp.path),
          modelService: models);
      await p.startForFile(File('${tmp.path}/a.mp4'));
      final f = File(
          '${await models.modelsDir()}/${WhisperModelService.infoFor(WhisperModelTier.base).fileName}');
      await f.create(recursive: true);
      p.downloadedTiers.add(WhisperModelTier.base);
      expect(p.downloadedTiers.contains(WhisperModelTier.base), isTrue);
      await p.deleteModel(WhisperModelTier.base);
      expect(f.existsSync(), isFalse);
      expect(p.downloadedTiers.contains(WhisperModelTier.base), isFalse);

      // 转录中守卫
      await f.create(recursive: true);
      p.downloadedTiers.add(WhisperModelTier.base);
      await p.confirmAndStart(
        runOverride: (_, _) async {
          await Future.delayed(const Duration(seconds: 5));
          throw StateError('unreachable');
        },
        saveNote: (r) async => null,
        waitCompletion: false,
      );
      await p.deleteModel(WhisperModelTier.base);
      expect(p.errorMessage, '转录进行中，无法删除模型');
      expect(f.existsSync(), isTrue);
      p.cancel();
    });
  });

  group('downloadTool 磁盘预检分级', () {
    test('diskNeedBytes：whisperCli 2.5GB，其余 200MB', () {
      expect(MediaImportProvider.diskNeedBytes(MediaToolKind.whisperCli),
          2560 * 1024 * 1024);
      expect(MediaImportProvider.diskNeedBytes(MediaToolKind.ffmpeg),
          200 * 1024 * 1024);
      expect(MediaImportProvider.diskNeedBytes(MediaToolKind.ytDlp),
          200 * 1024 * 1024);
    });

    test('whisperCli 1GB 可用被拦截（文案 2560 MB）；yt-dlp 维持 200MB 拦截线', () async {
      final fake = _LowDiskDownloader()..freeBytes = 1024 * 1024 * 1024;
      final p = MediaImportProvider(
        toolService: _ReadyToolService(() async => tmp.path),
        modelService: _AllModelsService(() async => tmp.path),
        downloader: fake,
      );
      await p.startForFile(File('${tmp.path}/a.mp4'));
      p.toolStatuses[MediaToolKind.whisperCli] = const MediaToolStatus.missing(
          MediaToolKind.whisperCli);
      await p.downloadTool(MediaToolKind.whisperCli);
      expect(p.errorMessage, '磁盘空间不足');
      expect(p.errorDetail, contains('需要约 2560 MB'));
      expect(fake.downloadCalls, 0, reason: '空间不足不应发起下载');

      fake.freeBytes = 150 * 1024 * 1024;
      p.toolStatuses[MediaToolKind.ytDlp] = const MediaToolStatus.missing(
          MediaToolKind.ytDlp);
      await p.downloadTool(MediaToolKind.ytDlp);
      expect(p.errorMessage, '磁盘空间不足');
      expect(p.errorDetail, contains('需要约 200 MB'));
      expect(fake.downloadCalls, 0);
    });
  });

  group('ffmpeg 单文件下载 URL 回归', () {
    test('downloadTool(ffmpeg) 使用 ffmpeg-static 而非 yt-dlp URL', () async {
      final fake = _CapturingDownloader();
      final p = MediaImportProvider(
        toolService: _ReadyToolService(() async => tmp.path),
        modelService: _AllModelsService(() async => tmp.path),
        downloader: fake,
      );
      await p.startForFile(File('${tmp.path}/a.mp4'));
      p.toolStatuses[MediaToolKind.ffmpeg] = const MediaToolStatus.missing(
          MediaToolKind.ffmpeg);
      await p.downloadTool(MediaToolKind.ffmpeg);
      expect(fake.lastUrl, contains('/ffmpeg-static/releases/'));
      expect(fake.lastUrl, isNot(contains('/yt-dlp/')));
    });

    test('downloadTool(ffmpeg) 更新时用检测到的具体 tag 下载并清除徽标', () async {
      final fake = _CapturingDownloader();
      final p = MediaImportProvider(
        toolService: _ReadyToolService(() async => tmp.path),
        modelService: _AllModelsService(() async => tmp.path),
        downloader: fake,
      );
      await p.startForFile(File('${tmp.path}/a.mp4'));
      p.toolStatuses[MediaToolKind.ffmpeg] = const MediaToolStatus.missing(
          MediaToolKind.ffmpeg);
      p.updateAvailableVersion[MediaToolKind.ffmpeg] = 'b6.1.1';

      await p.downloadTool(MediaToolKind.ffmpeg);

      expect(fake.lastUrl, contains('/releases/download/b6.1.1/'));
      expect(fake.lastUrl, isNot(contains('/releases/latest/')));
      expect(p.updateAvailableVersion[MediaToolKind.ffmpeg], isNull);
    });
  });
  group('ffmpeg 装前可执行验证（坏资产防护）', () {
    List<String> ranExe = [];
    List<List<String>> ranArgs = [];

    MediaImportProvider makeVerifyProvider({
      required int exitCode,
      _ReadyToolService? tools,
    }) {
      ranExe = [];
      ranArgs = [];
      return MediaImportProvider(
        toolService: tools ?? _ReadyToolService(() async => tmp.path),
        modelService: _AllModelsService(() async => tmp.path),
        downloader: _WritingDownloader(),
        installerRunner: (exe, args) async {
          ranExe.add(exe);
          ranArgs.add(args);
          return ProcessRunResult(exitCode, 'ffmpeg version n6.0', '');
        },
      );
    }

    Future<File> destPath(MediaToolService tools, MediaToolKind kind) async =>
        File('${await tools.toolDir(kind)}/${tools.binaryName(kind)}');

    test('坏资产（exitCode 1）：旧文件不被替换，走错误路径并清理临时文件', () async {
      final tools = _ReadyToolService(() async => tmp.path);
      final dest = await destPath(tools, MediaToolKind.ffmpeg);
      await dest.create(recursive: true);
      await dest.writeAsString('OLD');
      final p = makeVerifyProvider(exitCode: 1, tools: tools);
      await p.startForFile(File('${tmp.path}/a.mp4'));

      await p.downloadTool(MediaToolKind.ffmpeg);

      expect(ranExe, hasLength(1));
      expect(ranExe.single, isNot(dest.path)); // 验证发生在替换前的临时文件上
      expect(ranArgs.single, ['-version']);
      expect(dest.readAsStringSync(), 'OLD'); // 旧文件未被替换
      expect(p.errorMessage, '下载的引擎文件无法运行，已保留当前版本');
      expect(File('${dest.path}.staging').existsSync(), isFalse); // 临时文件已清理
      expect(p.toolDownloading[MediaToolKind.ffmpeg] ?? false, isFalse);
      expect(p.toolFinishing[MediaToolKind.ffmpeg] ?? false, isFalse);
    });

    test('好资产（exitCode 0）：替换旧文件且无错误', () async {
      final tools = _ReadyToolService(() async => tmp.path);
      final dest = await destPath(tools, MediaToolKind.ffmpeg);
      await dest.create(recursive: true);
      await dest.writeAsString('OLD');
      final p = makeVerifyProvider(exitCode: 0, tools: tools);
      await p.startForFile(File('${tmp.path}/a.mp4'));

      await p.downloadTool(MediaToolKind.ffmpeg);

      expect(dest.readAsStringSync(), 'NEW-BINARY');
      expect(p.errorMessage, isNull);
      expect(File('${dest.path}.staging').existsSync(), isFalse);
    });

    test('yt-dlp 不做装前可执行验证', () async {
      final tools = _ReadyToolService(() async => tmp.path);
      final dest = await destPath(tools, MediaToolKind.ytDlp);
      final p = makeVerifyProvider(exitCode: 1, tools: tools);
      await p.startForFile(File('${tmp.path}/a.mp4'));

      await p.downloadTool(MediaToolKind.ytDlp);

      expect(ranExe, isEmpty); // 未执行 -version 探测
      expect(dest.readAsStringSync(), 'NEW-BINARY'); // 直接落位
      expect(File('${dest.path}.staging').existsSync(), isFalse);
      expect(p.errorMessage, isNull);
    });
  });

  group('装后版本比对（更新未生效检测）', () {
    test('更新后版本未变化：清除更新标记并给出非阻断提示', () async {
      // _ReadyToolService 恒返回 version '1' → 模拟镜像内容未变化
      final p = MediaImportProvider(
        toolService: _ReadyToolService(() async => tmp.path),
        modelService: _AllModelsService(() async => tmp.path),
        downloader: _WritingDownloader(),
        installerRunner: (exe, args) async => const ProcessRunResult(0, '', ''),
      );
      await p.startForFile(File('${tmp.path}/a.mp4'));
      p.updateAvailableVersion[MediaToolKind.ffmpeg] = 'b6.1.1';

      await p.downloadTool(MediaToolKind.ffmpeg);

      expect(p.updateAvailableVersion[MediaToolKind.ffmpeg], isNull);
      expect(await MediaImportSettings().readUpdateAvailable(), isEmpty);
      expect(p.toolHints[MediaToolKind.ffmpeg], contains('更新未生效'));
      expect(p.errorMessage, isNull); // 非阻断：无 ErrorBanner 错误
    });

    test('更新后版本变化：无提示，标记保持清除', () async {
      final p = MediaImportProvider(
        toolService: _VersionShiftToolService(() async => tmp.path),
        modelService: _AllModelsService(() async => tmp.path),
        downloader: _WritingDownloader(),
        installerRunner: (exe, args) async => const ProcessRunResult(0, '', ''),
      );
      await p.startForFile(File('${tmp.path}/a.mp4'));
      p.updateAvailableVersion[MediaToolKind.ffmpeg] = 'b6.1';

      await p.downloadTool(MediaToolKind.ffmpeg);

      expect(p.updateAvailableVersion[MediaToolKind.ffmpeg], isNull);
      expect(p.toolHints[MediaToolKind.ffmpeg], isNull);
      expect(p.errorMessage, isNull);
    });

    test('非更新场景（首次安装）：不产生更新未生效提示', () async {
      final p = MediaImportProvider(
        toolService: _ReadyToolService(() async => tmp.path),
        modelService: _AllModelsService(() async => tmp.path),
        downloader: _WritingDownloader(),
        installerRunner: (exe, args) async => const ProcessRunResult(0, '', ''),
      );
      await p.startForFile(File('${tmp.path}/a.mp4'));
      p.toolStatuses[MediaToolKind.ffmpeg] =
          const MediaToolStatus.missing(MediaToolKind.ffmpeg);

      await p.downloadTool(MediaToolKind.ffmpeg);

      expect(p.toolHints[MediaToolKind.ffmpeg], isNull);
      expect(p.errorMessage, isNull);
    });
  });

  group('工具静默新版本检查（checkToolUpdates）', () {
    MediaImportProvider makeUpdateProvider(_CountingFetcher fetcher) =>
        MediaImportProvider(
          toolService: _MixedSourceToolService(() async => tmp.path),
          modelService: _AllModelsService(() async => tmp.path),
          updateService: ToolUpdateService(fetcher: fetcher.call),
          clock: () => DateTime(2026, 1, 1, 12),
        );

    test('只检查 ready+appManaged 工具，systemPath/无状态跳过', () async {
      final fetcher = _CountingFetcher('b7.0');
      final p = makeUpdateProvider(fetcher);
      await p.startForFile(File('${tmp.path}/a.mp4'));

      await p.checkToolUpdates();

      expect(fetcher.calls, 1);
      expect(fetcher.urls.single,
          contains('repos/eugeneware/ffmpeg-static/releases/latest'));
    });

    test('发现新版本写入 updateAvailableVersion 并复位 checking', () async {
      final fetcher = _CountingFetcher('b7.0');
      final p = makeUpdateProvider(fetcher);
      await p.startForFile(File('${tmp.path}/a.mp4'));

      await p.checkToolUpdates();

      expect(p.updateAvailableVersion[MediaToolKind.ffmpeg], 'b7.0');
      expect(p.updateChecking[MediaToolKind.ffmpeg] ?? false, isFalse);
    });

    test('24h 内二次调用被节流跳过（fetch 次数不变）', () async {
      final fetcher = _CountingFetcher('b7.0');
      final p = makeUpdateProvider(fetcher);
      await p.startForFile(File('${tmp.path}/a.mp4'));

      await p.checkToolUpdates();
      expect(fetcher.calls, 1);
      await p.checkToolUpdates();
      expect(fetcher.calls, 1);
    });

    test('本地版本等于远端时不写入更新', () async {
      final fetcher = _CountingFetcher('b6.0'); // normalize 后 == 本地 6.0
      final p = makeUpdateProvider(fetcher);
      await p.startForFile(File('${tmp.path}/a.mp4'));

      await p.checkToolUpdates();

      expect(p.updateAvailableVersion[MediaToolKind.ffmpeg], isNull);
    });

    test('下载进行中时检查跳过该 kind：fetch 返回也不写回更新徽标', () async {
      final fetcher = _GatedFetcher();
      final fake = _HangingDownloader();
      final p = MediaImportProvider(
        toolService: _MixedSourceToolService(() async => tmp.path),
        modelService: _AllModelsService(() async => tmp.path),
        downloader: fake,
        updateService: ToolUpdateService(fetcher: fetcher.call),
        clock: () => DateTime(2026, 1, 1, 12),
      );
      await p.startForFile(File('${tmp.path}/a.mp4'));

      final run = p.downloadTool(MediaToolKind.ffmpeg);
      await fake.started.future;
      expect(p.toolDownloading[MediaToolKind.ffmpeg] ?? false, isTrue);

      final check = p.checkToolUpdates();
      fetcher.gate.complete();
      await check;

      fake.release.complete();
      await run;

      expect(p.updateAvailableVersion[MediaToolKind.ffmpeg], isNull);
    });

    test('全部被跳过（systemPath）时：不 fetch 也不写 24h 节流时间戳', () async {
      final fetcher = _CountingFetcher('b7.0');
      final p = MediaImportProvider(
        toolService: _SystemToolService(() async => tmp.path),
        modelService: _AllModelsService(() async => tmp.path),
        updateService: ToolUpdateService(fetcher: fetcher.call),
        clock: () => DateTime(2026, 1, 1, 12),
      );
      await p.startForFile(File('${tmp.path}/a.mp4'));

      await p.checkToolUpdates();

      expect(fetcher.calls, 0);
      expect(await MediaImportSettings().lastUpdateCheckAt(), isNull);
    });

    test('环境未检测（toolStatuses 空）时定时器顺延且不空转，填充后下一轮才检查',
        () async {
      final fetcher = _CountingFetcher('b7.0');
      final p = makeUpdateProvider(fetcher);
      await SharedPreferences.getInstance(); // 预热 mock 存储（纯微任务，FakeAsync 内可完成）

      FakeAsync().run((async) {
        // 1) toolStatuses 为空（splash 只调度未检测）：到点不 fetch；
        //    顺延 60s 到点仍空 → 再顺延，fetch 恒为 0，也不写节流时间戳
        p.scheduleUpdateCheck(delay: const Duration(milliseconds: 50));
        async.elapse(const Duration(seconds: 1));
        expect(fetcher.calls, 0);
        async.elapse(const Duration(seconds: 61));
        expect(fetcher.calls, 0);

        // 2) 用户打开媒体 UI：startForFile 填充状态（fake 服务纯微任务可完成）
        //    （不再 await 其 future——FakeAsync 区内创建的 future 出区后 await 会悬死）
        unawaited(p.startForFile(File('${tmp.path}/a.mp4')));
        async.elapse(const Duration(seconds: 1));
        expect(p.toolStatuses[MediaToolKind.ffmpeg], isNotNull);

        // 3) 重新调度：到点才真正执行检查
        p.scheduleUpdateCheck(delay: const Duration(milliseconds: 50));
        async.elapse(const Duration(seconds: 1));
        expect(fetcher.calls, 1);
        expect(p.updateAvailableVersion[MediaToolKind.ffmpeg], 'b7.0');
      });
    });

    test('定时器到点时操作进行中：顺延重试而非永久跳过，空闲后执行检查', () async {
      final fetcher = _CountingFetcher('b7.0');
      final p = makeUpdateProvider(fetcher);
      await p.startForFile(File('${tmp.path}/a.mp4'));
      await SharedPreferences.getInstance(); // 预热 mock 存储（纯微任务，FakeAsync 内可完成）

      FakeAsync().run((async) {
        p.modelDownloading = true; // 模拟启动 15 秒内开始的长操作（如模型下载）
        p.scheduleUpdateCheck(delay: const Duration(milliseconds: 50));

        async.elapse(const Duration(seconds: 1));
        expect(fetcher.calls, 0); // 忙：本轮跳过

        p.modelDownloading = false; // 操作结束
        async.elapse(const Duration(seconds: 61)); // 顺延的 60s 重试到点
        expect(fetcher.calls, greaterThanOrEqualTo(1)); // 重试确实执行了检查
        expect(p.updateAvailableVersion[MediaToolKind.ffmpeg], 'b7.0');
      });
    });
  });

  group('环境就绪跳过检测步骤', () {
    void seedAllReady(MediaImportProvider p, {bool withModel = true}) {
      for (final k in MediaToolKind.values) {
        p.toolStatuses[k] = MediaToolStatus(
          kind: k,
          ready: true,
          path: 'fake',
          version: '1',
          source: MediaToolSource.appManaged,
        );
      }
      if (withModel) p.downloadedTiers.add(p.selectedTier);
    }

    test('工具与模型全就绪：startForUrl 直达 confirm 并后台刷新检测', () async {
      final tools = _ReadyToolService(() async => tmp.path);
      final p = MediaImportProvider(
        toolService: tools,
        modelService: _AllModelsService(() async => tmp.path),
      );
      seedAllReady(p);
      final before = tools.checkCount;

      await p.startForUrl('https://example.com/v');

      expect(p.step, MediaImportStep.confirm);
      // 后台静默刷新确实执行了检测（验证缓存使其廉价）
      expect(tools.checkCount, greaterThan(before));
    });

    test('工具就绪：startForFile 直达 confirm', () async {
      final p = makeProvider();
      seedAllReady(p);

      await p.startForFile(File('${tmp.path}/a.mp4'));

      expect(p.step, MediaImportStep.confirm);
    });

    test('缺模型：仍走 envCheck 完整检测', () async {
      final p = makeProvider();
      seedAllReady(p, withModel: false);

      await p.startForFile(File('${tmp.path}/a.mp4'));

      expect(p.step, MediaImportStep.envCheck);
      expect(p.environmentReady, isTrue); // 检测完成后模型就绪
    });
  });

  group('更新标记持久化（跨重启恢复 + 落盘）', () {
    MediaImportProvider makeUpdateProvider(_CountingFetcher fetcher) =>
        MediaImportProvider(
          toolService: _MixedSourceToolService(() async => tmp.path),
          modelService: _AllModelsService(() async => tmp.path),
          updateService: ToolUpdateService(fetcher: fetcher.call),
          clock: () => DateTime(2026, 1, 1, 12),
        );

    Future<void> flushRestore() async {
      await Future<void>.delayed(const Duration(milliseconds: 30));
    }

    test('构造后从持久化恢复更新标记，非法 kind 跳过', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'media_tool_update_available': '{"ffmpeg":"b7.0","bogus":"x"}',
      });
      final p = makeUpdateProvider(_CountingFetcher('b7.0'));
      await flushRestore();
      expect(p.updateAvailableVersion[MediaToolKind.ffmpeg], 'b7.0');
      expect(p.updateAvailableVersion.length, 1);
    });

    test('checkToolUpdates 发现更新：内存与持久化表都写入', () async {
      final fetcher = _CountingFetcher('b7.0');
      final p = makeUpdateProvider(fetcher);
      await p.startForFile(File('${tmp.path}/a.mp4'));

      await p.checkToolUpdates();

      expect(p.updateAvailableVersion[MediaToolKind.ffmpeg], 'b7.0');
      expect(await MediaImportSettings().readUpdateAvailable(),
          {'ffmpeg': 'b7.0'});
    });

    test('checkToolUpdates 无更新：清除该 kind 的持久化标记', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'media_tool_update_available': '{"ffmpeg":"b7.0"}',
      });
      final fetcher = _CountingFetcher('b6.0'); // == 本地版本 → 无更新
      final p = makeUpdateProvider(fetcher);
      await flushRestore();
      await p.startForFile(File('${tmp.path}/a.mp4'));

      await p.checkToolUpdates();

      expect(p.updateAvailableVersion[MediaToolKind.ffmpeg], isNull);
      expect(await MediaImportSettings().readUpdateAvailable(), isEmpty);
    });

    test('downloadTool 成功后从持久化表移除该 kind', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'media_tool_update_available': '{"ffmpeg":"b6.1.1"}',
      });
      final p = MediaImportProvider(
        toolService: _ReadyToolService(() async => tmp.path),
        modelService: _AllModelsService(() async => tmp.path),
        downloader: _CapturingDownloader(),
        // 装前可执行验证需通过：fake runner 模拟可运行资产
        installerRunner: (exe, args) async => const ProcessRunResult(0, '', ''),
      );
      await p.startForFile(File('${tmp.path}/a.mp4'));
      await flushRestore();
      expect(p.updateAvailableVersion[MediaToolKind.ffmpeg], 'b6.1.1');

      await p.downloadTool(MediaToolKind.ffmpeg);

      expect(p.errorMessage, isNull);
      expect(p.updateAvailableVersion[MediaToolKind.ffmpeg], isNull);
      expect(await MediaImportSettings().readUpdateAvailable(), isEmpty);
    });

    test('uninstallTool 成功后从持久化表移除该 kind', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'media_tool_update_available': '{"whisperCli":"b1.2.3"}',
      });
      final tools = _ReadyToolService(() async => tmp.path);
      final p = MediaImportProvider(
        toolService: tools,
        modelService: _AllModelsService(() async => tmp.path),
      );
      await p.startForFile(File('${tmp.path}/a.mp4'));
      await flushRestore();
      final bin = File(
          '${await tools.toolDir(MediaToolKind.whisperCli)}/${tools.binaryName(MediaToolKind.whisperCli)}');
      await bin.create(recursive: true);

      await p.uninstallTool(MediaToolKind.whisperCli);

      expect(p.errorMessage, isNull);
      expect(p.updateAvailableVersion[MediaToolKind.whisperCli], isNull);
      expect(await MediaImportSettings().readUpdateAvailable(), isEmpty);
    });
  });

  group('模型下载失败手动兜底（buildModelManualHint）', () {
    test('组装手动下载提示：含文件名保持说明与模型目录', () {
      final hint = MediaImportProvider.buildModelManualHint(
        fileName: 'ggml-medium.bin',
        modelsDir: '/tmp/models',
      );
      expect(hint, contains('手动下载'));
      expect(hint, contains('ggml-medium.bin'));
      expect(hint, contains('重新检测'));
      expect(hint, contains('模型目录：/tmp/models'));
    });
  });

  group('whisper GPU 安装层纯函数', () {
    test('expectedWhisperBuild：useGpu 映射 cuda/cpu', () {
      expect(MediaImportProvider.expectedWhisperBuild(useGpu: true), 'cuda');
      expect(MediaImportProvider.expectedWhisperBuild(useGpu: false), 'cpu');
    });

    test('reinstallNeeded：stored 非空且不等 expected 才重装（unknown 不重装）',
        () {
      expect(MediaImportProvider.reinstallNeeded('cuda', 'cpu'), isTrue);
      expect(MediaImportProvider.reinstallNeeded('cpu', 'cuda'), isTrue);
      expect(MediaImportProvider.reinstallNeeded('cpu', 'cpu'), isFalse);
      expect(MediaImportProvider.reinstallNeeded(null, 'cpu'), isFalse);
      expect(MediaImportProvider.reinstallNeeded(null, 'cuda'), isFalse);
    });
  });

  group('whisperNoGpuDecision 运行层纯函数（开关∧能力∧黑名单）', () {
    bool decision({
      required bool gpuEnabled,
      required GpuKind kind,
      String? installedVersion,
      Set<String> unavailableKeys = const {},
    }) =>
        MediaImportProvider.whisperNoGpuDecision(
          gpuEnabled: gpuEnabled,
          kind: kind,
          installedVersion: installedVersion,
          unavailableKeys: unavailableKeys,
        );

    test('开关关闭 → 禁 GPU（-ng）', () {
      expect(
          decision(gpuEnabled: false, kind: GpuKind.metal, installedVersion: '1.9.5'),
          isTrue);
    });

    test('Metal + 版本已知 + 黑名单未命中 → 允许 GPU', () {
      expect(
          decision(gpuEnabled: true, kind: GpuKind.metal, installedVersion: '1.9.5'),
          isFalse);
    });

    test('Metal + 黑名单命中 mac:版本 → 禁 GPU（同版本直接 CPU 启动）', () {
      expect(
          decision(
              gpuEnabled: true,
              kind: GpuKind.metal,
              installedVersion: '1.9.5',
              unavailableKeys: const {'mac:1.9.5'}),
          isTrue);
      // 其他版本不受影响（升级后键自然不命中）
      expect(
          decision(
              gpuEnabled: true,
              kind: GpuKind.metal,
              installedVersion: '1.9.6',
              unavailableKeys: const {'mac:1.9.5'}),
          isFalse);
    });

    test('Metal + 版本未知（null/ready 旧缓存）→ 允许 GPU（Metal 崩溃兜底仍在）',
        () {
      expect(
          decision(gpuEnabled: true, kind: GpuKind.metal, installedVersion: null),
          isFalse);
      expect(
          decision(
              gpuEnabled: true,
              kind: GpuKind.metal,
              installedVersion: 'ready'),
          isFalse);
    });

    test('CUDA 能力（Windows）→ 运行层不禁 GPU（构建已由安装层选定）', () {
      expect(
          decision(gpuEnabled: true, kind: GpuKind.cuda, installedVersion: '1.9.5'),
          isFalse);
    });

    test('无 GPU 能力 → 禁 GPU', () {
      expect(
          decision(gpuEnabled: true, kind: GpuKind.none, installedVersion: '1.9.5'),
          isTrue);
    });
  });

  group('pickWhisperDownloadUrl（GPU 选包与黑名单）', () {
    const releases = [
      {
        'tag_name': 'b5454',
        'assets': [
          {'name': 'whisper-bin-x64.zip'},
          {'name': 'whisper-bin-win-cuda-12.4.0-x64.zip'},
        ],
      },
    ];

    test('preferCuda=true → cuda 包优先且 build 记录 cuda', () {
      final picked = MediaImportProvider.pickWhisperDownloadUrl(
        releases,
        preferCuda: true,
        gpuUnavailableKeys: const {},
        isWindows: true,
        isMac: false,
        isArm: false,
      );
      expect(picked!.url, contains('b5454/whisper-bin-win-cuda-12.4.0-x64.zip'));
      expect(picked.build, 'cuda');
    });

    test('黑名单含 win:tag → 同 release 强制 CPU 选包', () {
      final picked = MediaImportProvider.pickWhisperDownloadUrl(
        releases,
        preferCuda: true,
        gpuUnavailableKeys: const {'win:b5454'},
        isWindows: true,
        isMac: false,
        isArm: false,
      );
      expect(picked!.url, contains('b5454/whisper-bin-x64.zip'));
      expect(picked.build, 'cpu');
    });

    test('preferCuda=false → 纯 CPU 包', () {
      final picked = MediaImportProvider.pickWhisperDownloadUrl(
        releases,
        preferCuda: false,
        gpuUnavailableKeys: const {},
        isWindows: true,
        isMac: false,
        isArm: false,
      );
      expect(picked!.build, 'cpu');
      expect(picked.url, contains('whisper-bin-x64.zip'));
    });
  });

  group('setWhisperGpuEnabled 切换联动', () {
    _SpyDownloadProvider makeSpy({
      Map<String, Object> prefs = const {},
      bool? isWindowsOverride,
    }) {
      if (prefs.isNotEmpty) {
        SharedPreferences.setMockInitialValues(prefs);
      }
      return _SpyDownloadProvider(
        toolService: _ReadyToolService(() async => tmp.path),
        modelService: _AllModelsService(() async => tmp.path),
        isWindowsOverride: isWindowsOverride,
      );
    }

    test('appManaged 且已装 cuda：关 GPU 触发重装并提示正在切换（Windows 流）',
        () async {
      final p = makeSpy(
        prefs: {'media_tool_whisper_build': 'cuda'},
        isWindowsOverride: true,
      )..installedBuildOnDownload = 'cpu';
      await p.startForFile(File('${tmp.path}/a.mp4'));

      await p.setWhisperGpuEnabled(false);

      expect(p.downloadCalls, 1, reason: 'cuda→cpu 构建不匹配应重装');
      expect(p.toolHints[MediaToolKind.whisperCli], contains('正在切换'));
      expect(await MediaImportSettings().whisperGpu(), isFalse);
    });

    test('appManaged 且已装 cpu：关 GPU 不重装', () async {
      final p = makeSpy(prefs: {'media_tool_whisper_build': 'cpu'});
      await p.startForFile(File('${tmp.path}/a.mp4'));

      await p.setWhisperGpuEnabled(false);

      expect(p.downloadCalls, 0);
      expect(p.toolHints[MediaToolKind.whisperCli], isNull);
    });

    test('appManaged 且已装 cpu：开 GPU 触发重装（Windows 流）', () async {
      final p = makeSpy(
        prefs: {'media_tool_whisper_build': 'cpu'},
        isWindowsOverride: true,
      )..installedBuildOnDownload = 'cuda';
      await p.startForFile(File('${tmp.path}/a.mp4'));

      await p.setWhisperGpuEnabled(true);

      expect(p.downloadCalls, 1, reason: 'cpu→cuda 构建不匹配应重装');
      expect(p.toolHints[MediaToolKind.whisperCli], contains('正在切换'));
    });

    test('mac 流（非 Windows）：开 GPU 不触发重装（Metal 内置，仅运行层生效）',
        () async {
      final p = makeSpy(
        prefs: {'media_tool_whisper_build': 'cpu'},
        isWindowsOverride: false,
      );
      await p.startForFile(File('${tmp.path}/a.mp4'));

      await p.setWhisperGpuEnabled(true);

      expect(p.downloadCalls, 0, reason: 'Mac 无包选择：开 GPU 不应重装');
      expect(p.toolHints[MediaToolKind.whisperCli], isNull);
      expect(await MediaImportSettings().whisperGpu(), isTrue);
    });

    test('切换触发下载且下载内部已回退 CPU：保留回退文案不覆写「正在切换」',
        () async {
      // 真 downloadTool：CUDA 资产装后校验失败 → 内部自动回退 CPU（含回退提示）
      final tools = _FlakyVerifyToolService(() async => tmp.path, 1);
      final fake = _ZipWritingDownloader('whisper-cli');
      var resolverCalls = 0;
      SharedPreferences.setMockInitialValues(
          <String, Object>{'media_tool_whisper_build': 'cpu'});
      final p = MediaImportProvider(
        toolService: tools,
        modelService: _AllModelsService(() async => tmp.path),
        downloader: fake,
        whisperAssetResolver: () async {
          resolverCalls++;
          return resolverCalls == 1
              ? (
                  url: 'https://github.com/ggml-org/whisper.cpp/releases/'
                      'download/b5454/whisper-bin-win-cuda-12.4.0-x64.zip',
                  build: 'cuda',
                )
              : (
                  url: 'https://github.com/ggml-org/whisper.cpp/releases/'
                      'download/b5454/whisper-bin-x64.zip',
                  build: 'cpu',
                );
        },
        isWindowsOverride: true,
      );
      await p.startForFile(File('${tmp.path}/a.mp4'));

      await p.setWhisperGpuEnabled(true);

      expect(fake.downloadCalls, 2, reason: 'CUDA 尝试 + CPU 回退各一次');
      expect(p.toolHints[MediaToolKind.whisperCli], contains('已回退 CPU'));
      expect(p.toolHints[MediaToolKind.whisperCli],
          isNot(contains('正在切换')));
      expect(await MediaImportSettings().whisperBuild(), 'cpu');
    });

    test('构建记录 unknown（无记录）→ 不重装且提示重新下载引擎后生效', () async {
      final p = makeSpy();
      await p.startForFile(File('${tmp.path}/a.mp4'));

      await p.setWhisperGpuEnabled(false);

      expect(p.downloadCalls, 0);
      expect(p.toolHints[MediaToolKind.whisperCli], contains('重新下载引擎'));
    });

    test('systemPath 来源 → 仅写设置不联动', () async {
      final p = _SpyDownloadProvider(
        toolService: _SystemToolService(() async => tmp.path),
        modelService: _AllModelsService(() async => tmp.path),
      );
      await p.startForFile(File('${tmp.path}/a.mp4'));

      await p.setWhisperGpuEnabled(false);

      expect(p.downloadCalls, 0);
      expect(p.toolHints[MediaToolKind.whisperCli], isNull);
      expect(await MediaImportSettings().whisperGpu(), isFalse);
    });
  });

  group('CUDA 包装后校验失败自动回退 CPU', () {
    test('cuda 构建校验失败 → 写黑名单 + 单次重下 CPU + 回退提示', () async {
      final tools = _FlakyVerifyToolService(() async => tmp.path, 1);
      final fake = _ZipWritingDownloader('whisper-cli');
      var resolverCalls = 0;
      final p = MediaImportProvider(
        toolService: tools,
        modelService: _AllModelsService(() async => tmp.path),
        downloader: fake,
        whisperAssetResolver: () async {
          resolverCalls++;
          return resolverCalls == 1
              ? (
                  url: 'https://github.com/ggml-org/whisper.cpp/releases/'
                      'download/b5454/whisper-bin-win-cuda-12.4.0-x64.zip',
                  build: 'cuda',
                )
              : (
                  url: 'https://github.com/ggml-org/whisper.cpp/releases/'
                      'download/b5454/whisper-bin-x64.zip',
                  build: 'cpu',
                );
        },
        isWindowsOverride: true,
      );
      await p.startForFile(File('${tmp.path}/a.mp4'));
      p.toolStatuses[MediaToolKind.whisperCli] =
          const MediaToolStatus.missing(MediaToolKind.whisperCli);

      await p.downloadTool(MediaToolKind.whisperCli);

      expect(fake.downloadCalls, 2, reason: 'CUDA 尝试 + CPU 回退各一次');
      expect(resolverCalls, 2);
      expect((await MediaImportSettings().gpuUnavailableVersions()).keys,
          contains('win:b5454'));
      expect(
          p.toolHints[MediaToolKind.whisperCli], contains('已回退 CPU'));
      expect(p.toolStatuses[MediaToolKind.whisperCli]!.ready, isTrue);
      expect(await MediaImportSettings().whisperBuild(), 'cpu');
      expect(p.errorMessage, isNull);
    });

    test('cuda 构建校验通过 → 记录 cuda 且不回退', () async {
      final fake = _ZipWritingDownloader('whisper-cli');
      final p = MediaImportProvider(
        toolService: _ReadyToolService(() async => tmp.path),
        modelService: _AllModelsService(() async => tmp.path),
        downloader: fake,
        whisperAssetResolver: () async => (
          url: 'https://github.com/ggml-org/whisper.cpp/releases/'
              'download/b5454/whisper-bin-win-cuda-12.4.0-x64.zip',
          build: 'cuda',
        ),
        isWindowsOverride: true,
      );
      await p.startForFile(File('${tmp.path}/a.mp4'));
      p.toolStatuses[MediaToolKind.whisperCli] =
          const MediaToolStatus.missing(MediaToolKind.whisperCli);

      await p.downloadTool(MediaToolKind.whisperCli);

      expect(fake.downloadCalls, 1);
      expect(await MediaImportSettings().whisperBuild(), 'cuda');
      expect((await MediaImportSettings().gpuUnavailableVersions()), isEmpty);
      expect(p.toolHints[MediaToolKind.whisperCli], isNull);
    });
  });

  group('whisper 运行层 GPU 决策与 Metal 黑名单（假 cli 脚本集成）', () {
    // confirmAndStart 真实执行 service.run：resolveBaseDir 走 path_provider，
    // 测试环境 mock 到 tmp 目录

    File makeWavSource() => File('${tmp.path}/src.wav')
      ..writeAsBytesSync(List<int>.filled(44 + 32000, 0));

    Future<(MediaImportProvider, File)> makeScriptProvider() async {
      mockPathProviderTo(tmp);
      final whisperDir = Directory('${tmp.path}/tools/whisper')
        ..createSync(recursive: true);
      final log = File('${tmp.path}/invocations.log');
      final cli = await _writeFakeWhisperCli(whisperDir, log.path);
      final p = MediaImportProvider(
        toolService: _WhisperScriptToolService(cli.path, () async => tmp.path),
        modelService: _AllModelsService(() async => tmp.path),
      );
      await p.startForFile(makeWavSource());
      // 完成点自动探测会真实跑脚本并写黑名单/日志：排空并清场，
      // 保证 confirmAndStart 场景从干净状态开始（开关预置不受影响）
      await drainMetalProbe(p);
      await clearMetalProbeCaches();
      if (log.existsSync()) log.deleteSync();
      return (p, log);
    }

    test('Metal 崩溃→CPU 重试成功：写 mac:版本 黑名单（版本升级后自动重试 GPU）',
        skip: !Platform.isMacOS ? '依赖宿主 detect()==metal 与 sh 脚本假进程' : null,
        () async {
      final (p, log) = await makeScriptProvider();

      await p.confirmAndStart(saveNote: (r) async => 'note-1');
      // onGpuFallback 黑名单写入为 fire-and-forget，等待落盘
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(p.step, MediaImportStep.done);
      expect(p.errorMessage, isNull);
      expect(log.readAsStringSync().trim().split('\n'), ['ng=0', 'ng=1'],
          reason: '决策不禁 GPU：首启无 -ng 崩溃后重试');
      expect(
          (await MediaImportSettings().gpuUnavailableVersions()).keys,
          contains('mac:1.9.5'),
          reason: 'toolStatuses 版本 1.9.5 构造黑名单键');
    });

    test('GPU 开关关闭：决策禁 GPU 首启带 -ng 直达成功，不写黑名单',
        skip: !Platform.isMacOS ? '依赖宿主 detect()==metal 与 sh 脚本假进程' : null,
        () async {
      SharedPreferences.setMockInitialValues(
          <String, Object>{'media_whisper_gpu': false});
      final (p, log) = await makeScriptProvider();

      await p.confirmAndStart(saveNote: (r) async => 'note-1');
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(p.step, MediaImportStep.done);
      expect(p.errorMessage, isNull);
      expect(log.readAsStringSync().trim().split('\n'), ['ng=1'],
          reason: '开关关 → 首启即 -ng，不再先无参尝试');
      expect(await MediaImportSettings().gpuUnavailableVersions(), isEmpty,
          reason: '首启即 -ng 成功，不应触发回退黑名单');
    });
  });

  group('Windows CUDA 构建转录失败指引', () {
    Future<MediaImportProvider> startWithBuild(String build) async {
      SharedPreferences.setMockInitialValues(
          <String, Object>{'media_tool_whisper_build': build});
      final p = makeProvider();
      await p.startForFile(File('${tmp.path}/a.mp4'));
      return p;
    }

    test('build==cuda：转录失败 errorDetail 追加关闭 GPU 加速指引', () async {
      final p = await startWithBuild('cuda');
      await p.confirmAndStart(
        runOverride: (_, _) async => throw const WhisperException(
            'whisper.cpp 退出码 3222226', 'CUDA error at ggml-cuda'),
        saveNote: (r) async => null,
      );
      expect(p.errorMessage, '转换失败');
      expect(
          p.errorDetail, contains('可在设置关闭 GPU 加速后重新下载引擎（CPU 版）'));
    });

    test('build==cpu：不追加指引', () async {
      final p = await startWithBuild('cpu');
      await p.confirmAndStart(
        runOverride: (_, _) async =>
            throw const WhisperException('whisper.cpp 退出码 1', 'boom'),
        saveNote: (r) async => null,
      );
      expect(p.errorMessage, '转换失败');
      expect(p.errorDetail, isNot(contains('关闭 GPU 加速')));
    });
  });

  group('Mac Metal 实测探测（假 cli 脚本集成）', () {
    Future<(MediaImportProvider, File)> makeProbeProvider({
      required File cli,
      MediaToolService? toolService,
      WhisperModelService? modelService,
      bool? isMacOverride = true,
    }) async {
      mockPathProviderTo(tmp);
      final log = File('${tmp.path}/probe-invocations.log');
      final p = MediaImportProvider(
        toolService: toolService ??
            _WhisperScriptToolService(cli.path, () async => tmp.path),
        modelService: modelService ??
            _AllModelsService(() async => tmp.path),
        isMacOverride: isMacOverride,
      );
      // 填充 toolStatuses（探测守卫读取 whisperCli 状态，与真实启动路径一致）
      await p.checkEnvironment();
      // 完成点自动触发探测（unawaited）：排空后交还用例断言/清理
      await drainMetalProbe(p);
      return (p, log);
    }

    test('checkEnvironment 完成点自动触发 Metal 探测（环境检查→探测集成）',
        skip: !Platform.isMacOS ? '依赖 sh 脚本假进程' : null,
        () async {
      final logPath = '${tmp.path}/probe-invocations.log';
      final cli = await _writeFakeWhisperCliOk(tmp, logPath);
      // makeProbeProvider 仅 await checkEnvironment（含排空），未显式调探测
      final (p, log) = await makeProbeProvider(cli: cli);

      expect(log.readAsStringSync().trim().split('\n'), ['run'],
          reason: '环境检查完成点应自动执行探测');
      expect((await MediaImportSettings().metalOkVersions()).keys,
          contains('1.9.5'), reason: '自动探测走完整链路并写 OK 缓存');
      expect(p.metalProbeRunning, isFalse);
    });

    test('Metal 崩溃→CPU 重试成功：写黑名单 mac:版本，不写 OK', 
        skip: !Platform.isMacOS ? '依赖 sh 脚本假进程' : null,
        () async {
      final logPath = '${tmp.path}/probe-invocations.log';
      final cli = await _writeFakeWhisperCli(tmp, logPath);
      final (p, log) = await makeProbeProvider(cli: cli);

      await p.ensureWhisperMetalProbe();

      expect(log.readAsStringSync().trim().split('\n'), ['ng=0', 'ng=1'],
          reason: '首启无 -ng 崩溃后带 -ng 重试');
      expect(
          (await MediaImportSettings().gpuUnavailableVersions()).keys,
          contains('mac:1.9.5'));
      expect(await MediaImportSettings().metalOkVersions(), isEmpty);
      expect(p.whisperMetalUnavailableVersion, '1.9.5');
      expect(p.metalProbeRunning, isFalse);
    });

    test('Metal 正常：写 OK 缓存，不写黑名单', 
        skip: !Platform.isMacOS ? '依赖 sh 脚本假进程' : null,
        () async {
      final logPath = '${tmp.path}/probe-invocations.log';
      final cli = await _writeFakeWhisperCliOk(tmp, logPath);
      final (p, log) = await makeProbeProvider(cli: cli);

      await p.ensureWhisperMetalProbe();

      expect(log.readAsStringSync().trim().split('\n'), ['run']);
      expect((await MediaImportSettings().metalOkVersions()).keys,
          contains('1.9.5'));
      expect(await MediaImportSettings().gpuUnavailableVersions(), isEmpty);
      expect(p.whisperMetalUnavailableVersion, isNull);
    });

    test('Metal 崩且 CPU 重试也失败：仍写黑名单（Metal 确实坏）', 
        skip: !Platform.isMacOS ? '依赖 sh 脚本假进程' : null,
        () async {
      final logPath = '${tmp.path}/probe-invocations.log';
      final cli = await _writeFakeWhisperCliAlwaysFail(tmp, logPath);
      final (p, log) = await makeProbeProvider(cli: cli);

      await p.ensureWhisperMetalProbe();

      expect(log.readAsStringSync().trim().split('\n'), ['invoked', 'invoked']);
      expect(
          (await MediaImportSettings().gpuUnavailableVersions()).keys,
          contains('mac:1.9.5'));
    });

    test('守卫：开关关 / 无模型 / 已黑名单 / 已 OK / 非 Mac / 操作中 → 不执行',
        skip: !Platform.isMacOS ? '依赖 sh 脚本假进程' : null,
        () async {
      // 断言必须指向脚本实际落笔的日志（此前误指 probe-invocations.log，
      // 脚本从不写它，六个「不探测」断言恒真空转）
      final guardLog = File('${tmp.path}/guard.log');

      Future<(MediaImportProvider, File)> make(String? presetKey,
          [Object? presetValue]) async {
        final initial = <String, Object>{
          ?presetKey: presetValue ?? 'x',
        };
        SharedPreferences.setMockInitialValues(initial);
        final cli =
            await _writeFakeWhisperCliOk(tmp, guardLog.path);
        return makeProbeProvider(cli: cli);
      }

      // 开关关
      var (p, _) = await make('media_whisper_gpu', false);
      await p.ensureWhisperMetalProbe();
      expect(guardLog.existsSync(), isFalse, reason: '开关关不探测');
      if (guardLog.existsSync()) guardLog.deleteSync();

      // 无模型（make(null) 无预置 → setup 期自动探测会跑满并写 OK 与
      // guard.log：先清场；noModel 补做环境检查填充 toolStatuses，
      // 显式探测才真正走到「无模型」守卫）
      (p, _) = await make(null);
      await clearMetalProbeCaches();
      if (guardLog.existsSync()) guardLog.deleteSync();
      final noModel = MediaImportProvider(
        toolService: _WhisperScriptToolService(
            '${tmp.path}/whisper-cli-ok.sh', () async => tmp.path),
        modelService: _NoModelsService(() async => tmp.path),
        isMacOverride: true,
      );
      await noModel.checkEnvironment();
      await drainMetalProbe(noModel);
      await noModel.ensureWhisperMetalProbe();
      expect(guardLog.existsSync(), isFalse, reason: '无模型不探测');
      if (guardLog.existsSync()) guardLog.deleteSync();

      // 已黑名单
      (p, _) = await make('media_gpu_unavailable_versions',
          '{"mac:1.9.5":"Metal 崩溃"}');
      await p.ensureWhisperMetalProbe();
      expect(guardLog.existsSync(), isFalse, reason: '黑名单命中不探测');
      if (guardLog.existsSync()) guardLog.deleteSync();

      // 已 OK
      (p, _) =
          await make('media_metal_ok_versions', '{"1.9.5":"1700000000"}');
      await p.ensureWhisperMetalProbe();
      expect(guardLog.existsSync(), isFalse, reason: 'OK 缓存命中不探测');
      if (guardLog.existsSync()) guardLog.deleteSync();

      // 非 Mac
      final cli = await _writeFakeWhisperCliOk(tmp, guardLog.path);
      (p, _) = await makeProbeProvider(cli: cli, isMacOverride: false);
      await p.ensureWhisperMetalProbe();
      expect(guardLog.existsSync(), isFalse, reason: '非 Mac 不探测');
      if (guardLog.existsSync()) guardLog.deleteSync();

      // 操作进行中
      final busyLogPath = '${tmp.path}/busy.log';
      final busyCli = await _writeFakeWhisperCliOk(tmp, busyLogPath);
      final busy = _BusyProbeProvider(
        toolService:
            _WhisperScriptToolService(busyCli.path, () async => tmp.path),
        modelService: _AllModelsService(() async => tmp.path),
      );
      await busy.ensureWhisperMetalProbe();
      expect(File(busyLogPath).existsSync(), isFalse, reason: '操作中不探测');
    });

    test('并发重入：只执行一次', 
        skip: !Platform.isMacOS ? '依赖 sh 脚本假进程' : null,
        () async {
      // 与 makeProbeProvider 返回的 log 同路径（脚本按 logPath 落笔）
      final logPath = '${tmp.path}/probe-invocations.log';
      final cli = await _writeFakeWhisperCliOk(tmp, logPath);
      final (p, log) = await makeProbeProvider(cli: cli);

      // setup 期自动探测已写 OK 缓存与日志：清场后再验证并发只执行一次
      await clearMetalProbeCaches();
      if (log.existsSync()) log.deleteSync();

      final f1 = p.ensureWhisperMetalProbe();
      final f2 = p.ensureWhisperMetalProbe();
      await Future.wait([f1, f2]);

      expect(log.readAsStringSync().trim().split('\n'), ['run'],
          reason: 'busy 防重入只跑一次');
    });
  });
}

class _CountingFetcher {
  int calls = 0;
  final List<String> urls = [];
  final String tag;
  _CountingFetcher(this.tag);
  Future<Response<dynamic>> call(String url, Options options) async {
    calls++;
    urls.add(url);
    return Response<dynamic>(
      data: {'tag_name': tag},
      requestOptions: RequestOptions(path: url),
    );
  }
}

class _GatedFetcher {
  final Completer<void> gate = Completer<void>();
  int calls = 0;
  Future<Response<dynamic>> call(String url, Options options) async {
    calls++;
    await gate.future;
    return Response<dynamic>(
      data: const {'tag_name': 'b7.0'},
      requestOptions: RequestOptions(path: url),
    );
  }
}

class _MixedSourceToolService extends MediaToolService {
  _MixedSourceToolService(Future<String> Function() base)
      : super(resolveBaseDir: base);
  @override
  Future<MediaToolStatus> check(MediaToolKind kind,
      {bool forceVerify = false}) async {
    if (kind == MediaToolKind.whisperCli) {
      return const MediaToolStatus(
        kind: MediaToolKind.whisperCli,
        ready: true,
        path: '/usr/bin/whisper-cli',
        version: 'ready',
        source: MediaToolSource.systemPath,
      );
    }
    return MediaToolStatus(
      kind: kind,
      ready: true,
      path: 'fake',
      version: '6.0',
      source: MediaToolSource.appManaged,
    );
  }
}

class _CapturingDownloader extends MediaDownloader {
  String? lastUrl;
  @override
  Future<File> download(
    String directUrl, {
    required File destFile,
    MediaDownloadSourceMode mode = MediaDownloadSourceMode.auto,
    void Function(int received, int total)? onProgress,
    CancelToken? cancelToken,
    String? expectedSha256,
  }) async {
    lastUrl = directUrl;
    await destFile.parent.create(recursive: true);
    await destFile.writeAsString('NEW-BINARY');
    return destFile;
  }
}

/// 真实写入目标文件（模拟下载产物落盘），供装前验证链路测试。
class _WritingDownloader extends MediaDownloader {
  @override
  Future<File> download(
    String directUrl, {
    required File destFile,
    MediaDownloadSourceMode mode = MediaDownloadSourceMode.auto,
    void Function(int received, int total)? onProgress,
    CancelToken? cancelToken,
    String? expectedSha256,
  }) async {
    await destFile.parent.create(recursive: true);
    await destFile.writeAsString('NEW-BINARY');
    return destFile;
  }
}

/// 可编程磁盘剩余量（null 视为探测失败跳过预检），并记录 download 调用次数。
class _LowDiskDownloader extends MediaDownloader {
  int? freeBytes;
  int downloadCalls = 0;
  @override
  Future<int?> freeDiskBytes(String path) async => freeBytes;
  @override
  Future<File> download(
    String directUrl, {
    required File destFile,
    MediaDownloadSourceMode mode = MediaDownloadSourceMode.auto,
    void Function(int received, int total)? onProgress,
    CancelToken? cancelToken,
    String? expectedSha256,
  }) async {
    downloadCalls++;
    await destFile.parent.create(recursive: true);
    await destFile.writeAsString('NEW-BINARY');
    return destFile;
  }
}

/// 装前检测返回 6.0、forceVerify（装后重检）返回 6.1。
class _VersionShiftToolService extends _ReadyToolService {
  _VersionShiftToolService(super.base);
  @override
  Future<MediaToolStatus> check(MediaToolKind kind,
      {bool forceVerify = false}) async {
    checkCount++;
    return MediaToolStatus(
      kind: kind,
      ready: true,
      path: 'fake',
      version: forceVerify ? '6.1' : '6.0',
      source: MediaToolSource.appManaged,
    );
  }
}

class _HangingDownloader extends MediaDownloader {
  final Completer<void> started = Completer<void>();
  final Completer<void> release = Completer<void>();
  int downloadCount = 0;

  _HangingDownloader();

  @override
  Future<File> download(
    String directUrl, {
    required File destFile,
    MediaDownloadSourceMode mode = MediaDownloadSourceMode.auto,
    void Function(int received, int total)? onProgress,
    CancelToken? cancelToken,
    String? expectedSha256,
  }) async {
    downloadCount++;
    onProgress?.call(0, 1000);
    onProgress?.call(500, 1000);
    started.complete();
    await release.future;
    return destFile;
  }
}

/// downloadTool 间谍：仅计数不执行（隔离网络/文件副作用，验证切换联动触发）。
/// [installedBuildOnDownload] 模拟真实下载安装后的落位构建（写回设置）。
class _SpyDownloadProvider extends MediaImportProvider {
  int downloadCalls = 0;
  String? installedBuildOnDownload;
  _SpyDownloadProvider({
    super.toolService,
    super.modelService,
    super.isWindowsOverride,
  });
  @override
  Future<void> downloadTool(MediaToolKind kind) async {
    downloadCalls++;
    final build = installedBuildOnDownload;
    if (kind == MediaToolKind.whisperCli && build != null) {
      await settings.setWhisperBuild(build);
    }
  }
}

/// forceVerify 前 N 次返回未就绪（模拟 CUDA 包安装后启动校验失败），此后就绪。
class _FlakyVerifyToolService extends _ReadyToolService {
  int pendingFailures;
  _FlakyVerifyToolService(super.base, this.pendingFailures);
  @override
  Future<MediaToolStatus> check(MediaToolKind kind,
      {bool forceVerify = false}) async {
    checkCount++;
    if (forceVerify && pendingFailures > 0) {
      pendingFailures--;
      return MediaToolStatus.missing(kind);
    }
    return MediaToolStatus(
      kind: kind,
      ready: true,
      path: 'fake',
      version: '1',
      source: MediaToolSource.appManaged,
    );
  }
}

/// 下载时写入含单个二进制条目的有效 zip（供真实解压+安装链路执行）。
class _ZipWritingDownloader extends MediaDownloader {
  final String entryName;
  int downloadCalls = 0;
  _ZipWritingDownloader(this.entryName);
  @override
  Future<File> download(
    String directUrl, {
    required File destFile,
    MediaDownloadSourceMode mode = MediaDownloadSourceMode.auto,
    void Function(int received, int total)? onProgress,
    CancelToken? cancelToken,
    String? expectedSha256,
  }) async {
    downloadCalls++;
    await destFile.parent.create(recursive: true);
    final archive = Archive()
      ..addFile(ArchiveFile(entryName, 2, 'ok'.codeUnits));
    await destFile.writeAsBytes(ZipEncoder().encode(archive));
    return destFile;
  }
}
