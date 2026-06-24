///
/// Generated file. Do not edit.
///
// coverage:ignore-file
// ignore_for_file: type=lint, unused_import
// dart format off

import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:slang/generated.dart';
import 'strings.g.dart';

// Path: <root>
class TranslationsEn extends Translations with BaseTranslations<AppLocale, Translations> {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	TranslationsEn({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = meta ?? TranslationMetadata(
		    locale: AppLocale.en,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ),
		  super(cardinalResolver: cardinalResolver, ordinalResolver: ordinalResolver);

	/// Metadata for the translations of <en>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	late final TranslationsEn _root = this; // ignore: unused_field

	@override 
	TranslationsEn $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => TranslationsEn(meta: meta ?? this.$meta);

	// Translations

	/// 取消按钮
	@override String get common_cancel => 'Cancel';

	/// 保存按钮
	@override String get common_save => 'Save';

	/// 删除按钮
	@override String get common_delete => 'Delete';

	/// 确定按钮
	@override String get common_ok => 'OK';

	/// 关闭按钮
	@override String get common_close => 'Close';

	/// 重试按钮
	@override String get common_retry => 'Retry';

	/// 编辑按钮
	@override String get common_edit => 'Edit';

	/// 创建按钮
	@override String get common_create => 'Create';

	/// 添加按钮
	@override String get common_add => 'Add';

	/// 清空/清除按钮
	@override String get common_clear => 'Clear';

	/// 粘贴按钮
	@override String get common_paste => 'Paste';

	/// 暂停按钮
	@override String get common_pause => 'Pause';

	/// 继续/恢复按钮
	@override String get common_resume => 'Resume';

	/// 跳过按钮
	@override String get common_skip => 'Skip';

	/// 下一步按钮
	@override String get common_next => 'Next';

	/// 上一页按钮
	@override String get common_previous => 'Previous';

	/// 删除确认标题
	@override String get common_confirmDelete => 'Confirm Delete';

	/// 清空确认标题
	@override String get common_confirmClear => 'Confirm Clear';

	/// 即将上线标签
	@override String get common_comingSoon => 'Coming Soon';

	/// 跟随系统选项
	@override String get common_followSystem => 'Follow System';

	/// 亮色模式
	@override String get common_lightMode => 'Light Mode';

	/// 暗色模式
	@override String get common_darkMode => 'Dark Mode';

	/// 收起按钮
	@override String get common_collapse => 'Collapse';

	/// 展开按钮
	@override String get common_expand => 'Expand';

	/// 发送按钮
	@override String get common_send => 'Send';

	/// 停止按钮
	@override String get common_stop => 'Stop';

	/// 是
	@override String get common_yes => 'Yes';

	/// 否
	@override String get common_no => 'No';

	/// 完成按钮
	@override String get common_done => 'Done';

	/// 更多选项
	@override String get common_more => 'More';

	/// 未知状态
	@override String get common_unknown => 'Unknown';

	/// 导航-首页
	@override String get home_home => 'Home';

	/// 导航-目录
	@override String get home_categories => 'Categories';

	/// 导航-AI
	@override String get home_ai => 'AI';

	/// 导航-收藏
	@override String get home_favorites => 'Favorites';

	/// 导航-设置
	@override String get home_settings => 'Settings';

	/// 平板导航-笔记
	@override String get home_note => 'Notes';

	/// 拖拽导入覆盖层
	@override String get home_dragDropImport => 'Drop files to import notes';

	/// 导入成功
	@override String home_successImportCount({required Object count}) => 'Successfully imported ${count} file(s)';

	/// 导入失败
	@override String home_failImportCount({required Object count}) => '${count} file(s) failed to import';

	/// 剪贴板URL提示
	@override String get home_clipboardUrlDetected => 'URL detected in clipboard, create a note?';

	/// 忽略按钮
	@override String get home_dismiss => 'Dismiss';

	/// 摘要暂停状态
	@override String home_summaryGenerationPaused({required Object processedCount, required Object totalPending}) => 'Summary generation paused (${processedCount}/${totalPending})';

	/// 多选计数
	@override String home_selectedCount({required Object count}) => '${count} selected';

	/// 笔记列表标题
	@override String get home_allNotes => 'All Notes';

	/// 取消多选
	@override String get home_cancelMultiSelect => 'Cancel Multi-select';

	/// 多选切换
	@override String get home_multiSelect => 'Multi-select';

	/// 回收站图标提示
	@override String get home_trash => 'Trash';

	/// 回收站带数量
	@override String home_trashWithCount({required Object count}) => 'Trash (${count})';

	/// 新建空白笔记
	@override String get home_newBlankNote => 'New Blank Note';

	/// 从URL创建
	@override String get home_createFromUrl => 'Create from URL';

	/// 从文件导入
	@override String get home_importFromFile => 'Import from File';

	/// 删除后提示
	@override String get home_noteMovedToTrash => 'Note moved to trash';

	/// 空内容提示
	@override String get home_selectNoteToStart => 'Select a note to start viewing';

	/// 删除确认内容
	@override String home_confirmDeleteNoteContent({required Object title}) => 'Are you sure you want to delete "${title}"?';

	/// 批量删除标题
	@override String get home_confirmBatchDelete => 'Confirm Batch Delete';

	/// 批量删除内容
	@override String home_confirmBatchDeleteContent({required Object count}) => 'Are you sure you want to delete ${count} selected notes?';

	/// 批量操作栏
	@override String home_selectedNotesCount({required Object count}) => '${count} notes selected';

	/// 批量删除后提示
	@override String home_deletedCountNotes({required Object count}) => '${count} note(s) deleted';

	/// 回收站对话框标题
	@override String get home_trashTitle => 'Trash';

	/// 空回收站提示
	@override String get home_trashEmpty => 'Trash is empty';

	/// 回收站副标题
	@override String home_daysAgoDeleted({required Object days}) => 'Deleted ${days} days ago';

	/// 恢复按钮
	@override String get home_restore => 'Restore';

	/// 恢复后提示
	@override String get home_noteRestored => 'Note restored';

	/// 永久删除
	@override String get home_permanentlyDelete => 'Permanently Delete';

	/// 永久删除提示
	@override String get home_notePermanentlyDeleted => 'Note permanently deleted';

	/// 清空回收站按钮
	@override String get home_emptyTrash => 'Empty Trash';

	/// 清空回收站标题
	@override String get home_emptyTrashTitle => 'Empty Trash';

	/// 清空回收站内容
	@override String home_emptyTrashContent({required Object count}) => 'Are you sure you want to permanently delete ${count} note(s)? This cannot be undone.';

	/// 清空后提示
	@override String get home_trashEmptied => 'Trash emptied';

	/// 切换主题标题
	@override String get home_switchTheme => 'Switch Theme';

	/// 切换亮色
	@override String get home_switchToLight => 'Switch to Light Mode';

	/// 切换暗色
	@override String get home_switchToDark => 'Switch to Dark Mode';

	/// 取消收藏菜单
	@override String get home_unfavorite => 'Unfavorite';

	/// 收藏菜单
	@override String get home_favorite => 'Favorite';

	/// 分享菜单
	@override String get home_share => 'Share';

	/// 分享功能提示
	@override String get home_shareComingSoon => 'Sharing feature coming soon';

	/// 默认标题
	@override String get editor_untitledNote => 'Untitled Note';

	/// 保存中状态
	@override String get editor_saving => 'Saving...';

	/// 自动保存成功
	@override String get editor_autoSaved => 'Auto-saved';

	/// 自动保存失败
	@override String get editor_autoSaveFailed => 'Auto-save failed';

	/// 分类选择器
	@override String get editor_selectCategory => 'Select Category';

	/// 无分类选项
	@override String get editor_noCategory => 'No Category';

	/// 清除分类
	@override String get editor_clearCategory => 'Clear Category';

	/// 内容不能为空
	@override String get editor_noteContentCannotBeEmpty => 'Note content cannot be empty';

	/// 保存成功
	@override String get editor_saveSuccess => 'Saved successfully';

	/// 保存失败
	@override String editor_saveFailed({required Object error}) => 'Save failed: ${error}';

	/// 填写提示
	@override String get editor_fillTitleAndContentFirst => 'Please fill in title and content first';

	/// 配置超时
	@override String get editor_configTimeoutRetry => 'Config load timeout, please try again';

	/// AI未配置
	@override String get editor_configureAIFirst => 'Please configure AI service first';

	/// 建议生成失败
	@override String editor_generateSuggestionsFailed({required Object error}) => 'Failed to generate suggestions: ${error}';

	/// 智能建议标题
	@override String get editor_smartSuggestions => 'Smart Suggestions';

	/// 分类建议标签
	@override String get editor_categorySuggestion => 'Category Suggestion:';

	/// 标签建议标签
	@override String get editor_tagSuggestion => 'Tag Suggestion:';

	/// 无建议
	@override String get editor_noSuggestions => 'No suggestions available';

	/// 应用建议按钮
	@override String get editor_applySuggestions => 'Apply Suggestions';

	/// 新笔记标题
	@override String get editor_newNote => 'New Note';

	/// 编辑笔记标题
	@override String get editor_editNote => 'Edit Note';

	/// 预览模式
	@override String get editor_preview => 'Preview';

	/// 智能建议提示
	@override String get editor_smartSuggestionsTooltip => 'Smart Suggestions';

	/// AI助手提示
	@override String get editor_aiAssistant => 'AI Assistant';

	/// 来源标签
	@override String get editor_source => 'Source: ';

	/// 标题文本框
	@override String get editor_title => 'Title';

	/// Markdown占位符
	@override String get editor_startWritingMarkdown => 'Start writing your Markdown note...';

	/// 纯文本占位符
	@override String get editor_startWritingPlainText => 'Start writing your plain text note...';

	/// 富文本占位符
	@override String get editor_startWritingRichText => 'Start writing your rich text note...';

	/// 设置导航-首选项
	@override String get settings_preferences => 'Preferences';

	/// 设置导航-AI服务
	@override String get settings_aiService => 'AI Service';

	/// 设置导航-外观
	@override String get settings_appearance => 'Appearance';

	/// 设置导航-知识库
	@override String get settings_knowledgeBase => 'Knowledge Base';

	/// 设置导航-智能助理
	@override String get settings_assistant => 'Assistant';

	/// 设置导航-CLI
	@override String get settings_cliTools => 'CLI Tools';

	/// 设置对话框标题
	@override String get settings_title => 'Settings';

	/// 开发中占位
	@override String get settings_featureInDevelopment => 'Feature in development...';

	/// 自定义配置标题
	@override String get settings_customConfig => 'Custom Config';

	/// 快速添加标题
	@override String get settings_quickAddPresets => 'Quick Add Presets';

	/// 快速添加描述
	@override String get settings_quickAddDescription => 'Click to quickly add common provider configs';

	/// 无AI配置
	@override String get settings_noAIConfig => 'No AI config yet';

	/// 空状态提示
	@override String get settings_clickToAddPreset => 'Click below or use quick add presets';

	/// 已配置列表
	@override String get settings_configured => 'Configured';

	/// 配置数量
	@override String settings_configCount({required Object count}) => '${count}';

	/// 当前徽章
	@override String get settings_current => 'Current';

	/// 配置模型提示
	@override String get settings_setModelFirst => 'Please configure a model first';

	/// 添加提供商
	@override String settings_addProvider({required Object name}) => 'Add ${name}';

	/// API地址标签
	@override String get settings_apiAddress => 'API Address: ';

	/// 预设模型
	@override String settings_presetsModels({required Object models}) => 'Preset Models: ${models}';

	/// API密钥标签
	@override String get settings_apiKey => 'API Key';

	/// API密钥提示
	@override String get settings_enterApiKey => 'Enter your API key';

	/// API密钥错误
	@override String get settings_enterApiKeyError => 'Please enter API key';

	/// 厂商名称
	@override String get settings_vendorName => 'Vendor Name';

	/// 厂商名称提示
	@override String get settings_vendorNameHint => 'e.g.: My API, Proxy';

	/// Base URL标签
	@override String get settings_baseUrl => 'Base URL';

	/// Base URL提示
	@override String get settings_baseUrlHint => 'https://api.example.com/v1';

	/// 模型列表
	@override String get settings_modelList => 'Model List';

	/// 模型列表提示
	@override String get settings_modelListHint => 'Comma separated, e.g.: model-1,model-2';

	/// 厂商名称错误
	@override String get settings_enterVendorName => 'Please enter vendor name';

	/// 模型错误
	@override String get settings_enterAtLeastOneModel => 'Please enter at least one model';

	/// 显示名称
	@override String get settings_displayName => 'Display Name';

	/// 删除配置确认
	@override String settings_confirmDeleteConfig({required Object name}) => 'Delete config "${name}"?';

	/// 连接成功
	@override String settings_connectionSuccess({required Object name}) => 'Successfully connected to ${name}';

	/// 未知错误
	@override String get settings_unknownError => 'Unknown error';

	/// 测试异常
	@override String settings_testException({required Object error}) => 'Test exception: ${error}';

	/// 测试连接
	@override String get settings_testConnection => 'Test Connection';

	/// 测试连接中
	@override String get settings_testingConnection => 'Testing connection...';

	/// 连接成功标签
	@override String get settings_connectionSuccessful => 'Connection Successful';

	/// 连接失败标签
	@override String get settings_connectionFailed => 'Connection Failed';

	/// 搜索框
	@override String get search_placeholder => 'Search notes...';

	/// 分类筛选
	@override String get search_categoryFilter => 'Category Filter';

	/// 所有分类
	@override String get search_allCategories => 'All Categories';

	/// 输入提示
	@override String get search_enterToSearch => 'Enter keywords to search';

	/// 无结果
	@override String get search_noResults => 'No notes found';

	/// 无历史
	@override String get search_noHistory => 'No search history';

	/// 最近搜索
	@override String get search_recentSearches => 'Recent Searches';

	/// 未命名回退
	@override String get search_untitledNote => 'Untitled Note';

	/// 刚刚
	@override String get search_justNow => 'Just now';

	/// 分钟前
	@override String search_minutesAgo({required Object count}) => '${count} min ago';

	/// 小时前
	@override String search_hoursAgo({required Object count}) => '${count} hr ago';

	/// 昨天
	@override String get search_yesterday => 'Yesterday';

	/// 天前
	@override String search_daysAgo({required Object count}) => '${count} days ago';

	/// Enter键
	@override String get search_enterHint => 'Enter';

	/// 打开
	@override String get search_open => 'Open';

	/// 上下键
	@override String get search_navigateHint => '↑↓';

	/// 导航
	@override String get search_navigate => 'Navigate';

	/// Esc键
	@override String get search_escHint => 'Esc';

	/// 关闭
	@override String get search_closeHint => 'Close';

	/// 新建笔记
	@override String get dialog_newNote => 'New Note';

	/// 空白笔记
	@override String get dialog_blankNote => 'Blank Note';

	/// 空白笔记副标题
	@override String get dialog_createBlankNote => 'Create a new blank note';

	/// 从文件导入
	@override String get dialog_importFromFile => 'Import from File';

	/// 从文件导入副标题
	@override String get dialog_importFromFileSubtitle => 'Create notes from TXT, code, or HTML files';

	/// 导入成功
	@override String get dialog_noteImportSuccess => 'Note imported successfully';

	/// 不支持格式
	@override String get dialog_importFailedUnsupported => 'Import failed: Unsupported file format';

	/// 导入失败
	@override String dialog_importFailed({required Object error}) => 'Import failed: ${error}';

	/// 选择格式
	@override String get dialog_selectNoteFormat => 'Select Note Format';

	/// Markdown格式
	@override String get dialog_markdown => 'Markdown';

	/// Markdown描述
	@override String get dialog_markdownDescription => 'Supports rich text, code blocks, tables, etc.';

	/// 纯文本
	@override String get dialog_plainText => 'Plain Text';

	/// 纯文本描述
	@override String get dialog_plainTextDescription => 'Simple plain text format, no special formatting';

	/// 富文本
	@override String get dialog_richText => 'Rich Text';

	/// 富文本描述
	@override String get dialog_richTextDescription => 'Quill editor, supports bold, italic, lists, etc.';

	/// 代码
	@override String get dialog_code => 'Code';

	/// 代码描述
	@override String get dialog_codeDescription => 'Code editor with syntax highlighting';

	/// URL创建
	@override String get dialog_createFromUrl => 'Create Note from URL';

	/// URL字段
	@override String get dialog_webUrl => 'Web URL';

	/// URL提示
	@override String get dialog_urlHint => 'example.com';

	/// URL错误
	@override String get dialog_enterUrl => 'Please enter URL';

	/// URL格式错误
	@override String get dialog_invalidUrlFormat => 'Invalid URL format';

	/// 提取失败
	@override String get dialog_extractFailed => 'Content extraction failed';

	/// 提取中
	@override String get dialog_extractingContent => 'Extracting content...';

	/// 提取成功
	@override String get dialog_extractSuccess => 'Extracted successfully';

	/// AI初始化
	@override String get dialog_aiInitializing => 'AI is initializing note...';

	/// 自动初始化
	@override String get dialog_noteAutoInitialized => 'Note auto-initialized';

	/// 摘要
	@override String get dialog_summary => 'Summary';

	/// 关键词
	@override String get dialog_keywords => 'Keywords';

	/// 分类
	@override String get dialog_category => 'Category';

	/// 标签
	@override String get dialog_tags => 'Tags';

	/// 提取内容按钮
	@override String get dialog_extractContent => 'Extract Content';

	/// 创建笔记按钮
	@override String get dialog_createNote => 'Create Note';

	/// 模型管理标题
	@override String dialog_manageModelsTitle({required Object providerName}) => 'Manage Models - ${providerName}';

	/// 新模型标签
	@override String get dialog_newModelLabel => 'New Model Name';

	/// 添加模型
	@override String get dialog_addModelTooltip => 'Add Model';

	/// 当前模型
	@override String dialog_currentModelsHeader({required Object count}) => 'Current Models (${count}):';

	/// 设为默认
	@override String get dialog_setDefaultTooltip => 'Set as Default';

	/// 模型更新
	@override String get dialog_modelsUpdated => 'Model list updated';

	/// 分类管理
	@override String get category_title => 'Category Manager';

	/// 平铺视图
	@override String get category_flatViewTooltip => 'Flat View';

	/// 树形视图
	@override String get category_treeViewTooltip => 'Tree View';

	/// 新建分类
	@override String get category_createNewTooltip => 'New Category';

	/// 无分类
	@override String get category_emptyState => 'No categories yet';

	/// 新建分类标题
	@override String get category_createTitle => 'New Category';

	/// 新建子分类
	@override String get category_createChildTitle => 'New Subcategory';

	/// 分类名称提示
	@override String get category_nameHint => 'Enter category name';

	/// 名称为空
	@override String get category_nameEmptyError => 'Category name cannot be empty';

	/// 名称过长
	@override String get category_nameTooLongError => 'Category name cannot exceed 20 characters';

	/// 名称含横杠
	@override String get category_nameDashError => 'Category name cannot contain "-" character';

	/// 名称重复
	@override String get category_duplicateNameError => 'A category with this name already exists at this level';

	/// 删除分类
	@override String get category_deleteTitle => 'Delete Category';

	/// 删除确认
	@override String category_deleteConfirm({required Object name}) => 'Are you sure you want to delete "${name}"?';

	/// 删除警告
	@override String category_deleteWarning({required Object count}) => 'This category has ${count} note(s). Deleting the category will also delete these notes!';

	/// 重命名
	@override String get category_renameTitle => 'Rename Category';

	/// 新名称提示
	@override String get category_newNameHint => 'Enter new category name';

	/// 重命名
	@override String get category_renameTooltip => 'Rename';

	/// 添加子分类
	@override String get category_addChildTooltip => 'Add Subcategory';

	/// AI问候
	@override String get ai_ciciGreeting => 'Hi, I\'m Cici';

	/// AI副标题
	@override String get ai_ciciSubtitle => 'Based on your note knowledge base, I can help you:';

	/// 查找笔记
	@override String get ai_quickActionSearch => 'Find Notes';

	/// 总结提炼
	@override String get ai_quickActionSummarize => 'Summarize';

	/// 答疑解惑
	@override String get ai_quickActionQa => 'Q&A';

	/// 示例消息1
	@override String get ai_sampleUserMessage1 => 'Help me find notes about "OKR methodology"';

	/// 示例回复-找到
	@override String get ai_sampleAssistantFound => 'Sure, I found';

	/// 示例回复-数量
	@override String get ai_sampleAssistantNotes => '1 related note:';

	/// 示例笔记标题
	@override String get ai_sampleNoteTitle => 'OKR Methodology: Goal Setting and Implementation';

	/// 示例笔记描述
	@override String get ai_sampleNoteDesc => 'Introduces the definition of OKR, core principles, and application methods in teams...';

	/// 示例消息2
	@override String get ai_sampleUserMessage2 => 'What are the core principles of OKR?';

	/// 示例回复-原则
	@override String get ai_sampleAssistantPrinciples => 'The core principles of OKR include:';

	/// 示例原则1
	@override String get ai_samplePrinciple1 => '• Objectives (O) should be challenging to inspire potential;';

	/// 示例原则2
	@override String get ai_samplePrinciple2 => '• Key Results (KR) should be measurable to ensure goals are trackable;';

	/// 示例原则3
	@override String get ai_samplePrinciple3 => '• Maintain transparency and alignment, team goals consistent top to bottom;';

	/// 示例原则4
	@override String get ai_samplePrinciple4 => '• Regular reviews, continuous learning and improvement.';

	/// 示例结论
	@override String get ai_sampleAssistantConclusion => 'These principles help teams focus on priorities and improve execution.';

	/// AI输入框
	@override String get ai_inputPlaceholder => 'Ask a question, or use natural language to find notes...';

	/// 搜索模板
	@override String get ai_quickActionSearchTemplate => 'Help me find notes about ""';

	/// 总结当前笔记
	@override String ai_quickActionSummarizeWithNote({required Object title}) => 'Please summarize the core content of this note "${title}"';

	/// 总结默认
	@override String get ai_quickActionSummarizeDefault => 'Please summarize the core content of the current note';

	/// 问答模板
	@override String get ai_quickActionQaTemplate => 'I have a question I\'d like answered based on note content...';

	/// 新会话
	@override String get ai_newSessionTitle => 'New Session';

	/// 新会话确认
	@override String get ai_newSessionConfirm => 'Start a new session? Current conversation will be cleared.';

	/// 分析需求
	@override String get ai_thinkingAnalyzing => 'Analyzing user request...';

	/// 知识库未启用
	@override String get ai_knowledgeBaseDisabled => '⚠️ Knowledge base is not enabled, using plain text search';

	/// 回复失败
	@override String ai_replyFailed({required Object error}) => 'AI reply failed: ${error}';

	/// 调用中断
	@override String get ai_toolCallInterrupted => 'Call interrupted';

	/// 执行取消
	@override String get ai_executionCancelled => 'Execution cancelled';

	/// 用户中断
	@override String get ai_operationInterrupted => 'Operation interrupted by user';

	/// 默认输入框
	@override String get ai_inputDefaultPlaceholder => 'Ask a question, or search notes with natural language';

	/// 工具类别-探索
	@override String get ai_toolCategoryExplore => 'Explore';

	/// 工具类别-编辑
	@override String get ai_toolCategoryEdit => 'Edit';

	/// 工具类别-写入
	@override String get ai_toolCategoryWrite => 'Write';

	/// 工具类别-删除
	@override String get ai_toolCategoryDelete => 'Delete';

	/// 工具类别-总结
	@override String get ai_toolCategorySummarize => 'Summarize';

	/// 工具类别-提取
	@override String get ai_toolCategoryExtract => 'Extract';

	/// 工具类别-处理
	@override String get ai_toolCategoryProcess => 'Process';

	/// 执行终止
	@override String get ai_toolTerminated => 'Execution terminated';

	/// 执行中
	@override String get ai_toolInProgress => 'Executing...';

	/// 执行完成
	@override String get ai_toolCompleted => 'Completed';

	/// 工具统计
	@override String ai_toolBadgeCount({required Object category, required Object count}) => '${category} ${count} times';

	/// 思考中
	@override String get ai_thinking => 'Thinking';

	/// AI摘要标题
	@override String get ai_summaryTitle => 'AI Summary';

	/// 点击展开
	@override String get ai_clickToExpand => 'Click to expand and view summary';

	/// 生成摘要
	@override String get ai_generateSummary => 'Generate Summary';

	/// 重新生成
	@override String get ai_regenerate => 'Regenerate';

	/// 生成摘要中
	@override String get ai_generatingSummary => 'Generating summary...';

	/// 关键词标签
	@override String get ai_keywordsLabel => 'Keywords: ';

	/// AI未配置
	@override String get ai_noAiConfig => 'AI service not configured, cannot generate summary';

	/// 前往设置
	@override String get ai_goToSettings => 'Go to Settings';

	/// 生成中
	@override String get ai_generating => 'Generating...';

	/// 点击生成
	@override String get ai_clickToGenerate => 'Click to generate AI summary';

	/// 进入编辑模式并生成摘要
	@override String get ai_switchToEditAndGenerate => 'Switch to edit mode & generate summary';

	/// 取消收藏
	@override String get card_unfavoriteTooltip => 'Unfavorite';

	/// 收藏
	@override String get card_favoriteTooltip => 'Favorite';

	/// 删除
	@override String get card_deleteTooltip => 'Delete';

	/// 未命名
	@override String get card_untitledNote => 'Untitled Note';

	/// 刚刚
	@override String get card_justNow => 'Just now';

	/// 分钟前
	@override String card_minutesAgo({required Object minutes}) => '${minutes} min ago';

	/// 小时前
	@override String card_hoursAgo({required Object hours}) => '${hours} hr ago';

	/// 昨天
	@override String get card_yesterday => 'Yesterday';

	/// 天前
	@override String card_daysAgo({required Object days}) => '${days} days ago';

	/// 标签区域
	@override String get tag_sectionTitle => 'Tags';

	/// 可选标签
	@override String get tag_availableTagsTitle => 'Available Tags';

	/// 无标签
	@override String get tag_noTagsEmpty => 'No tags yet, tap below to create';

	/// 创建标签
	@override String get tag_createNew => 'Create New Tag';

	/// 添加标签
	@override String get tag_addTag => 'Add Tag';

	/// 标签名提示
	@override String get tag_nameHint => 'Tag name';

	/// 确定
	@override String get tag_confirmTooltip => 'Confirm';

	/// 跳过
	@override String get onboarding_skip => 'Skip';

	/// 上一页
	@override String get onboarding_previous => 'Previous';

	/// 下一步
	@override String get onboarding_next => 'Next';

	/// 欢迎标题
	@override String get onboarding_welcomeTitle => 'Welcome to OpenNote';

	/// 欢迎副标题
	@override String get onboarding_welcomeSubtitle => 'Smart note assistant for efficient recording';

	/// 开始配置
	@override String get onboarding_startConfig => 'Start Configuring';

	/// 稍后配置
	@override String get onboarding_configLater => 'Configure Later';

	/// 图片加载失败
	@override String get onboarding_imageLoadError => 'Image failed to load';

	/// 选择服务商
	@override String get onboarding_selectProviderTitle => 'Choose AI Provider';

	/// 选择副标题
	@override String get onboarding_selectProviderSubtitle => 'Select the AI provider you want to use, you can add more later in settings';

	/// 未选择厂商
	@override String get onboarding_noProviderSelected => 'Please select an AI provider first';

	/// 返回选择
	@override String get onboarding_returnToSelectProvider => 'Go back and choose your preferred AI provider';

	/// 自定义配置
	@override String get onboarding_configCustomTitle => 'Configure Custom AI Service';

	/// 配置提供商
	@override String onboarding_configProviderTitle({required Object providerName}) => 'Configure ${providerName}';

	/// 自定义副标题
	@override String get onboarding_customConfigSubtitle => 'Enter vendor info, API address, model list, and API key';

	/// 提供商副标题
	@override String get onboarding_providerConfigSubtitle => 'Enter API key to complete configuration';

	/// 厂商标签
	@override String get onboarding_vendorLabel => 'Vendor';

	/// API地址标签
	@override String get onboarding_apiUrlLabel => 'API Address';

	/// 预设模型标签
	@override String get onboarding_presetModelsLabel => 'Preset Models';

	/// API密钥标签
	@override String get onboarding_apiKeyLabel => 'API Key';

	/// 已验证提示
	@override String get onboarding_apiKeyVerifiedHint => 'API key verified';

	/// API密钥提示
	@override String get onboarding_apiKeyHint => 'Enter API key';

	/// 获取密钥
	@override String get onboarding_getApiKey => 'Get API Key';

	/// 测试中
	@override String get onboarding_testingConnection => 'Testing connection...';

	/// 测试连接
	@override String get onboarding_testConnection => 'Test Connection';

	/// 完成配置
	@override String get onboarding_completeConfig => 'Complete Config';

	/// 厂商名称
	@override String get onboarding_vendorNameLabel => 'Vendor Name';

	/// 厂商名称提示
	@override String get onboarding_vendorNameHint => 'e.g.: My AI Service';

	/// API地址提示
	@override String get onboarding_apiUrlInputHint => 'e.g.: https://api.example.com/v1';

	/// 模型列表
	@override String get onboarding_modelListLabel => 'Model List';

	/// 模型输入提示
	@override String get onboarding_modelInputHint => 'Enter model name';

	/// 添加模型
	@override String get onboarding_addModel => 'Add';

	/// 默认模型
	@override String get onboarding_defaultModelLabel => 'Default Model';

	/// 选择默认
	@override String get onboarding_selectDefaultModel => 'Select default model';

	/// 选择厂商错误
	@override String get onboarding_errorSelectVendorFirst => 'Please select a vendor first';

	/// 输入密钥错误
	@override String get onboarding_errorEnterApiKey => 'Please enter API key';

	/// 输入厂商错误
	@override String get onboarding_errorEnterVendorName => 'Please enter vendor name';

	/// 输入地址错误
	@override String get onboarding_errorEnterApiUrl => 'Please enter API address';

	/// 添加模型错误
	@override String get onboarding_errorAddModel => 'Please add at least one model';

	/// 连接成功
	@override String get onboarding_connectionSuccess => 'Connection successful';

	/// 连接失败
	@override String get onboarding_connectionFailed => 'Connection failed, please check API key and network';

	/// 测试异常
	@override String onboarding_testException({required Object error}) => 'Test exception: ${error}';

	/// 保存失败
	@override String onboarding_saveConfigFailed({required Object error}) => 'Failed to save config: ${error}';

	/// 配置成功
	@override String get onboarding_configSuccess => 'Configured successfully!';

	/// 配置成功副标题
	@override String get onboarding_configSuccessSubtitle => 'You can now start using AI features';

	/// 配置未完成
	@override String get onboarding_configIncomplete => 'Configuration Incomplete';

	/// 未完成副标题
	@override String get onboarding_configIncompleteSubtitle => 'You haven\'t completed the AI service configuration yet. Please return and complete it before using.';

	/// 提示
	@override String get onboarding_infoTip => 'Tip';

	/// 滑动警告
	@override String get onboarding_swipedToCompleteWarning => 'You swiped to the completion page, but the AI service configuration has not been saved. Please return to the config page to complete API key entry and connection testing.';

	/// 下一步标题
	@override String get onboarding_nextStepTitle => 'Next Steps';

	/// 下一步1
	@override String get onboarding_nextStep1 => 'Create a new note and try AI smart summaries';

	/// 下一步2
	@override String get onboarding_nextStep2 => 'Use keyword extraction to quickly organize notes';

	/// 下一步3
	@override String get onboarding_nextStep3 => 'Let AI auto-categorize your notes';

	/// 开始使用
	@override String get onboarding_startUsing => 'Start Using';

	/// 返回配置
	@override String get onboarding_returnToConfig => 'Return to Config';

	/// 加粗
	@override String get toolbar_bold => 'Bold';

	/// 斜体
	@override String get toolbar_italic => 'Italic';

	/// 删除线
	@override String get toolbar_strikethrough => 'Strikethrough';

	/// H1
	@override String get toolbar_heading1 => 'H1';

	/// H2
	@override String get toolbar_heading2 => 'H2';

	/// H3
	@override String get toolbar_heading3 => 'H3';

	/// 代码
	@override String get toolbar_code => 'Code';

	/// 引用
	@override String get toolbar_quote => 'Quote';

	/// 列表
	@override String get toolbar_list => 'List';

	/// 编号
	@override String get toolbar_numberedList => 'Numbered List';

	/// 待办
	@override String get toolbar_todo => 'Todo';

	/// 链接
	@override String get toolbar_link => 'Link';

	/// 图片
	@override String get toolbar_image => 'Image';

	/// 分割线
	@override String get toolbar_divider => 'Divider';

	/// 表格
	@override String get toolbar_table => 'Table';

	/// 表格模板头
	@override String get toolbar_tableHeader => 'Col 1 | Col 2 | Col 3';

	/// 表格内容
	@override String get toolbar_tableContent => 'Content';

	/// 暂不可用
	@override String get format_unavailable => 'Unavailable';

	/// 无笔记标题
	@override String get empty_noNotesTitle => 'No notes yet';

	/// 无笔记描述
	@override String get empty_noNotesDesc => 'Tap + in the top right to create your first note';

	/// 创建笔记
	@override String get empty_createNote => 'Create Note';

	/// 无搜索结果
	@override String get empty_noSearchResultsTitle => 'No matching notes found';

	/// 无搜索描述
	@override String get empty_noSearchResultsDesc => 'Try different keywords';

	/// 清除搜索
	@override String get empty_clearSearch => 'Clear Search';

	/// 无标签标题
	@override String get empty_noTagsTitle => 'No tags yet';

	/// 无标签描述
	@override String get empty_noTagsDesc => 'You can add tags while editing notes';

	/// 无收藏标题
	@override String get empty_noFavoritesTitle => 'No favorite notes';

	/// 无收藏描述
	@override String get empty_noFavoritesDesc => 'Tap the star on a note card to favorite it';

	/// 浏览笔记
	@override String get empty_browseNotes => 'Browse Notes';

	/// 重试
	@override String get empty_retry => 'Retry';

	/// 网络错误
	@override String get empty_networkErrorTitle => 'Network Connection Failed';

	/// 网络错误描述
	@override String get empty_networkErrorDesc => 'Please check your network and try again';

	/// AI服务错误
	@override String get empty_aiServiceErrorTitle => 'AI Service Temporarily Unavailable';

	/// AI错误描述
	@override String get empty_aiServiceErrorDesc => 'Please try again later or check AI config';

	/// 菜单
	@override String get navigation_menu => 'Menu';

	/// 搜索框占位
	@override String get navigation_search => 'Search...';

	/// 发现新版本
	@override String get update_newVersionFound => 'New Version Found';

	/// 跳过版本
	@override String get update_skipThisVersion => 'Skip This Version';

	/// 稍后提醒
	@override String get update_remindLater => 'Remind Later';

	/// 更新
	@override String get update_update => 'Update';

	/// 版本号
	@override String get preferences_versionNumber => 'Version';

	/// 平台
	@override String get preferences_platform => 'Platform';

	/// 构建号
	@override String get preferences_buildNumber => 'Build';

	/// 自动检查更新
	@override String get preferences_autoCheckUpdate => 'Auto Check for Updates';

	/// 检查中
	@override String get preferences_checking => 'Checking...';

	/// 最新版本
	@override String get preferences_latestVersion => 'Up to Date';

	/// 检查失败
	@override String get preferences_checkFailedRetry => 'Check failed, retry';

	/// 检查更新
	@override String get preferences_checkForUpdate => 'Check for Updates';

	/// 发现新版本
	@override String preferences_newVersionFound({required Object version}) => 'New version v${version} found';

	/// 下载中
	@override String get preferences_downloadingUpdate => 'Downloading update';

	/// 停止下载更新
	@override String get preferences_cancelDownload => 'Stop Download';

	/// 下载已取消
	@override String get preferences_downloadCancelled => 'Download cancelled';

	/// 已下载大小
	@override String preferences_downloadedSize({required String size}) => 'Downloaded ${size}';

	/// 下载完成
	@override String get preferences_downloadComplete => 'Download complete';

	/// 安装提示
	@override String get preferences_installPrompt => 'Installer has been opened, please follow prompts to update';

	/// 跳过版本
	@override String get preferences_skippedVersions => 'Skipped Versions';

	/// 语言
	@override String get preferences_language => 'Language';

	/// 简体中文
	@override String get preferences_languageZhCN => '简体中文';

	/// 繁体中文
	@override String get preferences_languageZhTW => '繁體中文';

	/// 英文
	@override String get preferences_languageEn => 'English';

	/// 俄语
	@override String get preferences_languageRu => 'Русский';

	/// 重启提示
	@override String get preferences_languageRestartHint => 'Restart the app for language changes to take effect';

	/// 准备服务
	@override String get kb_preparingService => 'Preparing service...';

	/// 启动服务
	@override String get kb_startingService => 'Starting service...';

	/// 停止服务
	@override String get kb_stoppingService => 'Stopping service...';

	/// 初始化向量
	@override String get kb_initializingVectorService => 'Initializing vector service, please wait...';

	/// 启动失败
	@override String get kb_serviceStartupFailed => 'Service startup failed';

	/// 端口被占用提示
	@override String kb_portOccupied({required int port}) => 'Port ${port} is already in use by another application';

	/// 端口被占用详情
	@override String kb_portOccupiedDetail({required String pid}) => 'Close the application using this port and try again. Process PID: ${pid}';

	/// 已就绪
	@override String get kb_knowledgeBaseReady => 'Knowledge base is ready';

	/// 未启用
	@override String get kb_knowledgeBaseNotEnabled => 'Knowledge base not enabled';

	/// 运行中
	@override String get kb_serviceRunning => 'Service running';

	/// 模型已加载
	@override String get kb_localModelLoaded => 'Local model loaded';

	/// 向量化说明
	@override String get kb_enableKnowledgeBaseVectorization => 'Enable to use local Embedding model for note vectorization indexing';

	/// 启用开关
	@override String get kb_enableToggle => 'Enable/Disable';

	/// 启用知识库
	@override String get kb_enableKnowledgeBase => 'Enable Knowledge Base';

	/// 自动索引说明
	@override String get kb_autoVectorIndexing => 'Notes will be automatically vectorized when enabled';

	/// Embedding模型
	@override String get kb_embeddingModel => 'Embedding Model';

	/// 模型
	@override String get kb_model => 'Model';

	/// 向量维度
	@override String get kb_vectorDimensions => 'Vector Dimensions';

	/// 下载源
	@override String get kb_downloadSource => 'Download Source';

	/// 魔搭社区
	@override String get kb_modelscope => 'ModelScope (modelscope.cn)';

	/// 模型版本
	@override String get kb_modelVersion => 'Model Version:';

	/// 精度最高
	@override String get kb_highestPrecision => '~617MB · Highest precision';

	/// 平衡推荐
	@override String get kb_balancedRecommended => '~309MB · Balanced (recommended)';

	/// 轻量模式
	@override String get kb_lightweightMode => '~197MB · Lightweight';

	/// 状态
	@override String get kb_status => 'Status';

	/// 已下载
	@override String get kb_downloaded => 'Downloaded';

	/// 未下载
	@override String get kb_notDownloaded => 'Not downloaded';

	/// 路径
	@override String get kb_path => 'Path';

	/// 错误
	@override String kb_error({required Object error}) => 'Error: ${error}';

	/// 校验中
	@override String get kb_verifyingFile => 'Verifying file integrity...';

	/// 下载中
	@override String kb_downloading({required Object progress}) => 'Downloading... ${progress}%';

	/// 下载模型
	@override String get kb_downloadModel => 'Download Model';

	/// 选择路径
	@override String get kb_selectLocalPath => 'Select Local Path';

	/// 索引设置
	@override String get kb_indexSettings => 'Index Settings';

	/// 分块大小
	@override String get kb_chunkSize => 'Chunk Size';

	/// 分块重叠
	@override String get kb_chunkOverlap => 'Chunk Overlap';

	/// 缓存大小
	@override String get kb_cacheSize => 'Cache Size';

	/// 索引统计
	@override String get kb_indexStats => 'Index Stats';

	/// 准备Python
	@override String get kb_preparingPythonService => 'Preparing Vector service...';

	/// 启动Python
	@override String get kb_startingPythonService => 'Starting Vector service...';

	/// 未启用提示
	@override String get kb_knowledgeBaseNotEnabledPrompt => 'Knowledge base not enabled, please enable it above first';

	/// 已索引
	@override String get kb_indexedNotes => 'Indexed Notes';

	/// 总向量
	@override String get kb_totalVectors => 'Total Vectors';

	/// 最后更新
	@override String get kb_lastUpdate => 'Last Update';

	/// 未索引
	@override String get kb_notIndexed => 'Not indexed';

	/// 索引进度
	@override String kb_indexingProgress({required Object progress, required Object total}) => 'Indexing ${progress}/${total} notes...';

	/// 索引失败
	@override String kb_indexFailedAll({required Object count}) => 'Index failed: All ${count} notes failed';

	/// 部分失败
	@override String kb_indexCompleteWithFailures({required Object success, required Object failed}) => 'Index complete: ${success} success, ${failed} failed';

	/// 索引完成
	@override String kb_indexComplete({required Object count}) => 'Index complete: ${count} successful';

	/// 收起错误
	@override String get kb_collapseErrorDetails => 'Collapse error details';

	/// 查看错误
	@override String kb_viewErrorDetails({required Object count}) => 'View error details (${count})';

	/// 未索引提示
	@override String kb_unindexedNotesPrompt({required Object count}) => '${count} note(s) not indexed, click "Rebuild Index" to update';

	/// 重建索引
	@override String get kb_rebuildIndex => 'Rebuild Index';

	/// 清空索引
	@override String get kb_clearIndex => 'Clear Index';

	/// 清空索引确认
	@override String get kb_confirmClearIndex => 'Confirm Clear Index';

	/// 清空内容
	@override String get kb_confirmClearIndexContent => 'All notes will need to be re-indexed. Continue?';

	/// 重建索引确认
	@override String get kb_confirmRebuildIndex => 'Confirm Rebuild Index';

	/// 重建内容
	@override String kb_confirmRebuildIndexContent({required Object count}) => '${count} note(s) will be vectorized.\nThis may take a few minutes. Continue?';

	/// 开始重建
	@override String get kb_startRebuild => 'Start Rebuild';

	/// 重建失败
	@override String get kb_rebuildFailed => 'Rebuild index failed';

	/// Python启动失败
	@override String get kb_rebuildFailedPythonService => 'Rebuild failed: Vector service failed to start, check model config';

	/// 未就绪
	@override String get kb_rebuildFailedNotReady => 'Rebuild failed: Knowledge base not ready, download model and enable it first';

	/// 健康检查失败
	@override String get kb_rebuildFailedHealthCheck => 'Rebuild failed: Vector service not running properly, try again later';

	/// 记忆能力
	@override String get assistant_memoryCapability => 'Memory Capability';

	/// AI模型选择
	@override String get assistant_aiModelSelection => 'AI Model Selection';

	/// 记忆注入
	@override String get assistant_memoryInjectionControl => 'Memory Injection Control';

	/// 清空记忆
	@override String get assistant_clearMemory => 'Clear Memory';

	/// 角色控制
	@override String get assistant_roleControl => 'Role Control';

	/// 启用长期记忆
	@override String get assistant_enableLongTermMemory => 'Enable Long-term Memory';

	/// 禁用提示
	@override String get assistant_memoryDisabledHint => 'Disabling will stop recording and using all memories';

	/// 配置模型提示
	@override String get assistant_configureAIModelFirst => 'Please configure an available AI model first';

	/// 配置模型提示2
	@override String get assistant_configureAIModelsFirst => 'Please configure available AI models in "AI Service" first';

	/// 无模型
	@override String get assistant_noAvailableModels => 'Status: No available models';

	/// 可用模型
	@override String assistant_availableModelsCount({required Object count}) => 'Status: ${count} available models';

	/// 档案记忆
	@override String get assistant_profileMemory => 'Profile Memory';

	/// 档案副标题
	@override String get assistant_profileMemorySubtitle => 'Name, occupation, language preferences, etc.';

	/// 事实偏好
	@override String get assistant_factPreferenceMemory => 'Fact Preference Memory';

	/// 事实副标题
	@override String get assistant_factPreferenceSubtitle => 'Usage habits, specific preferences, etc.';

	/// 经验总结
	@override String get assistant_experienceSummaryMemory => 'Experience Summary Memory';

	/// 经验副标题
	@override String get assistant_experienceSummarySubtitle => 'Workflows, strategies, etc.';

	/// 清空档案
	@override String assistant_clearProfileMemory({required Object count}) => 'Clear Profile Memory (${count})';

	/// 清空事实
	@override String assistant_clearFactMemory({required Object count}) => 'Clear Fact Memory (${count})';

	/// 清空经验
	@override String assistant_clearExperienceMemory({required Object count}) => 'Clear Experience Memory (${count})';

	/// 清空全部
	@override String assistant_clearAllMemory({required Object count}) => 'Clear All Memory (${count})';

	/// 角色自定义开发中
	@override String get assistant_roleCustomizationInDevelopment => 'Role tone and personality customization coming soon';

	/// 清空记忆确认
	@override String assistant_confirmClearMemoryContent({required Object typeName}) => 'Are you sure you want to clear all ${typeName}? This cannot be undone.';

	/// 已清空
	@override String assistant_clearedMemory({required Object typeName}) => '${typeName} cleared';

	/// 清空全部确认
	@override String get assistant_confirmClearAllMemoryContent => 'Are you sure you want to clear all types of memory? This cannot be undone.';

	/// 已清空全部
	@override String get assistant_clearedAllMemory => 'All memory cleared';

	/// 清空全部
	@override String get assistant_clearAll => 'Clear All';

	/// 检查环境
	@override String get cli_checkingEnv => 'Checking environment...';

	/// 环境不满足
	@override String get cli_envNotMet => 'Environment requirements not met';

	/// 安装CLI
	@override String get cli_installingCLI => 'Installing CLI...';

	/// 安装成功
	@override String get cli_installSuccess => 'Installation Successful';

	/// 安装失败
	@override String get cli_installFailed => 'Installation Failed';

	/// pip安装
	@override String get cli_executingPipInstall => 'Executing: pip install open-note-cli --upgrade';

	/// 安装中
	@override String get cli_installingPleaseWait => 'Installing, please wait...';

	/// 安装成功消息
	@override String get cli_cliInstalledSuccessfully => 'CLI tool installed successfully!';

	/// 安装完成
	@override String get cli_installComplete => 'Installation Complete';

	/// 使用方法
	@override String get cli_usageMethod => 'Usage: opennote --help';

	/// 降级安装
	@override String get cli_fallbackInstallMethod => 'Fallback installation method:';

	/// 重新检查
	@override String get cli_recheck => 'Recheck';

	/// 启动失败
	@override String get splash_startFailed => 'Startup Failed';

	/// Follow system option
	@override String get preferences_followSystem => 'Follow System';

	/// New note button tooltip
	@override String get home_newNote => 'New Note';

	/// settings_modelCount
	@override String get settings_modelCount => 'models';

	/// common_notConfigured
	@override String get common_notConfigured => 'Not configured';

	/// settings_defaultModel
	@override String get settings_defaultModel => 'Default Model';

	/// settings_autoFollowSystemTheme
	@override String get settings_autoFollowSystemTheme => 'Auto follow system theme';

	/// settings_alwaysUseLightTheme
	@override String get settings_alwaysUseLightTheme => 'Always use light theme';

	/// settings_alwaysUseDarkTheme
	@override String get settings_alwaysUseDarkTheme => 'Always use dark theme';

	/// kb_serviceJustStarted
	@override String get kb_serviceJustStarted => 'Service just started, preparing initialization...';

	/// kb_chromaDbInitializing
	@override String get kb_chromaDbInitializing => 'Initializing ChromaDB database...';

	/// kb_loadingEmbeddingModel
	@override String get kb_loadingEmbeddingModel => 'Loading Embedding AI model...';

	/// kb_chromaDbInitFailed
	@override String get kb_chromaDbInitFailed => 'ChromaDB init failed';

	/// kb_modelLoadFailed
	@override String get kb_modelLoadFailed => 'Embedding model load failed';

	/// kb_serviceInitError
	@override String get kb_serviceInitError => 'Service init error';

	/// kb_vectorServiceNotRunning
	@override String get kb_vectorServiceNotRunning => 'Vector service not running';

	/// kb_serviceNotStarted
	@override String get kb_serviceNotStarted => 'Service not started';

	/// kb_cannotFetchStatus
	@override String get kb_cannotFetchStatus => 'Cannot fetch service status';

	/// kb_serviceConnectionFailed
	@override String get kb_serviceConnectionFailed => 'Service connection failed';

	/// kb_vectorServicePrepareFailed
	@override String get kb_vectorServicePrepareFailed => 'Vector service prepare failed';

	/// kb_vectorServicePrepareError
	@override String get kb_vectorServicePrepareError => 'Vector service prepare error';

	/// kb_vectorServiceStartFailed
	@override String get kb_vectorServiceStartFailed => 'Vector service start failed, check model config';

	/// kb_vectorServiceError
	@override String get kb_vectorServiceError => 'Vector service error';

	/// kb_serviceAlreadyRunning
	@override String get kb_serviceAlreadyRunning => 'Service already running';

	/// kb_serviceStarted
	@override String get kb_serviceStarted => 'Service started';

	/// kb_serviceStartFailedPython
	@override String get kb_serviceStartFailedPython => 'Start failed, check Python environment and dependencies';

	/// kb_directoryNotExist
	@override String get kb_directoryNotExist => 'Directory does not exist';

	/// kb_missingModelFile
	@override String get kb_missingModelFile => 'Missing model file: model.onnx';

	/// kb_missingTokenizer
	@override String get kb_missingTokenizer => 'Missing tokenizer.json';

	/// kb_modelFileSizeAbnormal
	@override String get kb_modelFileSizeAbnormal => 'Model file size abnormal';

	/// kb_knowledgeBaseNotReady
	@override String get kb_knowledgeBaseNotReady => 'Knowledge base not ready, download model and enable it first';

	/// kb_vectorServiceStartFailedIndex
	@override String get kb_vectorServiceStartFailedIndex => 'Vector service start failed, cannot index';

	/// kb_healthCheckFailed
	@override String get kb_healthCheckFailed => 'Health check failed, service may not be running';

	/// cli_pythonNotInstalled
	@override String get cli_pythonNotInstalled => 'Python not found, please install Python 3.10+ first';

	/// cli_pipNotInstalled
	@override String get cli_pipNotInstalled => 'pip not found, please install pip first';

	/// cli_pythonVersionTooLow
	@override String get cli_pythonVersionTooLow => 'Python version too low, requires Python 3.10+';

	/// cli_pythonVersionMismatch
	@override String get cli_pythonVersionMismatch => 'Python version incompatible, open-note-cli requires Python 3.10+, please upgrade Python and retry';

	/// cli_installProcessError
	@override String get cli_installProcessError => 'Installation error: ';

	/// cli_envInstructionsMac
	@override String get cli_envInstructionsMac => 'Please install Python 3.10+ and pip:\n\nUsing Homebrew:\n  brew install python3\n\nOr download from https://python.org';

	/// cli_envInstructionsWindows
	@override String get cli_envInstructionsWindows => 'Please install Python 3.10+:\n\nDownload from https://python.org\nCheck "Add Python to PATH" during installation';

	/// cli_envInstructionsLinux
	@override String get cli_envInstructionsLinux => 'Please install Python 3.10+ and pip:\n\nUbuntu/Debian:\n  sudo apt install python3 python3-pip\n\nFedora:\n  sudo dnf install python3 python3-pip';

	/// cli_envCheckFailed
	@override String get cli_envCheckFailed => 'Environment check failed';

	/// cli_envStatus
	@override String get cli_envStatus => 'Environment Status';

	/// cli_installCLI
	@override String get cli_installCLI => 'Install CLI';

	/// cli_usage
	@override String get cli_usage => 'Usage';

	/// cli_cliStatus
	@override String get cli_cliStatus => 'CLI Status';

	/// cli_installed
	@override String get cli_installed => 'Installed';

	/// cli_notInstalled
	@override String get cli_notInstalled => 'Not installed';

	/// cli_notDetected
	@override String get cli_notDetected => 'Not detected';

	/// cli_installDescription
	@override String get cli_installDescription => 'Click the button to automatically install OpenNote CLI tool to your system';

	/// cli_helpText
	@override String get cli_helpText => 'opennote --help              # View help\nopennote note list           # List notes\nopennote note search <query> # Search notes\nopennote mcp start           # Start MCP service';

	/// ai_copyMessage
	@override String get ai_copyMessage => 'Copy';

	/// ai_messageCopied
	@override String get ai_messageCopied => 'Copied';

	/// ai_undoMessage
	@override String get ai_undoMessage => 'Undo';

	/// ai_newSession
	@override String get ai_newSession => 'New Session';

	/// kb_switchModelWarning
	@override String get kb_switchModelWarning => 'Switching model version will clear the vector index. The index will be rebuilt after switching.';
}
