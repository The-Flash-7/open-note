// Copyright (c) 2026 litongshuai
// SPDX-License-Identifier: MIT OR Apache-2.0

import 'dart:io';

import 'media/process_runner.dart';

/// 进程执行器（可注入测试）；默认接 runCommand。
typedef CliProcRunner = Future<ProcessRunResult> Function(
  String executable,
  List<String> args, {
  String? workingDirectory,
});

/// 文件存在性（可注入测试）；默认真实文件系统。
typedef CliExistsFn = bool Function(String path);

/// CLI 环境检测与安装。
///
/// 检测采用「裸命令 + 绝对路径候选链」：macOS GUI 应用从 Finder 启动时
/// PATH 仅含 /usr/bin:/bin:/usr/sbin:/sbin，brew/用户级安装的工具无法被
/// which 解析（真机实证），故按平台规范前缀逐一探测。绝对路径 spawn 前
/// 做存在性守卫（缺失路径的 spawn 在 dart:io 原生层有 SIGPIPE 风险，
/// 见 media_tool_service._verify 同类防护）。
class CLIInstallService {
  static const int _minPythonMajor = 3;
  static const int _minPythonMinor = 10;

  /// 各平台 python3 绝对路径候选（顺序即优先级：brew 前缀 > 系统自带）。
  static List<String> _pythonCandidates() => Platform.isMacOS
      ? ['/opt/homebrew/bin/python3', '/usr/local/bin/python3', '/usr/bin/python3']
      : Platform.isLinux
          ? ['/usr/local/bin/python3', '/usr/bin/python3']
          : const [];

  /// pip3 绝对路径候选（brew/用户级脚本目录）。
  static List<String> _pipCandidates() => Platform.isMacOS
      ? [
          '/opt/homebrew/bin/pip3',
          '/usr/local/bin/pip3',
          '${_home()}/.local/bin/pip3',
        ]
      : Platform.isLinux
          ? ['/usr/local/bin/pip3', '${_home()}/.local/bin/pip3']
          : const [];

  /// opennote CLI 绝对路径候选。
  static List<String> _cliCandidates() => Platform.isMacOS
      ? [
          '/opt/homebrew/bin/opennote',
          '/usr/local/bin/opennote',
          '${_home()}/.local/bin/opennote',
        ]
      : Platform.isLinux
          ? ['/usr/local/bin/opennote', '${_home()}/.local/bin/opennote']
          : const [];

  static String _home() => Platform.environment['HOME'] ?? '~';

  /// 首个版本达标的 python：裸命令优先（终端/debug 场景即用户默认解释器），
  /// 失败后走绝对候选链。返回 (命令, --version 输出)；全不达标时返回
  /// (null, 最后一次看到的版本输出) 供错误提示。
  static Future<(String?, String)> _resolvePython(
    CliProcRunner run,
    CliExistsFn exists,
  ) async {
    final bare = Platform.isWindows ? 'python' : 'python3';
    final candidates = <String>[bare, ..._pythonCandidates()];
    String? lastVersionOutput;
    for (final cmd in candidates) {
      // 绝对路径先做存在性守卫；裸命令交给 PATH 解析（ENOENT 由 catch 兜底）
      if (cmd.contains('/') && !exists(cmd)) continue;
      final ProcessRunResult r;
      try {
        r = await run(cmd, ['--version']);
      } catch (_) {
        continue;
      }
      if (r.exitCode != 0) continue;
      final output = r.stdout.trim();
      lastVersionOutput = output;
      if (_validatePythonVersion(output)) {
        return (cmd, output);
      }
    }
    return (null, lastVersionOutput ?? '');
  }

  /// 首个可用的 pip：裸命令 -> 绝对候选链 -> 已选 python `-m pip` 兜底
  /// （保证与检测通过的 python 同解释器）。
  static Future<(String?, List<String>)> _resolvePip(
    CliProcRunner run,
    CliExistsFn exists,
    String? pythonCmd,
  ) async {
    final bare = Platform.isWindows ? 'pip' : 'pip3';
    final candidates = <(String, List<String>)>[
      (bare, ['--version']),
      ..._pipCandidates().map((p) => (p, <String>['--version'])),
      if (pythonCmd != null) (pythonCmd, ['-m', 'pip', '--version']),
    ];
    for (final (cmd, args) in candidates) {
      if (cmd.contains('/') && !exists(cmd)) continue;
      final ProcessRunResult r;
      try {
        r = await run(cmd, args);
      } catch (_) {
        continue;
      }
      if (r.exitCode == 0) {
        return (cmd, args);
      }
    }
    return (null, const <String>[]);
  }

