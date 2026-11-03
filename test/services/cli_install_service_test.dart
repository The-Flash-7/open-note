// Copyright (c) 2026 litongshuai
// SPDX-License-Identifier: MIT OR Apache-2.0

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:open_note/services/cli_install_service.dart';
import 'package:open_note/services/media/process_runner.dart';

/// 测试统一注入空 shell PATH 目录，避免真实 spawn 登录 shell；
/// shell 目录层的行为由专用用例（customShellDirs）覆盖。
Future<List<String>> noShellDirs() async => const <String>[];

/// mac GUI 无 PATH 场景的假执行器：裸命令全部 ENOENT（抛异常模拟），
/// brew 前缀工具可用；记录全部 spawn 供断言。
Future<ProcessRunResult> Function(String, List<String>, {String? workingDirectory})
    macGuiRunner({
  required Set<String> existing,
  Map<String, String> outputs = const {},
  List<String> failExit = const [],
}) {
  return (exe, args, {String? workingDirectory}) async {
    final key = [exe, ...args].join(' ');
    if (!existing.contains(exe)) {
      throw ProcessException(exe, args, 'No such file or directory', 2);
    }
    if (failExit.contains(key)) {
      return ProcessRunResult(1, '', 'boom');
    }
    return ProcessRunResult(0, outputs[key] ?? '', '');
  };
}

