// test/services/media/media_tool_service_test.dart
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_note/services/media/media_import_settings.dart';
import 'package:open_note/services/media/media_tool_service.dart';
import 'package:open_note/services/media/process_runner.dart';
import 'package:shared_preferences/shared_preferences.dart';

ProcessRunResult ok(String out) => ProcessRunResult(0, out, '');
const ProcessRunResult fail = ProcessRunResult(1, '', '');

void main() {
  group('版本解析', () {
    test('parseFfmpegVersion', () {
      expect(
        MediaToolService.parseFfmpegVersion('ffmpeg version 7.1-x\n...'),
        '7.1-x',
      );
      expect(MediaToolService.parseFfmpegVersion('nonsense'), isNull);
    });
    test('parseYtDlpVersion', () {
      expect(MediaToolService.parseYtDlpVersion('2025.10.22'), isNotNull);
      expect(MediaToolService.parseYtDlpVersion('garbage'), isNull);
    });
    test('parseWhisperVersion：提取真实版本号，解析失败为 null', () {
      expect(
        MediaToolService.parseWhisperVersion(
            'whisper.cpp version: 1.9.5 (built: Nov  1 2025)'),
        '1.9.5',
      );
      expect(MediaToolService.parseWhisperVersion('garbage'), isNull);
    });
  });

  group('check（注入假命令执行）', () {
    late Directory tmp;
    setUp(() => tmp = Directory.systemTemp.createTempSync('vtn_tools'));
    tearDown(() => tmp.deleteSync(recursive: true));

    test('应用自管目录存在且版本可用 -> appManaged', () async {
      final ffmpegDir = Directory('${tmp.path}/tools/ffmpeg');
      ffmpegDir.createSync(recursive: true);
      final bin = File(
        '${ffmpegDir.path}/ffmpeg${Platform.isWindows ? '.exe' : ''}',
      );
      bin.writeAsStringSync('');
      if (!Platform.isWindows) {
        await Process.run('chmod', ['+x', bin.path]);
      }

      final svc = MediaToolService(
        resolveBaseDir: () async => tmp.path,
        run: (exe, args, {String? workingDirectory}) async {
          if (args.contains('-version')) return ok('ffmpeg version 7.1');
          return fail;
        },
      );
      final st = await svc.check(MediaToolKind.ffmpeg);
      expect(st.ready, isTrue);
      expect(st.source, MediaToolSource.appManaged);
      expect(st.version, '7.1');
    });

    test('自管缺失且 which 成功 -> systemPath', () async {
      // _verify 有存在性前置守卫（release SIGPIPE 防护），which 命中的
      // 路径必须真实落盘
      final sysBin = Directory('${tmp.path}/sysbin')..createSync(recursive: true);
      final sysFfmpeg = File('${sysBin.path}/ffmpeg')..writeAsStringSync('');
      if (!Platform.isWindows) {
        await Process.run('chmod', ['+x', sysFfmpeg.path]);
      }
      final svc = MediaToolService(
        resolveBaseDir: () async => tmp.path,
        run: (exe, args, {String? workingDirectory}) async {
          if (exe == 'which') return ok('${sysFfmpeg.path}\n');
          if (args.contains('-version')) return ok('ffmpeg version 6.0');
          return fail;
        },
      );
      final st = await svc.check(MediaToolKind.ffmpeg);
      expect(st.ready, isTrue);
      expect(st.source, MediaToolSource.systemPath);
      expect(st.path, sysFfmpeg.path);
    });

    test('全部缺失 -> ready=false', () async {
      final svc = MediaToolService(
        resolveBaseDir: () async => tmp.path,
        run: (exe, args, {String? workingDirectory}) async => fail,
      );
      expect((await svc.check(MediaToolKind.ytDlp)).ready, isFalse);
    });

    test('verify 前置存在性守卫：不存在的绝对路径不发起 spawn', () async {
      if (!Platform.isMacOS) {
        return;
      }
      // 真机实证：release 下 spawn 不存在的路径会在 dart:io 原生层
      // 触发主线程 SIGPIPE 杀死应用（进程平台线程未忽略该信号），
      // _verify 必须先 stat 再 spawn。断言目标为真实候选路径，
      // 且测试前置条件要求该路径当前不存在
      final missingPath = '/opt/homebrew/bin/whisper-cli';
      if (File(missingPath).existsSync()) {
        return; // 本机存在该工具时无法模拟缺失场景，跳过
      }
      final spawned = <String>[];
      final svc = MediaToolService(
        resolveBaseDir: () async => tmp.path,
        run: (exe, args, {String? workingDirectory}) async {
          spawned.add(exe);
          return fail;
        },
      );
      final st = await svc.check(MediaToolKind.whisperCli);
      expect(st.ready, isFalse);
      expect(spawned, isNot(contains(missingPath)),
          reason: '绝对路径候选不存在时应跳过 spawn');
    });

    test('自管缺失且 which 失败 -> macOS 绝对路径兜底 systemPath（GUI 无 PATH）',
        () async {
      // 绝对路径兜底按平台常量实现，仅在 macOS 生效；本套件在 macOS 上运行
      //（其余平台由 which/appManaged 语义覆盖，不引入平台分叉测试）。
      // _verify 有存在性前置守卫，候选路径须真实落盘：测试期间临时创建，
      // 结束时清理（仅当本机原本不存在时）
      if (!Platform.isMacOS) {
        return;
      }
      const candidate = '/opt/homebrew/bin/whisper-cli';
      final created = !File(candidate).existsSync();
      if (created) {
        File(candidate).writeAsStringSync('#!/bin/sh\nexit 0\n');
        await Process.run('chmod', ['+x', candidate]);
      }
      try {
        var verifySpawns = 0;
        final svc = MediaToolService(
          resolveBaseDir: () async => tmp.path,
          run: (exe, args, {String? workingDirectory}) async {
            if (exe == 'which') return fail;
            if (exe == candidate && args.contains('--version')) {
              verifySpawns++;
              return ok('whisper.cpp version: 1.9.5 (built: Nov  1 2025)');
            }
            return fail;
          },
        );
        final st = await svc.check(MediaToolKind.whisperCli);
        expect(st.ready, isTrue);
        expect(st.source, MediaToolSource.systemPath);
        expect(st.path, candidate);
        expect(st.version, '1.9.5');

        // 绝对路径命中写入缓存后，二次 check 不再 spawn 验证
        final st2 = await svc.check(MediaToolKind.whisperCli);
        expect(st2.path, candidate);
        expect(verifySpawns, 1, reason: '缓存命中不应重复验证');
      } finally {
        if (created) {
          try {
            File(candidate).deleteSync();
          } catch (_) {}
        }
      }
    });

    test('whisperCli 探测以 exe 所在目录为工作目录（dll 搜索保险）', () async {
      final whisperDir = Directory('${tmp.path}/tools/whisper');
      whisperDir.createSync(recursive: true);
      final bin = File(
        '${whisperDir.path}/whisper-cli${Platform.isWindows ? '.exe' : ''}',
      );
      bin.writeAsStringSync('');
      if (!Platform.isWindows) {
        await Process.run('chmod', ['+x', bin.path]);
      }
      String? capturedWd;
      final svc = MediaToolService(
        resolveBaseDir: () async => tmp.path,
        run: (exe, args, {workingDirectory}) async {
          if (args.contains('--version')) {
            capturedWd = workingDirectory;
            return ok('whisper.cpp version: 1.9.5 (built: Oct 30 2026)');
          }
          return fail;
        },
      );
      final st = await svc.check(MediaToolKind.whisperCli);
      expect(st.ready, isTrue);
      expect(capturedWd, whisperDir.path);
      expect(st.version, '1.9.5', reason: '探测 --version 应存真实版本号');
    });
  });

  group('installExtractedBinary', () {
    late Directory tmp;
    setUp(() => tmp = Directory.systemTemp.createTempSync('vtn_install'));
    tearDown(() => tmp.deleteSync(recursive: true));

    test('递归找到二进制并安装到 toolDir', () async {
      final nested = Directory('${tmp.path}/extract/ffmpeg-7.1/bin');
      nested.createSync(recursive: true);
      final found = File(
        '${nested.path}/ffmpeg${Platform.isWindows ? '.exe' : ''}',
      );
      found.writeAsStringSync('#!/bin/sh\n');
      final svc = MediaToolService(resolveBaseDir: () async => tmp.path);
      final installed = await svc.installExtractedBinary(
        '${tmp.path}/extract',
        MediaToolKind.ffmpeg,
      );
      expect(installed, isNotNull);
      expect(
        File(installed!).path.endsWith(
          'tools/ffmpeg/ffmpeg${Platform.isWindows ? '.exe' : ''}',
        ),
        isTrue,
      );
    });

    test('找不到二进制返回 null', () async {
      Directory('${tmp.path}/extract').createSync(recursive: true);
      final svc = MediaToolService(resolveBaseDir: () async => tmp.path);
      expect(
        await svc.installExtractedBinary(
          '${tmp.path}/extract',
          MediaToolKind.whisperCli,
        ),
        isNull,
      );
    });

    test('whisper 安装时把 exe 同目录文件全部平铺搬到 toolDir（全量安装）', () async {
      final nested = Directory('${tmp.path}/extract2/build/bin');
      nested.createSync(recursive: true);
      final exeName = Platform.isWindows ? 'whisper-cli.exe' : 'whisper-cli';
      final libExt = Platform.isWindows ? '.dll' : '.so';
      File('${nested.path}/$exeName').writeAsStringSync('x');
      final lib = File('${nested.path}/whisper$libExt')
        ..writeAsStringSync('lib');
      File('${nested.path}/readme.txt').writeAsStringSync('doc');
      final svc = MediaToolService(resolveBaseDir: () async => tmp.path);
      final installed = await svc.installExtractedBinary(
          '${tmp.path}/extract2', MediaToolKind.whisperCli);
      expect(installed, isNotNull);
      final toolDirPath = await svc.toolDir(MediaToolKind.whisperCli);
      expect(File('$toolDirPath/$exeName').existsSync(), isTrue);
      final libName = lib.uri.pathSegments.last;
      expect(File('$toolDirPath/$libName').existsSync(), isTrue);
      expect(File('$toolDirPath/readme.txt').existsSync(), isTrue,
          reason: '全量安装：非库文件同样平铺复制');
    });

    test('exe 搜索按候选优先级：whisper-cli 优先于 main（修复 main.exe 覆盖）', () async {
      // 复刻实证包结构并复现 Windows 枚举序：bin/main（旧入口，27B）先于
      // Release/whisper-cli（真主程序，479B）被枚举（本机 APFS 实证该布局
      // 稳定 main 在前），旧实现按枚举序误选 main 并覆盖真 exe
      final binDir = Directory('${tmp.path}/extract4/bin')..createSync(recursive: true);
      final relDir = Directory('${tmp.path}/extract4/Release')..createSync(recursive: true);
      final exeName = Platform.isWindows ? 'whisper-cli.exe' : 'whisper-cli';
      final mainName = Platform.isWindows ? 'main.exe' : 'main';
      File('${binDir.path}/$mainName').writeAsStringSync('M' * 27);
      File('${relDir.path}/$exeName').writeAsStringSync('C' * 479);
      final svc = MediaToolService(resolveBaseDir: () async => tmp.path);
      final installed = await svc.installExtractedBinary(
          '${tmp.path}/extract4', MediaToolKind.whisperCli);
      expect(installed, isNotNull);
      final toolDirPath = await svc.toolDir(MediaToolKind.whisperCli);
      final dest = File('$toolDirPath/$exeName');
      expect(dest.lengthSync(), 479,
          reason: '主程序必须取 whisper-cli 字节，而非枚举序靠前的 main');
      expect(dest.readAsStringSync(), 'C' * 479);
      // 全量平铺规格：main 非 foundName，仍会复制进 toolDir（无害副产物，
      // 应用仅执行 binaryName 即 whisper-cli）
      expect(File('$toolDirPath/$mainName').existsSync(), isTrue);
    });

    test('whisper 全量安装：嵌套 Release/ 子目录 exe+dll+杂文件全部平铺且 exe 改名', () async {
      final release = Directory('${tmp.path}/extract3/whisper-bin-x64/Release');
      release.createSync(recursive: true);
      final exeName = Platform.isWindows ? 'whisper-cli.exe' : 'whisper-cli';
      final libExt = Platform.isWindows ? '.dll' : '.so';
      File('${release.path}/$exeName').writeAsStringSync('exe');
      File('${release.path}/ggml$libExt').writeAsStringSync('ggml');
      File('${release.path}/whisper$libExt').writeAsStringSync('whisper');
      File('${release.path}/BUILD-INFO.txt').writeAsStringSync('meta');
      File('${tmp.path}/extract3/LICENSE').writeAsStringSync('mit');
      final svc = MediaToolService(resolveBaseDir: () async => tmp.path);
      final installed = await svc.installExtractedBinary(
          '${tmp.path}/extract3', MediaToolKind.whisperCli);
      expect(installed, isNotNull);
      final toolDirPath = await svc.toolDir(MediaToolKind.whisperCli);
      expect(File('$toolDirPath/$exeName').readAsStringSync(), 'exe');
      for (final name in [
        'ggml$libExt',
        'whisper$libExt',
        'BUILD-INFO.txt',
        'LICENSE',
      ]) {
        expect(File('$toolDirPath/$name').existsSync(), isTrue, reason: name);
      }
      expect(Directory('$toolDirPath/Release').existsSync(), isFalse,
          reason: '子目录结构不带入 toolDir（平铺）');
      expect(Directory('$toolDirPath/whisper-bin-x64').existsSync(), isFalse);
    });
  });

  group('check 验证缓存（yt-dlp 二进制 spawn 慢，避免重复验证）', () {
    late Directory tmp;
    late Map<String, String> store;
    late Directory appDir;
    late File bin;
    late int runCount;

    setUp(() {
      tmp = Directory.systemTemp.createTempSync('vtn_cache');
      store = <String, String>{};
      runCount = 0;
      appDir = Directory('${tmp.path}/tools/ffmpeg')
        ..createSync(recursive: true);
      bin = File('${appDir.path}/ffmpeg${Platform.isWindows ? '.exe' : ''}')
        ..writeAsStringSync('x' * 10);
    });
    tearDown(() => tmp.deleteSync(recursive: true));

    MediaToolService makeSvc() => MediaToolService(
          resolveBaseDir: () async => tmp.path,
          run: (exe, args, {String? workingDirectory}) async {
            // 只应答 appManaged 路径（模拟本机无 brew 系统 ffmpeg，
            // 绝对路径兜底候选一并失败）
            if (exe != bin.path || !args.contains('-version')) return fail;
            runCount++;
            return ok('ffmpeg version 7.1');
          },
          cacheReader: () async => store,
          cacheWriter: (m) async => store
            ..clear()
            ..addAll(m),
        );

    test('同一二进制第二次 check 不再 spawn 验证命令', () async {
      final svc = makeSvc();
      final st1 = await svc.check(MediaToolKind.ffmpeg);
      expect(st1.ready, isTrue);
      expect(runCount, 1);

      final st2 = await svc.check(MediaToolKind.ffmpeg);
      expect(st2.ready, isTrue);
      expect(st2.version, '7.1');
      expect(st2.source, MediaToolSource.appManaged);
      expect(runCount, 1, reason: '缓存命中不应重复 spawn');
    });

    test('文件被替换（大小/mtime 变化）后缓存失效重新验证', () async {
      final svc = makeSvc();
      await svc.check(MediaToolKind.ffmpeg);
      expect(runCount, 1);

      bin.writeAsStringSync('x' * 99);
      final st = await svc.check(MediaToolKind.ffmpeg);
      expect(st.ready, isTrue);
      expect(runCount, 2, reason: '二进制变化应重新验证');
    });

    test('forceVerify: true 绕过缓存强制重验', () async {
      final svc = makeSvc();
      await svc.check(MediaToolKind.ffmpeg);
      expect(runCount, 1);

      final st = await svc.check(MediaToolKind.ffmpeg, forceVerify: true);
      expect(st.ready, isTrue);
      expect(runCount, 2);
    });

    test('缓存跨实例持久化（新实例零 spawn 命中）', () async {
      final svc1 = makeSvc();
      await svc1.check(MediaToolKind.ffmpeg);
      expect(runCount, 1);
      expect(store, isNotEmpty);

      runCount = 0;
      final st = await makeSvc().check(MediaToolKind.ffmpeg);
      expect(st.ready, isTrue);
      expect(st.version, '7.1');
      expect(runCount, 0, reason: '新实例应从持久化缓存命中');
    });

    test('二进制被删除后缓存失效回落 which 流程', () async {
      final svc = makeSvc();
      await svc.check(MediaToolKind.ffmpeg);
      expect(runCount, 1);

      bin.deleteSync();
      final st = await svc.check(MediaToolKind.ffmpeg);
      expect(st.ready, isFalse);
      expect(runCount, 1, reason: '缓存因文件缺失失效，但 which 全失败无验证 spawn');
    });

    test('MediaImportSettings 验证缓存 roundtrip', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final settings = MediaImportSettings();
      expect(await settings.readVerifyCache(), isEmpty);

      await settings.writeVerifyCache({'ffmpeg': '{"p":"/a","s":1}'});
      expect(await settings.readVerifyCache(),
          {'ffmpeg': '{"p":"/a","s":1}'});
    });
  });

  group('autoInstallPlan（一键安装命令构建）', () {
    test('macOS + brew 路径 -> brew install whisper.cpp', () {
      final plan = MediaToolService.autoInstallPlan(
        MediaToolKind.whisperCli,
        brewPath: '/opt/homebrew/bin/brew',
        isMac: true,
        isWin: false,
      );
      expect(plan, isNotNull);
      expect(plan!.executable, '/opt/homebrew/bin/brew');
      expect(plan.args, ['install', '-q', 'whisper.cpp']);
    });

    test('macOS 但未找到 brew -> null（回退指引）', () {
      expect(
        MediaToolService.autoInstallPlan(
          MediaToolKind.whisperCli,
          brewPath: null,
          isMac: true,
          isWin: false,
        ),
        isNull,
      );
    });

    test('Windows -> winget 静默安装 ggml.whisper-cpp（绝对路径）', () {
      final plan = MediaToolService.autoInstallPlan(
        MediaToolKind.whisperCli,
        brewPath: null,
        wingetPath:
            r'C:\Users\a\AppData\Local\Microsoft\WindowsApps\winget.exe',
        isMac: false,
        isWin: true,
      );
      expect(plan, isNotNull);
      expect(
          plan!.executable, r'C:\Users\a\AppData\Local\Microsoft\WindowsApps\winget.exe');
      expect(plan.args.join(' '), contains('ggml.whisper-cpp'));
      expect(plan.args.join(' '), contains('--disable-interactivity'));
    });

    test('Windows 但未找到 winget -> null（回退指引）', () {
      expect(
        MediaToolService.autoInstallPlan(
          MediaToolKind.whisperCli,
          brewPath: null,
          wingetPath: null,
          isMac: false,
          isWin: true,
        ),
        isNull,
      );
    });

    test('wingetCandidatePaths：Windows 展开 LOCALAPPDATA，非 Windows 返回空', () {
      final paths = MediaToolService.wingetCandidatePaths();
      if (Platform.isWindows) {
        final local = Platform.environment['LOCALAPPDATA'];
        expect(paths, ['$local\\Microsoft\\WindowsApps\\winget.exe']);
      } else {
        expect(paths, isEmpty);
      }
    });

    test('Linux 不支持自动安装 -> null（保留指引）', () {
      expect(
        MediaToolService.autoInstallPlan(
          MediaToolKind.whisperCli,
          brewPath: null,
          isMac: false,
          isWin: false,
        ),
        isNull,
      );
    });

    test('非 whisperCli 工具不提供自动安装 -> null', () {
      expect(
        MediaToolService.autoInstallPlan(
          MediaToolKind.ffmpeg,
          brewPath: '/opt/homebrew/bin/brew',
          isMac: true,
          isWin: false,
        ),
        isNull,
      );
    });
  });
}
