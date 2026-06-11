// Copyright (c) 2026 litongshuai
// SPDX-License-Identifier: MIT OR Apache-2.0

import 'dart:io';

class CLIInstallService {
  static const int _minPythonMajor = 3;
  static const int _minPythonMinor = 10;

  static Future<EnvCheckResult> checkEnvironment() async {
    try {
      final pythonCmd = Platform.isWindows ? 'python' : 'python3';
      final pipCmd = Platform.isWindows ? 'pip' : 'pip3';

      final pythonResult = await Process.run(pythonCmd, ['--version']);
      if (pythonResult.exitCode != 0) {
        return EnvCheckResult(available: false, errorKey: 'pythonNotInstalled');
      }

      final versionOutput = pythonResult.stdout.toString().trim();
      if (!_validatePythonVersion(versionOutput)) {
        return EnvCheckResult(
          available: false,
          errorKey: 'pythonVersionTooLow',
          pythonVersion: versionOutput,
        );
      }

      final pipResult = await Process.run(pipCmd, ['--version']);
      if (pipResult.exitCode != 0) {
        return EnvCheckResult(available: false, errorKey: 'pipNotInstalled');
      }

      return EnvCheckResult(
        available: true,
        pythonVersion: versionOutput,
        pipVersion: pipResult.stdout.toString().trim(),
      );
    } catch (e) {
      return EnvCheckResult(
        available: false,
        errorKey: 'envCheckError',
        errorArgs: [e.toString()],
      );
    }
  }

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

  static Future<bool> isCLIInstalled() async {
    try {
      // Windows 使用 cmd /c 确保 PATH 解析正确，避免匹配到桌面应用 exe
      final cmd = Platform.isWindows ? 'cmd' : 'opennote';
      final args = Platform.isWindows
          ? ['/c', 'opennote', '--version']
          : ['--version'];

      final result = await Process.run(
        cmd,
        args,
        workingDirectory: Directory.systemTemp.path,
      );
      if (result.exitCode != 0) return false;

      final output = result.stdout.toString().toLowerCase();
      return output.contains('open-note-cli') ||
          output.contains('opennote-cli');
    } catch (e) {
      return false;
    }
  }

  static Future<InstallResult> install() async {
    try {
      final pipCmd = Platform.isWindows ? 'pip' : 'pip3';

      final result = await Process.run(pipCmd, [
        'install',
        'open-note-cli',
        '--upgrade',
      ]);

      final stderr = result.stderr.toString();
      final exitCode = result.exitCode;

      if (exitCode != 0) {
        // 检测是否为 Python 版本不匹配错误
        if (stderr.contains('requires a different Python') ||
            stderr.contains('requires-python') ||
            stderr.contains('version')) {
          return InstallResult(
            success: false,
            output: result.stdout.toString(),
            errorKey: 'pythonVersionMismatch',
          );
        }

        return InstallResult(
          success: false,
          output: result.stdout.toString(),
          errorKey: 'installProcessError',
        );
      }

      return InstallResult(success: true, output: result.stdout.toString());
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