void main() {
  group('mac GUI 无 PATH：绝对候选链兜底', () {
    test('裸 python3 缺失 -> brew python3 候选命中（3.13 达标）', () async {
      final spawned = <String>[];
      bool exists(String p) => p == '/opt/homebrew/bin/python3';
      final r = await CLIInstallService.checkEnvironment(
        shellDirs: noShellDirs, 
        run: (exe, args, {String? workingDirectory}) async {
          spawned.add(exe);
          if (!exists(exe) && !exe.contains('pip')) {
            throw ProcessException(exe, args, 'not found', 2);
          }
          if (args.contains('--version') && exe.endsWith('python3')) {
            return ProcessRunResult(0, 'Python 3.13.1\n', '');
          }
          if (exe == '/opt/homebrew/bin/python3') {
            return ProcessRunResult(
                0, 'pip 24.0 from /opt/homebrew/lib/python3.13/site-packages/pip (python 3.13)\n', '');
          }
          throw ProcessException(exe, args, 'not found', 2);
        },
        exists: exists,
      );
      expect(r.available, isTrue);
      expect(r.pythonVersion, 'Python 3.13.1');
      // 存在性守卫：不存在的候选路径不发起 spawn
      expect(spawned.where((e) => e.startsWith('/usr/')), isEmpty);
    });

    test('裸 python3 为系统 3.9.6（GUI PATH 命中但不达标）-> 继续走候选链',
        () async {
      final r = await CLIInstallService.checkEnvironment(
        shellDirs: noShellDirs, 
        run: (exe, args, {String? workingDirectory}) async {
          if (exe == 'python3') {
            return ProcessRunResult(0, 'Python 3.9.6\n', '');
          }
          if (exe == '/opt/homebrew/bin/python3' && args.contains('--version')) {
            return ProcessRunResult(0, 'Python 3.13.1\n', '');
          }
          if (exe == '/opt/homebrew/bin/python3') {
            return ProcessRunResult(0, 'pip 24.0\n', '');
          }
          throw ProcessException(exe, args, 'not found', 2);
        },
        exists: (p) => p == '/opt/homebrew/bin/python3',
      );
      expect(r.available, isTrue);
      expect(r.pythonVersion, 'Python 3.13.1', reason: '低版本命中后应继续探测候选');
    });

    test('pip 裸命令与绝对候选全缺失 -> python -m pip 兜底', () async {
      final r = await CLIInstallService.checkEnvironment(
        shellDirs: noShellDirs, 
        run: (exe, args, {String? workingDirectory}) async {
          // 注意先判 pip：'-m pip --version' 同时含两关键词
          if (exe == '/opt/homebrew/bin/python3' && args.contains('pip')) {
            return ProcessRunResult(0, 'pip 24.0 from ... (python 3.13)\n', '');
          }
          if (exe == '/opt/homebrew/bin/python3' && args.contains('--version')) {
            return ProcessRunResult(0, 'Python 3.13.1\n', '');
          }
          throw ProcessException(exe, args, 'not found', 2);
        },
        exists: (p) => p == '/opt/homebrew/bin/python3',
      );
      expect(r.available, isTrue);
      expect(r.pipVersion, contains('pip 24.0'));
    });

    test('全链路缺失 -> pythonNotInstalled（错误键保持兼容）', () async {
      final r = await CLIInstallService.checkEnvironment(
        shellDirs: noShellDirs, 
        run: macGuiRunner(existing: {}),
        exists: (_) => false,
      );
      expect(r.available, isFalse);
      expect(r.errorKey, 'pythonNotInstalled');
    });

    test('仅有低版本 python -> pythonVersionTooLow 并带版本输出', () async {
      final r = await CLIInstallService.checkEnvironment(
        shellDirs: noShellDirs, 
        run: (exe, args, {String? workingDirectory}) async {
          if (exe == '/usr/bin/python3') {
            return ProcessRunResult(0, 'Python 3.9.6\n', '');
          }
          throw ProcessException(exe, args, 'not found', 2);
        },
        exists: (p) => p == '/usr/bin/python3',
      );
      expect(r.available, isFalse);
      expect(r.errorKey, 'pythonVersionTooLow');
      expect(r.pythonVersion, 'Python 3.9.6');
    });

    test('conda 系前缀（miniforge3）命中 python/pip', () async {
      final home = Platform.environment['HOME'] ?? '~';
      final py = '$home/miniforge3/bin/python3';
      final r = await CLIInstallService.checkEnvironment(
        shellDirs: noShellDirs, 
        run: (exe, args, {String? workingDirectory}) async {
          if (exe == py && args.contains('--version') && !args.contains('pip')) {
            return ProcessRunResult(0, 'Python 3.13.1\n', '');
          }
          if (exe == py && args.contains('pip')) {
            return ProcessRunResult(0, 'pip 25.0 (python 3.13)\n', '');
          }
          throw ProcessException(exe, args, 'not found', 2);
        },
        exists: (p) => p == py,
      );
      expect(r.available, isTrue);
      expect(r.pythonVersion, 'Python 3.13.1');
      expect(r.pipVersion, contains('pip 25.0'));
    });

    test('shell PATH 快照目录命中（pyenv/nix/自定义 conda 等任意前缀）', () async {
      final r = await CLIInstallService.checkEnvironment(
        shellDirs: () async => ['/Users/x/.pyenv/shims', '/opt/miniconda/bin'],
        run: (exe, args, {String? workingDirectory}) async {
          if (exe == '/opt/miniconda/bin/python3' &&
              args.contains('--version') &&
              !args.contains('pip')) {
            return ProcessRunResult(0, 'Python 3.12.4\n', '');
          }
          if (exe == '/opt/miniconda/bin/python3' && args.contains('pip')) {
            return ProcessRunResult(0, 'pip 24.1\n', '');
          }
          throw ProcessException(exe, args, 'not found', 2);
        },
        exists: (p) => p == '/opt/miniconda/bin/python3',
      );
      expect(r.available, isTrue);
      expect(r.pythonVersion, 'Python 3.12.4');
    });

    test('shell 快照失败（空目录）时静态常见目录仍兜底', () async {
      final r = await CLIInstallService.checkEnvironment(
        shellDirs: () async => const <String>[],
        run: (exe, args, {String? workingDirectory}) async {
          if (exe == '/opt/homebrew/bin/python3.13' &&
              args.contains('--version') &&
              !args.contains('pip')) {
            return ProcessRunResult(0, 'Python 3.13.3\n', '');
          }
          if (exe == '/opt/homebrew/bin/python3.13' && args.contains('pip')) {
            return ProcessRunResult(0, 'pip 24.2\n', '');
          }
          throw ProcessException(exe, args, 'not found', 2);
        },
        exists: (p) => p == '/opt/homebrew/bin/python3.13',
      );
      expect(r.available, isTrue);
      expect(r.pythonVersion, 'Python 3.13.3');
    });
  });

  group('isCLIInstalled', () {
    test('裸命令缺失 -> python 同 bin 推导命中（conda/venv 场景）', () async {
      final home = Platform.environment['HOME'] ?? '~';
      final py = '$home/miniforge3/bin/python3';
      final r = await CLIInstallService.isCLIInstalled(
          shellDirs: noShellDirs, 
        run: (exe, args, {String? workingDirectory}) async {
          if (exe == py && args.contains('--version')) {
            return ProcessRunResult(0, 'Python 3.13.1\n', '');
          }
          if (exe == '$home/miniforge3/bin/opennote') {
            return ProcessRunResult(0, 'open-note-cli 0.3.2\n', '');
          }
          throw ProcessException(exe, args, 'not found', 2);
        },
        exists: (p) => p == py || p == '$home/miniforge3/bin/opennote',
      );
      expect(r, isTrue);
    });

    test('裸命令与同 bin 推导缺失 -> ~/.local/bin/opennote 候选命中', () async {
      final home = Platform.environment['HOME'] ?? '~';
      final r = await CLIInstallService.isCLIInstalled(
          shellDirs: noShellDirs, 
        run: (exe, args, {String? workingDirectory}) async {
          if (exe == '$home/.local/bin/opennote') {
            return ProcessRunResult(0, 'open-note-cli 0.3.2\n', '');
          }
          throw ProcessException(exe, args, 'not found', 2);
        },
        exists: (p) => p == '$home/.local/bin/opennote',
      );
      expect(r, isTrue);
    });

    test('候选存在但版本输出不含 CLI 标识 -> false', () async {
      final home = Platform.environment['HOME'] ?? '~';
      final r = await CLIInstallService.isCLIInstalled(
          shellDirs: noShellDirs, 
        run: macGuiRunner(
          existing: {'$home/.local/bin/opennote'},
          outputs: {'$home/.local/bin/opennote --version': 'other 1.0\n'},
        ),
        exists: (p) => p == '$home/.local/bin/opennote',
      );
      expect(r, isFalse);
    });
  });

  group('install', () {
    test('用检测通过的 python -m pip 安装（解释器一致性）', () async {
      String? installExe;
      List<String>? installArgs;
      final r = await CLIInstallService.install(
          shellDirs: noShellDirs, 
        run: (exe, args, {String? workingDirectory}) async {
          if (exe == '/opt/homebrew/bin/python3' && args.contains('--version')) {
            return ProcessRunResult(0, 'Python 3.13.1\n', '');
          }
          if (args.contains('install')) {
            installExe = exe;
            installArgs = args;
            return ProcessRunResult(0, 'Successfully installed\n', '');
          }
          if (exe == '/opt/homebrew/bin/python3') {
            return ProcessRunResult(0, 'pip 24.0\n', '');
          }
          throw ProcessException(exe, args, 'not found', 2);
        },
        exists: (p) => p == '/opt/homebrew/bin/python3',
      );
      expect(r.success, isTrue);
      expect(installExe, '/opt/homebrew/bin/python3');
      expect(installArgs,
          ['-m', 'pip', 'install', 'open-note-cli', '--upgrade']);
    });

    test('python 不可用 -> 失败并归为版本不匹配', () async {
      final r = await CLIInstallService.install(
          shellDirs: noShellDirs, 
        run: macGuiRunner(existing: {}),
        exists: (_) => false,
      );
      expect(r.success, isFalse);
      expect(r.errorKey, 'pythonVersionMismatch');
    });
  });
}
