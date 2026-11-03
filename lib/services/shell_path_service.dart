// Copyright (c) 2026 litongshuai
// SPDX-License-Identifier: MIT OR Apache-2.0

import 'dart:async';
import 'dart:io';

/// 进程执行器（可注入测试）；返回 stdout。默认实现带超时杀进程。
typedef ShellRunner = Future<String> Function(
  String executable,
  List<String> args,
);

/// 登录 shell PATH 快照。
///
/// macOS GUI 应用从 Finder 启动时 PATH 仅含系统 4 目录，用户终端里
/// 可用的工具链（brew/conda/pyenv/mise/asdf/nix 等）全部来自 rc 配置
/// 注入的 PATH。本服务主动向用户登录 shell 要一次 PATH：
/// `$SHELL -lc 'echo 哨兵; echo "$PATH"; echo 哨兵'`，
/// 哨兵标记隔离 rc 里的任意 echo 噪音；结果会话内缓存。
class ShellPathService {
  static const _begin = '__OPENNOTE_PATH_BEGIN__';
  static const _end = '__OPENNOTE_PATH_END__';

  /// 会话内缓存（首查后全程复用，避免每次打开设置页重复 spawn shell）。
  static Future<List<String>>? _cache;

  /// 解析哨兵标记包裹的 PATH：取两标记之间内容，按 `:` 切分，
  /// 去空去重保序。标记外内容（rc echo 噪音）一概无视。
  static List<String> parseSentinelPath(String stdout) {
    final lines = stdout.split('\n');
    final beginIdx = lines.indexOf(_begin);
    final endIdx = lines.indexOf(_end, beginIdx + 1);
    if (beginIdx < 0 || endIdx < 0) return const [];
    final payload = lines
        .sublist(beginIdx + 1, endIdx)
        .join(); // PATH 单行输出；多行则拼接容错
    final seen = <String>{};
    final dirs = <String>[];
    for (final d in payload.split(':')) {
      if (d.isEmpty || !seen.add(d)) continue;
      dirs.add(d);
    }
    return dirs;
  }

  /// 默认执行器：登录 shell 一次，超时杀进程防极端 rc 卡死。
  static Future<String> _defaultRunner(
    String executable,
    List<String> args, {
    Duration timeout = const Duration(seconds: 2),
  }) async {
    final process = await Process.start(executable, args);
    final killTimer = Timer(timeout, process.kill);
    try {
      final stdout = await process.stdout
          .transform(systemEncoding.decoder)
          .join();
      await process.stderr.drain<void>();
      await process.exitCode;
      return stdout;
    } finally {
      killTimer.cancel();
    }
  }

  /// 登录 shell 的 PATH bin 目录列表；Windows 无登录 shell 概念返回空；
  /// 失败/超时/解析不出标记一律返回空（调用方降级静态候选链）。
  static Future<List<String>> loginShellBinDirs({
    ShellRunner? run,
  }) async {
    if (Platform.isWindows) return const [];
    return _cache ??= _query(run: run);
  }

  /// 测试隔离用：清空会话缓存。
  static void invalidateCache() {
    _cache = null;
  }

  static Future<List<String>> _query({ShellRunner? run}) async {
    try {
      final shell = Platform.environment['SHELL'] ??
          (Platform.isMacOS ? '/bin/zsh' : '/bin/bash');
      final runner = run ??
          (String exe, List<String> args) =>
              _defaultRunner(exe, args);
      final stdout = await runner(shell, [
        '-l',
        '-c',
        'echo "$_begin"; echo "\$PATH"; echo "$_end"',
      ]);
      return parseSentinelPath(stdout);
    } catch (_) {
      return const [];
    }
  }
}
