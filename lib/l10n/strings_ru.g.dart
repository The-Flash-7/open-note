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
class TranslationsRu extends Translations with BaseTranslations<AppLocale, Translations> {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	TranslationsRu({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = meta ?? TranslationMetadata(
		    locale: AppLocale.ru,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ),
		  super(cardinalResolver: cardinalResolver, ordinalResolver: ordinalResolver);

	/// Metadata for the translations of <ru>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	late final TranslationsRu _root = this; // ignore: unused_field

	@override 
	TranslationsRu $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => TranslationsRu(meta: meta ?? this.$meta);

	// Translations

	/// 取消按钮
	@override String get common_cancel => 'Отмена';

	/// 保存按钮
	@override String get common_save => 'Сохранить';

	/// 删除按钮
	@override String get common_delete => 'Удалить';

	/// 确定按钮
	@override String get common_ok => 'ОК';

	/// 关闭按钮
	@override String get common_close => 'Закрыть';

	/// 重试按钮
	@override String get common_retry => 'Повторить';

	/// 编辑按钮
	@override String get common_edit => 'Редактировать';

	/// 创建按钮
	@override String get common_create => 'Создать';

	/// 添加按钮
	@override String get common_add => 'Добавить';

	/// 清空/清除按钮
	@override String get common_clear => 'Очистить';

	/// 粘贴按钮
	@override String get common_paste => 'Вставить';

	/// 暂停按钮
	@override String get common_pause => 'Пауза';

	/// 继续/恢复按钮
	@override String get common_resume => 'Продолжить';

	/// 跳过按钮
	@override String get common_skip => 'Пропустить';

	/// 下一步按钮
	@override String get common_next => 'Далее';

	/// 上一页按钮
	@override String get common_previous => 'Назад';

	/// 删除确认标题
	@override String get common_confirmDelete => 'Подтвердить удаление';

	/// 清空确认标题
	@override String get common_confirmClear => 'Подтвердить очистку';

	/// 即将上线标签
	@override String get common_comingSoon => 'Скоро';

	/// 跟随系统选项
	@override String get common_followSystem => 'Как в системе';

	/// 亮色模式
	@override String get common_lightMode => 'Светлая тема';

	/// 暗色模式
	@override String get common_darkMode => 'Тёмная тема';

	/// 收起按钮
	@override String get common_collapse => 'Свернуть';

	/// 展开按钮
	@override String get common_expand => 'Развернуть';

	/// 发送按钮
	@override String get common_send => 'Отправить';

	/// 停止按钮
	@override String get common_stop => 'Стоп';

	/// 是
	@override String get common_yes => 'Да';

	/// 否
	@override String get common_no => 'Нет';

	/// 完成按钮
	@override String get common_done => 'Готово';

	/// 更多选项
	@override String get common_more => 'Ещё';

	/// 未知状态
	@override String get common_unknown => 'Неизвестно';

	/// 导航-首页
	@override String get home_home => 'Главная';

	/// 导航-目录
	@override String get home_categories => 'Категории';

	/// 导航-AI
	@override String get home_ai => 'ИИ';

	/// 导航-收藏
	@override String get home_favorites => 'Избранное';

	/// 导航-设置
	@override String get home_settings => 'Настройки';

	/// 平板导航-笔记
	@override String get home_note => 'Заметки';

	/// 拖拽导入覆盖层
	@override String get home_dragDropImport => 'Перетащите файлы для импорта';

	/// 导入成功
	@override String home_successImportCount({required Object count}) => 'Успешно импортировано: ${count} файл(ов)';

	/// 导入失败
	@override String home_failImportCount({required Object count}) => 'Не удалось импортировать: ${count} файл(ов)';

	/// 剪贴板URL提示
	@override String get home_clipboardUrlDetected => 'URL обнаружен в буфере обмена, создать заметку?';

	/// 忽略按钮
	@override String get home_dismiss => 'Отклонить';

	/// 摘要暂停状态
	@override String home_summaryGenerationPaused({required Object processedCount, required Object totalPending}) => 'Создание резюме приостановлено (${processedCount}/${totalPending})';

	/// 多选计数
	@override String home_selectedCount({required Object count}) => 'Выбрано: ${count}';

	/// 笔记列表标题
	@override String get home_allNotes => 'Все заметки';

	/// 取消多选
	@override String get home_cancelMultiSelect => 'Отменить多选';

	/// 多选切换
	@override String get home_multiSelect => 'Множественный выбор';

	/// 回收站图标提示
	@override String get home_trash => 'Корзина';

	/// 回收站带数量
	@override String home_trashWithCount({required Object count}) => 'Корзина (${count})';

	/// 新建空白笔记
	@override String get home_newBlankNote => 'Новая пустая заметка';

	/// 从URL创建
	@override String get home_createFromUrl => 'Создать из URL';

	/// 从文件导入
	@override String get home_importFromFile => 'Импорт из файла';

	/// 删除后提示
	@override String get home_noteMovedToTrash => 'Заметка перемещена в корзину';

	/// 空内容提示
	@override String get home_selectNoteToStart => 'Выберите заметку для просмотра';

	/// 删除确认内容
	@override String home_confirmDeleteNoteContent({required Object title}) => 'Удалить заметку "${title}"?';

	/// 批量删除标题
	@override String get home_confirmBatchDelete => 'Подтвердить удаление';

	/// 批量删除内容
	@override String home_confirmBatchDeleteContent({required Object count}) => 'Удалить ${count} выбранных заметок?';

	/// 批量操作栏
	@override String home_selectedNotesCount({required Object count}) => 'Выбрано заметок: ${count}';

	/// 批量删除后提示
	@override String home_deletedCountNotes({required Object count}) => 'Удалено заметок: ${count}';

	/// 回收站对话框标题
	@override String get home_trashTitle => 'Корзина';

	/// 空回收站提示
	@override String get home_trashEmpty => 'Корзина пуста';

	/// 回收站副标题
	@override String home_daysAgoDeleted({required Object days}) => 'Удалено ${days} дн. назад';

	/// 恢复按钮
	@override String get home_restore => 'Восстановить';

	/// 恢复后提示
	@override String get home_noteRestored => 'Заметка восстановлена';

	/// 永久删除
	@override String get home_permanentlyDelete => 'Удалить навсегда';

	/// 永久删除提示
	@override String get home_notePermanentlyDeleted => 'Заметка удалена навсегда';

	/// 清空回收站按钮
	@override String get home_emptyTrash => 'Очистить корзину';

	/// 清空回收站标题
	@override String get home_emptyTrashTitle => 'Очистить корзину';

	/// 清空回收站内容
	@override String home_emptyTrashContent({required Object count}) => 'Удалить ${count} заметок из корзины навсегда? Это действие нельзя отменить.';

	/// 清空后提示
	@override String get home_trashEmptied => 'Корзина очищена';

	/// 切换主题标题
	@override String get home_switchTheme => 'Сменить тему';

	/// 切换亮色
	@override String get home_switchToLight => 'Переключить на светлую тему';

	/// 切换暗色
	@override String get home_switchToDark => 'Переключить на тёмную тему';

	/// 取消收藏菜单
	@override String get home_unfavorite => 'Убрать из избранного';

	/// 收藏菜单
	@override String get home_favorite => 'В избранное';

	/// 分享菜单
	@override String get home_share => 'Поделиться';

	/// 分享功能提示
	@override String get home_shareComingSoon => 'Функция обмена скоро появится';

	/// 默认标题
	@override String get editor_untitledNote => 'Без названия';

	/// 保存中状态
	@override String get editor_saving => 'Сохранение...';

	/// 自动保存成功
	@override String get editor_autoSaved => 'Автосохранение выполнено';

	/// 自动保存失败
	@override String get editor_autoSaveFailed => 'Ошибка автосохранения';

	/// 分类选择器
	@override String get editor_selectCategory => 'Выбрать категорию';

	/// 无分类选项
	@override String get editor_noCategory => 'Без категории';

	/// 清除分类
	@override String get editor_clearCategory => 'Очистить категорию';

	/// 内容不能为空
	@override String get editor_noteContentCannotBeEmpty => 'Содержимое заметки не может быть пустым';

	/// 保存成功
	@override String get editor_saveSuccess => 'Сохранено';

	/// 保存失败
	@override String editor_saveFailed({required Object error}) => 'Ошибка сохранения: ${error}';

	/// 填写提示
	@override String get editor_fillTitleAndContentFirst => 'Сначала заполните заголовок и содержание';

	/// 配置超时
	@override String get editor_configTimeoutRetry => 'Таймаут загрузки конфигурации, попробуйте снова';

	/// AI未配置
	@override String get editor_configureAIFirst => 'Сначала настройте ИИ-сервис';

	/// 建议生成失败
	@override String editor_generateSuggestionsFailed({required Object error}) => 'Ошибка генерации предложений: ${error}';

	/// 智能建议标题
	@override String get editor_smartSuggestions => 'Умные предложения';

	/// 分类建议标签
	@override String get editor_categorySuggestion => 'Категория:';

	/// 标签建议标签
	@override String get editor_tagSuggestion => 'Теги:';

	/// 无建议
	@override String get editor_noSuggestions => 'Предложений нет';

	/// 应用建议按钮
	@override String get editor_applySuggestions => 'Применить';

	/// 新笔记标题
	@override String get editor_newNote => 'Новая заметка';

	/// 编辑笔记标题
	@override String get editor_editNote => 'Редактировать';

	/// 预览模式
	@override String get editor_preview => 'Предпросмотр';

	/// 智能建议提示
	@override String get editor_smartSuggestionsTooltip => 'Умные предложения';

	/// AI助手提示
	@override String get editor_aiAssistant => 'ИИ-ассистент';

	/// 来源标签
	@override String get editor_source => 'Источник: ';

	/// 标题文本框
	@override String get editor_title => 'Заголовок';

	/// Markdown占位符
	@override String get editor_startWritingMarkdown => 'Начните писать Markdown заметку...';

	/// 纯文本占位符
	@override String get editor_startWritingPlainText => 'Начните писать текстовую заметку...';

	/// 富文本占位符
	@override String get editor_startWritingRichText => 'Начните писать форматированную заметку...';

	/// 设置导航-首选项
	@override String get settings_preferences => 'Настройки';

	/// 设置导航-AI服务
	@override String get settings_aiService => 'ИИ-сервис';

	/// 设置导航-外观
	@override String get settings_appearance => 'Внешний вид';

	/// 设置导航-知识库
	@override String get settings_knowledgeBase => 'База знаний';

	/// 设置导航-智能助理
	@override String get settings_assistant => 'Ассистент';

	/// 设置导航-CLI
	@override String get settings_cliTools => 'CLI';

	/// 设置对话框标题
	@override String get settings_title => 'Настройки';

	/// 开发中占位
	@override String get settings_featureInDevelopment => 'В разработке...';

	/// 自定义配置标题
	@override String get settings_customConfig => 'Пользовательская конфигурация';

	/// 快速添加标题
	@override String get settings_quickAddPresets => 'Быстрое добавление';

	/// 快速添加描述
	@override String get settings_quickAddDescription => 'Нажмите для быстрого добавления популярных провайдеров';

	/// 无AI配置
	@override String get settings_noAIConfig => 'Конфигурация ИИ отсутствует';

	/// 空状态提示
	@override String get settings_clickToAddPreset => 'Нажмите кнопку ниже';

	/// 已配置列表
	@override String get settings_configured => 'Настроено';

	/// 配置数量
	@override String settings_configCount({required Object count}) => '${count}';

	/// 当前徽章
	@override String get settings_current => 'Текущий';

	/// 配置模型提示
	@override String get settings_setModelFirst => 'Сначала настройте модель';

	/// 添加提供商
	@override String settings_addProvider({required Object name}) => 'Добавить ${name}';

	/// API地址标签
	@override String get settings_apiAddress => 'API адрес: ';

	/// 预设模型
	@override String settings_presetsModels({required Object models}) => 'Модели: ${models}';

	/// API密钥标签
	@override String get settings_apiKey => 'API ключ';

	/// API密钥提示
	@override String get settings_enterApiKey => 'Введите ваш API ключ';

	/// API密钥错误
	@override String get settings_enterApiKeyError => 'Введите API ключ';

	/// 厂商名称
	@override String get settings_vendorName => 'Название провайдера';

	/// 厂商名称提示
	@override String get settings_vendorNameHint => 'например: Мой API, Прокси';

	/// Base URL标签
	@override String get settings_baseUrl => 'Base URL';

	/// Base URL提示
	@override String get settings_baseUrlHint => 'https://api.example.com/v1';

	/// 模型列表
	@override String get settings_modelList => 'Список моделей';

	/// 模型列表提示
	@override String get settings_modelListHint => 'через запятую, например: model-1,model-2';

	/// 厂商名称错误
	@override String get settings_enterVendorName => 'Введите название провайдера';

	/// 模型错误
	@override String get settings_enterAtLeastOneModel => 'Введите хотя бы одну модель';

	/// 显示名称
	@override String get settings_displayName => 'Отображаемое имя';

	/// 删除配置确认
	@override String settings_confirmDeleteConfig({required Object name}) => 'Удалить "${name}"?';

	/// 连接成功
	@override String settings_connectionSuccess({required Object name}) => 'Подключено к ${name}';

	/// 未知错误
	@override String get settings_unknownError => 'Неизвестная ошибка';

	/// 测试异常
	@override String settings_testException({required Object error}) => 'Ошибка теста: ${error}';

	/// 测试连接
	@override String get settings_testConnection => 'Тест подключения';

	/// 测试连接中
	@override String get settings_testingConnection => 'Тестирование...';

	/// 连接成功标签
	@override String get settings_connectionSuccessful => 'Подключено';

	/// 连接失败标签
	@override String get settings_connectionFailed => 'Не подключено';

	/// 搜索框
	@override String get search_placeholder => 'Поиск заметок...';

	/// 分类筛选
	@override String get search_categoryFilter => 'Фильтр по категории';

	/// 所有分类
	@override String get search_allCategories => 'Все категории';

	/// 输入提示
	@override String get search_enterToSearch => 'Введите ключевые слова';

	/// 无结果
	@override String get search_noResults => 'Заметки не найдены';

	/// 无历史
	@override String get search_noHistory => 'Нет истории поиска';

	/// 最近搜索
	@override String get search_recentSearches => 'Недавние запросы';

	/// 未命名回退
	@override String get search_untitledNote => 'Без названия';

	/// 刚刚
	@override String get search_justNow => 'Только что';

	/// 分钟前
	@override String search_minutesAgo({required Object count}) => '${count} мин. назад';

	/// 小时前
	@override String search_hoursAgo({required Object count}) => '${count} ч. назад';

	/// 昨天
	@override String get search_yesterday => 'Вчера';

	/// 天前
	@override String search_daysAgo({required Object count}) => '${count} дн. назад';

	/// Enter键
	@override String get search_enterHint => 'Enter';

	/// 打开
	@override String get search_open => 'Открыть';

	/// 上下键
	@override String get search_navigateHint => '↑↓';

	/// 导航
	@override String get search_navigate => 'Навигация';

	/// Esc键
	@override String get search_escHint => 'Esc';

	/// 关闭
	@override String get search_closeHint => 'Закрыть';

	/// 新建笔记
	@override String get dialog_newNote => 'Новая заметка';

	/// 空白笔记
	@override String get dialog_blankNote => 'Пустая заметка';

	/// 空白笔记副标题
	@override String get dialog_createBlankNote => 'Создать новую пустую заметку';

	/// 从文件导入
	@override String get dialog_importFromFile => 'Импорт из файла';

	/// 从文件导入副标题
	@override String get dialog_importFromFileSubtitle => 'Создать заметки из TXT, кода или HTML файлов';

	/// 导入成功
	@override String get dialog_noteImportSuccess => 'Заметка импортирована';

	/// 不支持格式
	@override String get dialog_importFailedUnsupported => 'Формат файла не поддерживается';

	/// 导入失败
	@override String dialog_importFailed({required Object error}) => 'Ошибка импорта: ${error}';

	/// 选择格式
	@override String get dialog_selectNoteFormat => 'Выберите формат';

	/// Markdown格式
	@override String get dialog_markdown => 'Markdown';

	/// Markdown描述
	@override String get dialog_markdownDescription => 'Поддерживает форматирование, код, таблицы';

	/// 纯文本
	@override String get dialog_plainText => 'Текст';

	/// 纯文本描述
	@override String get dialog_plainTextDescription => 'Простой текст без форматирования';

	/// 富文本
	@override String get dialog_richText => 'Форматированный';

	/// 富文本描述
	@override String get dialog_richTextDescription => 'Редактор Quill: жирный, курсив, списки';

	/// 代码
	@override String get dialog_code => 'Код';

	/// 代码描述
	@override String get dialog_codeDescription => 'Редактор кода с подсветкой синтаксиса';

	/// URL创建
	@override String get dialog_createFromUrl => 'Создать заметку из URL';

	/// URL字段
	@override String get dialog_webUrl => 'URL страницы';

	/// URL提示
	@override String get dialog_urlHint => 'example.com';

	/// URL错误
	@override String get dialog_enterUrl => 'Введите URL';

	/// URL格式错误
	@override String get dialog_invalidUrlFormat => 'Неверный формат URL';

	/// 提取失败
	@override String get dialog_extractFailed => 'Ошибка извлечения содержимого';

	/// 提取中
	@override String get dialog_extractingContent => 'Извлечение содержимого...';

	/// 提取成功
	@override String get dialog_extractSuccess => 'Извлечено';

	/// AI初始化
	@override String get dialog_aiInitializing => 'ИИ инициализирует заметку...';

	/// 自动初始化
	@override String get dialog_noteAutoInitialized => 'Заметка инициализирована';

	/// 摘要
	@override String get dialog_summary => 'Резюме';

	/// 关键词
	@override String get dialog_keywords => 'Ключевые слова';

	/// 分类
	@override String get dialog_category => 'Категория';

	/// 标签
	@override String get dialog_tags => 'Теги';

	/// 提取内容按钮
	@override String get dialog_extractContent => 'Извлечь содержимое';

	/// 创建笔记按钮
	@override String get dialog_createNote => 'Создать заметку';

	/// 模型管理标题
	@override String dialog_manageModelsTitle({required Object providerName}) => 'Управление моделями - ${providerName}';

	/// 新模型标签
	@override String get dialog_newModelLabel => 'Новая модель';

	/// 添加模型
	@override String get dialog_addModelTooltip => 'Добавить модель';

	/// 当前模型
	@override String dialog_currentModelsHeader({required Object count}) => 'Текущие модели (${count}):';

	/// 设为默认
	@override String get dialog_setDefaultTooltip => 'По умолчанию';

	/// 模型更新
	@override String get dialog_modelsUpdated => 'Список моделей обновлён';

	/// 分类管理
	@override String get category_title => 'Категории';

	/// 平铺视图
	@override String get category_flatViewTooltip => 'Плоский вид';

	/// 树形视图
	@override String get category_treeViewTooltip => 'Древовидный вид';

	/// 新建分类
	@override String get category_createNewTooltip => 'Новая категория';

	/// 无分类
	@override String get category_emptyState => 'Категорий пока нет';

	/// 新建分类标题
	@override String get category_createTitle => 'Новая категория';

	/// 新建子分类
	@override String get category_createChildTitle => 'Новая подкатегория';

	/// 分类名称提示
	@override String get category_nameHint => 'Введите название';

	/// 名称为空
	@override String get category_nameEmptyError => 'Название не может быть пустым';

	/// 名称过长
	@override String get category_nameTooLongError => 'Название не более 20 символов';

	/// 名称含横杠
	@override String get category_nameDashError => 'Название не может содержать "-"';

	/// 名称重复
	@override String get category_duplicateNameError => 'Такое имя уже существует';

	/// 删除分类
	@override String get category_deleteTitle => 'Удалить категорию';

	/// 删除确认
	@override String category_deleteConfirm({required Object name}) => 'Удалить "${name}"?';

	/// 删除警告
	@override String category_deleteWarning({required Object count}) => 'В категории ${count} заметок. Они будут удалены вместе с категорией!';

	/// 重命名
	@override String get category_renameTitle => 'Переименовать';

	/// 新名称提示
	@override String get category_newNameHint => 'Введите новое название';

	/// 重命名
	@override String get category_renameTooltip => 'Переименовать';

	/// 添加子分类
	@override String get category_addChildTooltip => 'Добавить подкатегорию';

	/// AI问候
	@override String get ai_ciciGreeting => 'Привет, я Cici';

	/// AI副标题
	@override String get ai_ciciSubtitle => 'На основе вашей базы знаний я могу помочь:';

	/// 查找笔记
	@override String get ai_quickActionSearch => 'Найти заметки';

	/// 总结提炼
	@override String get ai_quickActionSummarize => 'Обобщить';

	/// 答疑解惑
	@override String get ai_quickActionQa => 'Вопрос-ответ';

	/// 示例消息1
	@override String get ai_sampleUserMessage1 => 'Найди заметки про "OKR"';

	/// 示例回复-找到
	@override String get ai_sampleAssistantFound => 'Хорошо, я нашёл';

	/// 示例回复-数量
	@override String get ai_sampleAssistantNotes => '1 релевантная заметка:';

	/// 示例笔记标题
	@override String get ai_sampleNoteTitle => 'OKR: постановка целей и реализация';

	/// 示例笔记描述
	@override String get ai_sampleNoteDesc => 'Определение OKR, основные принципы и применение в команде...';

	/// 示例消息2
	@override String get ai_sampleUserMessage2 => 'Каковы основные принципы OKR?';

	/// 示例回复-原则
	@override String get ai_sampleAssistantPrinciples => 'Основные принципы OKR:';

	/// 示例原则1
	@override String get ai_samplePrinciple1 => '• Цели (O) должны быть амбициозными;';

	/// 示例原则2
	@override String get ai_samplePrinciple2 => '• Ключевые результаты (KR) должны быть измеримыми;';

	/// 示例原则3
	@override String get ai_samplePrinciple3 => '• Прозрачность и согласованность на всех уровнях;';

	/// 示例原则4
	@override String get ai_samplePrinciple4 => '• Регулярный анализ, непрерывное обучение.';

	/// 示例结论
	@override String get ai_sampleAssistantConclusion => 'Эти принципы помогают команде сфокусироваться на главном.';

	/// AI输入框
	@override String get ai_inputPlaceholder => 'Задайте вопрос или найдите заметки на естественном языке...';

	/// 搜索模板
	@override String get ai_quickActionSearchTemplate => 'Найди заметки про ""';

	/// 总结当前笔记
	@override String ai_quickActionSummarizeWithNote({required Object title}) => 'Обобщи эту заметку "${title}"';

	/// 总结默认
	@override String get ai_quickActionSummarizeDefault => 'Обобщи текущую заметку';

	/// 问答模板
	@override String get ai_quickActionQaTemplate => 'У меня есть вопрос по содержимому заметок...';

	/// 新会话
	@override String get ai_newSessionTitle => 'Новый чат';

	/// 新会话确认
	@override String get ai_newSessionConfirm => 'Начать новый чат? Текущий будет очищен.';

	/// 分析需求
	@override String get ai_thinkingAnalyzing => 'Анализ запроса...';

	/// 知识库未启用
	@override String get ai_knowledgeBaseDisabled => '⚠️ База знаний отключена, используется текстовый поиск';

	/// 回复失败
	@override String ai_replyFailed({required Object error}) => 'Ошибка ответа ИИ: ${error}';

	/// 调用中断
	@override String get ai_toolCallInterrupted => 'Вызов прерван';

	/// 执行取消
	@override String get ai_executionCancelled => 'Выполнение отменено';

	/// 用户中断
	@override String get ai_operationInterrupted => 'Операция прервана пользователем';

	/// 默认输入框
	@override String get ai_inputDefaultPlaceholder => 'Задайте вопрос или найдите заметки';

	/// 工具类别-探索
	@override String get ai_toolCategoryExplore => 'Поиск';

	/// 工具类别-编辑
	@override String get ai_toolCategoryEdit => 'Редактирование';

	/// 工具类别-写入
	@override String get ai_toolCategoryWrite => 'Запись';

	/// 工具类别-删除
	@override String get ai_toolCategoryDelete => 'Удаление';

	/// 工具类别-总结
	@override String get ai_toolCategorySummarize => 'Обобщение';

	/// 工具类别-提取
	@override String get ai_toolCategoryExtract => 'Извлечение';

	/// 工具类别-处理
	@override String get ai_toolCategoryProcess => 'Обработка';

	/// 执行终止
	@override String get ai_toolTerminated => 'Выполнение завершено';

	/// 执行中
	@override String get ai_toolInProgress => 'Выполняется...';

	/// 执行完成
	@override String get ai_toolCompleted => 'Завершено';

	/// 工具统计
	@override String ai_toolBadgeCount({required Object category, required Object count}) => '${category}: ${count} раз';

	/// 思考中
	@override String get ai_thinking => 'Думает';

	/// AI摘要标题
	@override String get ai_summaryTitle => 'ИИ Резюме';

	/// 点击展开
	@override String get ai_clickToExpand => 'Нажмите для просмотра';

	/// 生成摘要
	@override String get ai_generateSummary => 'Создать резюме';

	/// 重新生成
	@override String get ai_regenerate => 'Пересоздать';

	/// 生成摘要中
	@override String get ai_generatingSummary => 'Создание резюме...';

	/// 关键词标签
	@override String get ai_keywordsLabel => 'Ключевые слова: ';

	/// AI未配置
	@override String get ai_noAiConfig => 'ИИ-сервис не настроен';

	/// 前往设置
	@override String get ai_goToSettings => 'В настройки';

	/// 生成中
	@override String get ai_generating => 'Генерация...';

	/// 点击生成
	@override String get ai_clickToGenerate => 'Нажмите для создания резюме';

	/// 进入编辑模式并生成摘要
	@override String get ai_switchToEditAndGenerate => 'Переключиться в режим редактирования и создать сводку';

	/// 取消收藏
	@override String get card_unfavoriteTooltip => 'Убрать из избранного';

	/// 收藏
	@override String get card_favoriteTooltip => 'В избранное';

	/// 删除
	@override String get card_deleteTooltip => 'Удалить';

	/// 未命名
	@override String get card_untitledNote => 'Без названия';

	/// 刚刚
	@override String get card_justNow => 'Только что';

	/// 分钟前
	@override String card_minutesAgo({required Object minutes}) => '${minutes} мин. назад';

	/// 小时前
	@override String card_hoursAgo({required Object hours}) => '${hours} ч. назад';

	/// 昨天
	@override String get card_yesterday => 'Вчера';

	/// 天前
	@override String card_daysAgo({required Object days}) => '${days} дн. назад';

	/// 标签区域
	@override String get tag_sectionTitle => 'Теги';

	/// 可选标签
	@override String get tag_availableTagsTitle => 'Доступные теги';

	/// 无标签
	@override String get tag_noTagsEmpty => 'Тегов нет, создайте ниже';

	/// 创建标签
	@override String get tag_createNew => 'Создать тег';

	/// 添加标签
	@override String get tag_addTag => 'Добавить тег';

	/// 标签名提示
	@override String get tag_nameHint => 'Имя тега';

	/// 确定
	@override String get tag_confirmTooltip => 'ОК';

	/// 跳过
	@override String get onboarding_skip => 'Пропустить';

	/// 上一页
	@override String get onboarding_previous => 'Назад';

	/// 下一步
	@override String get onboarding_next => 'Далее';

	/// 欢迎标题
	@override String get onboarding_welcomeTitle => 'Добро пожаловать в OpenNote';

	/// 欢迎副标题
	@override String get onboarding_welcomeSubtitle => 'Умный помощник для заметок';

	/// 开始配置
	@override String get onboarding_startConfig => 'Начать настройку';

	/// 稍后配置
	@override String get onboarding_configLater => 'Настроить позже';

	/// 图片加载失败
	@override String get onboarding_imageLoadError => 'Ошибка загрузки изображения';

	/// 选择服务商
	@override String get onboarding_selectProviderTitle => 'Выберите ИИ-провайдера';

	/// 选择副标题
	@override String get onboarding_selectProviderSubtitle => 'Выберите провайдера, позже можно добавить больше';

	/// 未选择厂商
	@override String get onboarding_noProviderSelected => 'Сначала выберите провайдера';

	/// 返回选择
	@override String get onboarding_returnToSelectProvider => 'Вернитесь и выберите провайдера';

	/// 自定义配置
	@override String get onboarding_configCustomTitle => 'Настроить пользовательский ИИ';

	/// 配置提供商
	@override String onboarding_configProviderTitle({required Object providerName}) => 'Настройка ${providerName}';

	/// 自定义副标题
	@override String get onboarding_customConfigSubtitle => 'Введите информацию о провайдере, API адрес, модели и ключ';

	/// 提供商副标题
	@override String get onboarding_providerConfigSubtitle => 'Введите API ключ';

	/// 厂商标签
	@override String get onboarding_vendorLabel => 'Провайдер';

	/// API地址标签
	@override String get onboarding_apiUrlLabel => 'API адрес';

	/// 预设模型标签
	@override String get onboarding_presetModelsLabel => 'Модели';

	/// API密钥标签
	@override String get onboarding_apiKeyLabel => 'API ключ';

	/// 已验证提示
	@override String get onboarding_apiKeyVerifiedHint => 'API ключ подтверждён';

	/// API密钥提示
	@override String get onboarding_apiKeyHint => 'Введите API ключ';

	/// 获取密钥
	@override String get onboarding_getApiKey => 'Получить API ключ';

	/// 测试中
	@override String get onboarding_testingConnection => 'Тестирование...';

	/// 测试连接
	@override String get onboarding_testConnection => 'Тест подключения';

	/// 完成配置
	@override String get onboarding_completeConfig => 'Завершить';

	/// 厂商名称
	@override String get onboarding_vendorNameLabel => 'Название провайдера';

	/// 厂商名称提示
	@override String get onboarding_vendorNameHint => 'например: Мой ИИ';

	/// API地址提示
	@override String get onboarding_apiUrlInputHint => 'например: https://api.example.com/v1';

	/// 模型列表
	@override String get onboarding_modelListLabel => 'Модели';

	/// 模型输入提示
	@override String get onboarding_modelInputHint => 'Введите модель';

	/// 添加模型
	@override String get onboarding_addModel => 'Добавить';

	/// 默认模型
	@override String get onboarding_defaultModelLabel => 'Модель по умолчанию';

	/// 选择默认
	@override String get onboarding_selectDefaultModel => 'Выберите модель';

	/// 选择厂商错误
	@override String get onboarding_errorSelectVendorFirst => 'Выберите провайдера';

	/// 输入密钥错误
	@override String get onboarding_errorEnterApiKey => 'Введите API ключ';

	/// 输入厂商错误
	@override String get onboarding_errorEnterVendorName => 'Введите название';

	/// 输入地址错误
	@override String get onboarding_errorEnterApiUrl => 'Введите API адрес';

	/// 添加模型错误
	@override String get onboarding_errorAddModel => 'Добавьте хотя бы одну модель';

	/// 连接成功
	@override String get onboarding_connectionSuccess => 'Подключено';

	/// 连接失败
	@override String get onboarding_connectionFailed => 'Ошибка подключения, проверьте ключ и сеть';

	/// 测试异常
	@override String onboarding_testException({required Object error}) => 'Ошибка: ${error}';

	/// 保存失败
	@override String onboarding_saveConfigFailed({required Object error}) => 'Ошибка сохранения: ${error}';

	/// 配置成功
	@override String get onboarding_configSuccess => 'Настроено!';

	/// 配置成功副标题
	@override String get onboarding_configSuccessSubtitle => 'Теперь вы можете использовать ИИ';

	/// 配置未完成
	@override String get onboarding_configIncomplete => 'Настройка не завершена';

	/// 未完成副标题
	@override String get onboarding_configIncompleteSubtitle => 'Вы не завершили настройку ИИ. Вернитесь и завершите.';

	/// 提示
	@override String get onboarding_infoTip => 'Совет';

	/// 滑动警告
	@override String get onboarding_swipedToCompleteWarning => 'Вы перешли на страницу завершения, но конфигурация не сохранена. Вернитесь и завершите настройку.';

	/// 下一步标题
	@override String get onboarding_nextStepTitle => 'Следующие шаги';

	/// 下一步1
	@override String get onboarding_nextStep1 => 'Создайте заметку и попробуйте ИИ-резюме';

	/// 下一步2
	@override String get onboarding_nextStep2 => 'Используйте извлечение ключевых слов';

	/// 下一步3
	@override String get onboarding_nextStep3 => 'Позвольте ИИ автоматически классифицировать заметки';

	/// 开始使用
	@override String get onboarding_startUsing => 'Начать';

	/// 返回配置
	@override String get onboarding_returnToConfig => 'Вернуться';

	/// 加粗
	@override String get toolbar_bold => 'Жирный';

	/// 斜体
	@override String get toolbar_italic => 'Курсив';

	/// 删除线
	@override String get toolbar_strikethrough => 'Зачёркнутый';

	/// H1
	@override String get toolbar_heading1 => 'H1';

	/// H2
	@override String get toolbar_heading2 => 'H2';

	/// H3
	@override String get toolbar_heading3 => 'H3';

	/// 代码
	@override String get toolbar_code => 'Код';

	/// 引用
	@override String get toolbar_quote => 'Цитата';

	/// 列表
	@override String get toolbar_list => 'Список';

	/// 编号
	@override String get toolbar_numberedList => 'Нумерация';

	/// 待办
	@override String get toolbar_todo => 'Задача';

	/// 链接
	@override String get toolbar_link => 'Ссылка';

	/// 图片
	@override String get toolbar_image => 'Изображение';

	/// 分割线
	@override String get toolbar_divider => 'Разделитель';

	/// 表格
	@override String get toolbar_table => 'Таблица';

	/// 表格模板头
	@override String get toolbar_tableHeader => 'Кол 1 | Кол 2 | Кол 3';

	/// 表格内容
	@override String get toolbar_tableContent => 'Содержимое';

	/// 暂不可用
	@override String get format_unavailable => 'Недоступно';

	/// 无笔记标题
	@override String get empty_noNotesTitle => 'Заметок пока нет';

	/// 无笔记描述
	@override String get empty_noNotesDesc => 'Нажмите + для создания первой заметки';

	/// 创建笔记
	@override String get empty_createNote => 'Создать заметку';

	/// 无搜索结果
	@override String get empty_noSearchResultsTitle => 'Ничего не найдено';

	/// 无搜索描述
	@override String get empty_noSearchResultsDesc => 'Попробуйте другие ключевые слова';

	/// 清除搜索
	@override String get empty_clearSearch => 'Очистить поиск';

	/// 无标签标题
	@override String get empty_noTagsTitle => 'Тегов пока нет';

	/// 无标签描述
	@override String get empty_noTagsDesc => 'Теги можно добавить при редактировании';

	/// 无收藏标题
	@override String get empty_noFavoritesTitle => 'Избранных заметок нет';

	/// 无收藏描述
	@override String get empty_noFavoritesDesc => 'Нажмите звёздочку на карточке заметки';

	/// 浏览笔记
	@override String get empty_browseNotes => 'Просмотреть заметки';

	/// 重试
	@override String get empty_retry => 'Повторить';

	/// 网络错误
	@override String get empty_networkErrorTitle => 'Ошибка сети';

	/// 网络错误描述
	@override String get empty_networkErrorDesc => 'Проверьте соединение';

	/// AI服务错误
	@override String get empty_aiServiceErrorTitle => 'ИИ-сервис временно недоступен';

	/// AI错误描述
	@override String get empty_aiServiceErrorDesc => 'Попробуйте позже';

	/// 菜单
	@override String get navigation_menu => 'Меню';

	/// 搜索框占位
	@override String get navigation_search => 'Поиск...';

	/// 发现新版本
	@override String get update_newVersionFound => 'Доступна новая версия';

	/// 跳过版本
	@override String get update_skipThisVersion => 'Пропустить';

	/// 稍后提醒
	@override String get update_remindLater => 'Напомнить позже';

	/// 更新
	@override String get update_update => 'Обновить';

	/// 版本号
	@override String get preferences_versionNumber => 'Версия';

	/// 平台
	@override String get preferences_platform => 'Платформа';

	/// 构建号
	@override String get preferences_buildNumber => 'Сборка';

	/// 自动检查更新
	@override String get preferences_autoCheckUpdate => 'Автопроверка обновлений';

	/// 检查中
	@override String get preferences_checking => 'Проверка...';

	/// 最新版本
	@override String get preferences_latestVersion => 'Последняя версия';

	/// 检查失败
	@override String get preferences_checkFailedRetry => 'Ошибка, повторить';

	/// 检查更新
	@override String get preferences_checkForUpdate => 'Проверить обновления';

	/// 发现新版本
	@override String preferences_newVersionFound({required Object version}) => 'Найдена версия v${version}';

	/// 下载中
	@override String get preferences_downloadingUpdate => 'Загрузка обновления';

	/// 停止下载更新
	@override String get preferences_cancelDownload => 'Остановить загрузку';

	/// 下载已取消
	@override String get preferences_downloadCancelled => 'Загрузка отменена';

	/// 已下载大小
	@override String preferences_downloadedSize({required String size}) => 'Загружено ${size}';

	/// 下载完成
	@override String get preferences_downloadComplete => 'Загрузка завершена';

	/// 安装提示
	@override String get preferences_installPrompt => 'Установщик открыт, следуйте инструкциям';

	/// 跳过版本
	@override String get preferences_skippedVersions => 'Пропущенные версии';

	/// 语言
	@override String get preferences_language => 'Язык';

	/// 简体中文
	@override String get preferences_languageZhCN => '简体中文';

	/// 繁体中文
	@override String get preferences_languageZhTW => '繁體中文';

	/// 英文
	@override String get preferences_languageEn => 'English';

	/// 俄语
	@override String get preferences_languageRu => 'Русский';

	/// 重启提示
	@override String get preferences_languageRestartHint => 'Перезапустите приложение для применения';

	/// 准备服务
	@override String get kb_preparingService => 'Подготовка сервиса...';

	/// 启动服务
	@override String get kb_startingService => 'Запуск сервиса...';

	/// 停止服务
	@override String get kb_stoppingService => 'Остановка сервиса...';

	/// 初始化向量
	@override String get kb_initializingVectorService => 'Инициализация векторного сервиса...';

	/// 启动失败
	@override String get kb_serviceStartupFailed => 'Ошибка запуска';

	/// 端口被占用提示
	@override String kb_portOccupied({required int port}) => 'Порт ${port} уже используется другим приложением';

	/// 端口被占用详情
	@override String kb_portOccupiedDetail({required String pid}) => 'Закройте приложение, использующее этот порт, и повторите попытку. PID процесса: ${pid}';

	/// 已就绪
	@override String get kb_knowledgeBaseReady => 'База знаний готова';

	/// 未启用
	@override String get kb_knowledgeBaseNotEnabled => 'База знаний отключена';

	/// 运行中
	@override String get kb_serviceRunning => 'Сервис работает';

	/// 模型已加载
	@override String get kb_localModelLoaded => 'Модель загружена';

	/// 向量化说明
	@override String get kb_enableKnowledgeBaseVectorization => 'Включите для векторизации заметок';

	/// 启用开关
	@override String get kb_enableToggle => 'Вкл/Выкл';

	/// 启用知识库
	@override String get kb_enableKnowledgeBase => 'Включить базу знаний';

	/// 自动索引说明
	@override String get kb_autoVectorIndexing => 'Заметки будут автоматически векторизованы';

	/// Embedding模型
	@override String get kb_embeddingModel => 'Embedding модель';

	/// 模型
	@override String get kb_model => 'Модель';

	/// 向量维度
	@override String get kb_vectorDimensions => 'Размерность';

	/// 下载源
	@override String get kb_downloadSource => 'Источник';

	/// 魔搭社区
	@override String get kb_modelscope => 'ModelScope (modelscope.cn)';

	/// 模型版本
	@override String get kb_modelVersion => 'Версия:';

	/// 精度最高
	@override String get kb_highestPrecision => '~617MB · Макс. точность';

	/// 平衡推荐
	@override String get kb_balancedRecommended => '~309MB · Баланс';

	/// 轻量模式
	@override String get kb_lightweightMode => '~197MB · Лёгкий';

	/// 状态
	@override String get kb_status => 'Статус';

	/// 已下载
	@override String get kb_downloaded => 'Загружено';

	/// 未下载
	@override String get kb_notDownloaded => 'Не загружено';

	/// 路径
	@override String get kb_path => 'Путь';

	/// 错误
	@override String kb_error({required Object error}) => 'Ошибка: ${error}';

	/// 校验中
	@override String get kb_verifyingFile => 'Проверка файла...';

	/// 下载中
	@override String kb_downloading({required Object progress}) => 'Загрузка... ${progress}%';

	/// 下载模型
	@override String get kb_downloadModel => 'Скачать модель';

	/// 选择路径
	@override String get kb_selectLocalPath => 'Выбрать путь';

	/// 索引设置
	@override String get kb_indexSettings => 'Настройки индекса';

	/// 分块大小
	@override String get kb_chunkSize => 'Размер блока';

	/// 分块重叠
	@override String get kb_chunkOverlap => 'Перекрытие';

	/// 缓存大小
	@override String get kb_cacheSize => 'Кэш';

	/// 索引统计
	@override String get kb_indexStats => 'Статистика';

	/// 准备Python
	@override String get kb_preparingPythonService => 'Подготовка вектор сервиса...';

	/// 启动Python
	@override String get kb_startingPythonService => 'Запуск вектор сервиса...';

	/// 未启用提示
	@override String get kb_knowledgeBaseNotEnabledPrompt => 'База знаний отключена, включите её выше';

	/// 已索引
	@override String get kb_indexedNotes => 'Индексировано';

	/// 总向量
	@override String get kb_totalVectors => 'Векторов';

	/// 最后更新
	@override String get kb_lastUpdate => 'Последнее обновление';

	/// 未索引
	@override String get kb_notIndexed => 'Не индексировано';

	/// 索引进度
	@override String kb_indexingProgress({required Object progress, required Object total}) => 'Индексация ${progress}/${total} заметок...';

	/// 索引失败
	@override String kb_indexFailedAll({required Object count}) => 'Ошибка: все ${count} заметок не проиндексированы';

	/// 部分失败
	@override String kb_indexCompleteWithFailures({required Object success, required Object failed}) => 'Завершено: ${success} успешно, ${failed} ошибок';

	/// 索引完成
	@override String kb_indexComplete({required Object count}) => 'Завершено: ${count} успешно';

	/// 收起错误
	@override String get kb_collapseErrorDetails => 'Скрыть ошибки';

	/// 查看错误
	@override String kb_viewErrorDetails({required Object count}) => 'Ошибки (${count})';

	/// 未索引提示
	@override String kb_unindexedNotesPrompt({required Object count}) => '${count} заметок не индексировано, нажмите "Перестроить"';

	/// 重建索引
	@override String get kb_rebuildIndex => 'Перестроить';

	/// 清空索引
	@override String get kb_clearIndex => 'Очистить';

	/// 清空索引确认
	@override String get kb_confirmClearIndex => 'Подтвердить очистку';

	/// 清空内容
	@override String get kb_confirmClearIndexContent => 'Все заметки будут переиндексированы. Продолжить?';

	/// 重建索引确认
	@override String get kb_confirmRebuildIndex => 'Подтвердить перестройку';

	/// 重建内容
	@override String kb_confirmRebuildIndexContent({required Object count}) => '${count} заметок будет векторизовано.\nЭто может занять несколько минут.';

	/// 开始重建
	@override String get kb_startRebuild => 'Начать';

	/// 重建失败
	@override String get kb_rebuildFailed => 'Ошибка перестройки';

	/// Python启动失败
	@override String get kb_rebuildFailedPythonService => 'вектор сервис не запустился, проверьте настройки';

	/// 未就绪
	@override String get kb_rebuildFailedNotReady => 'База знаний не готова, скачайте модель и включите её';

	/// 健康检查失败
	@override String get kb_rebuildFailedHealthCheck => 'вектор сервис не работает, попробуйте позже';

	/// 记忆能力
	@override String get assistant_memoryCapability => 'Память';

	/// AI模型选择
	@override String get assistant_aiModelSelection => 'Выбор ИИ-модели';

	/// 记忆注入
	@override String get assistant_memoryInjectionControl => 'Управление памятью';

	/// 清空记忆
	@override String get assistant_clearMemory => 'Очистить память';

	/// 角色控制
	@override String get assistant_roleControl => 'Роль';

	/// 启用长期记忆
	@override String get assistant_enableLongTermMemory => 'Включить долгосрочную память';

	/// 禁用提示
	@override String get assistant_memoryDisabledHint => 'Запись и использование памяти будет остановлена';

	/// 配置模型提示
	@override String get assistant_configureAIModelFirst => 'Настройте ИИ-модель';

	/// 配置模型提示2
	@override String get assistant_configureAIModelsFirst => 'Настройте модели в "ИИ-сервис"';

	/// 无模型
	@override String get assistant_noAvailableModels => 'Нет доступных моделей';

	/// 可用模型
	@override String assistant_availableModelsCount({required Object count}) => '${count} моделей доступно';

	/// 档案记忆
	@override String get assistant_profileMemory => 'Профиль пользователя';

	/// 档案副标题
	@override String get assistant_profileMemorySubtitle => 'Имя, профессия, предпочтения';

	/// 事实偏好
	@override String get assistant_factPreferenceMemory => 'Факты и предпочтения';

	/// 事实副标题
	@override String get assistant_factPreferenceSubtitle => 'Привычки, предпочтения';

	/// 经验总结
	@override String get assistant_experienceSummaryMemory => 'Опыт';

	/// 经验副标题
	@override String get assistant_experienceSummarySubtitle => 'Стратегии, шаблоны';

	/// 清空档案
	@override String assistant_clearProfileMemory({required Object count}) => 'Очистить профиль (${count})';

	/// 清空事实
	@override String assistant_clearFactMemory({required Object count}) => 'Очистить факты (${count})';

	/// 清空经验
	@override String assistant_clearExperienceMemory({required Object count}) => 'Очистить опыт (${count})';

	/// 清空全部
	@override String assistant_clearAllMemory({required Object count}) => 'Очистить всё (${count})';

	/// 角色自定义开发中
	@override String get assistant_roleCustomizationInDevelopment => 'Настройка роли скоро';

	/// 清空记忆确认
	@override String assistant_confirmClearMemoryContent({required Object typeName}) => 'Очистить ${typeName}? Это нельзя отменить.';

	/// 已清空
	@override String assistant_clearedMemory({required Object typeName}) => '${typeName} очищено';

	/// 清空全部确认
	@override String get assistant_confirmClearAllMemoryContent => 'Очистить всю память? Это нельзя отменить.';

	/// 已清空全部
	@override String get assistant_clearedAllMemory => 'Вся память очищена';

	/// 清空全部
	@override String get assistant_clearAll => 'Очистить всё';

	/// 检查环境
	@override String get cli_checkingEnv => 'Проверка среды...';

	/// 环境不满足
	@override String get cli_envNotMet => 'Требования не выполнены';

	/// 安装CLI
	@override String get cli_installingCLI => 'Установка CLI...';

	/// 安装成功
	@override String get cli_installSuccess => 'Установка успешна';

	/// 安装失败
	@override String get cli_installFailed => 'Ошибка установки';

	/// pip安装
	@override String get cli_executingPipInstall => 'Выполняется: pip install open-note-cli --upgrade';

	/// 安装中
	@override String get cli_installingPleaseWait => 'Установка, подождите...';

	/// 安装成功消息
	@override String get cli_cliInstalledSuccessfully => 'CLI установлен!';

	/// 安装完成
	@override String get cli_installComplete => 'Установка завершена';

	/// 使用方法
	@override String get cli_usageMethod => 'Использование: opennote --help';

	/// 降级安装
	@override String get cli_fallbackInstallMethod => 'Альтернативный метод:';

	/// 重新检查
	@override String get cli_recheck => 'Проверить снова';

	/// 启动失败
	@override String get splash_startFailed => 'Ошибка запуска';

	/// Follow system option
	@override String get preferences_followSystem => 'Как в системе';

	/// New note button tooltip
	@override String get home_newNote => 'Новая заметка';

	/// settings_modelCount
	@override String get settings_modelCount => 'моделей';

	/// common_notConfigured
	@override String get common_notConfigured => 'Не настроено';

	/// settings_defaultModel
	@override String get settings_defaultModel => 'Модель по умолчанию';

	/// settings_autoFollowSystemTheme
	@override String get settings_autoFollowSystemTheme => 'Автоматически следовать системной теме';

	/// settings_alwaysUseLightTheme
	@override String get settings_alwaysUseLightTheme => 'Всегда использовать светлую тему';

	/// settings_alwaysUseDarkTheme
	@override String get settings_alwaysUseDarkTheme => 'Всегда использовать тёмную тему';

	/// kb_serviceJustStarted
	@override String get kb_serviceJustStarted => 'Сервис запущен, подготовка...';

	/// kb_chromaDbInitializing
	@override String get kb_chromaDbInitializing => 'Инициализация ChromaDB...';

	/// kb_loadingEmbeddingModel
	@override String get kb_loadingEmbeddingModel => 'Загрузка модели...';

	/// kb_chromaDbInitFailed
	@override String get kb_chromaDbInitFailed => 'Ошибка инициализации ChromaDB';

	/// kb_modelLoadFailed
	@override String get kb_modelLoadFailed => 'Ошибка загрузки модели';

	/// kb_serviceInitError
	@override String get kb_serviceInitError => 'Ошибка инициализации';

	/// kb_vectorServiceNotRunning
	@override String get kb_vectorServiceNotRunning => 'Векторный сервис не запущен';

	/// kb_serviceNotStarted
	@override String get kb_serviceNotStarted => 'Сервис не запущен';

	/// kb_cannotFetchStatus
	@override String get kb_cannotFetchStatus => 'Не удалось получить статус';

	/// kb_serviceConnectionFailed
	@override String get kb_serviceConnectionFailed => 'Ошибка подключения';

	/// kb_vectorServicePrepareFailed
	@override String get kb_vectorServicePrepareFailed => 'Ошибка подготовки сервиса';

	/// kb_vectorServicePrepareError
	@override String get kb_vectorServicePrepareError => 'Ошибка подготовки';

	/// kb_vectorServiceStartFailed
	@override String get kb_vectorServiceStartFailed => 'Ошибка запуска сервиса';

	/// kb_vectorServiceError
	@override String get kb_vectorServiceError => 'Ошибка сервиса';

	/// kb_serviceAlreadyRunning
	@override String get kb_serviceAlreadyRunning => 'Сервис уже запущен';

	/// kb_serviceStarted
	@override String get kb_serviceStarted => 'Сервис запущен';

	/// kb_serviceStartFailedPython
	@override String get kb_serviceStartFailedPython => 'Ошибка запуска, проверьте Python';

	/// kb_directoryNotExist
	@override String get kb_directoryNotExist => 'Каталог не существует';

	/// kb_missingModelFile
	@override String get kb_missingModelFile => 'Отсутствует файл модели: model.onnx';

	/// kb_missingTokenizer
	@override String get kb_missingTokenizer => 'Отсутствует tokenizer.json';

	/// kb_modelFileSizeAbnormal
	@override String get kb_modelFileSizeAbnormal => 'Размер файла модели аномальный';

	/// kb_knowledgeBaseNotReady
	@override String get kb_knowledgeBaseNotReady => 'База знаний не готова';

	/// kb_vectorServiceStartFailedIndex
	@override String get kb_vectorServiceStartFailedIndex => 'Ошибка запуска, индексация невозможна';

	/// kb_healthCheckFailed
	@override String get kb_healthCheckFailed => 'Проверка не пройдена';

	/// cli_pythonNotInstalled
	@override String get cli_pythonNotInstalled => 'Python не найден, установите Python 3.10+';

	/// cli_pipNotInstalled
	@override String get cli_pipNotInstalled => 'pip не найден, установите pip';

	/// cli_installProcessError
	@override String get cli_installProcessError => 'Ошибка установки: ';

	/// cli_envInstructionsMac
	@override String get cli_envInstructionsMac => 'Установите Python 3.10+ и pip:\n\nЧерез Homebrew:\n  brew install python3\n\nИли скачайте с https://python.org';

	/// cli_envInstructionsWindows
	@override String get cli_envInstructionsWindows => 'Установите Python 3.10+:\n\nСкачайте с https://python.org\nОтметьте "Add Python to PATH" при установке';

	/// cli_envInstructionsLinux
	@override String get cli_envInstructionsLinux => 'Установите Python 3.10+ и pip:\n\nUbuntu/Debian:\n  sudo apt install python3 python3-pip\n\nFedora:\n  sudo dnf install python3 python3-pip';

	/// cli_envCheckFailed
	@override String get cli_envCheckFailed => 'Проверка среды не удалась';

	/// cli_envStatus
	@override String get cli_envStatus => 'Статус среды';

	/// cli_installCLI
	@override String get cli_installCLI => 'Установить CLI';

	/// cli_usage
	@override String get cli_usage => 'Использование';

	/// cli_cliStatus
	@override String get cli_cliStatus => 'Статус CLI';

	/// cli_installed
	@override String get cli_installed => 'Установлено';

	/// cli_notInstalled
	@override String get cli_notInstalled => 'Не установлено';

	/// cli_notDetected
	@override String get cli_notDetected => 'Не обнаружено';

	/// cli_installDescription
	@override String get cli_installDescription => 'Нажмите кнопку для автоматической установки OpenNote CLI';

	/// cli_helpText
	@override String get cli_helpText => 'opennote --help              # Показать справку\nopennote note list           # Список заметок\nopennote note search <запрос> # Поиск заметок\nopennote mcp start           # Запуск службы MCP';

	/// ai_copyMessage
	@override String get ai_copyMessage => 'Копировать';

	/// ai_messageCopied
	@override String get ai_messageCopied => 'Скопировано';

	/// ai_undoMessage
	@override String get ai_undoMessage => 'Отменить';

	/// ai_newSession
	@override String get ai_newSession => 'Новая сессия';

	/// kb_switchModelWarning
	@override String get kb_switchModelWarning => 'Переключение версии модели очистит векторный индекс. После переключения индекс будет перестроен.';
}