  static Future<EnvCheckResult> checkEnvironment({
    CliProcRunner run = runCommand,
    CliExistsFn exists = defaultExists,
  }) async {
    try {
      final (pythonCmd, pythonVersion) = await _resolvePython(run, exists);
      if (pythonCmd == null) {
        // spawn 过但版本不达标 -> 版本过低；完全没找到 -> 未安装
        if (pythonVersion.isNotEmpty) {
          return EnvCheckResult(
            available: false,
            errorKey: 'pythonVersionTooLow',
            pythonVersion: pythonVersion,
          );
        }
        return EnvCheckResult(available: false, errorKey: 'pythonNotInstalled');
      }

      final (pipCmd, pipArgs) = await _resolvePip(run, exists, pythonCmd);
      if (pipCmd == null) {
        return EnvCheckResult(available: false, errorKey: 'pipNotInstalled');
      }
      final pipResult = await run(pipCmd, pipArgs);
      final pipVersion = pipResult.stdout.trim().isNotEmpty
          ? pipResult.stdout.trim()
          : pipResult.stderr.trim();

      return EnvCheckResult(
        available: true,
        pythonVersion: pythonVersion,
        pipVersion: pipVersion,
      );
    } catch (e) {
      return EnvCheckResult(
        available: false,
        errorKey: 'envCheckError',
        errorArgs: [e.toString()],
      );
    }
  }

  static bool defaultExists(String path) => File(path).existsSync();

  static bool _validatePythonVersion(String versionOutput) {
    try {
      // 解析类似 "Python 3.9.12" 或 "Python 3.10.4" 的输出
      final parts = versionOutput.split(' ');
      if (parts.length < 2) return false;

      final versionStr = parts[1];
      final versionParts = versionStr.split('.');
      if (versionParts.length < 2) return false;

      final major = int.tryParse(versionParts[0]);
      final minor = int.tryParse(versionParts[1]);

      if (major == null || minor == null) return false;

      if (major < _minPythonMajor) return false;
      if (major == _minPythonMajor && minor < _minPythonMinor) return false;

      return true;
    } catch (_) {
      return false;
    }
  }

  /// 解析 opennote CLI 命令：裸命令 -> 平台绝对候选链。
  /// 返回 (命令, 参数)；Windows 经 cmd /c 保证 PATH 解析并避免匹配桌面应用 exe。
  static Future<(String, List<String>)?> _resolveCli(
    CliProcRunner run,
    CliExistsFn exists,
  ) async {
    final candidates = Platform.isWindows
        ? <(String, List<String>)>[('cmd', ['/c', 'opennote', '--version'])]
        : <(String, List<String>)>[
            ('opennote', ['--version']),
            ..._cliCandidates().map((p) => (p, <String>['--version'])),
          ];
    for (final (cmd, args) in candidates) {
      // cmd /c 与裸命令交给系统解析；绝对候选做存在性守卫
      if (Platform.isWindows || !cmd.contains('/') || exists(cmd)) {
        final ProcessRunResult r;
        try {
          r = await run(cmd, args,
              workingDirectory: Directory.systemTemp.path);
        } catch (_) {
          continue;
        }
        if (r.exitCode != 0) continue;
        final output = r.stdout.toLowerCase();
        if (output.contains('open-note-cli') || output.contains('opennote-cli')) {
          return (cmd, args);
        }
      }
    }
    return null;
  }

  static Future<bool> isCLIInstalled({
    CliProcRunner run = runCommand,
    CliExistsFn exists = defaultExists,
  }) async {
    return await _resolveCli(run, exists) != null;
  }

  static Future<InstallResult> install({
    CliProcRunner run = runCommand,
    CliExistsFn exists = defaultExists,
  }) async {
    try {
      // 用检测通过的 python 解释器 -m pip 安装，确保 CLI 装到正确环境
      final (pythonCmd, _) = await _resolvePython(run, exists);
      if (pythonCmd == null) {
        return InstallResult(
          success: false,
          errorKey: 'pythonVersionMismatch',
        );
      }

      final result = await run(
          pythonCmd, ['-m', 'pip', 'install', 'open-note-cli', '--upgrade']);

      final stderr = result.stderr;
      final exitCode = result.exitCode;

      if (exitCode != 0) {
        // 检测是否为 Python 版本不匹配错误
        if (stderr.contains('requires a different Python') ||
            stderr.contains('requires-python') ||
            stderr.contains('version')) {
          return InstallResult(
            success: false,
            output: result.stdout,
            errorKey: 'pythonVersionMismatch',
          );
        }

        return InstallResult(
          success: false,
          output: result.stdout,
          errorKey: 'installProcessError',
        );
      }

      return InstallResult(success: true, output: result.stdout);
    } catch (e) {
      return InstallResult(
        success: false,
        errorKey: 'installProcessError',
        errorArgs: [e.toString()],
      );
    }
  }

  /// Returns the key for fallback instructions based on platform
  static String getFallbackInstructionsKey() {
    if (Platform.isMacOS) return 'envInstructionsMac';
    if (Platform.isWindows) return 'envInstructionsWindows';
    return 'envInstructionsLinux';
  }
}

class EnvCheckResult {
  final bool available;
  final String? pythonVersion;
  final String? pipVersion;
  final String? errorKey;
  final List<String> errorArgs;

  EnvCheckResult({
    required this.available,
    this.pythonVersion,
    this.pipVersion,
    this.errorKey,
    this.errorArgs = const [],
  });
}

class InstallResult {
  final bool success;
  final String output;
  final String? errorKey;
  final List<String> errorArgs;

  InstallResult({
    required this.success,
    this.output = '',
    this.errorKey,
    this.errorArgs = const [],
  });
}
