// Copyright (c) 2026 litongshuai
// SPDX-License-Identifier: MIT OR Apache-2.0

import 'package:flutter_test/flutter_test.dart';
import 'package:open_note/services/shell_path_service.dart';

void main() {
  setUp(ShellPathService.invalidateCache);
  tearDown(ShellPathService.invalidateCache);

  group('parseSentinelPath', () {
    test('正常输出：标记之间即 PATH', () {
      final dirs = ShellPathService.parseSentinelPath(
          '__OPENNOTE_PATH_BEGIN__\n/opt/homebrew/bin:/usr/local/bin\n__OPENNOTE_PATH_END__\n');
      expect(dirs, ['/opt/homebrew/bin', '/usr/local/bin']);
    });

    test('rc echo 噪音在标记前后：全部无视', () {
      final stdout = '欢迎回来！\nnvm loaded\n'
          '__OPENNOTE_PATH_BEGIN__\n'
          '/Users/x/miniforge3/bin:/usr/bin\n'
          '__OPENNOTE_PATH_END__\nsome precmd output\n';
      expect(ShellPathService.parseSentinelPath(stdout),
          ['/Users/x/miniforge3/bin', '/usr/bin']);
    });

    test('去重保序、去空段', () {
      final dirs = ShellPathService.parseSentinelPath(
          '__OPENNOTE_PATH_BEGIN__\n/a:/b:/a::/b:/c\n__OPENNOTE_PATH_END__\n');
      expect(dirs, ['/a', '/b', '/c']);
    });

    test('缺开始或结束标记 -> 空（降级信号）', () {
      expect(ShellPathService.parseSentinelPath('no markers\n/a:/b'), isEmpty);
      expect(
          ShellPathService.parseSentinelPath(
              '__OPENNOTE_PATH_BEGIN__\n/a:/b\n'),
          isEmpty);
    });

    test('标记之间为空 -> 空', () {
      expect(
          ShellPathService.parseSentinelPath(
              '__OPENNOTE_PATH_BEGIN__\n__OPENNOTE_PATH_END__\n'),
          isEmpty);
    });
  });

  group('loginShellBinDirs', () {
    test('向登录 shell 要 PATH 并解析（run 注入）', () async {
      Future<String> fakeRun(String exe, List<String> args) async {
        expect(args[0], '-l');
        expect(args[1], '-c');
        expect(args[2], contains('__OPENNOTE_PATH_BEGIN__'));
        expect(args[2], contains(r'"$PATH"'));
        return '__OPENNOTE_PATH_BEGIN__\n/Users/x/miniforge3/bin:/usr/bin\n__OPENNOTE_PATH_END__\n';
      }

      expect(await ShellPathService.loginShellBinDirs(run: fakeRun),
          ['/Users/x/miniforge3/bin', '/usr/bin']);
    });

    test('shell 执行失败 -> 空列表（降级，不抛异常）', () async {
      Future<String> boom(String exe, List<String> args) async =>
          throw StateError('shell broken');
      expect(await ShellPathService.loginShellBinDirs(run: boom), isEmpty);
    });

    test('会话缓存：多次调用只 spawn 一次；invalidate 后重新查询', () async {
      var invocations = 0;
      Future<String> countingRun(String exe, List<String> args) async {
        invocations++;
        return '__OPENNOTE_PATH_BEGIN__\n/a:/b\n__OPENNOTE_PATH_END__\n';
      }

      await ShellPathService.loginShellBinDirs(run: countingRun);
      await ShellPathService.loginShellBinDirs(run: countingRun);
      expect(invocations, 1, reason: '会话内缓存应复用首次结果');

      ShellPathService.invalidateCache();
      await ShellPathService.loginShellBinDirs(run: countingRun);
      expect(invocations, 2);
    });
  });
}
