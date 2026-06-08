// Copyright (c) 2026 litongshuai
// SPDX-License-Identifier: MIT OR Apache-2.0

///
/// Generated file. Do not edit.
///
// coverage:ignore-file
// ignore_for_file: type=lint, unused_import
// dart format off

part of 'strings.g.dart';

// Path: <root>
typedef TranslationsZh = Translations; // ignore: unused_element
class Translations with BaseTranslations<AppLocale, Translations> {
	/// Returns the current translations of the given [context].
	///
	/// Usage:
	/// final t = Translations.of(context);
	static Translations of(BuildContext context) => InheritedLocaleData.of<AppLocale, Translations>(context).translations;

	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	Translations({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = meta ?? TranslationMetadata(
		    locale: AppLocale.zh,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  );

	/// Metadata for the translations of <zh>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	late final Translations _root = this; // ignore: unused_field

	Translations $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => Translations(meta: meta ?? this.$meta);

	// Translations

	/// 取消按钮
	///
	/// zh: '取消'
	String get common_cancel => '取消';

	/// 保存按钮
	///
	/// zh: '保存'
	String get common_save => '保存';

	/// 删除按钮
	///
	/// zh: '删除'
	String get common_delete => '删除';

	/// 确定按钮
	///
	/// zh: '确定'
	String get common_ok => '确定';

	/// 关闭按钮
	///
	/// zh: '关闭'
	String get common_close => '关闭';

	/// 重试按钮
	///
	/// zh: '重试'
	String get common_retry => '重试';

	/// 编辑按钮
	///
	/// zh: '编辑'
	String get common_edit => '编辑';

	/// 创建按钮
	///
	/// zh: '创建'
	String get common_create => '创建';

	/// 添加按钮
	///
	/// zh: '添加'
	String get common_add => '添加';

	/// 清空/清除按钮
	///
	/// zh: '清空'
	String get common_clear => '清空';

	/// 粘贴按钮
	///
	/// zh: '粘贴'
	String get common_paste => '粘贴';

	/// 暂停按钮
	///
	/// zh: '暂停'
	String get common_pause => '暂停';

	/// 继续/恢复按钮
	///
	/// zh: '继续'
	String get common_resume => '继续';

	/// 跳过按钮
	///
	/// zh: '跳过'
	String get common_skip => '跳过';

	/// 下一步按钮
	///
	/// zh: '下一步'
	String get common_next => '下一步';

	/// 上一页按钮
	///
	/// zh: '上一页'
	String get common_previous => '上一页';

	/// 删除确认标题
	///
	/// zh: '确认删除'
	String get common_confirmDelete => '确认删除';

	/// 清空确认标题
	///
	/// zh: '确认清空'
	String get common_confirmClear => '确认清空';

	/// 即将上线标签
	///
	/// zh: '敬请期待'
	String get common_comingSoon => '敬请期待';

	/// 跟随系统选项
	///
	/// zh: '跟随系统'
	String get common_followSystem => '跟随系统';

	/// 亮色模式
	///
	/// zh: '亮色模式'
	String get common_lightMode => '亮色模式';

	/// 暗色模式
	///
	/// zh: '暗色模式'
	String get common_darkMode => '暗色模式';

	/// 收起按钮
	///
	/// zh: '收起'
	String get common_collapse => '收起';

	/// 展开按钮
	///
	/// zh: '展开'
	String get common_expand => '展开';

	/// 发送按钮
	///
	/// zh: '发送'
	String get common_send => '发送';

	/// 停止按钮
	///
	/// zh: '停止'
	String get common_stop => '停止';

	/// 是
	///
	/// zh: '是'
	String get common_yes => '是';

	/// 否
	///
	/// zh: '否'
	String get common_no => '否';

	/// 完成按钮
	///
	/// zh: '完成'
	String get common_done => '完成';

	/// 更多选项
	///
	/// zh: '更多'
	String get common_more => '更多';

	/// 未知状态
	///
	/// zh: '未知'
	String get common_unknown => '未知';

	/// 导航-首页
	///
	/// zh: '首页'
	String get home_home => '首页';

	/// 导航-目录
	///
	/// zh: '目录'
	String get home_categories => '目录';

	/// 导航-AI
	///
	/// zh: 'AI'
	String get home_ai => 'AI';

	/// 导航-收藏
	///
	/// zh: '收藏'
	String get home_favorites => '收藏';

	/// 导航-设置
	///
	/// zh: '设置'
	String get home_settings => '设置';

	/// 平板导航-笔记
	///
	/// zh: '笔记'
	String get home_note => '笔记';

	/// 拖拽导入覆盖层
	///
	/// zh: '拖放文件以导入笔记'
	String get home_dragDropImport => '拖放文件以导入笔记';

	/// 导入成功
	///
	/// zh: '成功导入 {count} 个文件'
	String home_successImportCount({required Object count}) => '成功导入 ${count} 个文件';

	/// 导入失败
	///
	/// zh: '{count} 个文件导入失败'
	String home_failImportCount({required Object count}) => '${count} 个文件导入失败';

	/// 剪贴板URL提示
	///
	/// zh: '检测到剪贴板URL，是否创建笔记？'
	String get home_clipboardUrlDetected => '检测到剪贴板URL，是否创建笔记？';

	/// 忽略按钮
	///
	/// zh: '忽略'
	String get home_dismiss => '忽略';

	/// 摘要暂停状态
	///
	/// zh: '摘要生成已暂停 ({processedCount}/{totalPending})'
	String home_summaryGenerationPaused({required Object processedCount, required Object totalPending}) => '摘要生成已暂停 (${processedCount}/${totalPending})';

	/// 多选计数
	///
	/// zh: '已选中 {count} 个'
	String home_selectedCount({required Object count}) => '已选中 ${count} 个';

	/// 笔记列表标题
	///
	/// zh: '所有笔记'
	String get home_allNotes => '所有笔记';

	/// 取消多选
	///
	/// zh: '取消多选'
	String get home_cancelMultiSelect => '取消多选';

	/// 多选切换
	///
	/// zh: '多选'
	String get home_multiSelect => '多选';

	/// 回收站图标提示
	///
	/// zh: '回收站'
	String get home_trash => '回收站';

	/// 回收站带数量
	///
	/// zh: '回收站 ({count})'
	String home_trashWithCount({required Object count}) => '回收站 (${count})';

	/// 新建空白笔记
	///
	/// zh: '新建空白笔记'
	String get home_newBlankNote => '新建空白笔记';

	/// 从URL创建
	///
	/// zh: '从URL创建'
	String get home_createFromUrl => '从URL创建';

	/// 从文件导入
	///
	/// zh: '从文件导入'
	String get home_importFromFile => '从文件导入';

	/// 删除后提示
	///
	/// zh: '笔记已移至回收站'
	String get home_noteMovedToTrash => '笔记已移至回收站';

	/// 空内容提示
	///
	/// zh: '选择一个笔记开始查看'
	String get home_selectNoteToStart => '选择一个笔记开始查看';

	/// 删除确认内容
	///
	/// zh: '确定删除笔记 "{title}" 吗？'
	String home_confirmDeleteNoteContent({required Object title}) => '确定删除笔记 "${title}" 吗？';

	/// 批量删除标题
	///
	/// zh: '确认批量删除'
	String get home_confirmBatchDelete => '确认批量删除';

	/// 批量删除内容
	///
	/// zh: '确定删除已选中的 {count} 个笔记吗？'
	String home_confirmBatchDeleteContent({required Object count}) => '确定删除已选中的 ${count} 个笔记吗？';

	/// 批量操作栏
	///
	/// zh: '已选中 {count} 个笔记'
	String home_selectedNotesCount({required Object count}) => '已选中 ${count} 个笔记';

	/// 批量删除后提示
	///
	/// zh: '已删除 {count} 个笔记'
	String home_deletedCountNotes({required Object count}) => '已删除 ${count} 个笔记';

	/// 回收站对话框标题
	///
	/// zh: '回收站'
	String get home_trashTitle => '回收站';

	/// 空回收站提示
	///
	/// zh: '回收站为空'
	String get home_trashEmpty => '回收站为空';

	/// 回收站副标题
	///
	/// zh: '{days}天前删除'
	String home_daysAgoDeleted({required Object days}) => '${days}天前删除';

	/// 恢复按钮
	///
	/// zh: '恢复'
	String get home_restore => '恢复';

	/// 恢复后提示
	///
	/// zh: '笔记已恢复'
	String get home_noteRestored => '笔记已恢复';

	/// 永久删除
	///
	/// zh: '永久删除'
	String get home_permanentlyDelete => '永久删除';

	/// 永久删除提示
	///
	/// zh: '笔记已永久删除'
	String get home_notePermanentlyDeleted => '笔记已永久删除';

	/// 清空回收站按钮
	///
	/// zh: '清空回收站'
	String get home_emptyTrash => '清空回收站';

	/// 清空回收站标题
	///
	/// zh: '清空回收站'
	String get home_emptyTrashTitle => '清空回收站';

	/// 清空回收站内容
	///
	/// zh: '确定清空回收站中的 {count} 个笔记吗？此操作不可恢复。'
	String home_emptyTrashContent({required Object count}) => '确定清空回收站中的 ${count} 个笔记吗？此操作不可恢复。';

	/// 清空后提示
	///
	/// zh: '回收站已清空'
	String get home_trashEmptied => '回收站已清空';

	/// 切换主题标题
	///
	/// zh: '切换主题'
	String get home_switchTheme => '切换主题';

	/// 切换亮色
	///
	/// zh: '切换到亮色模式'
	String get home_switchToLight => '切换到亮色模式';

	/// 切换暗色
	///
	/// zh: '切换到暗色模式'
	String get home_switchToDark => '切换到暗色模式';

	/// 取消收藏菜单
	///
	/// zh: '取消收藏'
	String get home_unfavorite => '取消收藏';

	/// 收藏菜单
	///
	/// zh: '收藏'
	String get home_favorite => '收藏';

	/// 分享菜单
	///
	/// zh: '分享'
	String get home_share => '分享';

	/// 分享功能提示
	///
	/// zh: '分享功能即将上线'
	String get home_shareComingSoon => '分享功能即将上线';

	/// 默认标题
	///
	/// zh: '无标题笔记'
	String get editor_untitledNote => '无标题笔记';

	/// 保存中状态
	///
	/// zh: '保存中...'
	String get editor_saving => '保存中...';

	/// 自动保存成功
	///
	/// zh: '已自动保存'
	String get editor_autoSaved => '已自动保存';

	/// 自动保存失败
	///
	/// zh: '自动保存失败'
	String get editor_autoSaveFailed => '自动保存失败';

	/// 分类选择器
	///
	/// zh: '选择分类'
	String get editor_selectCategory => '选择分类';

	/// 无分类选项
	///
	/// zh: '无分类'
	String get editor_noCategory => '无分类';

	/// 清除分类
	///
	/// zh: '清除分类'
	String get editor_clearCategory => '清除分类';

	/// 内容不能为空
	///
	/// zh: '笔记内容不能为空'
	String get editor_noteContentCannotBeEmpty => '笔记内容不能为空';

	/// 保存成功
	///
	/// zh: '保存成功'
	String get editor_saveSuccess => '保存成功';

	/// 保存失败
	///
	/// zh: '保存失败: {error}'
	String editor_saveFailed({required Object error}) => '保存失败: ${error}';

	/// 填写提示
	///
	/// zh: '请先填写标题和内容'
	String get editor_fillTitleAndContentFirst => '请先填写标题和内容';

	/// 配置超时
	///
	/// zh: '加载配置超时，请稍后再试'
	String get editor_configTimeoutRetry => '加载配置超时，请稍后再试';

	/// AI未配置
	///
	/// zh: '请先配置AI服务'
	String get editor_configureAIFirst => '请先配置AI服务';

	/// 建议生成失败
	///
	/// zh: '生成建议失败: {error}'
	String editor_generateSuggestionsFailed({required Object error}) => '生成建议失败: ${error}';

	/// 智能建议标题
	///
	/// zh: '智能建议'
	String get editor_smartSuggestions => '智能建议';

	/// 分类建议标签
	///
	/// zh: '分类建议:'
	String get editor_categorySuggestion => '分类建议:';

	/// 标签建议标签
	///
	/// zh: '标签建议:'
	String get editor_tagSuggestion => '标签建议:';

	/// 无建议
	///
	/// zh: '暂无建议'
	String get editor_noSuggestions => '暂无建议';

	/// 应用建议按钮
	///
	/// zh: '应用建议'
	String get editor_applySuggestions => '应用建议';

	/// 新笔记标题
	///
	/// zh: '新建笔记'
	String get editor_newNote => '新建笔记';

	/// 编辑笔记标题
	///
	/// zh: '编辑笔记'
	String get editor_editNote => '编辑笔记';

	/// 预览模式
	///
	/// zh: '预览'
	String get editor_preview => '预览';

	/// 智能建议提示
	///
	/// zh: '智能建议'
	String get editor_smartSuggestionsTooltip => '智能建议';

	/// AI助手提示
	///
	/// zh: 'AI助手'
	String get editor_aiAssistant => 'AI助手';

	/// 来源标签
	///
	/// zh: '来源：'
	String get editor_source => '来源：';

	/// 标题文本框
	///
	/// zh: '标题'
	String get editor_title => '标题';

	/// Markdown占位符
	///
	/// zh: '开始编写 Markdown 笔记...'
	String get editor_startWritingMarkdown => '开始编写 Markdown 笔记...';

	/// 纯文本占位符
	///
	/// zh: '开始编写纯文本笔记...'
	String get editor_startWritingPlainText => '开始编写纯文本笔记...';

	/// 富文本占位符
	///
	/// zh: '开始编写富文本笔记...'
	String get editor_startWritingRichText => '开始编写富文本笔记...';

	/// 设置导航-首选项
	///
	/// zh: '首选项'
	String get settings_preferences => '首选项';

	/// 设置导航-AI服务
	///
	/// zh: 'AI服务'
	String get settings_aiService => 'AI服务';

	/// 设置导航-外观
	///
	/// zh: '外观'
	String get settings_appearance => '外观';

	/// 设置导航-知识库
	///
	/// zh: '知识库'
	String get settings_knowledgeBase => '知识库';

	/// 设置导航-智能助理
	///
	/// zh: '智能助理'
	String get settings_assistant => '智能助理';

	/// 设置导航-CLI
	///
	/// zh: 'CLI工具'
	String get settings_cliTools => 'CLI工具';

	/// 设置对话框标题
	///
	/// zh: '设置'
	String get settings_title => '设置';

	/// 开发中占位
	///
	/// zh: '功能开发中...'
	String get settings_featureInDevelopment => '功能开发中...';

	/// 自定义配置标题
	///
	/// zh: '自定义配置'
	String get settings_customConfig => '自定义配置';

	/// 快速添加标题
	///
	/// zh: '快速添加预设'
	String get settings_quickAddPresets => '快速添加预设';

	/// 快速添加描述
	///
	/// zh: '点击快速添加常见厂商配置'
	String get settings_quickAddDescription => '点击快速添加常见厂商配置';

	/// 无AI配置
	///
	/// zh: '暂无AI配置'
	String get settings_noAIConfig => '暂无AI配置';

	/// 空状态提示
	///
	/// zh: '点击下方按钮或快速添加预设'
	String get settings_clickToAddPreset => '点击下方按钮或快速添加预设';

	/// 已配置列表
	///
	/// zh: '已配置'
	String get settings_configured => '已配置';

	/// 配置数量
	///
	/// zh: '{count}个'
	String settings_configCount({required Object count}) => '${count}个';

	/// 当前徽章
	///
	/// zh: '当前'
	String get settings_current => '当前';

	/// 配置模型提示
	///
	/// zh: '请先配置模型'
	String get settings_setModelFirst => '请先配置模型';

	/// 添加提供商
	///
	/// zh: '添加 {name}'
	String settings_addProvider({required Object name}) => '添加 ${name}';

	/// API地址标签
	///
	/// zh: 'API地址: '
	String get settings_apiAddress => 'API地址: ';

	/// 预设模型
	///
	/// zh: '预设模型: {models}'
	String settings_presetsModels({required Object models}) => '预设模型: ${models}';

	/// API密钥标签
	///
	/// zh: 'API密钥'
	String get settings_apiKey => 'API密钥';

	/// API密钥提示
	///
	/// zh: '输入您的API密钥'
	String get settings_enterApiKey => '输入您的API密钥';

	/// API密钥错误
	///
	/// zh: '请输入API密钥'
	String get settings_enterApiKeyError => '请输入API密钥';

	/// 厂商名称
	///
	/// zh: '厂商名称'
	String get settings_vendorName => '厂商名称';

	/// 厂商名称提示
	///
	/// zh: '如: 我的API、中转站'
	String get settings_vendorNameHint => '如: 我的API、中转站';

	/// Base URL标签
	///
	/// zh: 'Base URL'
	String get settings_baseUrl => 'Base URL';

	/// Base URL提示
	///
	/// zh: 'https://api.example.com/v1'
	String get settings_baseUrlHint => 'https://api.example.com/v1';

	/// 模型列表
	///
	/// zh: '模型列表'
	String get settings_modelList => '模型列表';

	/// 模型列表提示
	///
	/// zh: '逗号分隔，如: model-1,model-2'
	String get settings_modelListHint => '逗号分隔，如: model-1,model-2';

	/// 厂商名称错误
	///
	/// zh: '请输入厂商名称'
	String get settings_enterVendorName => '请输入厂商名称';

	/// 模型错误
	///
	/// zh: '请输入至少一个模型'
	String get settings_enterAtLeastOneModel => '请输入至少一个模型';

	/// 显示名称
	///
	/// zh: '显示名称'
	String get settings_displayName => '显示名称';

	/// 删除配置确认
	///
	/// zh: '确定删除配置 "{name}"?'
	String settings_confirmDeleteConfig({required Object name}) => '确定删除配置 "${name}"?';

	/// 连接成功
	///
	/// zh: '已成功连接到{name}'
	String settings_connectionSuccess({required Object name}) => '已成功连接到${name}';

	/// 未知错误
	///
	/// zh: '未知错误'
	String get settings_unknownError => '未知错误';

	/// 测试异常
	///
	/// zh: '测试异常: {error}'
	String settings_testException({required Object error}) => '测试异常: ${error}';

	/// 测试连接
	///
	/// zh: '测试连接'
	String get settings_testConnection => '测试连接';

	/// 测试连接中
	///
	/// zh: '正在测试连接...'
	String get settings_testingConnection => '正在测试连接...';

	/// 连接成功标签
	///
	/// zh: '连接成功'
	String get settings_connectionSuccessful => '连接成功';

	/// 连接失败标签
	///
	/// zh: '连接失败'
	String get settings_connectionFailed => '连接失败';

	/// 搜索框
	///
	/// zh: '搜索笔记...'
	String get search_placeholder => '搜索笔记...';

	/// 分类筛选
	///
	/// zh: '分类筛选'
	String get search_categoryFilter => '分类筛选';

	/// 所有分类
	///
	/// zh: '所有分类'
	String get search_allCategories => '所有分类';

	/// 输入提示
	///
	/// zh: '输入关键词开始搜索'
	String get search_enterToSearch => '输入关键词开始搜索';

	/// 无结果
	///
	/// zh: '未找到相关笔记'
	String get search_noResults => '未找到相关笔记';

	/// 无历史
	///
	/// zh: '暂无搜索历史'
	String get search_noHistory => '暂无搜索历史';

	/// 最近搜索
	///
	/// zh: '最近搜索'
	String get search_recentSearches => '最近搜索';

	/// 未命名回退
	///
	/// zh: '未命名笔记'
	String get search_untitledNote => '未命名笔记';

	/// 刚刚
	///
	/// zh: '刚刚'
	String get search_justNow => '刚刚';

	/// 分钟前
	///
	/// zh: '{count}分钟前'
	String search_minutesAgo({required Object count}) => '${count}分钟前';

	/// 小时前
	///
	/// zh: '{count}小时前'
	String search_hoursAgo({required Object count}) => '${count}小时前';

	/// 昨天
	///
	/// zh: '昨天'
	String get search_yesterday => '昨天';

	/// 天前
	///
	/// zh: '{count}天前'
	String search_daysAgo({required Object count}) => '${count}天前';

	/// Enter键
	///
	/// zh: 'Enter'
	String get search_enterHint => 'Enter';

	/// 打开
	///
	/// zh: '打开'
	String get search_open => '打开';

	/// 上下键
	///
	/// zh: '↑↓'
	String get search_navigateHint => '↑↓';

	/// 导航
	///
	/// zh: '导航'
	String get search_navigate => '导航';

	/// Esc键
	///
	/// zh: 'Esc'
	String get search_escHint => 'Esc';

	/// 关闭
	///
	/// zh: '关闭'
	String get search_closeHint => '关闭';

	/// 新建笔记
	///
	/// zh: '新建笔记'
	String get dialog_newNote => '新建笔记';

	/// 空白笔记
	///
	/// zh: '空白笔记'
	String get dialog_blankNote => '空白笔记';

	/// 空白笔记副标题
	///
	/// zh: '创建一个新的空白笔记'
	String get dialog_createBlankNote => '创建一个新的空白笔记';

	/// 从文件导入
	///
	/// zh: '从文件导入'
	String get dialog_importFromFile => '从文件导入';

	/// 从文件导入副标题
	///
	/// zh: '从 TXT、代码、HTML 文件创建笔记'
	String get dialog_importFromFileSubtitle => '从 TXT、代码、HTML 文件创建笔记';

	/// 导入成功
	///
	/// zh: '笔记导入成功'
	String get dialog_noteImportSuccess => '笔记导入成功';

	/// 不支持格式
	///
	/// zh: '导入失败：不支持的文件格式'
	String get dialog_importFailedUnsupported => '导入失败：不支持的文件格式';

	/// 导入失败
	///
	/// zh: '导入失败：{error}'
	String dialog_importFailed({required Object error}) => '导入失败：${error}';

	/// 选择格式
	///
	/// zh: '选择笔记格式'
	String get dialog_selectNoteFormat => '选择笔记格式';

	/// Markdown格式
	///
	/// zh: 'Markdown'
	String get dialog_markdown => 'Markdown';

	/// Markdown描述
	///
	/// zh: '支持富文本格式、代码块、表格等'
	String get dialog_markdownDescription => '支持富文本格式、代码块、表格等';

	/// 纯文本
	///
	/// zh: '纯文本'
	String get dialog_plainText => '纯文本';

	/// 纯文本描述
	///
	/// zh: '简单的纯文本格式，无特殊格式'
	String get dialog_plainTextDescription => '简单的纯文本格式，无特殊格式';

	/// 富文本
	///
	/// zh: '富文本'
	String get dialog_richText => '富文本';

	/// 富文本描述
	///
	/// zh: 'Quill 编辑器，支持粗体、斜体、列表等'
	String get dialog_richTextDescription => 'Quill 编辑器，支持粗体、斜体、列表等';

	/// 代码
	///
	/// zh: '代码'
	String get dialog_code => '代码';

	/// 代码描述
	///
	/// zh: '代码编辑器，支持语法高亮'
	String get dialog_codeDescription => '代码编辑器，支持语法高亮';

	/// URL创建
	///
	/// zh: '从URL创建笔记'
	String get dialog_createFromUrl => '从URL创建笔记';

	/// URL字段
	///
	/// zh: '网页URL'
	String get dialog_webUrl => '网页URL';

	/// URL提示
	///
	/// zh: 'example.com'
	String get dialog_urlHint => 'example.com';

	/// URL错误
	///
	/// zh: '请输入URL'
	String get dialog_enterUrl => '请输入URL';

	/// URL格式错误
	///
	/// zh: 'URL格式不正确'
	String get dialog_invalidUrlFormat => 'URL格式不正确';

	/// 提取失败
	///
	/// zh: '内容提取失败'
	String get dialog_extractFailed => '内容提取失败';

	/// 提取中
	///
	/// zh: '正在提取内容...'
	String get dialog_extractingContent => '正在提取内容...';

	/// 提取成功
	///
	/// zh: '提取成功'
	String get dialog_extractSuccess => '提取成功';

	/// AI初始化
	///
	/// zh: 'AI正在初始化笔记...'
	String get dialog_aiInitializing => 'AI正在初始化笔记...';

	/// 自动初始化
	///
	/// zh: '笔记已自动初始化'
	String get dialog_noteAutoInitialized => '笔记已自动初始化';

	/// 摘要
	///
	/// zh: '摘要'
	String get dialog_summary => '摘要';

	/// 关键词
	///
	/// zh: '关键词'
	String get dialog_keywords => '关键词';

	/// 分类
	///
	/// zh: '分类'
	String get dialog_category => '分类';

	/// 标签
	///
	/// zh: '标签'
	String get dialog_tags => '标签';

	/// 提取内容按钮
	///
	/// zh: '提取内容'
	String get dialog_extractContent => '提取内容';

	/// 创建笔记按钮
	///
	/// zh: '创建笔记'
	String get dialog_createNote => '创建笔记';

	/// 模型管理标题
	///
	/// zh: '管理模型 - {providerName}'
	String dialog_manageModelsTitle({required Object providerName}) => '管理模型 - ${providerName}';

	/// 新模型标签
	///
	/// zh: '新模型名称'
	String get dialog_newModelLabel => '新模型名称';

	/// 添加模型
	///
	/// zh: '添加模型'
	String get dialog_addModelTooltip => '添加模型';

	/// 当前模型
	///
	/// zh: '当前模型 ({count}):'
	String dialog_currentModelsHeader({required Object count}) => '当前模型 (${count}):';

	/// 设为默认
	///
	/// zh: '设为默认'
	String get dialog_setDefaultTooltip => '设为默认';

	/// 模型更新
	///
	/// zh: '模型列表已更新'
	String get dialog_modelsUpdated => '模型列表已更新';

	/// 分类管理
	///
	/// zh: '分类管理'
	String get category_title => '分类管理';

	/// 平铺视图
	///
	/// zh: '平铺视图'
	String get category_flatViewTooltip => '平铺视图';

	/// 树形视图
	///
	/// zh: '树形视图'
	String get category_treeViewTooltip => '树形视图';

	/// 新建分类
	///
	/// zh: '新建分类'
	String get category_createNewTooltip => '新建分类';

	/// 无分类
	///
	/// zh: '暂无分类'
	String get category_emptyState => '暂无分类';

	/// 新建分类标题
	///
	/// zh: '新建分类'
	String get category_createTitle => '新建分类';

	/// 新建子分类
	///
	/// zh: '新建子分类'
	String get category_createChildTitle => '新建子分类';

	/// 分类名称提示
	///
	/// zh: '请输入分类名称'
	String get category_nameHint => '请输入分类名称';

	/// 名称为空
	///
	/// zh: '分类名称不能为空'
	String get category_nameEmptyError => '分类名称不能为空';

	/// 名称过长
	///
	/// zh: '分类名称不能超过20字符'
	String get category_nameTooLongError => '分类名称不能超过20字符';

	/// 名称含横杠
	///
	/// zh: '分类名称不能包含 "-" 字符'
	String get category_nameDashError => '分类名称不能包含 "-" 字符';

	/// 名称重复
	///
	/// zh: '同级已存在同名目录'
	String get category_duplicateNameError => '同级已存在同名目录';

	/// 删除分类
	///
	/// zh: '删除分类'
	String get category_deleteTitle => '删除分类';

	/// 删除确认
	///
	/// zh: '确定要删除分类"{name}"吗？'
	String category_deleteConfirm({required Object name}) => '确定要删除分类"${name}"吗？';

	/// 删除警告
	///
	/// zh: '该分类下有 {count} 条笔记，删除分类将同时删除这些笔记！'
	String category_deleteWarning({required Object count}) => '该分类下有 ${count} 条笔记，删除分类将同时删除这些笔记！';

	/// 重命名
	///
	/// zh: '重命名分类'
	String get category_renameTitle => '重命名分类';

	/// 新名称提示
	///
	/// zh: '请输入新分类名称'
	String get category_newNameHint => '请输入新分类名称';

	/// 重命名
	///
	/// zh: '重命名'
	String get category_renameTooltip => '重命名';

	/// 添加子分类
	///
	/// zh: '添加子分类'
	String get category_addChildTooltip => '添加子分类';

	/// AI问候
	///
	/// zh: 'Hi，我是 Cici'
	String get ai_ciciGreeting => 'Hi，我是 Cici';

	/// AI副标题
	///
	/// zh: '基于你的笔记知识库，我可以帮你：'
	String get ai_ciciSubtitle => '基于你的笔记知识库，我可以帮你：';

	/// 查找笔记
	///
	/// zh: '查找笔记'
	String get ai_quickActionSearch => '查找笔记';

	/// 总结提炼
	///
	/// zh: '总结提炼'
	String get ai_quickActionSummarize => '总结提炼';

	/// 答疑解惑
	///
	/// zh: '答疑解惑'
	String get ai_quickActionQa => '答疑解惑';

	/// 示例消息1
	///
	/// zh: '帮我找一下关于"OKR 工作法"的笔记'
	String get ai_sampleUserMessage1 => '帮我找一下关于"OKR 工作法"的笔记';

	/// 示例回复-找到
	///
	/// zh: '好的，已为你找到'
	String get ai_sampleAssistantFound => '好的，已为你找到';

	/// 示例回复-数量
	///
	/// zh: '1 条相关笔记：'
	String get ai_sampleAssistantNotes => '1 条相关笔记：';

	/// 示例笔记标题
	///
	/// zh: 'OKR 工作法：目标设定与落地实践'
	String get ai_sampleNoteTitle => 'OKR 工作法：目标设定与落地实践';

	/// 示例笔记描述
	///
	/// zh: '介绍了 OKR 的定义、核心原则以及在团队中的应用方法...'
	String get ai_sampleNoteDesc => '介绍了 OKR 的定义、核心原则以及在团队中的应用方法...';

	/// 示例消息2
	///
	/// zh: 'OKR 的核心原则是什么？'
	String get ai_sampleUserMessage2 => 'OKR 的核心原则是什么？';

	/// 示例回复-原则
	///
	/// zh: 'OKR 的核心原则主要包括：'
	String get ai_sampleAssistantPrinciples => 'OKR 的核心原则主要包括：';

	/// 示例原则1
	///
	/// zh: '• 目标（O）要有挑战性，激发潜力；'
	String get ai_samplePrinciple1 => '• 目标（O）要有挑战性，激发潜力；';

	/// 示例原则2
	///
	/// zh: '• 关键结果（KR）要可衡量，确保目标可追踪；'
	String get ai_samplePrinciple2 => '• 关键结果（KR）要可衡量，确保目标可追踪；';

	/// 示例原则3
	///
	/// zh: '• 保持透明对齐，团队上下目标一致；'
	String get ai_samplePrinciple3 => '• 保持透明对齐，团队上下目标一致；';

	/// 示例原则4
	///
	/// zh: '• 定期复盘，持续学习与改进。'
	String get ai_samplePrinciple4 => '• 定期复盘，持续学习与改进。';

	/// 示例结论
	///
	/// zh: '这些原则能帮助团队聚焦重点，提升执行力。'
	String get ai_sampleAssistantConclusion => '这些原则能帮助团队聚焦重点，提升执行力。';

	/// AI输入框
	///
	/// zh: '输入你的问题，或直接用自然语言查找笔记...'
	String get ai_inputPlaceholder => '输入你的问题，或直接用自然语言查找笔记...';

	/// 搜索模板
	///
	/// zh: '帮我查找关于「」的笔记'
	String get ai_quickActionSearchTemplate => '帮我查找关于「」的笔记';

	/// 总结当前笔记
	///
	/// zh: '请帮我总结提炼这篇笔记「{title}」的核心内容'
	String ai_quickActionSummarizeWithNote({required Object title}) => '请帮我总结提炼这篇笔记「${title}」的核心内容';

	/// 总结默认
	///
	/// zh: '请帮我总结当前笔记的核心内容'
	String get ai_quickActionSummarizeDefault => '请帮我总结当前笔记的核心内容';

	/// 问答模板
	///
	/// zh: '我有一个问题想基于笔记内容来回答...'
	String get ai_quickActionQaTemplate => '我有一个问题想基于笔记内容来回答...';

	/// 新会话
	///
	/// zh: '开启新会话'
	String get ai_newSessionTitle => '开启新会话';

	/// 新会话确认
	///
	/// zh: '确定要开启新会话吗？当前对话记录将被清空。'
	String get ai_newSessionConfirm => '确定要开启新会话吗？当前对话记录将被清空。';

	/// 分析需求
	///
	/// zh: '正在分析用户需求...'
	String get ai_thinkingAnalyzing => '正在分析用户需求...';

	/// 知识库未启用
	///
	/// zh: '⚠️ 知识库未启用，使用普通文本搜索模式'
	String get ai_knowledgeBaseDisabled => '⚠️ 知识库未启用，使用普通文本搜索模式';

	/// 回复失败
	///
	/// zh: 'AI 回复失败：{error}'
	String ai_replyFailed({required Object error}) => 'AI 回复失败：${error}';

	/// 调用中断
	///
	/// zh: '调用中断'
	String get ai_toolCallInterrupted => '调用中断';

	/// 执行取消
	///
	/// zh: '已中断执行'
	String get ai_executionCancelled => '已中断执行';

	/// 用户中断
	///
	/// zh: '操作已被用户中断'
	String get ai_operationInterrupted => '操作已被用户中断';

	/// 默认输入框
	///
	/// zh: '输入问题，或用自然语言查找笔记'
	String get ai_inputDefaultPlaceholder => '输入问题，或用自然语言查找笔记';

	/// 工具类别-探索
	///
	/// zh: '探索'
	String get ai_toolCategoryExplore => '探索';

	/// 工具类别-编辑
	///
	/// zh: '编辑'
	String get ai_toolCategoryEdit => '编辑';

	/// 工具类别-写入
	///
	/// zh: '写入'
	String get ai_toolCategoryWrite => '写入';

	/// 工具类别-删除
	///
	/// zh: '删除'
	String get ai_toolCategoryDelete => '删除';

	/// 工具类别-总结
	///
	/// zh: '总结'
	String get ai_toolCategorySummarize => '总结';

	/// 工具类别-提取
	///
	/// zh: '提取'
	String get ai_toolCategoryExtract => '提取';

	/// 工具类别-处理
	///
	/// zh: '处理'
	String get ai_toolCategoryProcess => '处理';

	/// 执行终止
	///
	/// zh: '已终止执行'
	String get ai_toolTerminated => '已终止执行';

	/// 执行中
	///
	/// zh: '正在执行...'
	String get ai_toolInProgress => '正在执行...';

	/// 执行完成
	///
	/// zh: '执行完成'
	String get ai_toolCompleted => '执行完成';

	/// 工具统计
	///
	/// zh: '{category} {count} 次'
	String ai_toolBadgeCount({required Object category, required Object count}) => '${category} ${count} 次';

	/// 思考中
	///
	/// zh: '思考中'
	String get ai_thinking => '思考中';

	/// AI摘要标题
	///
	/// zh: 'AI 摘要'
	String get ai_summaryTitle => 'AI 摘要';

	/// 点击展开
	///
	/// zh: '点击展开查看摘要'
	String get ai_clickToExpand => '点击展开查看摘要';

	/// 生成摘要
	///
	/// zh: '生成摘要'
	String get ai_generateSummary => '生成摘要';

	/// 重新生成
	///
	/// zh: '重新生成'
	String get ai_regenerate => '重新生成';

	/// 生成摘要中
	///
	/// zh: '正在生成摘要...'
	String get ai_generatingSummary => '正在生成摘要...';

	/// 关键词标签
	///
	/// zh: '关键词：'
	String get ai_keywordsLabel => '关键词：';

	/// AI未配置
	///
	/// zh: '未配置AI服务，无法生成摘要'
	String get ai_noAiConfig => '未配置AI服务，无法生成摘要';

	/// 前往设置
	///
	/// zh: '前往设置'
	String get ai_goToSettings => '前往设置';

	/// 生成中
	///
	/// zh: '正在生成...'
	String get ai_generating => '正在生成...';

	/// 点击生成
	///
	/// zh: '点击生成AI摘要'
	String get ai_clickToGenerate => '点击生成AI摘要';

	/// 取消收藏
	///
	/// zh: '取消收藏'
	String get card_unfavoriteTooltip => '取消收藏';

	/// 收藏
	///
	/// zh: '收藏'
	String get card_favoriteTooltip => '收藏';

	/// 删除
	///
	/// zh: '删除'
	String get card_deleteTooltip => '删除';

	/// 未命名
	///
	/// zh: '未命名笔记'
	String get card_untitledNote => '未命名笔记';

	/// 刚刚
	///
	/// zh: '刚刚'
	String get card_justNow => '刚刚';

	/// 分钟前
	///
	/// zh: '{minutes}分钟前'
	String card_minutesAgo({required Object minutes}) => '${minutes}分钟前';

	/// 小时前
	///
	/// zh: '{hours}小时前'
	String card_hoursAgo({required Object hours}) => '${hours}小时前';

	/// 昨天
	///
	/// zh: '昨天'
	String get card_yesterday => '昨天';

	/// 天前
	///
	/// zh: '{days}天前'
	String card_daysAgo({required Object days}) => '${days}天前';

	/// 标签区域
	///
	/// zh: '标签'
	String get tag_sectionTitle => '标签';

	/// 可选标签
	///
	/// zh: '可选标签'
	String get tag_availableTagsTitle => '可选标签';

	/// 无标签
	///
	/// zh: '暂无标签，点击下方创建'
	String get tag_noTagsEmpty => '暂无标签，点击下方创建';

	/// 创建标签
	///
	/// zh: '创建新标签'
	String get tag_createNew => '创建新标签';

	/// 添加标签
	///
	/// zh: '添加标签'
	String get tag_addTag => '添加标签';

	/// 标签名提示
	///
	/// zh: '标签名'
	String get tag_nameHint => '标签名';

	/// 确定
	///
	/// zh: '确定'
	String get tag_confirmTooltip => '确定';

	/// 跳过
	///
	/// zh: '跳过'
	String get onboarding_skip => '跳过';

	/// 上一页
	///
	/// zh: '上一页'
	String get onboarding_previous => '上一页';

	/// 下一步
	///
	/// zh: '下一步'
	String get onboarding_next => '下一步';

	/// 欢迎标题
	///
	/// zh: '欢迎使用 OpenNote'
	String get onboarding_welcomeTitle => '欢迎使用 OpenNote';

	/// 欢迎副标题
	///
	/// zh: '智能笔记助手，让记录更高效'
	String get onboarding_welcomeSubtitle => '智能笔记助手，让记录更高效';

	/// 开始配置
	///
	/// zh: '开始配置'
	String get onboarding_startConfig => '开始配置';

	/// 稍后配置
	///
	/// zh: '稍后配置'
	String get onboarding_configLater => '稍后配置';

	/// 图片加载失败
	///
	/// zh: '图片加载失败'
	String get onboarding_imageLoadError => '图片加载失败';

	/// 选择服务商
	///
	/// zh: '选择AI服务商'
	String get onboarding_selectProviderTitle => '选择AI服务商';

	/// 选择副标题
	///
	/// zh: '选择您想要使用的AI服务商，稍后可在设置中添加更多'
	String get onboarding_selectProviderSubtitle => '选择您想要使用的AI服务商，稍后可在设置中添加更多';

	/// 未选择厂商
	///
	/// zh: '请先选择AI服务厂商'
	String get onboarding_noProviderSelected => '请先选择AI服务厂商';

	/// 返回选择
	///
	/// zh: '返回上一页选择您偏好的AI服务商'
	String get onboarding_returnToSelectProvider => '返回上一页选择您偏好的AI服务商';

	/// 自定义配置
	///
	/// zh: '配置自定义AI服务'
	String get onboarding_configCustomTitle => '配置自定义AI服务';

	/// 配置提供商
	///
	/// zh: '配置 {providerName}'
	String onboarding_configProviderTitle({required Object providerName}) => '配置 ${providerName}';

	/// 自定义副标题
	///
	/// zh: '请输入厂商信息、API地址、模型列表和API密钥'
	String get onboarding_customConfigSubtitle => '请输入厂商信息、API地址、模型列表和API密钥';

	/// 提供商副标题
	///
	/// zh: '请输入API密钥以完成配置'
	String get onboarding_providerConfigSubtitle => '请输入API密钥以完成配置';

	/// 厂商标签
	///
	/// zh: '厂商'
	String get onboarding_vendorLabel => '厂商';

	/// API地址标签
	///
	/// zh: 'API地址'
	String get onboarding_apiUrlLabel => 'API地址';

	/// 预设模型标签
	///
	/// zh: '预设模型'
	String get onboarding_presetModelsLabel => '预设模型';

	/// API密钥标签
	///
	/// zh: 'API密钥'
	String get onboarding_apiKeyLabel => 'API密钥';

	/// 已验证提示
	///
	/// zh: 'API密钥已验证'
	String get onboarding_apiKeyVerifiedHint => 'API密钥已验证';

	/// API密钥提示
	///
	/// zh: '请输入API密钥'
	String get onboarding_apiKeyHint => '请输入API密钥';

	/// 获取密钥
	///
	/// zh: '获取API密钥'
	String get onboarding_getApiKey => '获取API密钥';

	/// 测试中
	///
	/// zh: '正在测试连接...'
	String get onboarding_testingConnection => '正在测试连接...';

	/// 测试连接
	///
	/// zh: '测试连接'
	String get onboarding_testConnection => '测试连接';

	/// 完成配置
	///
	/// zh: '完成配置'
	String get onboarding_completeConfig => '完成配置';

	/// 厂商名称
	///
	/// zh: '厂商名称'
	String get onboarding_vendorNameLabel => '厂商名称';

	/// 厂商名称提示
	///
	/// zh: '例如：我的AI服务'
	String get onboarding_vendorNameHint => '例如：我的AI服务';

	/// API地址提示
	///
	/// zh: '例如：https://api.example.com/v1'
	String get onboarding_apiUrlInputHint => '例如：https://api.example.com/v1';

	/// 模型列表
	///
	/// zh: '模型列表'
	String get onboarding_modelListLabel => '模型列表';

	/// 模型输入提示
	///
	/// zh: '输入模型名称'
	String get onboarding_modelInputHint => '输入模型名称';

	/// 添加模型
	///
	/// zh: '添加'
	String get onboarding_addModel => '添加';

	/// 默认模型
	///
	/// zh: '默认模型'
	String get onboarding_defaultModelLabel => '默认模型';

	/// 选择默认
	///
	/// zh: '选择默认模型'
	String get onboarding_selectDefaultModel => '选择默认模型';

	/// 选择厂商错误
	///
	/// zh: '请先选择厂商'
	String get onboarding_errorSelectVendorFirst => '请先选择厂商';

	/// 输入密钥错误
	///
	/// zh: '请输入API密钥'
	String get onboarding_errorEnterApiKey => '请输入API密钥';

	/// 输入厂商错误
	///
	/// zh: '请输入厂商名称'
	String get onboarding_errorEnterVendorName => '请输入厂商名称';

	/// 输入地址错误
	///
	/// zh: '请输入API地址'
	String get onboarding_errorEnterApiUrl => '请输入API地址';

	/// 添加模型错误
	///
	/// zh: '请至少添加一个模型'
	String get onboarding_errorAddModel => '请至少添加一个模型';

	/// 连接成功
	///
	/// zh: '连接成功'
	String get onboarding_connectionSuccess => '连接成功';

	/// 连接失败
	///
	/// zh: '连接失败，请检查API密钥和网络连接'
	String get onboarding_connectionFailed => '连接失败，请检查API密钥和网络连接';

	/// 测试异常
	///
	/// zh: '测试异常: {error}'
	String onboarding_testException({required Object error}) => '测试异常: ${error}';

	/// 保存失败
	///
	/// zh: '保存配置失败: {error}'
	String onboarding_saveConfigFailed({required Object error}) => '保存配置失败: ${error}';

	/// 配置成功
	///
	/// zh: '配置成功！'
	String get onboarding_configSuccess => '配置成功！';

	/// 配置成功副标题
	///
	/// zh: '现在您可以开始使用AI功能了'
	String get onboarding_configSuccessSubtitle => '现在您可以开始使用AI功能了';

	/// 配置未完成
	///
	/// zh: '配置未完成'
	String get onboarding_configIncomplete => '配置未完成';

	/// 未完成副标题
	///
	/// zh: '您尚未完成AI服务配置，请返回完成配置后才能开始使用'
	String get onboarding_configIncompleteSubtitle => '您尚未完成AI服务配置，请返回完成配置后才能开始使用';

	/// 提示
	///
	/// zh: '提示'
	String get onboarding_infoTip => '提示';

	/// 滑动警告
	///
	/// zh: '您通过滑动进入了完成页面，但AI服务配置尚未保存。请返回配置页面完成API密钥填写和连接测试。'
	String get onboarding_swipedToCompleteWarning => '您通过滑动进入了完成页面，但AI服务配置尚未保存。请返回配置页面完成API密钥填写和连接测试。';

	/// 下一步标题
	///
	/// zh: '下一步建议'
	String get onboarding_nextStepTitle => '下一步建议';

	/// 下一步1
	///
	/// zh: '创建新笔记，体验AI智能摘要'
	String get onboarding_nextStep1 => '创建新笔记，体验AI智能摘要';

	/// 下一步2
	///
	/// zh: '使用关键词提取功能快速整理笔记'
	String get onboarding_nextStep2 => '使用关键词提取功能快速整理笔记';

	/// 下一步3
	///
	/// zh: '让AI帮您自动分类笔记内容'
	String get onboarding_nextStep3 => '让AI帮您自动分类笔记内容';

	/// 开始使用
	///
	/// zh: '开始使用'
	String get onboarding_startUsing => '开始使用';

	/// 返回配置
	///
	/// zh: '返回配置'
	String get onboarding_returnToConfig => '返回配置';

	/// 加粗
	///
	/// zh: '加粗'
	String get toolbar_bold => '加粗';

	/// 斜体
	///
	/// zh: '斜体'
	String get toolbar_italic => '斜体';

	/// 删除线
	///
	/// zh: '删除线'
	String get toolbar_strikethrough => '删除线';

	/// H1
	///
	/// zh: 'H1'
	String get toolbar_heading1 => 'H1';

	/// H2
	///
	/// zh: 'H2'
	String get toolbar_heading2 => 'H2';

	/// H3
	///
	/// zh: 'H3'
	String get toolbar_heading3 => 'H3';

	/// 代码
	///
	/// zh: '代码'
	String get toolbar_code => '代码';

	/// 引用
	///
	/// zh: '引用'
	String get toolbar_quote => '引用';

	/// 列表
	///
	/// zh: '列表'
	String get toolbar_list => '列表';

	/// 编号
	///
	/// zh: '编号'
	String get toolbar_numberedList => '编号';

	/// 待办
	///
	/// zh: '待办'
	String get toolbar_todo => '待办';

	/// 链接
	///
	/// zh: '链接'
	String get toolbar_link => '链接';

	/// 图片
	///
	/// zh: '图片'
	String get toolbar_image => '图片';

	/// 分割线
	///
	/// zh: '分割线'
	String get toolbar_divider => '分割线';

	/// 表格
	///
	/// zh: '表格'
	String get toolbar_table => '表格';

	/// 表格模板头
	///
	/// zh: '列1 | 列2 | 列3'
	String get toolbar_tableHeader => '列1 | 列2 | 列3';

	/// 表格内容
	///
	/// zh: '内容'
	String get toolbar_tableContent => '内容';

	/// 暂不可用
	///
	/// zh: '暂不可用'
	String get format_unavailable => '暂不可用';

	/// 无笔记标题
	///
	/// zh: '还没有笔记'
	String get empty_noNotesTitle => '还没有笔记';

	/// 无笔记描述
	///
	/// zh: '点击右上角 + 创建第一条笔记'
	String get empty_noNotesDesc => '点击右上角 + 创建第一条笔记';

	/// 创建笔记
	///
	/// zh: '创建笔记'
	String get empty_createNote => '创建笔记';

	/// 无搜索结果
	///
	/// zh: '没有找到相关笔记'
	String get empty_noSearchResultsTitle => '没有找到相关笔记';

	/// 无搜索描述
	///
	/// zh: '试试其他关键词'
	String get empty_noSearchResultsDesc => '试试其他关键词';

	/// 清除搜索
	///
	/// zh: '清除搜索'
	String get empty_clearSearch => '清除搜索';

	/// 无标签标题
	///
	/// zh: '还没有标签'
	String get empty_noTagsTitle => '还没有标签';

	/// 无标签描述
	///
	/// zh: '在编辑笔记时可以添加标签'
	String get empty_noTagsDesc => '在编辑笔记时可以添加标签';

	/// 无收藏标题
	///
	/// zh: '还没有收藏笔记'
	String get empty_noFavoritesTitle => '还没有收藏笔记';

	/// 无收藏描述
	///
	/// zh: '点击笔记卡片上的星标即可收藏'
	String get empty_noFavoritesDesc => '点击笔记卡片上的星标即可收藏';

	/// 浏览笔记
	///
	/// zh: '浏览笔记'
	String get empty_browseNotes => '浏览笔记';

	/// 重试
	///
	/// zh: '重试'
	String get empty_retry => '重试';

	/// 网络错误
	///
	/// zh: '网络连接失败'
	String get empty_networkErrorTitle => '网络连接失败';

	/// 网络错误描述
	///
	/// zh: '请检查网络连接后重试'
	String get empty_networkErrorDesc => '请检查网络连接后重试';

	/// AI服务错误
	///
	/// zh: 'AI 服务暂时不可用'
	String get empty_aiServiceErrorTitle => 'AI 服务暂时不可用';

	/// AI错误描述
	///
	/// zh: '请稍后重试或检查AI配置'
	String get empty_aiServiceErrorDesc => '请稍后重试或检查AI配置';

	/// 菜单
	///
	/// zh: '菜单'
	String get navigation_menu => '菜单';

	/// 搜索框占位
	///
	/// zh: '搜索...'
	String get navigation_search => '搜索...';

	/// 发现新版本
	///
	/// zh: '发现新版本'
	String get update_newVersionFound => '发现新版本';

	/// 跳过版本
	///
	/// zh: '跳过此版本'
	String get update_skipThisVersion => '跳过此版本';

	/// 稍后提醒
	///
	/// zh: '稍后提醒'
	String get update_remindLater => '稍后提醒';

	/// 更新
	///
	/// zh: '更新'
	String get update_update => '更新';

	/// 版本号
	///
	/// zh: '版本号'
	String get preferences_versionNumber => '版本号';

	/// 平台
	///
	/// zh: '平台'
	String get preferences_platform => '平台';

	/// 构建号
	///
	/// zh: '构建号'
	String get preferences_buildNumber => '构建号';

	/// 自动检查更新
	///
	/// zh: '自动检查更新'
	String get preferences_autoCheckUpdate => '自动检查更新';

	/// 检查中
	///
	/// zh: '检查中...'
	String get preferences_checking => '检查中...';

	/// 最新版本
	///
	/// zh: '已是最新版本'
	String get preferences_latestVersion => '已是最新版本';

	/// 检查失败
	///
	/// zh: '检查失败，重试'
	String get preferences_checkFailedRetry => '检查失败，重试';

	/// 检查更新
	///
	/// zh: '检查更新'
	String get preferences_checkForUpdate => '检查更新';

	/// 发现新版本
	///
	/// zh: '发现新版本 v{version}'
	String preferences_newVersionFound({required Object version}) => '发现新版本 v${version}';

	/// 下载中
	///
	/// zh: '正在下载更新'
	String get preferences_downloadingUpdate => '正在下载更新';

	/// 下载完成
	///
	/// zh: '下载完成'
	String get preferences_downloadComplete => '下载完成';

	/// 安装提示
	///
	/// zh: '安装程序已打开，请按照提示完成更新'
	String get preferences_installPrompt => '安装程序已打开，请按照提示完成更新';

	/// 跳过版本
	///
	/// zh: '已跳过的版本'
	String get preferences_skippedVersions => '已跳过的版本';

	/// 语言
	///
	/// zh: '语言'
	String get preferences_language => '语言';

	/// 简体中文
	///
	/// zh: '简体中文'
	String get preferences_languageZhCN => '简体中文';

	/// 繁体中文
	///
	/// zh: '繁體中文'
	String get preferences_languageZhTW => '繁體中文';

	/// 英文
	///
	/// zh: 'English'
	String get preferences_languageEn => 'English';

	/// 俄语
	///
	/// zh: 'Русский'
	String get preferences_languageRu => 'Русский';

	/// 重启提示
	///
	/// zh: '切换语言后重启应用即可生效'
	String get preferences_languageRestartHint => '切换语言后重启应用即可生效';

	/// 准备服务
	///
	/// zh: '准备服务中...'
	String get kb_preparingService => '准备服务中...';

	/// 启动服务
	///
	/// zh: '启动服务中...'
	String get kb_startingService => '启动服务中...';

	/// 初始化向量
	///
	/// zh: '正在初始化向量服务，请稍候...'
	String get kb_initializingVectorService => '正在初始化向量服务，请稍候...';

	/// 启动失败
	///
	/// zh: '服务启动失败'
	String get kb_serviceStartupFailed => '服务启动失败';

	/// 已就绪
	///
	/// zh: '知识库已就绪'
	String get kb_knowledgeBaseReady => '知识库已就绪';

	/// 未启用
	///
	/// zh: '知识库未启用'
	String get kb_knowledgeBaseNotEnabled => '知识库未启用';

	/// 运行中
	///
	/// zh: '服务运行中'
	String get kb_serviceRunning => '服务运行中';

	/// 模型已加载
	///
	/// zh: '本地模型已加载'
	String get kb_localModelLoaded => '本地模型已加载';

	/// 向量化说明
	///
	/// zh: '启用后将使用本地 Embedding 模型进行笔记向量化索引'
	String get kb_enableKnowledgeBaseVectorization => '启用后将使用本地 Embedding 模型进行笔记向量化索引';

	/// 启用开关
	///
	/// zh: '启用/关闭'
	String get kb_enableToggle => '启用/关闭';

	/// 启用知识库
	///
	/// zh: '启用知识库'
	String get kb_enableKnowledgeBase => '启用知识库';

	/// 自动索引说明
	///
	/// zh: '启用后笔记将自动进行向量化索引'
	String get kb_autoVectorIndexing => '启用后笔记将自动进行向量化索引';

	/// Embedding模型
	///
	/// zh: 'Embedding 模型'
	String get kb_embeddingModel => 'Embedding 模型';

	/// 模型
	///
	/// zh: '模型'
	String get kb_model => '模型';

	/// 向量维度
	///
	/// zh: '向量维度'
	String get kb_vectorDimensions => '向量维度';

	/// 下载源
	///
	/// zh: '下载源'
	String get kb_downloadSource => '下载源';

	/// 魔搭社区
	///
	/// zh: '魔搭社区 (modelscope.cn)'
	String get kb_modelscope => '魔搭社区 (modelscope.cn)';

	/// 模型版本
	///
	/// zh: '模型版本:'
	String get kb_modelVersion => '模型版本:';

	/// 精度最高
	///
	/// zh: '~617MB · 精度最高'
	String get kb_highestPrecision => '~617MB · 精度最高';

	/// 平衡推荐
	///
	/// zh: '~309MB · 平衡推荐'
	String get kb_balancedRecommended => '~309MB · 平衡推荐';

	/// 轻量模式
	///
	/// zh: '~197MB · 轻量模式'
	String get kb_lightweightMode => '~197MB · 轻量模式';

	/// 状态
	///
	/// zh: '状态'
	String get kb_status => '状态';

	/// 已下载
	///
	/// zh: '已下载'
	String get kb_downloaded => '已下载';

	/// 未下载
	///
	/// zh: '未下载'
	String get kb_notDownloaded => '未下载';

	/// 路径
	///
	/// zh: '路径'
	String get kb_path => '路径';

	/// 错误
	///
	/// zh: '错误: {error}'
	String kb_error({required Object error}) => '错误: ${error}';

	/// 校验中
	///
	/// zh: '正在校验文件完整性...'
	String get kb_verifyingFile => '正在校验文件完整性...';

	/// 下载中
	///
	/// zh: '下载中... {progress}%'
	String kb_downloading({required Object progress}) => '下载中... ${progress}%';

	/// 下载模型
	///
	/// zh: '下载模型'
	String get kb_downloadModel => '下载模型';

	/// 选择路径
	///
	/// zh: '选择本地路径'
	String get kb_selectLocalPath => '选择本地路径';

	/// 索引设置
	///
	/// zh: '索引设置'
	String get kb_indexSettings => '索引设置';

	/// 分块大小
	///
	/// zh: '分块大小'
	String get kb_chunkSize => '分块大小';

	/// 分块重叠
	///
	/// zh: '分块重叠'
	String get kb_chunkOverlap => '分块重叠';

	/// 缓存大小
	///
	/// zh: '缓存大小'
	String get kb_cacheSize => '缓存大小';

	/// 索引统计
	///
	/// zh: '索引统计'
	String get kb_indexStats => '索引统计';

	/// 准备Python
	///
	/// zh: '正在准备 向量服务...'
	String get kb_preparingPythonService => '正在准备 向量服务...';

	/// 启动Python
	///
	/// zh: '正在启动 向量服务...'
	String get kb_startingPythonService => '正在启动 向量服务...';

	/// 未启用提示
	///
	/// zh: '知识库未启用，请先在上方启用知识库'
	String get kb_knowledgeBaseNotEnabledPrompt => '知识库未启用，请先在上方启用知识库';

	/// 已索引
	///
	/// zh: '已索引笔记'
	String get kb_indexedNotes => '已索引笔记';

	/// 总向量
	///
	/// zh: '总向量数'
	String get kb_totalVectors => '总向量数';

	/// 最后更新
	///
	/// zh: '最后更新'
	String get kb_lastUpdate => '最后更新';

	/// 未索引
	///
	/// zh: '未索引'
	String get kb_notIndexed => '未索引';

	/// 索引进度
	///
	/// zh: '正在索引 {progress}/{total} 条笔记...'
	String kb_indexingProgress({required Object progress, required Object total}) => '正在索引 ${progress}/${total} 条笔记...';

	/// 索引失败
	///
	/// zh: '索引失败: 所有 {count} 条笔记均未成功'
	String kb_indexFailedAll({required Object count}) => '索引失败: 所有 ${count} 条笔记均未成功';

	/// 部分失败
	///
	/// zh: '索引完成: {success} 成功, {failed} 失败'
	String kb_indexCompleteWithFailures({required Object success, required Object failed}) => '索引完成: ${success} 成功, ${failed} 失败';

	/// 索引完成
	///
	/// zh: '索引完成: {count} 条成功'
	String kb_indexComplete({required Object count}) => '索引完成: ${count} 条成功';

	/// 收起错误
	///
	/// zh: '收起错误详情'
	String get kb_collapseErrorDetails => '收起错误详情';

	/// 查看错误
	///
	/// zh: '查看错误详情 ({count} 条)'
	String kb_viewErrorDetails({required Object count}) => '查看错误详情 (${count} 条)';

	/// 未索引提示
	///
	/// zh: '{count} 条笔记未索引，点击"重建索引"以更新'
	String kb_unindexedNotesPrompt({required Object count}) => '${count} 条笔记未索引，点击"重建索引"以更新';

	/// 重建索引
	///
	/// zh: '重建索引'
	String get kb_rebuildIndex => '重建索引';

	/// 清空索引
	///
	/// zh: '清空索引'
	String get kb_clearIndex => '清空索引';

	/// 清空索引确认
	///
	/// zh: '确认清空索引'
	String get kb_confirmClearIndex => '确认清空索引';

	/// 清空内容
	///
	/// zh: '清空后需要重新索引所有笔记，是否继续？'
	String get kb_confirmClearIndexContent => '清空后需要重新索引所有笔记，是否继续？';

	/// 重建索引确认
	///
	/// zh: '确认重建索引'
	String get kb_confirmRebuildIndex => '确认重建索引';

	/// 重建内容
	///
	/// zh: '将对 {count} 条笔记进行向量化索引。 这可能需要几分钟时间，是否继续？'
	String kb_confirmRebuildIndexContent({required Object count}) => '将对 ${count} 条笔记进行向量化索引。\n这可能需要几分钟时间，是否继续？';

	/// 开始重建
	///
	/// zh: '开始重建'
	String get kb_startRebuild => '开始重建';

	/// 重建失败
	///
	/// zh: '重建索引失败'
	String get kb_rebuildFailed => '重建索引失败';

	/// Python启动失败
	///
	/// zh: '重建索引失败：向量服务启动失败，请检查模型配置是否正确'
	String get kb_rebuildFailedPythonService => '重建索引失败：向量服务启动失败，请检查模型配置是否正确';

	/// 未就绪
	///
	/// zh: '重建索引失败：知识库未就绪，请先下载模型并启用知识库'
	String get kb_rebuildFailedNotReady => '重建索引失败：知识库未就绪，请先下载模型并启用知识库';

	/// 健康检查失败
	///
	/// zh: '重建索引失败：向量服务未正常启动，请稍后重试'
	String get kb_rebuildFailedHealthCheck => '重建索引失败：向量服务未正常启动，请稍后重试';

	/// 记忆能力
	///
	/// zh: '记忆能力'
	String get assistant_memoryCapability => '记忆能力';

	/// AI模型选择
	///
	/// zh: 'AI模型选择'
	String get assistant_aiModelSelection => 'AI模型选择';

	/// 记忆注入
	///
	/// zh: '记忆注入控制'
	String get assistant_memoryInjectionControl => '记忆注入控制';

	/// 清空记忆
	///
	/// zh: '清空记忆'
	String get assistant_clearMemory => '清空记忆';

	/// 角色控制
	///
	/// zh: '角色控制'
	String get assistant_roleControl => '角色控制';

	/// 启用长期记忆
	///
	/// zh: '启用长期记忆'
	String get assistant_enableLongTermMemory => '启用长期记忆';

	/// 禁用提示
	///
	/// zh: '关闭后将停止记录和使用所有记忆'
	String get assistant_memoryDisabledHint => '关闭后将停止记录和使用所有记忆';

	/// 配置模型提示
	///
	/// zh: '请先配置可用的AI模型'
	String get assistant_configureAIModelFirst => '请先配置可用的AI模型';

	/// 配置模型提示2
	///
	/// zh: '请先在"AI服务"中配置可用的AI模型'
	String get assistant_configureAIModelsFirst => '请先在"AI服务"中配置可用的AI模型';

	/// 无模型
	///
	/// zh: '状态: 无可用模型'
	String get assistant_noAvailableModels => '状态: 无可用模型';

	/// 可用模型
	///
	/// zh: '状态: {count}个可用模型'
	String assistant_availableModelsCount({required Object count}) => '状态: ${count}个可用模型';

	/// 档案记忆
	///
	/// zh: '用户档案记忆'
	String get assistant_profileMemory => '用户档案记忆';

	/// 档案副标题
	///
	/// zh: '称呼、职业、语言偏好等'
	String get assistant_profileMemorySubtitle => '称呼、职业、语言偏好等';

	/// 事实偏好
	///
	/// zh: '事实偏好记忆'
	String get assistant_factPreferenceMemory => '事实偏好记忆';

	/// 事实副标题
	///
	/// zh: '使用习惯、具体偏好等'
	String get assistant_factPreferenceSubtitle => '使用习惯、具体偏好等';

	/// 经验总结
	///
	/// zh: '经验总结记忆'
	String get assistant_experienceSummaryMemory => '经验总结记忆';

	/// 经验副标题
	///
	/// zh: '操作套路、应对策略等'
	String get assistant_experienceSummarySubtitle => '操作套路、应对策略等';

	/// 清空档案
	///
	/// zh: '清空档案记忆 ({count} 条)'
	String assistant_clearProfileMemory({required Object count}) => '清空档案记忆 (${count} 条)';

	/// 清空事实
	///
	/// zh: '清空事实记忆 ({count} 条)'
	String assistant_clearFactMemory({required Object count}) => '清空事实记忆 (${count} 条)';

	/// 清空经验
	///
	/// zh: '清空经验记忆 ({count} 条)'
	String assistant_clearExperienceMemory({required Object count}) => '清空经验记忆 (${count} 条)';

	/// 清空全部
	///
	/// zh: '清空全部记忆 ({count} 条)'
	String assistant_clearAllMemory({required Object count}) => '清空全部记忆 (${count} 条)';

	/// 角色自定义开发中
	///
	/// zh: '角色语气、性格自定义功能开发中'
	String get assistant_roleCustomizationInDevelopment => '角色语气、性格自定义功能开发中';

	/// 清空记忆确认
	///
	/// zh: '确定清空所有{typeName}吗？此操作不可恢复。'
	String assistant_confirmClearMemoryContent({required Object typeName}) => '确定清空所有${typeName}吗？此操作不可恢复。';

	/// 已清空
	///
	/// zh: '已清空{typeName}'
	String assistant_clearedMemory({required Object typeName}) => '已清空${typeName}';

	/// 清空全部确认
	///
	/// zh: '确定清空所有类型的记忆吗？此操作不可恢复。'
	String get assistant_confirmClearAllMemoryContent => '确定清空所有类型的记忆吗？此操作不可恢复。';

	/// 已清空全部
	///
	/// zh: '已清空全部记忆'
	String get assistant_clearedAllMemory => '已清空全部记忆';

	/// 清空全部
	///
	/// zh: '清空全部'
	String get assistant_clearAll => '清空全部';

	/// 检查环境
	///
	/// zh: '检查环境...'
	String get cli_checkingEnv => '检查环境...';

	/// 环境不满足
	///
	/// zh: '环境不满足要求'
	String get cli_envNotMet => '环境不满足要求';

	/// 安装CLI
	///
	/// zh: '正在安装 CLI...'
	String get cli_installingCLI => '正在安装 CLI...';

	/// 安装成功
	///
	/// zh: '安装成功'
	String get cli_installSuccess => '安装成功';

	/// 安装失败
	///
	/// zh: '安装失败'
	String get cli_installFailed => '安装失败';

	/// pip安装
	///
	/// zh: '正在执行: pip install open-note-cli --upgrade'
	String get cli_executingPipInstall => '正在执行: pip install open-note-cli --upgrade';

	/// 安装中
	///
	/// zh: '安装中，请稍候...'
	String get cli_installingPleaseWait => '安装中，请稍候...';

	/// 安装成功消息
	///
	/// zh: 'CLI 工具已成功安装！'
	String get cli_cliInstalledSuccessfully => 'CLI 工具已成功安装！';

	/// 安装完成
	///
	/// zh: '安装完成'
	String get cli_installComplete => '安装完成';

	/// 使用方法
	///
	/// zh: '使用方法: opennote --help'
	String get cli_usageMethod => '使用方法: opennote --help';

	/// 降级安装
	///
	/// zh: '降级安装方法：'
	String get cli_fallbackInstallMethod => '降级安装方法：';

	/// 重新检查
	///
	/// zh: '重新检查'
	String get cli_recheck => '重新检查';

	/// 启动失败
	///
	/// zh: '启动失败'
	String get splash_startFailed => '启动失败';

	/// Follow system option
	///
	/// zh: '跟随系统'
	String get preferences_followSystem => '跟随系统';

	/// New note button tooltip
	///
	/// zh: '新建'
	String get home_newNote => '新建';

	/// settings_modelCount
	///
	/// zh: '个模型'
	String get settings_modelCount => '个模型';

	/// common_notConfigured
	///
	/// zh: '未配置'
	String get common_notConfigured => '未配置';

	/// settings_defaultModel
	///
	/// zh: '默认模型'
	String get settings_defaultModel => '默认模型';

	/// settings_autoFollowSystemTheme
	///
	/// zh: '自动跟随系统主题设置'
	String get settings_autoFollowSystemTheme => '自动跟随系统主题设置';

	/// settings_alwaysUseLightTheme
	///
	/// zh: '始终使用亮色主题'
	String get settings_alwaysUseLightTheme => '始终使用亮色主题';

	/// settings_alwaysUseDarkTheme
	///
	/// zh: '始终使用暗色主题'
	String get settings_alwaysUseDarkTheme => '始终使用暗色主题';

	/// kb_serviceJustStarted
	///
	/// zh: '服务刚启动，准备初始化...'
	String get kb_serviceJustStarted => '服务刚启动，准备初始化...';

	/// kb_chromaDbInitializing
	///
	/// zh: '正在初始化 ChromaDB 数据库...'
	String get kb_chromaDbInitializing => '正在初始化 ChromaDB 数据库...';

	/// kb_loadingEmbeddingModel
	///
	/// zh: '正在加载 Embedding AI 模型...'
	String get kb_loadingEmbeddingModel => '正在加载 Embedding AI 模型...';

	/// kb_chromaDbInitFailed
	///
	/// zh: 'ChromaDB 初始化失败'
	String get kb_chromaDbInitFailed => 'ChromaDB 初始化失败';

	/// kb_modelLoadFailed
	///
	/// zh: '嵌入模型加载失败'
	String get kb_modelLoadFailed => '嵌入模型加载失败';

	/// kb_serviceInitError
	///
	/// zh: '服务初始化异常'
	String get kb_serviceInitError => '服务初始化异常';

	/// kb_vectorServiceNotRunning
	///
	/// zh: '向量服务未运行'
	String get kb_vectorServiceNotRunning => '向量服务未运行';

	/// kb_serviceNotStarted
	///
	/// zh: '服务未启动'
	String get kb_serviceNotStarted => '服务未启动';

	/// kb_cannotFetchStatus
	///
	/// zh: '无法获取服务状态'
	String get kb_cannotFetchStatus => '无法获取服务状态';

	/// kb_serviceConnectionFailed
	///
	/// zh: '服务连接失败'
	String get kb_serviceConnectionFailed => '服务连接失败';

	/// kb_vectorServicePrepareFailed
	///
	/// zh: '向量服务准备失败'
	String get kb_vectorServicePrepareFailed => '向量服务准备失败';

	/// kb_vectorServicePrepareError
	///
	/// zh: '向量服务准备异常'
	String get kb_vectorServicePrepareError => '向量服务准备异常';

	/// kb_vectorServiceStartFailed
	///
	/// zh: '向量服务启动失败，请检查模型配置'
	String get kb_vectorServiceStartFailed => '向量服务启动失败，请检查模型配置';

	/// kb_vectorServiceError
	///
	/// zh: '向量服务异常'
	String get kb_vectorServiceError => '向量服务异常';

	/// kb_serviceAlreadyRunning
	///
	/// zh: '服务已在运行'
	String get kb_serviceAlreadyRunning => '服务已在运行';

	/// kb_serviceStarted
	///
	/// zh: '服务已启动'
	String get kb_serviceStarted => '服务已启动';

	/// kb_serviceStartFailedPython
	///
	/// zh: '服务启动失败，请检查 Python 环境和依赖'
	String get kb_serviceStartFailedPython => '服务启动失败，请检查 Python 环境和依赖';

	/// kb_directoryNotExist
	///
	/// zh: '目录不存在'
	String get kb_directoryNotExist => '目录不存在';

	/// kb_missingModelFile
	///
	/// zh: '缺少模型文件: model.onnx'
	String get kb_missingModelFile => '缺少模型文件: model.onnx';

	/// kb_missingTokenizer
	///
	/// zh: '缺少 tokenizer.json'
	String get kb_missingTokenizer => '缺少 tokenizer.json';

	/// kb_modelFileSizeAbnormal
	///
	/// zh: '模型文件大小异常'
	String get kb_modelFileSizeAbnormal => '模型文件大小异常';

	/// kb_knowledgeBaseNotReady
	///
	/// zh: '知识库未就绪，请先下载模型并启用知识库'
	String get kb_knowledgeBaseNotReady => '知识库未就绪，请先下载模型并启用知识库';

	/// kb_vectorServiceStartFailedIndex
	///
	/// zh: '向量服务启动失败，无法进行索引'
	String get kb_vectorServiceStartFailedIndex => '向量服务启动失败，无法进行索引';

	/// kb_healthCheckFailed
	///
	/// zh: '向量服务健康检查失败，服务可能未正常启动'
	String get kb_healthCheckFailed => '向量服务健康检查失败，服务可能未正常启动';

	/// cli_pythonNotInstalled
	///
	/// zh: '未找到 Python，请先安装 Python 3.10+'
	String get cli_pythonNotInstalled => '未找到 Python，请先安装 Python 3.10+';

	/// cli_pipNotInstalled
	///
	/// zh: '未找到 pip，请先安装 pip'
	String get cli_pipNotInstalled => '未找到 pip，请先安装 pip';

	/// cli_installProcessError
	///
	/// zh: '安装过程出错: '
	String get cli_installProcessError => '安装过程出错: ';

	/// cli_envInstructionsMac
	///
	/// zh: '请先安装 Python 3.10+ 和 pip： 使用 Homebrew: brew install python3 或从 https://python.org 下载安装包'
	String get cli_envInstructionsMac => '请先安装 Python 3.10+ 和 pip：\n\n使用 Homebrew:\n  brew install python3\n\n或从 https://python.org 下载安装包';

	/// cli_envInstructionsWindows
	///
	/// zh: '请先安装 Python 3.10+： 从 https://python.org 下载安装包 安装时勾选 "Add Python to PATH"'
	String get cli_envInstructionsWindows => '请先安装 Python 3.10+：\n\n从 https://python.org 下载安装包\n安装时勾选 "Add Python to PATH"';

	/// cli_envInstructionsLinux
	///
	/// zh: '请先安装 Python 3.10+ 和 pip： Ubuntu/Debian: sudo apt install python3 python3-pip Fedora: sudo dnf install python3 python3-pip'
	String get cli_envInstructionsLinux => '请先安装 Python 3.10+ 和 pip：\n\nUbuntu/Debian:\n  sudo apt install python3 python3-pip\n\nFedora:\n  sudo dnf install python3 python3-pip';

	/// cli_envCheckFailed
	///
	/// zh: '环境检查失败'
	String get cli_envCheckFailed => '环境检查失败';

	/// cli_envStatus
	///
	/// zh: '环境状态'
	String get cli_envStatus => '环境状态';

	/// cli_installCLI
	///
	/// zh: '安装 CLI'
	String get cli_installCLI => '安装 CLI';

	/// cli_usage
	///
	/// zh: '使用方法'
	String get cli_usage => '使用方法';

	/// cli_cliStatus
	///
	/// zh: 'CLI 状态'
	String get cli_cliStatus => 'CLI 状态';

	/// cli_installed
	///
	/// zh: '已安装'
	String get cli_installed => '已安装';

	/// cli_notInstalled
	///
	/// zh: '未安装'
	String get cli_notInstalled => '未安装';

	/// cli_notDetected
	///
	/// zh: '未检测到'
	String get cli_notDetected => '未检测到';

	/// cli_installDescription
	///
	/// zh: '点击按钮将自动安装 OpenNote CLI 工具到你的系统环境'
	String get cli_installDescription => '点击按钮将自动安装 OpenNote CLI 工具到你的系统环境';

	/// cli_helpText
	///
	/// zh: 'opennote --help # 查看帮助 opennote note list # 列出笔记 opennote note search 关键词 # 搜索笔记 opennote mcp start # 启动 MCP 服务'
	String get cli_helpText => 'opennote --help              # 查看帮助\nopennote note list           # 列出笔记\nopennote note search 关键词   # 搜索笔记\nopennote mcp start           # 启动 MCP 服务';

	/// ai_copyMessage
	///
	/// zh: '复制'
	String get ai_copyMessage => '复制';

	/// ai_messageCopied
	///
	/// zh: '已复制'
	String get ai_messageCopied => '已复制';

	/// ai_undoMessage
	///
	/// zh: '撤销'
	String get ai_undoMessage => '撤销';

	/// ai_newSession
	///
	/// zh: '新会话'
	String get ai_newSession => '新会话';

	/// kb_switchModelWarning
	///
	/// zh: '切换模型版本将清空向量索引，切换后将重建索引。'
	String get kb_switchModelWarning => '切换模型版本将清空向量索引，切换后将重建索引。';
}
