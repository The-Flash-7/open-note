// Copyright (c) 2026 litongshuai
// SPDX-License-Identifier: MIT OR Apache-2.0

import 'dart:io';
import 'package:dio/dio.dart';
import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';
import '../models/knowledge_base_config.dart';

class EmbeddingModelDownloader {
  static const String _baseUrl =
      'https://modelscope.cn/models/onnx-community/embeddinggemma-300m-ONNX/resolve/master';

  static const Map<EmbeddingModelVersion, Map<String, String>> _modelFiles = {
    EmbeddingModelVersion.fp16: {
      'model': 'onnx/model_fp16.onnx',
      'data': 'onnx/model_fp16.onnx_data',
    },
    EmbeddingModelVersion.q8: {
      'model': 'onnx/model_quantized.onnx',
      'data': 'onnx/model_quantized.onnx_data',
    },
    EmbeddingModelVersion.q4: {
      'model': 'onnx/model_q4.onnx',
      'data': 'onnx/model_q4.onnx_data',
    },
  };

  static const Map<String, String> _modelHashes = {
    // FP16
    'model_fp16.onnx':
        'dcfaf21ff7cae91af9295366ac0d7352efcadeaf7deefb98f82d5056502d0bf2',
    'model_fp16.onnx_data':
        '1cd839755aa8e24d5af7f16ef275b12d717a4401bb009099b8c17e4156d3d5d5',
    // Q8
    'model_quantized.onnx':
        '172efde319fe1542dc41f31be6154910b05b78f7a861c265c4600eec906bd6d8',
    'model_quantized.onnx_data':
        '705626e28e4c23c82ade34566b4197d97f534c12275fa406dfb71e9937d388c0',
    // Q4
    'model_q4.onnx':
        'ad1dfee81a70f7944b9b9d1cc6e48075b832881cf33fab2f2b248be78f3f0043',
    'model_q4.onnx_data':
        '599962c3143b040de2dd05e5975be3e9091dd067cacc6a8f7186e3203bab9e02',
    // Tokenizer
    'tokenizer.json':
        '4dda02faaf32bc91031dc8c88457ac272b00c1016cc679757d1c441b248b9c47',
  };

  static Future<String> getDefaultModelPath(
    EmbeddingModelVersion version,
  ) async {
    final appDir = await getApplicationSupportDirectory();
    final modelDir = Directory(
      '${appDir.path}/models/embedding-gemma/${version.name}',
    );
    if (!await modelDir.exists()) {
      await modelDir.create(recursive: true);
    }
    return modelDir.path;
  }

  static Future<String> getDefaultTokenizerPath() async {
    final appDir = await getApplicationSupportDirectory();
    return '${appDir.path}/models/embedding-gemma/tokenizer.json';
  }

  static Future<bool> isModelExists(EmbeddingModelVersion version) async {
    final modelDir = await getDefaultModelPath(version);
    final tokenizerPath = await getDefaultTokenizerPath();

    final files = _modelFiles[version]!;
    final modelFileName = files['model']!.split('/').last;
    final dataFileName = files['data']!.split('/').last;

    final modelFile = File('$modelDir/$modelFileName');
    final dataFile = File('$modelDir/$dataFileName');
    final tokenizerFile = File(tokenizerPath);

    return await modelFile.exists() &&
        await dataFile.exists() &&
        await tokenizerFile.exists();
  }

