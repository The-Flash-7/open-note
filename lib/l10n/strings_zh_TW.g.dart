// Copyright (c) 2026 litongshuai
// SPDX-License-Identifier: MIT OR Apache-2.0

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
class TranslationsZhTw extends Translations with BaseTranslations<AppLocale, Translations> {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	TranslationsZhTw({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = meta ?? TranslationMetadata(
		    locale: AppLocale.zhTw,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ),
		  super(cardinalResolver: cardinalResolver, ordinalResolver: ordinalResolver);

	/// Metadata for the translations of <zh-TW>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	late final TranslationsZhTw _root = this; // ignore: unused_field

	@override 
	TranslationsZhTw $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => TranslationsZhTw(meta: meta ?? this.$meta);

	// Translations

	/// 取消按钮
	@override String get common_cancel => '取消';

	/// 保存按钮
	@override String get common_save => '儲存';

	/// 删除按钮
	@override String get common_delete => '刪除';

	/// 确定按钮
	@override String get common_ok => '確定';

	/// 关闭按钮
	@override String get common_close => '關閉';

	/// 重试按钮
	@override String get common_retry => '重試';

	/// 编辑按钮
	@override String get common_edit => '編輯';

	/// 创建按钮
	@override String get common_create => '建立';

	/// 添加按钮
	@override String get common_add => '新增';

	/// 清空/清除按钮
	@override String get common_clear => '清除';

	/// 粘贴按钮
	@override String get common_paste => '貼上';

	/// 暂停按钮
	@override String get common_pause => '暫停';

	/// 继续/恢复按钮
	@override String get common_resume => '繼續';

	/// 跳过按钮
	@override String get common_skip => '跳過';

	/// 下一步按钮
	@override String get common_next => '下一步';

	/// 上一页按钮
	@override String get common_previous => '上一頁';

	/// 删除确认标题
	@override String get common_confirmDelete => '確認刪除';

	/// 清空确认标题
	@override String get common_confirmClear => '確認清除';

	/// 即将上线标签
	@override String get common_comingSoon => '即將推出';

	/// 跟随系统选项
	@override String get common_followSystem => '跟隨系統';

	/// 亮色模式
	@override String get common_lightMode => '淺色模式';

	/// 暗色模式
	@override String get common_darkMode => '深色模式';

	/// 收起按钮
	@override String get common_collapse => '收起';

	/// 展开按钮
	@override String get common_expand => '展開';

	/// 发送按钮
	@override String get common_send => '傳送';

	/// 停止按钮
	@override String get common_stop => '停止';

	/// 是
	@override String get common_yes => '是';

	/// 否
	@override String get common_no => '否';

	/// 完成按钮
	@override String get common_done => '完成';

	/// 更多选项
	@override String get common_more => '更多';

	/// 未知状态
	@override String get common_unknown => '未知';

	/// 导航-首页
	@override String get home_home => '首頁';

	/// 导航-目录
	@override String get home_categories => '目錄';

	/// 导航-AI
	@override String get home_ai => 'AI';

	/// 导航-收藏
	@override String get home_favorites => '收藏';

	/// 导航-设置
	@override String get home_settings => '設定';

	/// 平板导航-笔记
	@override String get home_note => '筆記';

	/// 拖拽导入覆盖层
	@override String get home_dragDropImport => '拖放檔案以匯入筆記';

	/// 导入成功
	@override String home_successImportCount({required Object count}) => '成功匯入 ${count} 個檔案';

	/// 导入失败
	@override String home_failImportCount({required Object count}) => '${count} 個檔案匯入失敗';

	/// 剪贴板URL提示
	@override String get home_clipboardUrlDetected => '偵測到剪貼簿URL，是否建立筆記？';

	/// 忽略按钮
	@override String get home_dismiss => '忽略';

	/// 摘要暂停状态
	@override String home_summaryGenerationPaused({required Object processedCount, required Object totalPending}) => '摘要產生已暫停 (${processedCount}/${totalPending})';

	/// 多选计数
	@override String home_selectedCount({required Object count}) => '已選取 ${count} 個';

	/// 笔记列表标题
	@override String get home_allNotes => '所有筆記';

	/// 取消多选
	@override String get home_cancelMultiSelect => '取消多選';

	/// 多选切换
	@override String get home_multiSelect => '多選';

	/// 回收站图标提示
	@override String get home_trash => '回收桶';

	/// 回收站带数量
	@override String home_trashWithCount({required Object count}) => '回收桶 (${count})';

	/// 新建空白笔记
	@override String get home_newBlankNote => '建立空白筆記';

	/// 从URL创建
	@override String get home_createFromUrl => '從URL建立';

	/// 从文件导入
	@override String get home_importFromFile => '從檔案匯入';

	/// 删除后提示
	@override String get home_noteMovedToTrash => '筆記已移至回收桶';

	/// 空内容提示
	@override String get home_selectNoteToStart => '選擇一則筆記開始檢視';

	/// 删除确认内容
	@override String home_confirmDeleteNoteContent({required Object title}) => '確定刪除筆記 "${title}" 嗎？';

	/// 批量删除标题
	@override String get home_confirmBatchDelete => '確認批次刪除';

	/// 批量删除内容
	@override String home_confirmBatchDeleteContent({required Object count}) => '確定刪除已選取的 ${count} 則筆記嗎？';

	/// 批量操作栏
	@override String home_selectedNotesCount({required Object count}) => '已選取 ${count} 則筆記';

	/// 批量删除后提示
	@override String home_deletedCountNotes({required Object count}) => '已刪除 ${count} 則筆記';

	/// 回收站对话框标题
	@override String get home_trashTitle => '回收桶';

	/// 空回收站提示
	@override String get home_trashEmpty => '回收桶為空';

	/// 回收站副标题
	@override String home_daysAgoDeleted({required Object days}) => '${days}天前刪除';

	/// 恢复按钮
	@override String get home_restore => '還原';

	/// 恢复后提示
	@override String get home_noteRestored => '筆記已還原';

	/// 永久删除
	@override String get home_permanentlyDelete => '永久刪除';

	/// 永久删除提示
	@override String get home_notePermanentlyDeleted => '筆記已永久刪除';

	/// 清空回收站按钮
	@override String get home_emptyTrash => '清空回收桶';

	/// 清空回收站标题
	@override String get home_emptyTrashTitle => '清空回收桶';

	/// 清空回收站内容
	@override String home_emptyTrashContent({required Object count}) => '確定清空回收桶中的 ${count} 則筆記嗎？此操作無法復原。';

	/// 清空后提示
	@override String get home_trashEmptied => '回收桶已清空';

	/// 切换主题标题
	@override String get home_switchTheme => '切換佈景主題';

	/// 切换亮色
	@override String get home_switchToLight => '切換至淺色模式';

	/// 切换暗色
	@override String get home_switchToDark => '切換至深色模式';

	/// 取消收藏菜单
	@override String get home_unfavorite => '取消收藏';

	/// 收藏菜单
	@override String get home_favorite => '收藏';

	/// 分享菜单
	@override String get home_share => '分享';

	/// 分享功能提示
	@override String get home_shareComingSoon => '分享功能即將推出';

	/// 默认标题
	@override String get editor_untitledNote => '未命名筆記';

	/// 保存中状态
	@override String get editor_saving => '儲存中...';

	/// 自动保存成功
	@override String get editor_autoSaved => '已自動儲存';

	/// 自动保存失败
	@override String get editor_autoSaveFailed => '自動儲存失敗';

	/// 分类选择器
	@override String get editor_selectCategory => '選擇分類';

	/// 无分类选项
	@override String get editor_noCategory => '無分類';

	/// 清除分类
	@override String get editor_clearCategory => '清除分類';

	/// 内容不能为空
	@override String get editor_noteContentCannotBeEmpty => '筆記內容不能為空';

	/// 保存成功
	@override String get editor_saveSuccess => '儲存成功';

	/// 保存失败
	@override String editor_saveFailed({required Object error}) => '儲存失敗: ${error}';

	/// 填写提示
	@override String get editor_fillTitleAndContentFirst => '請先填寫標題和內容';

	/// 配置超时
	@override String get editor_configTimeoutRetry => '載入設定逾時，請稍後再試';

	/// AI未配置
	@override String get editor_configureAIFirst => '請先設定AI服務';

	/// 建议生成失败
	@override String editor_generateSuggestionsFailed({required Object error}) => '產生建議失敗: ${error}';

	/// 智能建议标题
	@override String get editor_smartSuggestions => '智慧建議';

	/// 分类建议标签
	@override String get editor_categorySuggestion => '分類建議:';

	/// 标签建议标签
	@override String get editor_tagSuggestion => '標籤建議:';

	/// 无建议
	@override String get editor_noSuggestions => '暫無建議';

	/// 应用建议按钮
	@override String get editor_applySuggestions => '套用建議';

	/// 新笔记标题
	@override String get editor_newNote => '建立筆記';

	/// 编辑笔记标题
	@override String get editor_editNote => '編輯筆記';

	/// 预览模式
	@override String get editor_preview => '預覽';

	/// 智能建议提示
	@override String get editor_smartSuggestionsTooltip => '智慧建議';

	/// AI助手提示
	@override String get editor_aiAssistant => 'AI助理';

	/// 来源标签
	@override String get editor_source => '來源：';

	/// 标题文本框
	@override String get editor_title => '標題';

	/// Markdown占位符
	@override String get editor_startWritingMarkdown => '開始編寫 Markdown 筆記...';

	/// 纯文本占位符
	@override String get editor_startWritingPlainText => '開始編寫純文字筆記...';

	/// 富文本占位符
	@override String get editor_startWritingRichText => '開始編寫富文字筆記...';

	/// 设置导航-首选项
	@override String get settings_preferences => '偏好設定';

	/// 设置导航-AI服务
	@override String get settings_aiService => 'AI服務';

	/// 设置导航-外观
	@override String get settings_appearance => '外觀';

	/// 设置导航-知识库
	@override String get settings_knowledgeBase => '知識庫';

	/// 设置导航-智能助理
	@override String get settings_assistant => '智慧助理';

	/// 设置导航-CLI
	@override String get settings_cliTools => 'CLI工具';

	/// 设置对话框标题
	@override String get settings_title => '設定';

	/// 开发中占位
	@override String get settings_featureInDevelopment => '功能開發中...';

	/// 自定义配置标题
	@override String get settings_customConfig => '自訂設定';

	/// 快速添加标题
	@override String get settings_quickAddPresets => '快速新增預設';

	/// 快速添加描述
	@override String get settings_quickAddDescription => '點擊快速新增常見廠商設定';

	/// 无AI配置
	@override String get settings_noAIConfig => '暫無AI設定';

	/// 空状态提示
	@override String get settings_clickToAddPreset => '點擊下方按鈕或快速新增預設';

	/// 已配置列表
	@override String get settings_configured => '已設定';

	/// 配置数量
	@override String settings_configCount({required Object count}) => '${count}個';

	/// 当前徽章
	@override String get settings_current => '目前';

	/// 配置模型提示
	@override String get settings_setModelFirst => '請先設定模型';

	/// 添加提供商
	@override String settings_addProvider({required Object name}) => '新增 ${name}';

	/// API地址标签
	@override String get settings_apiAddress => 'API位址: ';

	/// 预设模型
	@override String settings_presetsModels({required Object models}) => '預設模型: ${models}';

	/// API密钥标签
	@override String get settings_apiKey => 'API金鑰';

	/// API密钥提示
	@override String get settings_enterApiKey => '輸入您的API金鑰';

	/// API密钥错误
	@override String get settings_enterApiKeyError => '請輸入API金鑰';

	/// 厂商名称
	@override String get settings_vendorName => '廠商名稱';

	/// 厂商名称提示
	@override String get settings_vendorNameHint => '如: 我的API、中轉站';

	/// Base URL标签
	@override String get settings_baseUrl => 'Base URL';

	/// Base URL提示
	@override String get settings_baseUrlHint => 'https://api.example.com/v1';

	/// 模型列表
	@override String get settings_modelList => '模型列表';

	/// 模型列表提示
	@override String get settings_modelListHint => '逗號分隔，如: model-1,model-2';

	/// 厂商名称错误
	@override String get settings_enterVendorName => '請輸入廠商名稱';

	/// 模型错误
	@override String get settings_enterAtLeastOneModel => '請輸入至少一個模型';

	/// 显示名称
	@override String get settings_displayName => '顯示名稱';

	/// 删除配置确认
	@override String settings_confirmDeleteConfig({required Object name}) => '確定刪除設定 "${name}"?';

	/// 连接成功
	@override String settings_connectionSuccess({required Object name}) => '已成功連線到${name}';

	/// 未知错误
	@override String get settings_unknownError => '未知錯誤';

	/// 测试异常
	@override String settings_testException({required Object error}) => '測試異常: ${error}';

	/// 测试连接
	@override String get settings_testConnection => '測試連線';

	/// 测试连接中
	@override String get settings_testingConnection => '正在測試連線...';

	/// 连接成功标签
	@override String get settings_connectionSuccessful => '連線成功';

	/// 连接失败标签
	@override String get settings_connectionFailed => '連線失敗';

	/// 搜索框
	@override String get search_placeholder => '搜尋筆記...';

	/// 分类筛选
	@override String get search_categoryFilter => '分類篩選';

	/// 所有分类
	@override String get search_allCategories => '所有分類';

	/// 输入提示
	@override String get search_enterToSearch => '輸入關鍵字開始搜尋';

	/// 无结果
	@override String get search_noResults => '未找到相關筆記';

	/// 无历史
	@override String get search_noHistory => '暫無搜尋歷史';

	/// 最近搜索
	@override String get search_recentSearches => '最近搜尋';

	/// 未命名回退
	@override String get search_untitledNote => '未命名筆記';

	/// 刚刚
	@override String get search_justNow => '剛剛';

	/// 分钟前
	@override String search_minutesAgo({required Object count}) => '${count}分鐘前';

	/// 小时前
	@override String search_hoursAgo({required Object count}) => '${count}小時前';

	/// 昨天
	@override String get search_yesterday => '昨天';

	/// 天前
	@override String search_daysAgo({required Object count}) => '${count}天前';

	/// Enter键
	@override String get search_enterHint => 'Enter';

	/// 打开
	@override String get search_open => '開啟';

	/// 上下键
	@override String get search_navigateHint => '↑↓';

	/// 导航
	@override String get search_navigate => '導航';

	/// Esc键
	@override String get search_escHint => 'Esc';

	/// 关闭
	@override String get search_closeHint => '關閉';

	/// 新建笔记
	@override String get dialog_newNote => '建立筆記';

	/// 空白笔记
	@override String get dialog_blankNote => '空白筆記';

	/// 空白笔记副标题
	@override String get dialog_createBlankNote => '建立一個新的空白筆記';

	/// 从文件导入
	@override String get dialog_importFromFile => '從檔案匯入';

	/// 从文件导入副标题
	@override String get dialog_importFromFileSubtitle => '從 TXT、程式碼、HTML 檔案建立筆記';

	/// 导入成功
	@override String get dialog_noteImportSuccess => '筆記匯入成功';

	/// 不支持格式
	@override String get dialog_importFailedUnsupported => '匯入失敗：不支援的檔案格式';

	/// 导入失败
	@override String dialog_importFailed({required Object error}) => '匯入失敗：${error}';

	/// 选择格式
	@override String get dialog_selectNoteFormat => '選擇筆記格式';

	/// Markdown格式
	@override String get dialog_markdown => 'Markdown';

	/// Markdown描述
	@override String get dialog_markdownDescription => '支援富文字格式、程式碼區塊、表格等';

	/// 纯文本
	@override String get dialog_plainText => '純文字';

	/// 纯文本描述
	@override String get dialog_plainTextDescription => '簡單的純文字格式，無特殊格式';

	/// 富文本
	@override String get dialog_richText => '富文字';

	/// 富文本描述
	@override String get dialog_richTextDescription => 'Quill 編輯器，支援粗體、斜體、列表等';

	/// 代码
	@override String get dialog_code => '程式碼';

	/// 代码描述
	@override String get dialog_codeDescription => '程式碼編輯器，支援語法突顯';

	/// URL创建
	@override String get dialog_createFromUrl => '從URL建立筆記';

	/// URL字段
	@override String get dialog_webUrl => '網頁URL';

	/// URL提示
	@override String get dialog_urlHint => 'example.com';

	/// URL错误
	@override String get dialog_enterUrl => '請輸入URL';

	/// URL格式错误
	@override String get dialog_invalidUrlFormat => 'URL格式不正確';

	/// 提取失败
	@override String get dialog_extractFailed => '內容擷取失敗';

	/// 提取中
	@override String get dialog_extractingContent => '正在擷取內容...';

	/// 提取成功
	@override String get dialog_extractSuccess => '擷取成功';

	/// AI初始化
	@override String get dialog_aiInitializing => 'AI正在初始化筆記...';

	/// 自动初始化
	@override String get dialog_noteAutoInitialized => '筆記已自動初始化';

	/// 摘要
	@override String get dialog_summary => '摘要';

	/// 关键词
	@override String get dialog_keywords => '關鍵字';

	/// 分类
	@override String get dialog_category => '分類';

	/// 标签
	@override String get dialog_tags => '標籤';

	/// 提取内容按钮
	@override String get dialog_extractContent => '擷取內容';

	/// 创建笔记按钮
	@override String get dialog_createNote => '建立筆記';

	/// 模型管理标题
	@override String dialog_manageModelsTitle({required Object providerName}) => '管理模型 - ${providerName}';

	/// 新模型标签
	@override String get dialog_newModelLabel => '新模型名稱';

	/// 添加模型
	@override String get dialog_addModelTooltip => '新增模型';

	/// 当前模型
	@override String dialog_currentModelsHeader({required Object count}) => '目前模型 (${count}):';

	/// 设为默认
	@override String get dialog_setDefaultTooltip => '設為預設';

	/// 模型更新
	@override String get dialog_modelsUpdated => '模型列表已更新';

	/// 分类管理
	@override String get category_title => '分類管理';

	/// 平铺视图
	@override String get category_flatViewTooltip => '平鋪檢視';

	/// 树形视图
	@override String get category_treeViewTooltip => '樹狀檢視';

	/// 新建分类
	@override String get category_createNewTooltip => '建立分類';

	/// 无分类
	@override String get category_emptyState => '暫無分類';

	/// 新建分类标题
	@override String get category_createTitle => '建立分類';

	/// 新建子分类
	@override String get category_createChildTitle => '建立子分類';

	/// 分类名称提示
	@override String get category_nameHint => '請輸入分類名稱';

	/// 名称为空
	@override String get category_nameEmptyError => '分類名稱不能為空';

	/// 名称过长
	@override String get category_nameTooLongError => '分類名稱不能超過20字元';

	/// 名称含横杠
	@override String get category_nameDashError => '分類名稱不能包含 "-" 字元';

	/// 名称重复
	@override String get category_duplicateNameError => '同級已存在同名目錄';

	/// 删除分类
	@override String get category_deleteTitle => '刪除分類';

	/// 删除确认
	@override String category_deleteConfirm({required Object name}) => '確定要刪除分類"${name}"嗎？';

	/// 删除警告
	@override String category_deleteWarning({required Object count}) => '該分類下有 ${count} 則筆記，刪除分類將同時刪除這些筆記！';

	/// 重命名
	@override String get category_renameTitle => '重新命名分類';

	/// 新名称提示
	@override String get category_newNameHint => '請輸入新分類名稱';

	/// 重命名
	@override String get category_renameTooltip => '重新命名';

	/// 添加子分类
	@override String get category_addChildTooltip => '新增子分類';

	/// AI问候
	@override String get ai_ciciGreeting => 'Hi，我是 Cici';

	/// AI副标题
	@override String get ai_ciciSubtitle => '基於你的筆記知識庫，我可以幫你：';

	/// 查找笔记
	@override String get ai_quickActionSearch => '尋找筆記';

	/// 总结提炼
	@override String get ai_quickActionSummarize => '總結提煉';

	/// 答疑解惑
	@override String get ai_quickActionQa => '答疑解惑';

	/// 示例消息1
	@override String get ai_sampleUserMessage1 => '幫我找一下關於"OKR 工作法"的筆記';

	/// 示例回复-找到
	@override String get ai_sampleAssistantFound => '好的，已為你找到';

	/// 示例回复-数量
	@override String get ai_sampleAssistantNotes => '1 則相關筆記：';

	/// 示例笔记标题
	@override String get ai_sampleNoteTitle => 'OKR 工作法：目標設定與落地實踐';

	/// 示例笔记描述
	@override String get ai_sampleNoteDesc => '介紹了 OKR 的定義、核心原則以及在團隊中的應用方法...';

	/// 示例消息2
	@override String get ai_sampleUserMessage2 => 'OKR 的核心原則是什麼？';

	/// 示例回复-原则
	@override String get ai_sampleAssistantPrinciples => 'OKR 的核心原則主要包括：';

	/// 示例原则1
	@override String get ai_samplePrinciple1 => '• 目標（O）要有挑戰性，激發潛力；';

	/// 示例原则2
	@override String get ai_samplePrinciple2 => '• 關鍵結果（KR）要可衡量，確保目標可追蹤；';

	/// 示例原则3
	@override String get ai_samplePrinciple3 => '• 保持透明對齊，團隊上下目標一致；';

	/// 示例原则4
	@override String get ai_samplePrinciple4 => '• 定期覆盤，持續學習與改進。';

	/// 示例结论
	@override String get ai_sampleAssistantConclusion => '這些原則能幫助團隊聚焦重點，提升執行力。';

	/// AI输入框
	@override String get ai_inputPlaceholder => '輸入你的問題，或直接用自然語言尋找筆記...';

	/// 搜索模板
	@override String get ai_quickActionSearchTemplate => '幫我尋找關於「」的筆記';

	/// 总结当前笔记
	@override String ai_quickActionSummarizeWithNote({required Object title}) => '請幫我總結提煉這篇筆記「${title}」的核心內容';

	/// 总结默认
	@override String get ai_quickActionSummarizeDefault => '請幫我總結目前筆記的核心內容';

	/// 问答模板
	@override String get ai_quickActionQaTemplate => '我有一個問題想基於筆記內容來回答...';

	/// 新会话
	@override String get ai_newSessionTitle => '開啟新會話';

	/// 新会话确认
	@override String get ai_newSessionConfirm => '確定要開啟新會話嗎？目前對話紀錄將被清空。';

	/// 分析需求
	@override String get ai_thinkingAnalyzing => '正在分析使用者需求...';

	/// 知识库未启用
	@override String get ai_knowledgeBaseDisabled => '⚠️ 知識庫未啟用，使用純文字搜尋模式';

	/// 回复失败
	@override String ai_replyFailed({required Object error}) => 'AI 回覆失敗：${error}';

	/// 调用中断
	@override String get ai_toolCallInterrupted => '呼叫中斷';

	/// 执行取消
	@override String get ai_executionCancelled => '已中斷執行';

	/// 用户中断
	@override String get ai_operationInterrupted => '操作已被使用者中斷';

	/// 默认输入框
	@override String get ai_inputDefaultPlaceholder => '輸入問題，或用自然語言尋找筆記';

	/// 工具类别-探索
	@override String get ai_toolCategoryExplore => '探索';

	/// 工具类别-编辑
	@override String get ai_toolCategoryEdit => '編輯';

	/// 工具类别-写入
	@override String get ai_toolCategoryWrite => '寫入';

	/// 工具类别-删除
	@override String get ai_toolCategoryDelete => '刪除';

	/// 工具类别-总结
	@override String get ai_toolCategorySummarize => '總結';

	/// 工具类别-提取
	@override String get ai_toolCategoryExtract => '擷取';

	/// 工具类别-处理
	@override String get ai_toolCategoryProcess => '處理';

	/// 执行终止
	@override String get ai_toolTerminated => '已終止執行';

	/// 执行中
	@override String get ai_toolInProgress => '正在執行...';

	/// 执行完成
	@override String get ai_toolCompleted => '執行完成';

	/// 工具统计
	@override String ai_toolBadgeCount({required Object category, required Object count}) => '${category} ${count} 次';

	/// 思考中
	@override String get ai_thinking => '思考中';

	/// AI摘要标题
	@override String get ai_summaryTitle => 'AI 摘要';

	/// 点击展开
	@override String get ai_clickToExpand => '點擊展開檢視摘要';

	/// 生成摘要
	@override String get ai_generateSummary => '產生摘要';

	/// 重新生成
	@override String get ai_regenerate => '重新產生';

	/// 生成摘要中
	@override String get ai_generatingSummary => '正在產生摘要...';

	/// 关键词标签
	@override String get ai_keywordsLabel => '關鍵字：';

	/// AI未配置
	@override String get ai_noAiConfig => '未設定AI服務，無法產生摘要';

	/// 前往设置
	@override String get ai_goToSettings => '前往設定';

	/// 生成中
	@override String get ai_generating => '正在產生...';

	/// 点击生成
	@override String get ai_clickToGenerate => '點擊產生AI摘要';

	/// 取消收藏
	@override String get card_unfavoriteTooltip => '取消收藏';

	/// 收藏
	@override String get card_favoriteTooltip => '收藏';

	/// 删除
	@override String get card_deleteTooltip => '刪除';

	/// 未命名
	@override String get card_untitledNote => '未命名筆記';

	/// 刚刚
	@override String get card_justNow => '剛剛';

	/// 分钟前
	@override String card_minutesAgo({required Object minutes}) => '${minutes}分鐘前';

	/// 小时前
	@override String card_hoursAgo({required Object hours}) => '${hours}小時前';

	/// 昨天
	@override String get card_yesterday => '昨天';

	/// 天前
	@override String card_daysAgo({required Object days}) => '${days}天前';

	/// 标签区域
	@override String get tag_sectionTitle => '標籤';

	/// 可选标签
	@override String get tag_availableTagsTitle => '可選標籤';

	/// 无标签
	@override String get tag_noTagsEmpty => '暫無標籤，點擊下方建立';

	/// 创建标签
	@override String get tag_createNew => '建立新標籤';

	/// 添加标签
	@override String get tag_addTag => '新增標籤';

	/// 标签名提示
	@override String get tag_nameHint => '標籤名';

	/// 确定
	@override String get tag_confirmTooltip => '確定';

	/// 跳过
	@override String get onboarding_skip => '跳過';

	/// 上一页
	@override String get onboarding_previous => '上一頁';

	/// 下一步
	@override String get onboarding_next => '下一步';

	/// 欢迎标题
	@override String get onboarding_welcomeTitle => '歡迎使用 OpenNote';

	/// 欢迎副标题
	@override String get onboarding_welcomeSubtitle => '智慧筆記助理，讓記錄更高效';

	/// 开始配置
	@override String get onboarding_startConfig => '開始設定';

	/// 稍后配置
	@override String get onboarding_configLater => '稍後設定';

	/// 图片加载失败
	@override String get onboarding_imageLoadError => '圖片載入失敗';

	/// 选择服务商
	@override String get onboarding_selectProviderTitle => '選擇AI服務商';

	/// 选择副标题
	@override String get onboarding_selectProviderSubtitle => '選擇您想要使用的AI服務商，稍後可在設定中新增更多';

	/// 未选择厂商
	@override String get onboarding_noProviderSelected => '請先選擇AI服務廠商';

	/// 返回选择
	@override String get onboarding_returnToSelectProvider => '返回上一頁選擇您偏好的AI服務商';

	/// 自定义配置
	@override String get onboarding_configCustomTitle => '設定自訂AI服務';

	/// 配置提供商
	@override String onboarding_configProviderTitle({required Object providerName}) => '設定 ${providerName}';

	/// 自定义副标题
	@override String get onboarding_customConfigSubtitle => '請輸入廠商資訊、API位址、模型列表和API金鑰';

	/// 提供商副标题
	@override String get onboarding_providerConfigSubtitle => '請輸入API金鑰以完成設定';

	/// 厂商标签
	@override String get onboarding_vendorLabel => '廠商';

	/// API地址标签
	@override String get onboarding_apiUrlLabel => 'API位址';

	/// 预设模型标签
	@override String get onboarding_presetModelsLabel => '預設模型';

	/// API密钥标签
	@override String get onboarding_apiKeyLabel => 'API金鑰';

	/// 已验证提示
	@override String get onboarding_apiKeyVerifiedHint => 'API金鑰已驗證';

	/// API密钥提示
	@override String get onboarding_apiKeyHint => '請輸入API金鑰';

	/// 获取密钥
	@override String get onboarding_getApiKey => '取得API金鑰';

	/// 测试中
	@override String get onboarding_testingConnection => '正在測試連線...';

	/// 测试连接
	@override String get onboarding_testConnection => '測試連線';

	/// 完成配置
	@override String get onboarding_completeConfig => '完成設定';

	/// 厂商名称
	@override String get onboarding_vendorNameLabel => '廠商名稱';

	/// 厂商名称提示
	@override String get onboarding_vendorNameHint => '例如：我的AI服務';

	/// API地址提示
	@override String get onboarding_apiUrlInputHint => '例如：https://api.example.com/v1';

	/// 模型列表
	@override String get onboarding_modelListLabel => '模型列表';

	/// 模型输入提示
	@override String get onboarding_modelInputHint => '輸入模型名稱';

	/// 添加模型
	@override String get onboarding_addModel => '新增';

	/// 默认模型
	@override String get onboarding_defaultModelLabel => '預設模型';

	/// 选择默认
	@override String get onboarding_selectDefaultModel => '選擇預設模型';

	/// 选择厂商错误
	@override String get onboarding_errorSelectVendorFirst => '請先選擇廠商';

	/// 输入密钥错误
	@override String get onboarding_errorEnterApiKey => '請輸入API金鑰';

	/// 输入厂商错误
	@override String get onboarding_errorEnterVendorName => '請輸入廠商名稱';

	/// 输入地址错误
	@override String get onboarding_errorEnterApiUrl => '請輸入API位址';

	/// 添加模型错误
	@override String get onboarding_errorAddModel => '請至少新增一個模型';

	/// 连接成功
	@override String get onboarding_connectionSuccess => '連線成功';

	/// 连接失败
	@override String get onboarding_connectionFailed => '連線失敗，請檢查API金鑰和網路連線';

	/// 测试异常
	@override String onboarding_testException({required Object error}) => '測試異常: ${error}';

	/// 保存失败
	@override String onboarding_saveConfigFailed({required Object error}) => '儲存設定失敗: ${error}';

	/// 配置成功
	@override String get onboarding_configSuccess => '設定成功！';

	/// 配置成功副标题
	@override String get onboarding_configSuccessSubtitle => '現在您可以開始使用AI功能了';

	/// 配置未完成
	@override String get onboarding_configIncomplete => '設定未完成';

	/// 未完成副标题
	@override String get onboarding_configIncompleteSubtitle => '您尚未完成AI服務設定，請返回完成設定後才能開始使用';

	/// 提示
	@override String get onboarding_infoTip => '提示';

	/// 滑动警告
	@override String get onboarding_swipedToCompleteWarning => '您透過滑動進入了完成頁面，但AI服務設定尚未儲存。請返回設定頁面完成API金鑰填寫和連線測試。';

	/// 下一步标题
	@override String get onboarding_nextStepTitle => '下一步建議';

	/// 下一步1
	@override String get onboarding_nextStep1 => '建立新筆記，體驗AI智慧摘要';

	/// 下一步2
	@override String get onboarding_nextStep2 => '使用關鍵字擷取功能快速整理筆記';

	/// 下一步3
	@override String get onboarding_nextStep3 => '讓AI幫您自動分類筆記內容';

	/// 开始使用
	@override String get onboarding_startUsing => '開始使用';

	/// 返回配置
	@override String get onboarding_returnToConfig => '返回設定';

	/// 加粗
	@override String get toolbar_bold => '粗體';

	/// 斜体
	@override String get toolbar_italic => '斜體';

	/// 删除线
	@override String get toolbar_strikethrough => '刪除線';

	/// H1
	@override String get toolbar_heading1 => 'H1';

	/// H2
	@override String get toolbar_heading2 => 'H2';

	/// H3
	@override String get toolbar_heading3 => 'H3';

	/// 代码
	@override String get toolbar_code => '程式碼';

	/// 引用
	@override String get toolbar_quote => '引用';

	/// 列表
	@override String get toolbar_list => '列表';

	/// 编号
	@override String get toolbar_numberedList => '編號';

	/// 待办
	@override String get toolbar_todo => '待辦';

	/// 链接
	@override String get toolbar_link => '連結';

	/// 图片
	@override String get toolbar_image => '圖片';

	/// 分割线
	@override String get toolbar_divider => '分割線';

	/// 表格
	@override String get toolbar_table => '表格';

	/// 表格模板头
	@override String get toolbar_tableHeader => '欄1 | 欄2 | 欄3';

	/// 表格内容
	@override String get toolbar_tableContent => '內容';

	/// 暂不可用
	@override String get format_unavailable => '暫不可用';

	/// 无笔记标题
	@override String get empty_noNotesTitle => '還沒有筆記';

	/// 无笔记描述
	@override String get empty_noNotesDesc => '點擊右上角 + 建立第一則筆記';

	/// 创建笔记
	@override String get empty_createNote => '建立筆記';

	/// 无搜索结果
	@override String get empty_noSearchResultsTitle => '沒有找到相關筆記';

	/// 无搜索描述
	@override String get empty_noSearchResultsDesc => '試試其他關鍵字';

	/// 清除搜索
	@override String get empty_clearSearch => '清除搜尋';

	/// 无标签标题
	@override String get empty_noTagsTitle => '還沒有標籤';

	/// 无标签描述
	@override String get empty_noTagsDesc => '在編輯筆記時可以新增標籤';

	/// 无收藏标题
	@override String get empty_noFavoritesTitle => '還沒有收藏筆記';

	/// 无收藏描述
	@override String get empty_noFavoritesDesc => '點擊筆記卡片上的星號即可收藏';

	/// 浏览笔记
	@override String get empty_browseNotes => '瀏覽筆記';

	/// 重试
	@override String get empty_retry => '重試';

	/// 网络错误
	@override String get empty_networkErrorTitle => '網路連線失敗';

	/// 网络错误描述
	@override String get empty_networkErrorDesc => '請檢查網路連線後重試';

	/// AI服务错误
	@override String get empty_aiServiceErrorTitle => 'AI 服務暫時不可用';

	/// AI错误描述
	@override String get empty_aiServiceErrorDesc => '請稍後重試或檢查AI設定';

	/// 菜单
	@override String get navigation_menu => '選單';

	/// 搜索框占位
	@override String get navigation_search => '搜尋...';

	/// 发现新版本
	@override String get update_newVersionFound => '發現新版本';

	/// 跳过版本
	@override String get update_skipThisVersion => '跳過此版本';

	/// 稍后提醒
	@override String get update_remindLater => '稍後提醒';

	/// 更新
	@override String get update_update => '更新';

	/// 版本号
	@override String get preferences_versionNumber => '版本號';

	/// 平台
	@override String get preferences_platform => '平台';

	/// 构建号
	@override String get preferences_buildNumber => '組建號';

	/// 自动检查更新
	@override String get preferences_autoCheckUpdate => '自動檢查更新';

	/// 检查中
	@override String get preferences_checking => '檢查中...';

	/// 最新版本
	@override String get preferences_latestVersion => '已是最新版本';

	/// 检查失败
	@override String get preferences_checkFailedRetry => '檢查失敗，重試';

	/// 检查更新
	@override String get preferences_checkForUpdate => '檢查更新';

	/// 发现新版本
	@override String preferences_newVersionFound({required Object version}) => '發現新版本 v${version}';

	/// 下载中
	@override String get preferences_downloadingUpdate => '正在下載更新';

	/// 下载完成
	@override String get preferences_downloadComplete => '下載完成';

	/// 安装提示
	@override String get preferences_installPrompt => '安裝程式已開啟，請按照提示完成更新';

	/// 跳过版本
	@override String get preferences_skippedVersions => '已跳過的版本';

	/// 语言
	@override String get preferences_language => '語言';

	/// 简体中文
	@override String get preferences_languageZhCN => '简体中文';

	/// 繁体中文
	@override String get preferences_languageZhTW => '繁體中文';

	/// 英文
	@override String get preferences_languageEn => 'English';

	/// 俄语
	@override String get preferences_languageRu => 'Русский';

	/// 重启提示
	@override String get preferences_languageRestartHint => '切換語言後重啟應用程式即可生效';

	/// 准备服务
	@override String get kb_preparingService => '準備服務中...';

	/// 启动服务
	@override String get kb_startingService => '啟動服務中...';

	/// 初始化向量
	@override String get kb_initializingVectorService => '正在初始化向量服務，請稍候...';

	/// 启动失败
	@override String get kb_serviceStartupFailed => '服務啟動失敗';

	/// 已就绪
	@override String get kb_knowledgeBaseReady => '知識庫已就緒';

	/// 未启用
	@override String get kb_knowledgeBaseNotEnabled => '知識庫未啟用';

	/// 运行中
	@override String get kb_serviceRunning => '服務執行中';

	/// 模型已加载
	@override String get kb_localModelLoaded => '本地模型已載入';

	/// 向量化说明
	@override String get kb_enableKnowledgeBaseVectorization => '啟用後將使用本地 Embedding 模型進行筆記向量化索引';

	/// 启用开关
	@override String get kb_enableToggle => '啟用/關閉';

	/// 启用知识库
	@override String get kb_enableKnowledgeBase => '啟用知識庫';

	/// 自动索引说明
	@override String get kb_autoVectorIndexing => '啟用後筆記將自動進行向量化索引';

	/// Embedding模型
	@override String get kb_embeddingModel => 'Embedding 模型';

	/// 模型
	@override String get kb_model => '模型';

	/// 向量维度
	@override String get kb_vectorDimensions => '向量維度';

	/// 下载源
	@override String get kb_downloadSource => '下載來源';

	/// 魔搭社区
	@override String get kb_modelscope => '魔搭社區 (modelscope.cn)';

	/// 模型版本
	@override String get kb_modelVersion => '模型版本:';

	/// 精度最高
	@override String get kb_highestPrecision => '~617MB · 精度最高';

	/// 平衡推荐
	@override String get kb_balancedRecommended => '~309MB · 平衡推薦';

	/// 轻量模式
	@override String get kb_lightweightMode => '~197MB · 輕量模式';

	/// 状态
	@override String get kb_status => '狀態';

	/// 已下载
	@override String get kb_downloaded => '已下載';

	/// 未下载
	@override String get kb_notDownloaded => '未下載';

	/// 路径
	@override String get kb_path => '路徑';

	/// 错误
	@override String kb_error({required Object error}) => '錯誤: ${error}';

	/// 校验中
	@override String get kb_verifyingFile => '正在校驗檔案完整性...';

	/// 下载中
	@override String kb_downloading({required Object progress}) => '下載中... ${progress}%';

	/// 下载模型
	@override String get kb_downloadModel => '下載模型';

	/// 选择路径
	@override String get kb_selectLocalPath => '選擇本地路徑';

	/// 索引设置
	@override String get kb_indexSettings => '索引設定';

	/// 分块大小
	@override String get kb_chunkSize => '分塊大小';

	/// 分块重叠
	@override String get kb_chunkOverlap => '分塊重疊';

	/// 缓存大小
	@override String get kb_cacheSize => '快取大小';

	/// 索引统计
	@override String get kb_indexStats => '索引統計';

	/// 准备Python
	@override String get kb_preparingPythonService => '正在準備 向量服務...';

	/// 启动Python
	@override String get kb_startingPythonService => '正在啟動 向量服務...';

	/// 未启用提示
	@override String get kb_knowledgeBaseNotEnabledPrompt => '知識庫未啟用，請先在上方啟用知識庫';

	/// 已索引
	@override String get kb_indexedNotes => '已索引筆記';

	/// 总向量
	@override String get kb_totalVectors => '總向量數';

	/// 最后更新
	@override String get kb_lastUpdate => '最後更新';

	/// 未索引
	@override String get kb_notIndexed => '未索引';

	/// 索引进度
	@override String kb_indexingProgress({required Object progress, required Object total}) => '正在索引 ${progress}/${total} 則筆記...';

	/// 索引失败
	@override String kb_indexFailedAll({required Object count}) => '索引失敗: 所有 ${count} 則筆記均未成功';

	/// 部分失败
	@override String kb_indexCompleteWithFailures({required Object success, required Object failed}) => '索引完成: ${success} 成功, ${failed} 失敗';

	/// 索引完成
	@override String kb_indexComplete({required Object count}) => '索引完成: ${count} 則成功';

	/// 收起错误
	@override String get kb_collapseErrorDetails => '收起錯誤詳情';

	/// 查看错误
	@override String kb_viewErrorDetails({required Object count}) => '檢視錯誤詳情 (${count} 則)';

	/// 未索引提示
	@override String kb_unindexedNotesPrompt({required Object count}) => '${count} 則筆記未索引，點擊"重建索引"以更新';

	/// 重建索引
	@override String get kb_rebuildIndex => '重建索引';

	/// 清空索引
	@override String get kb_clearIndex => '清空索引';

	/// 清空索引确认
	@override String get kb_confirmClearIndex => '確認清空索引';

	/// 清空内容
	@override String get kb_confirmClearIndexContent => '清空後需要重新索引所有筆記，是否繼續？';

	/// 重建索引确认
	@override String get kb_confirmRebuildIndex => '確認重建索引';

	/// 重建内容
	@override String kb_confirmRebuildIndexContent({required Object count}) => '將對 ${count} 則筆記進行向量化索引。\n這可能需要幾分鐘時間，是否繼續？';

	/// 开始重建
	@override String get kb_startRebuild => '開始重建';

	/// 重建失败
	@override String get kb_rebuildFailed => '重建索引失敗';

	/// Python启动失败
	@override String get kb_rebuildFailedPythonService => '重建索引失敗：向量服務啟動失敗，請檢查模型設定是否正確';

	/// 未就绪
	@override String get kb_rebuildFailedNotReady => '重建索引失敗：知識庫未就緒，請先下載模型並啟用知識庫';

	/// 健康检查失败
	@override String get kb_rebuildFailedHealthCheck => '重建索引失敗：向量服務未正常啟動，請稍後重試';

	/// 记忆能力
	@override String get assistant_memoryCapability => '記憶能力';

	/// AI模型选择
	@override String get assistant_aiModelSelection => 'AI模型選擇';

	/// 记忆注入
	@override String get assistant_memoryInjectionControl => '記憶注入控制';

	/// 清空记忆
	@override String get assistant_clearMemory => '清空記憶';

	/// 角色控制
	@override String get assistant_roleControl => '角色控制';

	/// 启用长期记忆
	@override String get assistant_enableLongTermMemory => '啟用長期記憶';

	/// 禁用提示
	@override String get assistant_memoryDisabledHint => '關閉後將停止記錄和使用所有記憶';

	/// 配置模型提示
	@override String get assistant_configureAIModelFirst => '請先設定可用的AI模型';

	/// 配置模型提示2
	@override String get assistant_configureAIModelsFirst => '請先在"AI服務"中設定可用的AI模型';

	/// 无模型
	@override String get assistant_noAvailableModels => '狀態: 無可用模型';

	/// 可用模型
	@override String assistant_availableModelsCount({required Object count}) => '狀態: ${count}個可用模型';

	/// 档案记忆
	@override String get assistant_profileMemory => '使用者檔案記憶';

	/// 档案副标题
	@override String get assistant_profileMemorySubtitle => '稱呼、職業、語言偏好等';

	/// 事实偏好
	@override String get assistant_factPreferenceMemory => '事實偏好記憶';

	/// 事实副标题
	@override String get assistant_factPreferenceSubtitle => '使用習慣、具體偏好等';

	/// 经验总结
	@override String get assistant_experienceSummaryMemory => '經驗總結記憶';

	/// 经验副标题
	@override String get assistant_experienceSummarySubtitle => '操作套路、應對策略等';

	/// 清空档案
	@override String assistant_clearProfileMemory({required Object count}) => '清空檔案記憶 (${count} 則)';

	/// 清空事实
	@override String assistant_clearFactMemory({required Object count}) => '清空事實記憶 (${count} 則)';

	/// 清空经验
	@override String assistant_clearExperienceMemory({required Object count}) => '清空經驗記憶 (${count} 則)';

	/// 清空全部
	@override String assistant_clearAllMemory({required Object count}) => '清空全部記憶 (${count} 則)';

	/// 角色自定义开发中
	@override String get assistant_roleCustomizationInDevelopment => '角色語氣、性格自訂功能開發中';

	/// 清空记忆确认
	@override String assistant_confirmClearMemoryContent({required Object typeName}) => '確定清空所有${typeName}嗎？此操作無法復原。';

	/// 已清空
	@override String assistant_clearedMemory({required Object typeName}) => '已清空${typeName}';

	/// 清空全部确认
	@override String get assistant_confirmClearAllMemoryContent => '確定清空所有類型的記憶嗎？此操作無法復原。';

	/// 已清空全部
	@override String get assistant_clearedAllMemory => '已清空全部記憶';

	/// 清空全部
	@override String get assistant_clearAll => '清空全部';

	/// 检查环境
	@override String get cli_checkingEnv => '檢查環境...';

	/// 环境不满足
	@override String get cli_envNotMet => '環境不滿足要求';

	/// 安装CLI
	@override String get cli_installingCLI => '正在安裝 CLI...';

	/// 安装成功
	@override String get cli_installSuccess => '安裝成功';

	/// 安装失败
	@override String get cli_installFailed => '安裝失敗';

	/// pip安装
	@override String get cli_executingPipInstall => '正在執行: pip install open-note-cli --upgrade';

	/// 安装中
	@override String get cli_installingPleaseWait => '安裝中，請稍候...';

	/// 安装成功消息
	@override String get cli_cliInstalledSuccessfully => 'CLI 工具已成功安裝！';

	/// 安装完成
	@override String get cli_installComplete => '安裝完成';

	/// 使用方法
	@override String get cli_usageMethod => '使用方法: opennote --help';

	/// 降级安装
	@override String get cli_fallbackInstallMethod => '降級安裝方法：';

	/// 重新检查
	@override String get cli_recheck => '重新檢查';

	/// 启动失败
	@override String get splash_startFailed => '啟動失敗';

	/// Follow system option
	@override String get preferences_followSystem => '跟隨系統';

	/// New note button tooltip
	@override String get home_newNote => '建立新筆記';

	/// settings_modelCount
	@override String get settings_modelCount => '個模型';

	/// common_notConfigured
	@override String get common_notConfigured => '未配置';

	/// settings_defaultModel
	@override String get settings_defaultModel => '預設模型';

	/// settings_autoFollowSystemTheme
	@override String get settings_autoFollowSystemTheme => '自動跟隨系統主題設定';

	/// settings_alwaysUseLightTheme
	@override String get settings_alwaysUseLightTheme => '始終使用淺色主題';

	/// settings_alwaysUseDarkTheme
	@override String get settings_alwaysUseDarkTheme => '始終使用深色主題';

	/// kb_serviceJustStarted
	@override String get kb_serviceJustStarted => '服務剛啟動，準備初始化...';

	/// kb_chromaDbInitializing
	@override String get kb_chromaDbInitializing => '正在初始化 ChromaDB 資料庫...';

	/// kb_loadingEmbeddingModel
	@override String get kb_loadingEmbeddingModel => '正在載入 Embedding AI 模型...';

	/// kb_chromaDbInitFailed
	@override String get kb_chromaDbInitFailed => 'ChromaDB 初始化失敗';

	/// kb_modelLoadFailed
	@override String get kb_modelLoadFailed => '嵌入模型載入失敗';

	/// kb_serviceInitError
	@override String get kb_serviceInitError => '服務初始化異常';

	/// kb_vectorServiceNotRunning
	@override String get kb_vectorServiceNotRunning => '向量服務未運行';

	/// kb_serviceNotStarted
	@override String get kb_serviceNotStarted => '服務未啟動';

	/// kb_cannotFetchStatus
	@override String get kb_cannotFetchStatus => '無法獲取服務狀態';

	/// kb_serviceConnectionFailed
	@override String get kb_serviceConnectionFailed => '服務連線失敗';

	/// kb_vectorServicePrepareFailed
	@override String get kb_vectorServicePrepareFailed => '向量服務準備失敗';

	/// kb_vectorServicePrepareError
	@override String get kb_vectorServicePrepareError => '向量服務準備異常';

	/// kb_vectorServiceStartFailed
	@override String get kb_vectorServiceStartFailed => '向量服務啟動失敗';

	/// kb_vectorServiceError
	@override String get kb_vectorServiceError => '向量服務異常';

	/// kb_serviceAlreadyRunning
	@override String get kb_serviceAlreadyRunning => '服務已在運行';

	/// kb_serviceStarted
	@override String get kb_serviceStarted => '服務已啟動';

	/// kb_serviceStartFailedPython
	@override String get kb_serviceStartFailedPython => '服務啟動失敗，請檢查 Python 環境和依賴';

	/// kb_directoryNotExist
	@override String get kb_directoryNotExist => '目錄不存在';

	/// kb_missingModelFile
	@override String get kb_missingModelFile => '缺少模型檔案: model.onnx';

	/// kb_missingTokenizer
	@override String get kb_missingTokenizer => '缺少 tokenizer.json';

	/// kb_modelFileSizeAbnormal
	@override String get kb_modelFileSizeAbnormal => '模型檔案大小異常';

	/// kb_knowledgeBaseNotReady
	@override String get kb_knowledgeBaseNotReady => '知識庫未就緒，請先下載模型並啟用知識庫';

	/// kb_vectorServiceStartFailedIndex
	@override String get kb_vectorServiceStartFailedIndex => '向量服務啟動失敗，無法進行索引';

	/// kb_healthCheckFailed
	@override String get kb_healthCheckFailed => '向量服務健康檢查失敗，服務可能未正常啟動';

	/// cli_pythonNotInstalled
	@override String get cli_pythonNotInstalled => '未找到 Python，請先安裝 Python 3.10+';

	/// cli_pipNotInstalled
	@override String get cli_pipNotInstalled => '未找到 pip，請先安裝 pip';

	/// cli_installProcessError
	@override String get cli_installProcessError => '安裝過程出錯: ';

	/// cli_envInstructionsMac
	@override String get cli_envInstructionsMac => '請先安裝 Python 3.10+ 和 pip：\n\n使用 Homebrew:\n  brew install python3\n\n或從 https://python.org 下載安裝包';

	/// cli_envInstructionsWindows
	@override String get cli_envInstructionsWindows => '請先安裝 Python 3.10+：\n\n從 https://python.org 下載安裝包\n安裝時勾選 "Add Python to PATH"';

	/// cli_envInstructionsLinux
	@override String get cli_envInstructionsLinux => '請先安裝 Python 3.10+ 和 pip：\n\nUbuntu/Debian:\n  sudo apt install python3 python3-pip\n\nFedora:\n  sudo dnf install python3 python3-pip';

	/// cli_envCheckFailed
	@override String get cli_envCheckFailed => '環境檢查失敗';

	/// cli_envStatus
	@override String get cli_envStatus => '環境狀態';

	/// cli_installCLI
	@override String get cli_installCLI => '安裝 CLI';

	/// cli_usage
	@override String get cli_usage => '使用方法';

	/// cli_cliStatus
	@override String get cli_cliStatus => 'CLI 狀態';

	/// cli_installed
	@override String get cli_installed => '已安裝';

	/// cli_notInstalled
	@override String get cli_notInstalled => '未安裝';

	/// cli_notDetected
	@override String get cli_notDetected => '未檢測到';

	/// cli_installDescription
	@override String get cli_installDescription => '點擊按鈕將自動安裝 OpenNote CLI 工具到你的系統環境';

	/// cli_helpText
	@override String get cli_helpText => 'opennote --help              # 檢視說明\nopennote note list           # 列出筆記\nopennote note search 關鍵詞   # 搜尋筆記\nopennote mcp start           # 啟動 MCP 服務';

	/// ai_copyMessage
	@override String get ai_copyMessage => '複製';

	/// ai_messageCopied
	@override String get ai_messageCopied => '已複製';

	/// ai_undoMessage
	@override String get ai_undoMessage => '撤銷';

	/// ai_newSession
	@override String get ai_newSession => '新會話';

	/// kb_switchModelWarning
	@override String get kb_switchModelWarning => '切換模型版本將清空向量索引，切換後將重建索引。';
}
