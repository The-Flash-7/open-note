// Copyright (c) 2026 litongshuai
// SPDX-License-Identifier: MIT OR Apache-2.0

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'embedding_service_status.dart';

class PythonServiceManager {
  static final PythonServiceManager _instance =
      PythonServiceManager._internal();
  factory PythonServiceManager() => _instance;
  PythonServiceManager._internal();

  Process? _pythonProcess;
  int? _pythonPid;
  bool _isRunning = false;
  bool _isPrepared = false;
  String _baseUrl = 'http://127.0.0.1:8765';
  String? _servicePath;

  bool get isRunning => _isRunning;
  bool get isPrepared => _isPrepared;
  String get baseUrl => _baseUrl;

  static const String _serviceIdentity = 'open-note-embedding-service';
  static const String _appId = 'net.zsdn.opennote';

  /// 准备 Python 服务（解压到应用数据目录）

  /// 准备 Python 服务（解压到应用数据目录）
  Future<bool> prepareService({
    void Function(String status, double progress)? onProgress,
  }) async {
    if (_isPrepared &&
        _servicePath != null &&
        File(_servicePath!).existsSync()) {
      onProgress?.call('就绪', 1.0);
      return true;
    }

    try {
      onProgress?.call('正在准备...', 0.1);

      // 获取应用数据目录
      final appDir = await getApplicationSupportDirectory();
      final targetDir = Directory('${appDir.path}/embedding_service');
      if (!await targetDir.exists()) {
        await targetDir.create(recursive: true);
      }

      onProgress?.call('正在解压...', 0.3);

      // 确定平台对应的文件名
      final bundledFileName = Platform.isWindows
          ? 'embedding_service.exe'
          : 'embedding_service';

      final bundledPath = 'assets/embedding_service/$bundledFileName';
      final targetPath =
          '${targetDir.path}/embedding_service${Platform.isWindows ? '.exe' : ''}';

      // 检查是否已存在且版本匹配（使用 MD5 校验）
      if (await File(targetPath).exists()) {
        onProgress?.call('正在校验版本...', 0.2);

        // 读取目标文件的 MD5
        final targetFile = File(targetPath);
        final targetBytes = await targetFile.readAsBytes();
        final targetHash = md5.convert(targetBytes).toString();

        // 读取 assets 中打包文件的 MD5
        final bundledData = await rootBundle.load(bundledPath);
        final bundledBytes = bundledData.buffer.asUint8List();
        final bundledHash = md5.convert(bundledBytes).toString();

        if (targetHash == bundledHash) {
          // 版本一致，跳过复制
          debugPrint('PythonService: 版本一致，跳过更新 ($targetHash)');
          onProgress?.call('就绪', 1.0);
          _isPrepared = true;
          _servicePath = targetPath;
          return true;
        }

        // 版本不一致，需要更新
        debugPrint('PythonService: 检测到新版本，正在更新...');
        debugPrint('PythonService: 当前: $targetHash → 新: $bundledHash');
      }

      // 从资源目录复制
      onProgress?.call('正在安装...', 0.5);
      final data = await rootBundle.load(bundledPath);
      final bytes = data.buffer.asUint8List();
      await File(targetPath).writeAsBytes(bytes);

      // 设置执行权限（macOS/Linux）
      if (!Platform.isWindows) {
        onProgress?.call('正在配置...', 0.8);
        await Process.run('chmod', ['+x', targetPath]);
      }

      _servicePath = targetPath;
      _isPrepared = true;

      onProgress?.call('完成', 1.0);
      debugPrint('PythonService: 服务已准备就绪 ($targetPath)');
      return true;
    } catch (e) {
      debugPrint('PythonService: 准备失败: $e');
      onProgress?.call('准备失败: $e', 0);
      return false;
    }
  }

