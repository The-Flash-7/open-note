# 字体文件下载说明

本应用使用以下字体以提升Windows端字体渲染效果：

## 当前字体文件清单（已完整）

所有必需的字体文件已成功下载并放置在本目录：

```
assets/fonts/
├── NotoSansSC-Regular.ttf      (10MB)
├── NotoSansSC-Medium.ttf       (10MB)
├── NotoSansSC-SemiBold.ttf     (10MB)
├── NotoSansSC-Bold.ttf         (10MB)
├── JetBrainsMono-Regular.ttf   (267KB)
├── JetBrainsMono-Medium.ttf    (267KB)
├── JetBrainsMono-Bold.ttf      (271KB)
└── README_FONT_DOWNLOAD.md     (本说明文件)
```

**总计体积**：约 42MB

---

## 字体配置说明

### 1. Noto Sans SC（思源黑体）- 主字体

**文件格式**：.ttf (TrueType)
**来源**：Google Fonts - https://fonts.google.com/noto/specimen/Noto+Sans+SC

**字重映射**：
- Regular (400) - 正文内容
- Medium (500) - 次级标题
- SemiBold (600) - 重要标题
- Bold (700) - 强调内容

**用途**：
- 全局UI字体（中英文统一）
- 所有Text组件默认使用此字体

---

### 2. JetBrains Mono - 代码字体

**文件格式**：.ttf (TrueType)
**来源**：JetBrains - https://www.jetbrains.com/lp/mono/

**字重映射**：
- Regular (400) - 代码正文
- Medium (500) - 代码强调
- Bold (700) - 代码标题

**用途**：
- Markdown代码块字体
- 代码编辑器字体（等宽字体）

---

## pubspec.yaml配置（已生效）

```yaml
flutter:
  fonts:
    - family: NotoSansSC
      fonts:
        - asset: assets/fonts/NotoSansSC-Regular.ttf
          weight: 400
        - asset: assets/fonts/NotoSansSC-Medium.ttf
          weight: 500
        - asset: assets/fonts/NotoSansSC-SemiBold.ttf
          weight: 600
        - asset: assets/fonts/NotoSansSC-Bold.ttf
          weight: 700
    
    - family: JetBrainsMono
      fonts:
        - asset: assets/fonts/JetBrainsMono-Regular.ttf
          weight: 400
        - asset: assets/fonts/JetBrainsMono-Medium.ttf
          weight: 500
        - asset: assets/fonts/JetBrainsMono-Bold.ttf
          weight: 700
```

---

## 字体生效位置

### 全局字体（已配置）
**文件**：`lib/theme/app_theme.dart`
```dart
static ThemeData lightTheme = ThemeData(
  fontFamily: 'NotoSansSC',  // 全局字体
  // ...
);

static ThemeData darkTheme = ThemeData(
  fontFamily: 'NotoSansSC',  // 全局字体
  // ...
);
```

### 代码字体（已配置）
**文件**：`lib/widgets/markdown_with_code_blocks.dart`
```dart
code: TextStyle(
  fontFamily: 'JetBrainsMono',  // 代码块字体
  fontSize: 14,
  // ...
),
```

---

## 重新编译应用（必需）

字体文件放置完成后，执行以下命令重新编译：

```bash
cd open_note
flutter clean
flutter pub get
flutter build windows
```

---

## 字体版权说明

- **Noto Sans SC**: 由Google开发，开源免费使用（Apache License 2.0）
- **JetBrains Mono**: 由JetBrains开发，开源免费使用（Apache License 2.0）

两款字体均可自由用于商业和个人项目。

---

## 预期改善效果

### Windows端字体对比：

| 对比项 | 使用前（系统字体） | 使用后（自定义字体） |
|-------|-----------------|-------------------|
| **中文清晰度** | ❌ SimSun锯齿感强 | ✅ 思源黑体平滑清晰 |
| **英文饱满度** | ⚠️ Segoe UI一般 | ✅ Noto Sans风格统一 |
| **代码可读性** | ⚠️ 系统等宽字体 | ✅ JetBrains Mono专业优化 |
| **跨平台一致性** | ❌ 各平台字体不同 | ✅ 统一字体体验一致 |

---

## 验证字体是否生效

编译完成后，在Windows端运行应用，观察以下变化：

1. **中文字体**：笔画平滑，无锯齿感
2. **英文字体**：字形饱满，风格统一
3. **代码块**：清晰易读，对齐精准
4. **整体视觉**：专业感强，舒适度高

---

**字体文件已完整，可以直接编译使用。**