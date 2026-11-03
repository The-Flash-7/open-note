// test/widgets/tool_status_row_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_note/l10n/strings.g.dart';
import 'package:open_note/services/media/media_tool_service.dart';
import 'package:open_note/widgets/media_import/tool_status_row.dart';

/// testWidgets（FakeAsync）下 dart:io 异步无法完成（见
/// media_import_provider.dart uninstallTool 注释），toolDir 用纯内存 fake。
class _FakeToolDirService extends MediaToolService {
  _FakeToolDirService(this.dirPath)
      : super(resolveBaseDir: () async => dirPath);
  final String dirPath;
  @override
  Future<String> toolDir(MediaToolKind kind) async => dirPath;
}

const _readyFfmpeg = MediaToolStatus(
  kind: MediaToolKind.ffmpeg,
  ready: true,
  path: '/fake/ffmpeg',
  version: '6.0',
  source: MediaToolSource.appManaged,
);

Widget _host({String? systemHint}) => TranslationProvider(
      child: MaterialApp(
        home: Scaffold(
          body: ToolStatusRow(
            kind: MediaToolKind.ffmpeg,
            status: _readyFfmpeg,
            downloading: false,
            finishing: false,
            autoInstalling: false,
            guide: 'brew install ffmpeg',
            systemHint: systemHint,
          ),
        ),
      ),
    );

Widget _missingHost({
  required MediaToolKind kind,
  TargetPlatform platform = TargetPlatform.macOS,
  MediaToolService? toolService,
  bool finishing = false,
}) =>
    TranslationProvider(
      child: MaterialApp(
        theme: ThemeData(platform: platform),
        home: Scaffold(
          body: ToolStatusRow(
            kind: kind,
            status: MediaToolStatus.missing(kind),
            downloading: false,
            finishing: finishing,
            autoInstalling: false,
            guide: 'brew install whisper-cpp',
            toolService: toolService,
          ),
        ),
      ),
    );

void main() {
  testWidgets('ready 行渲染 systemHint 提示文本', (tester) async {
    await tester.pumpWidget(_host(
      systemHint: '更新未生效（下载源内容未变化），已保留当前版本',
    ));
    expect(find.text('更新未生效（下载源内容未变化），已保留当前版本'), findsOneWidget);
  });

  testWidgets('无 systemHint 时不渲染提示行', (tester) async {
    await tester.pumpWidget(_host());
    expect(find.text('更新未生效（下载源内容未变化），已保留当前版本'), findsNothing);
  });

  testWidgets('ErrorBanner 内容包 SelectionArea 可复制', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: ErrorBanner(message: '模型下载失败', detail: 'HTTP 404'),
      ),
    ));
    expect(find.text('模型下载失败\nHTTP 404'), findsOneWidget);
    expect(find.byType(SelectionArea), findsOneWidget);
  });

  testWidgets('finishing 阶段不显示下载便携版按钮（防闪烁回归）', (tester) async {
    await tester.pumpWidget(_missingHost(
      kind: MediaToolKind.ffmpeg,
      finishing: true,
    ));
    // ffmpeg 平台不过滤 hideDownload，按钮可显示性完全由状态机决定
    expect(find.text('下载便携版'), findsNothing);
  });

  testWidgets('? 按钮打开手动安装指引对话框（ffmpeg 仅指引命令段）', (tester) async {
    await tester.pumpWidget(_missingHost(kind: MediaToolKind.ffmpeg));
    await tester.tap(find.byIcon(Icons.help_outline));
    await tester.pumpAndSettle();
    expect(find.text('手动安装指引'), findsOneWidget);
    expect(find.text('brew install whisper-cpp'), findsOneWidget);
    expect(find.byType(SelectionArea), findsOneWidget);
    // 非 whisperCli+Windows 不出现下载页指引
    expect(
        find.text('浏览器打开下载页，选择 win-x64 zip（直连不畅时用镜像链接）'), findsNothing);
  });

  testWidgets('whisperCli+Windows 对话框含下载页链接与目标目录', (tester) async {
    final tools = _FakeToolDirService('/fake/base/tools/whisper');
    await tester.pumpWidget(_missingHost(
      kind: MediaToolKind.whisperCli,
      platform: TargetPlatform.windows,
      toolService: tools,
    ));
    await tester.tap(find.byIcon(Icons.help_outline));
    await tester.pumpAndSettle();
    expect(find.text('浏览器打开下载页，选择 win-x64 zip（直连不畅时用镜像链接）'),
        findsOneWidget);
    expect(find.textContaining('github.com/ggml-org/whisper.cpp/releases'),
        findsNWidgets(2)); // 直链 + 镜像
    expect(find.text('解压后将 whisper-cli.exe 及同目录 dll 放入下方目录'),
        findsOneWidget);
    expect(find.text('/fake/base/tools/whisper'), findsOneWidget);
    expect(find.text('返回应用点击右上角刷新 ↻，将自动识别'), findsOneWidget);
  });
}