  /// 检查端口上是否已有我们的服务在运行
  Future<ServiceCheckResult> checkExistingService(int port) async {
    int? pid;
    try {
      final response = await http
          .get(Uri.parse('http://127.0.0.1:$port/api/service/identity'))
          .timeout(const Duration(seconds: 2));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final service = data['service'] as String?;
        final appId = data['app_id'] as String?;

        // 获取进程 PID
        pid = await _getProcessIdByPort(port);

        if (service == _serviceIdentity && appId == _appId) {
          debugPrint('PythonService: 检测到已有服务在运行 (端口 $port, PID: $pid)');
          return ServiceCheckResult(
            isRunning: true,
            isOurService: true,
            pid: pid,
          );
        } else {
          debugPrint(
            'PythonService: 端口 $port 被其他服务占用 (service: $service, PID: $pid)',
          );
          return ServiceCheckResult(
            isRunning: true,
            isOurService: false,
            pid: pid,
          );
        }
      }
    } catch (e) {
      // 端口未被占用或服务未响应
    }

    return ServiceCheckResult(isRunning: false, isOurService: false, pid: pid);
  }

  /// 获取占用指定端口的进程 PID
  Future<int?> _getProcessIdByPort(int port) async {
    try {
      if (Platform.isMacOS || Platform.isLinux) {
        final result = await Process.run('lsof', ['-ti', ':$port']);
        if (result.exitCode == 0 && result.stdout.toString().isNotEmpty) {
          final pids = result.stdout.toString().trim().split('\n');
          if (pids.isNotEmpty && pids[0].isNotEmpty) {
            return int.tryParse(pids[0].trim());
          }
        }
      } else if (Platform.isWindows) {
        final result = await Process.run('netstat', ['-ano']);
        if (result.exitCode == 0) {
          final lines = result.stdout.toString().split('\n');
          for (final line in lines) {
            if (line.contains(':$port') && line.contains('LISTENING')) {
              final parts = line.trim().split(RegExp(r'\s+'));
              if (parts.length >= 5) {
                return int.tryParse(parts[4]);
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint('PythonService: 获取端口 $port 的 PID 失败: $e');
    }
    return null;
  }

  /// 终止占用端口的进程
  Future<void> killProcessOnPort(int port) async {
    try {
      if (Platform.isMacOS || Platform.isLinux) {
        // macOS/Linux: 使用 lsof 查找并终止进程
        final result = await Process.run('lsof', ['-ti', ':$port']);
        if (result.exitCode == 0 && result.stdout.toString().isNotEmpty) {
          final pids = result.stdout.toString().trim().split('\n');
          for (final pid in pids) {
            if (pid.isNotEmpty) {
              await Process.run('kill', ['-9', pid.trim()]);
              debugPrint('PythonService: 已终止进程 $pid');
            }
          }
          // 等待端口释放
          await Future.delayed(const Duration(milliseconds: 500));
        }
      } else if (Platform.isWindows) {
        // Windows: 使用 netstat 和 taskkill
        final result = await Process.run('netstat', ['-ano']);
        if (result.exitCode == 0) {
          final lines = result.stdout.toString().split('\n');
          for (final line in lines) {
            if (line.contains(':$port') && line.contains('LISTENING')) {
              final parts = line.trim().split(RegExp(r'\s+'));
              if (parts.length >= 5) {
                final pid = parts[4];
                await Process.run('taskkill', ['/F', '/PID', pid]);
                debugPrint('PythonService: 已终止进程 $pid');
              }
            }
          }
          await Future.delayed(const Duration(milliseconds: 500));
        }
      }
    } catch (e) {
      debugPrint('PythonService: 终止端口 $port 进程失败: $e');
    }
  }

  /// 启动 Python 服务
  Future<bool> start({
    String? modelDir,
    int port = 8765,
    Duration timeout = const Duration(seconds: 60),
  }) async {
    if (_isRunning) {
      debugPrint('PythonService: 服务已在运行');
      return true;
    }

    // 确保服务已准备
    if (!_isPrepared) {
      final prepared = await prepareService();
      if (!prepared) {
        debugPrint('PythonService: 服务未准备，无法启动');
        return false;
      }
    }

    if (_servicePath == null || !File(_servicePath!).existsSync()) {
      debugPrint('PythonService: 服务文件不存在');
      return false;
    }

    try {
      debugPrint('PythonService: 正在启动服务...');

      // 检查是否已有服务在运行
      final existingService = await checkExistingService(port);
      if (existingService.isRunning) {
        if (existingService.isOurService) {
          debugPrint(
            'PythonService: 复用已有服务 (端口 $port, PID: ${existingService.pid})',
          );
          _baseUrl = 'http://127.0.0.1:$port';
          _isRunning = true;
          _pythonPid = existingService.pid; // 记录 PID 以便后续停止
          return true;
        } else {
          debugPrint('PythonService: 端口 $port 被其他服务占用，正在终止...');
          await killProcessOnPort(port);
        }
      }

      final appDir = await getApplicationSupportDirectory();
      final chromaDataDir = '${appDir.path}/chroma_db';

      final args = ['--port', port.toString(), '--data-dir', chromaDataDir];
      if (modelDir != null && modelDir.isNotEmpty) {
        args.addAll(['--model-dir', modelDir]);
      }

      _pythonProcess = await Process.start(
        _servicePath!,
        args,
        mode: ProcessStartMode.normal,
      );

      _baseUrl = 'http://127.0.0.1:$port';
      _isRunning = true;

      // 设置退出监听器（普通模式下可以正常访问 exitCode）
      _pythonProcess!.exitCode.then((code) {
        debugPrint('PythonService: 进程退出，代码: $code');
        _isRunning = false;
        _pythonProcess = null;
        _pythonPid = null;
      });

      // 可选：监听标准输出用于调试
      _pythonProcess!.stdout
          .transform(const Utf8Codec(allowMalformed: true).decoder)
          .listen((data) {
            debugPrint('PythonService[stdout]: $data');
          });
      _pythonProcess!.stderr
          .transform(const Utf8Codec(allowMalformed: true).decoder)
          .listen((data) {
            debugPrint('PythonService[stderr]: $data');
          });

      // 等待服务就绪
      final ready = await _waitForReady(timeout);
      if (ready) {
        debugPrint('PythonService: 服务已启动 ($baseUrl)');
      } else {
        debugPrint('PythonService: 服务启动超时');
        _isRunning = false;
        return false;
      }

      return true;
    } catch (e) {
      debugPrint('PythonService: 启动失败: $e');
      _isRunning = false;
      return false;
    }
  }

  /// 停止 Python 服务（同步方法，用于 dispose）
  void stopSync() {
    debugPrint(
      '🚨 stopSync: _isRunning=$_isRunning, _pythonProcess=${_pythonProcess != null}, _pythonPid=$_pythonPid',
    );
    if (!_isRunning) {
      debugPrint('🚨 stopSync: _isRunning=false，直接返回');
      return;
    }

    try {
      debugPrint('🚨 stopSync: 正在停止服务...');
      // 方式 1：如果有 Process 对象，通过它 kill
      if (_pythonProcess != null) {
        _pythonProcess!.kill();
        _pythonProcess = null;
      }

      // 方式 2：如果有 PID（复用服务的情况），通过 PID kill
      if (_pythonPid != null) {
        debugPrint('🚨 stopSync: 通过 PID $_pythonPid 终止进程');
        Process.killPid(_pythonPid!, ProcessSignal.sigterm);
        _pythonPid = null;
      }

      _isRunning = false;
      debugPrint('🚨 stopSync: 服务已停止');
    } catch (e) {
      debugPrint('🚨 stopSync: 停止失败: $e');
    }
  }

  /// 停止 Python 服务（异步方法）
  Future<void> stop() async {
    if (!_isRunning || _pythonProcess == null) return;

    try {
      debugPrint('PythonService: 正在停止服务...');
      _pythonProcess!.kill();
      _pythonProcess = null;
      _isRunning = false;
      debugPrint('PythonService: 服务已停止');
    } catch (e) {
      debugPrint('PythonService: 停止失败: $e');
    }
  }

  /// 等待服务就绪（通过轮询 /api/service/status 直到 state == ready）
  Future<bool> _waitForReady(Duration timeout) async {
    final startTime = DateTime.now();
    int attempt = 0;
    while (DateTime.now().difference(startTime) < timeout) {
      attempt++;
      try {
        final response = await http
            .get(Uri.parse('$_baseUrl/api/service/status'))
            .timeout(const Duration(seconds: 2));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          final state = data['state'] as String? ?? '';
          final elapsed = DateTime.now().difference(startTime).inMilliseconds;

          if (state == 'ready') {
            debugPrint('PythonService: 服务就绪 (第 $attempt 次, ${elapsed}ms)');
            return true;
          } else {
            // Service is still initializing, log progress
            if (attempt <= 3 || attempt % 10 == 0) {
              final message = data['message'] as String? ?? '';
              debugPrint(
                'PythonService: 等待中... state=$state, message=$message',
              );
            }

            // If error state, return false immediately
            if (state.startsWith('error_')) {
              final message = data['message'] as String? ?? '未知错误';
              debugPrint('PythonService: 服务初始化失败: $message');
              return false;
            }
          }
        }
      } catch (e) {
        if (attempt <= 3) {
          debugPrint('PythonService: 状态检查等待中... (第 $attempt 次)');
        }
      }

      await Future.delayed(const Duration(milliseconds: 500));
    }
    final elapsed = DateTime.now().difference(startTime).inMilliseconds;
    debugPrint('PythonService: 服务就绪超时 (${elapsed}ms, 共 $attempt 次尝试)');
    return false;
  }

  /// 获取服务详细状态
  Future<EmbeddingServiceStatus?> fetchServiceStatus() async {
    if (!_isRunning) return null;

    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/api/service/status'))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return EmbeddingServiceStatus.fromJson(data);
      }
    } catch (e) {
      debugPrint('PythonService: 获取状态失败: $e');
    }

    return null;
  }

  /// 热切换模型（无需重启服务），切换前会清空向量索引
  Future<bool> switchModel(String modelDir) async {
    if (!_isRunning) return false;
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/api/model/switch'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'model_dir': modelDir}),
          )
          .timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final success = data['success'] == true;
        final message = data['message'] as String? ?? '';
        debugPrint('PythonService: 模型切换${success ? "成功" : "失败"}: $message');
        return success;
      }
      debugPrint('PythonService: 模型切换 HTTP ${response.statusCode}');
      return false;
    } catch (e) {
      debugPrint('PythonService: 切换模型失败: $e');
      return false;
    }
  }

  /// 请求 Python 服务内部重启（进程不终止，仅重新加载模型和数据库）
  /// 注意：此方法要求服务进程已在运行，如果未运行请先调用 start()
  Future<bool> restartService() async {
    if (!_isRunning) {
      debugPrint('PythonService: 服务未运行，无法重启');
      return false;
    }
    try {
      final response = await http
          .post(Uri.parse('$_baseUrl/api/service/restart'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        debugPrint('PythonService: 重启请求已发送，等待服务重新就绪...');
        // 等待服务重新就绪（重启可能需要更长时间）
        return await _waitForReady(const Duration(seconds: 60));
      }
      debugPrint('PythonService: 重启请求失败 HTTP ${response.statusCode}');
      return false;
    } catch (e) {
      debugPrint('PythonService: 重启服务失败: $e');
      return false;
    }
  }

  /// 检查服务健康状态（旧接口，保留兼容）
  Future<Map<String, dynamic>?> getEmbeddingStatus() async {
    if (!_isRunning) return null;

    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/api/embedding/status'))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('PythonService: 获取状态失败: $e');
    }

    return null;
  }

  /// 清理资源
  void dispose() {
    stop();
  }
}

class ServiceCheckResult {
  final bool isRunning;
  final bool isOurService;
  final int? pid;

  ServiceCheckResult({
    required this.isRunning,
    required this.isOurService,
    this.pid,
  });
}
