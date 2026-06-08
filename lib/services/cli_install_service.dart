// Copyright (c) 2026 litongshuai
// SPDX-License-Identifier: MIT OR Apache-2.0

import 'dart:io';

class CLIInstallService {
  static Future<EnvCheckResult> checkEnvironment() async {
    try {
      final pythonCmd = Platform.isWindows ? 'python' : 'python3';
      final pipCmd = Platform.isWindows ? 'pip' : 'pip3';

      final pythonResult = await Process.run(pythonCmd, ['--version']);
      if (pythonResult.exitCode != 0) {
        return EnvCheckResult(available: false, errorKey: 'pythonNotInstalled');
      }

      final pipResult = await Process.run(pipCmd, ['--version']);
      if (pipResult.exitCode != 0) {
        return EnvCheckResult(available: false, errorKey: 'pipNotInstalled');
      }

      return EnvCheckResult(
        available: true,
        pythonVersion: pythonResult.stdout.toString().trim(),
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

  static Future<bool> isCLIInstalled() async {
    try {
      final cmd = Platform.isWindows ? 'opennote' : 'opennote';
      final result = await Process.run(cmd, ['--version']);
      return result.exitCode == 0;
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

      return InstallResult(
        success: result.exitCode == 0,
        output: result.stdout.toString(),
        errorKey: result.exitCode != 0
            ? result.stderr.toString().replaceAll('\n', '')
            : null,
      );
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