  static Future<bool> verifyModelIntegrity(
    EmbeddingModelVersion version,
  ) async {
    try {
      final modelDir = await getDefaultModelPath(version);
      await verifyDownloadedModel(modelDir, version);
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<void> download({
    required EmbeddingModelVersion version,
    required String outputDir,
    void Function(double progress, double speedMbps)? onProgress,
  }) async {
    final dir = Directory(outputDir);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    final dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(hours: 2),
        sendTimeout: const Duration(seconds: 60),
        validateStatus: (status) {
          return status != null && status < 500;
        },
      ),
    );

    final files = _modelFiles[version]!;

    // 提取原始文件名（保持 ONNX 内部引用的路径一致）
    final modelFileName = files['model']!.split('/').last;
    final dataFileName = files['data']!.split('/').last;

    // 1. 下载 model.onnx（保持原始文件名）
    await _downloadWithRetry(
      dio: dio,
      url: '$_baseUrl/${files['model']}',
      outputPath: '$outputDir/$modelFileName',
      onProgress: null,
      maxRetries: 1,
    );

    // 2. 下载 model.onnx_data（保持原始文件名）
    await _downloadWithRetry(
      dio: dio,
      url: '$_baseUrl/${files['data']}',
      outputPath: '$outputDir/$dataFileName',
      onProgress: onProgress,
      maxRetries: 1,
    );

    // 3. 下载 tokenizer.json（所有版本共享，已存在则跳过）
    final tokenizerPath = await getDefaultTokenizerPath();
    if (!await File(tokenizerPath).exists()) {
      await _downloadWithRetry(
        dio: dio,
        url: '$_baseUrl/tokenizer.json',
        outputPath: tokenizerPath,
        onProgress: null,
        maxRetries: 1,
      );
    }

    // 4. 校验模型文件完整性（不含 tokenizer，因为共享）
    await verifyDownloadedModel(outputDir, version);
  }

  static Future<void> verifyDownloadedModel(
    String outputDir,
    EmbeddingModelVersion version,
  ) async {
    final files = _modelFiles[version]!;

    final modelFile = files['model']!.split('/').last;
    final dataFile = files['data']!.split('/').last;

    final modelHash = _modelHashes[modelFile]!;
    final dataHash = _modelHashes[dataFile]!;

    final modelPath = '$outputDir/$modelFile';
    final dataPath = '$outputDir/$dataFile';

    final modelValid = await _verifyFileHash(modelPath, modelHash);
    final dataValid = await _verifyFileHash(dataPath, dataHash);

    if (!modelValid || !dataValid) {
      try {
        await File(modelPath).delete();
      } catch (_) {}
      try {
        await File(dataPath).delete();
      } catch (_) {}

      final errors = <String>[];
      if (!modelValid) errors.add(modelFile);
      if (!dataValid) errors.add(dataFile);

      throw Exception('模型文件校验失败: ${errors.join(', ')}，已删除损坏文件，请重新下载');
    }
  }

  static Future<bool> _verifyFileHash(
    String filePath,
    String expectedHash,
  ) async {
    final file = File(filePath);
    if (!await file.exists()) return false;

    final bytes = await file.readAsBytes();
    final digest = sha256.convert(bytes);
    return digest.toString() == expectedHash;
  }

  static Future<void> _downloadWithRetry({
    required Dio dio,
    required String url,
    required String outputPath,
    void Function(double progress, double speedMbps)? onProgress,
    int maxRetries = 1,
  }) async {
    int attempt = 0;
    Exception? lastError;

    while (attempt <= maxRetries) {
      try {
        if (attempt > 0) {
          await Future.delayed(Duration(seconds: attempt * 3));
        }

        await _downloadFile(
          dio: dio,
          url: url,
          outputPath: outputPath,
          onProgress: onProgress,
        );
        return;
      } catch (e) {
        lastError = e is Exception ? e : Exception(e.toString());
        attempt++;
      }
    }

    throw lastError ?? Exception('下载失败');
  }

  static Future<void> _downloadFile({
    required Dio dio,
    required String url,
    required String outputPath,
    void Function(double progress, double speedMbps)? onProgress,
  }) async {
    final startTime = DateTime.now();

    await dio.download(
      url,
      outputPath,
      onReceiveProgress: (received, total) {
        if (total > 0) {
          final progress = received / total;
          final elapsed = DateTime.now().difference(startTime).inSeconds;
          final speedMbps = elapsed > 0
              ? (received / elapsed / 1024 / 1024)
              : 0.0;
          onProgress?.call(progress, speedMbps);
        }
      },
    );
  }

  static bool verifyModel(String modelDir) {
    final dir = Directory(modelDir);
    if (!dir.existsSync()) return false;

    // 检查是否存在任意版本的 .onnx 文件
    final onnxFiles = dir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.onnx'))
        .toList();

    final tokenizerFile = File('$modelDir/tokenizer.json');
    return onnxFiles.isNotEmpty && tokenizerFile.existsSync();
  }
}
