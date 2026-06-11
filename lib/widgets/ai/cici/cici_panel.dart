// Copyright (c) 2026 litongshuai
// SPDX-License-Identifier: MIT OR Apache-2.0

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../l10n/strings.g.dart';
import '../../../models/chat_message.dart';
import '../../../models/note.dart';
import '../../../providers/notes_provider.dart';
import '../../../services/chat_message_persistence_service.dart';
import '../../../utils/cancellation_token.dart';
import 'cici_design_tokens.dart';
import 'cici_message_bubble.dart';
import 'cici_note_card.dart';
import 'cici_quick_action.dart';
import 'cici_ai_tag.dart';
import 'cici_input.dart';
import 'cici_system_message.dart';
import 'cici_tool_execution_log.dart';
import 'cici_thinking_indicator.dart';

class CiciPanel extends StatefulWidget {
  final bool isOpen;
  final VoidCallback? onClose;
  final Note? currentNote;
  final void Function(Note note)? onNoteTap;

  const CiciPanel({
    super.key,
    this.isOpen = false,
    this.onClose,
    this.currentNote,
    this.onNoteTap,
  });

  @override
  State<CiciPanel> createState() => _CiciPanelState();
}

class _CiciPanelState extends State<CiciPanel>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;
  final ScrollController _scrollController = ScrollController();
  late TextEditingController _inputController;
  late FocusNode _inputFocusNode;
  bool _isProcessing = false;
  CancellationToken _cancellationToken = CancellationToken();
  Translations? _t;

  // 智能滚动控制
  bool _shouldAutoScroll = true;
  bool _isScrollListenerAttached = false;
  static const double _pauseAutoScrollThreshold = 150; // 超过此距离暂停自动滚动
  static const double _resumeAutoScrollThreshold = 80; // 小于此距离恢复自动滚动

  // 双列表架构
  List<ChatMessage> _normalMessages = []; // 普通消息（固化历史）
  final List<Widget> _tempWidgets = []; // 临时组件（思考指示器等）
  String? _streamingMessageId; // 正在流式更新的消息 ID

  // 历史消息加载
  bool _isLoadingHistory = false;
  bool _hasMoreHistory = true;
  static const int _historyPageSize = 20;
  DateTime? _lastHistoryLoadTime;
  final ChatMessagePersistenceService _persistenceService =
      ChatMessagePersistenceService();
  bool _historySyncedToAgent = false;

  StreamSubscription<ChatMessage>? _messageSubscription;
  StreamSubscription<void>? _clearedSubscription;

  // 空状态引导标记
  bool _hasUserInteracted = false;
  static const String _kHasUserInteractedKey = 'cici_has_user_interacted';

  // 工具日志单组管理
  final List<ToolExecutionEntry> _toolLogEntries = []; // 所有工具条目（单组）
  int _currentToolLogIndex = -1; // 当前工具日志在 _normalMessages 中的索引
  bool _isReactInProgress = false; // ReAct 引擎是否还在运行
  CiciThinkingIndicator? _thinkingIndicator; // 思考指示器实例（复用）

  @override
  void initState() {
    super.initState();
    _inputController = TextEditingController();
    _inputFocusNode = FocusNode();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _loadInteractionFlag();
    _loadHistoryMessages();

    _messageSubscription = _persistenceService.onNewMessageSaved.listen((
      newMessage,
    ) {
      if (mounted) {
        _handleNewMessageFromPersistence(newMessage);
      }
    });

    _clearedSubscription = _persistenceService.onCleared.listen((_) {
      if (mounted) {
        _handleClearedFromRemote();
      }
    });

    if (widget.isOpen) {
      _controller.forward();
    }
  }

  Future<void> _loadInteractionFlag() async {
    final prefs = await SharedPreferences.getInstance();
    final hasInteracted = prefs.getBool(_kHasUserInteractedKey) ?? false;
    if (mounted) {
      setState(() {
        _hasUserInteracted = hasInteracted;
      });
    }
  }

  Future<void> _loadHistoryMessages() async {
    final notesProvider = context.read<NotesProvider>();

    final pageSize = _historyPageSize + 10;
    final historyMessages = await _persistenceService.loadRecentMessages(
      limit: pageSize,
      loadNote: (noteId) async => await notesProvider.getNoteById(noteId),
    );

    if (mounted && historyMessages.isNotEmpty) {
      setState(() {
        _normalMessages = historyMessages;
        _hasMoreHistory = !(pageSize > historyMessages.length);
        _shouldAutoScroll = true;
      });

      _attachScrollListener();

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _tryScrollToBottom();
      });
    }
  }

  void _handleNewMessageFromPersistence(ChatMessage newMessage) {
    final exists = _normalMessages.any((m) => m.id == newMessage.id);
    if (exists) return;

    debugPrint('[Scroll] New message from persistence');

    setState(() {
      _normalMessages.add(newMessage);
      _shouldAutoScroll = true;
    });

    if (widget.isOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        debugPrint('[Scroll] tryScrollToBottom after new message');
        _tryScrollToBottom();
      });
    }
  }

  void _clearChatState() {
    setState(() {
      // 清空UI消息列表
      _normalMessages.clear();
      _tempWidgets.clear();
      _toolLogEntries.clear();

      // 重置状态
      _isProcessing = false;
      _isReactInProgress = false;
      _historySyncedToAgent = false;
      _hasMoreHistory = true;
      _streamingMessageId = null;
      _currentToolLogIndex = -1;
      _thinkingIndicator = null;
    });

    _scrollToBottom();
    _detachScrollListener();
  }

  void _handleClearedFromRemote() {
    final notesProvider = context.read<NotesProvider>();
    notesProvider.ciciAgent?.clearHistory();
    _clearChatState();
  }

  /// Revoke the last user message and all subsequent messages
  void _revokeLastUserMessage() {
    // Find the last user message index
    int lastUserIndex = -1;
    for (int i = _normalMessages.length - 1; i >= 0; i--) {
      if (_normalMessages[i].messageType == CiciMessageType.user) {
        lastUserIndex = i;
        break;
      }
    }

    if (lastUserIndex == -1) return;

    final revokedMessage = _normalMessages[lastUserIndex];

    // Collect IDs to delete
    final idsToDelete = _normalMessages
        .sublist(lastUserIndex)
        .map((m) => m.id)
        .toList();

    // Remove from _normalMessages
    setState(() {
      _normalMessages.removeRange(lastUserIndex, _normalMessages.length);
      _isProcessing = false;
      _isReactInProgress = false;
      _streamingMessageId = null;
      _currentToolLogIndex = -1;
    });

    // Delete from database
    for (final id in idsToDelete) {
      _persistenceService.deleteMessage(id);
    }

    // Clear from agent history
    final notesProvider = context.read<NotesProvider>();
    notesProvider.ciciAgent?.clearHistoryFromIndex(lastUserIndex);

    // Restore content to input
    _inputController.text = revokedMessage.content;
    _inputController.selection = TextSelection.fromPosition(
      TextPosition(offset: revokedMessage.content.length),
    );

    _inputFocusNode.requestFocus();
  }

  /// Check if the message at the given index is the last user message
  bool _isLastUserMessage(int index) {
    if (index < 0 || index >= _normalMessages.length) return false;
    if (_normalMessages[index].messageType != CiciMessageType.user) {
      return false;
    }
    // Check if there are any user messages after this index
    for (int i = index + 1; i < _normalMessages.length; i++) {
      if (_normalMessages[i].messageType == CiciMessageType.user) {
        return false;
      }
    }
    return true;
  }

  /// 标记最近的用户消息为已回复（同时更新数据库）
  Future<void> _markUserMessageAsReplied() async {
    for (int i = _normalMessages.length - 1; i >= 0; i--) {
      if (_normalMessages[i].messageType == CiciMessageType.user &&
          !_normalMessages[i].isReplied) {
        _normalMessages[i] = _normalMessages[i].copyWith(isReplied: true);
        await _persistenceService.updateMessageRepliedStatus(
          _normalMessages[i].id,
          true,
        );
        break;
      }
    }
  }

  Future<void> _loadMoreHistory() async {
    if (_isLoadingHistory || !_hasMoreHistory || _isProcessing) return;

    // 防抖：1000ms 内不重复触发
    final now = DateTime.now();
    if (_lastHistoryLoadTime != null &&
        now.difference(_lastHistoryLoadTime!).inMilliseconds < 1000) {
      return;
    }

    // 记录加载前的滚动位置
    final double pixelsBefore = _scrollController.hasClients
        ? _scrollController.position.pixels
        : 0.0;
    final double maxScrollBefore = _scrollController.hasClients
        ? _scrollController.position.maxScrollExtent
        : 0.0;

    setState(() {
      _isLoadingHistory = true;
      _lastHistoryLoadTime = now;
    });

    final notesProvider = context.read<NotesProvider>();

    String? earliestTimestamp;
    if (_normalMessages.isNotEmpty) {
      earliestTimestamp = _normalMessages.first.timestamp.toIso8601String();
    }

    List<ChatMessage> messages = [];
    if (earliestTimestamp != null) {
      messages = await _persistenceService.loadEarlierMessages(
        beforeTimestamp: earliestTimestamp,
        limit: _historyPageSize,
        loadNote: (noteId) async => await notesProvider.getNoteById(noteId),
      );
    }

    if (mounted) {
      setState(() {
        if (messages.isNotEmpty) {
          _normalMessages.insertAll(0, messages);
          _hasMoreHistory = messages.length >= _historyPageSize;
        } else {
          _hasMoreHistory = false;
        }
        _isLoadingHistory = false;
      });

      // 布局完成后，补偿滚动位置
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _scrollController.hasClients) {
          final maxScrollAfter = _scrollController.position.maxScrollExtent;
          final delta = maxScrollAfter - maxScrollBefore;
          if (delta > 0) {
            _scrollController.jumpTo(pixelsBefore + delta);
          }
        }
      });
    }
  }

  @override
  void didUpdateWidget(CiciPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isOpen != oldWidget.isOpen) {
      if (widget.isOpen) {
        _controller.forward();
        // 面板打开时自动聚焦输入框，并滚动到底部
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _inputFocusNode.requestFocus();
            if (_shouldAutoScroll) {
              _tryScrollToBottom();
            }
          }
        });
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    _clearedSubscription?.cancel();
    _detachScrollListener();
    _controller.dispose();
    _scrollController.dispose();
    _inputController.dispose();
    _inputFocusNode.dispose();
    super.dispose();
  }

  void _attachScrollListener() {
    if (!_isScrollListenerAttached) {
      _scrollController.addListener(_onScroll);
      _isScrollListenerAttached = true;
    }
  }

  void _detachScrollListener() {
    if (_isScrollListenerAttached) {
      _scrollController.removeListener(_onScroll);
      _isScrollListenerAttached = false;
    }
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    final distanceFromBottom = maxScroll - currentScroll;

    if (distanceFromBottom > _pauseAutoScrollThreshold) {
      _shouldAutoScroll = false;
    } else if (distanceFromBottom < _resumeAutoScrollThreshold) {
      _shouldAutoScroll = true;
    }

    if (currentScroll <= 50 &&
        _hasMoreHistory &&
        !_isLoadingHistory &&
        !_isProcessing) {
      _loadMoreHistory();
    }
  }

  @override
  Widget build(BuildContext context) {
    _t = Translations.of(context);
    if (!widget.isOpen && _controller.status == AnimationStatus.dismissed) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Positioned(
          right: 24,
          top: 24,
          bottom: 24,
          child: Transform.translate(
            offset: Offset(
              (1 - _slideAnimation.value) * (CiciDesignTokens.panelWidth + 24),
              0,
            ),
            child: Opacity(opacity: _fadeAnimation.value, child: child!),
          ),
        );
      },
      child: Container(
        width: CiciDesignTokens.panelWidth,
        decoration: BoxDecoration(
          color: CiciDesignTokens.getColor(
            context,
            CiciDesignTokens.pageBg,
            CiciDesignTokens.darkPageBg,
          ),
          borderRadius: BorderRadius.circular(CiciDesignTokens.radiusXl),
          boxShadow: [
            BoxShadow(
              color: const Color.fromRGBO(0, 0, 0, 0.25),
              blurRadius: 32,
              offset: const Offset(-12, 0),
            ),
            if (Theme.of(context).brightness == Brightness.dark)
              BoxShadow(
                color: const Color.fromRGBO(255, 255, 255, 0.1),
                blurRadius: 0,
                spreadRadius: 1,
              ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(CiciDesignTokens.radiusXl),
          child: Column(
            children: [
              _buildHeaderSection(),
              Expanded(child: _buildChatCard(context)),
              _buildInputSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          top: 37,
          right: -30,
          child: Opacity(
            opacity: 0.8,
            child: SvgPicture.asset(
              'assets/svg/cici-bg-bubbles.svg',
              width: 240,
            ),
          ),
        ),
        Positioned(
          top: 8,
          right: 16,
          child: Tooltip(
            message: _t!.ai_newSession,
            child: GestureDetector(
              onTap: _handleNewSession,
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: SizedBox(
                  width: 19,
                  height: 19,
                  // padding: const EdgeInsets.all(2),
                  child: Image.asset(
                    Theme.of(context).brightness == Brightness.light
                        ? 'assets/images/ai-assistant-panel/new_session_light.png'
                        : 'assets/images/ai-assistant-panel/new_session_dark.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(20, 32, 20, 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          _t!.ai_ciciGreeting,
                          style: TextStyle(
                            fontSize: CiciDesignTokens.fontSizeH1,
                            fontWeight: CiciDesignTokens.fontWeightBold,
                            color: CiciDesignTokens.getColor(
                              context,
                              CiciDesignTokens.text,
                              CiciDesignTokens.darkText,
                            ),
                          ),
                        ),
                        const SizedBox(width: CiciDesignTokens.spaceMd),
                        const CiciAITag(),
                      ],
                    ),
                    const SizedBox(height: CiciDesignTokens.spaceMd),
                    Text(
                      _t!.ai_ciciSubtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: CiciDesignTokens.getColor(
                          context,
                          CiciDesignTokens.gray,
                          CiciDesignTokens.darkGray,
                        ),
                      ),
                    ),
                    const SizedBox(height: CiciDesignTokens.spaceMd),
                    CiciQuickActionRow(
                      actions: [
                        CiciQuickActionData(
                          label: _t!.ai_quickActionSearch,
                          iconPath: 'assets/svg/search.svg',
                          onTap: () => _handleQuickAction('search'),
                        ),
                        CiciQuickActionData(
                          label: _t!.ai_quickActionSummarize,
                          iconPath: 'assets/svg/lightbulb.svg',
                          onTap: () => _handleQuickAction('summarize'),
                        ),
                        CiciQuickActionData(
                          label: _t!.ai_quickActionQa,
                          iconPath: 'assets/svg/chat.svg',
                          onTap: () => _handleQuickAction('qa'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Transform.translate(
                offset: const Offset(-25, 5),
                child: Image.asset(
                  'assets/images/ai-assistant-panel/cici-hero.png',
                  width: CiciDesignTokens.heroWidth,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChatCard(BuildContext context) {
    final bgColor = CiciDesignTokens.getColor(
      context,
      CiciDesignTokens.white,
      CiciDesignTokens.darkCardBg,
    );

    return Container(
      margin: const EdgeInsets.only(top: 5, left: 20, right: 20),
      padding: const EdgeInsets.only(left: 1, right: 1),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(CiciDesignTokens.radiusXl),
        boxShadow: CiciDesignTokens.getShadow(
          context,
          CiciDesignTokens.shadowCard,
          CiciDesignTokens.shadowDarkCard,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(CiciDesignTokens.radiusXl),
        child: Stack(
          children: [
            ScrollConfiguration(
              behavior: ScrollConfiguration.of(
                context,
              ).copyWith(scrollbars: false),
              child: Scrollbar(
                controller: _scrollController,
                thickness: 4,
                radius: const Radius.circular(2),
                child: ListView.builder(
                  controller: _scrollController,
                  cacheExtent: 500,
                  padding: const EdgeInsets.only(
                    top: 20,
                    bottom: 36,
                    left: 6,
                    right: 10,
                  ),
                  itemCount:
                      _normalMessages.isEmpty &&
                          _tempWidgets.isEmpty &&
                          !_hasUserInteracted
                      ? 1
                      : _normalMessages.length + _tempWidgets.length,
                  itemBuilder: (context, index) {
                    if (_normalMessages.isEmpty &&
                        _tempWidgets.isEmpty &&
                        !_hasUserInteracted) {
                      return _buildSampleConversation();
                    }

                    if (index < _normalMessages.length) {
                      final msg = _normalMessages[index];
                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: 12,
                          top: msg.messageType == CiciMessageType.user ? 16 : 0,
                        ),
                        child: _buildMessageBubble(
                          msg,
                          showStatus: msg.isReplied,
                          showUndo: _isLastUserMessage(index),
                        ),
                      );
                    } else {
                      final widgetIndex = index - _normalMessages.length;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _tempWidgets[widgetIndex],
                      );
                    }
                  },
                ),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 20,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(CiciDesignTokens.radiusXl),
                    topRight: Radius.circular(CiciDesignTokens.radiusXl),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      bgColor.withValues(alpha: 1.0),
                      bgColor.withValues(alpha: 1.0),
                      bgColor.withValues(alpha: 0.0),
                    ],
                    stops: [0.0, 0.1, 1.0],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 20,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(CiciDesignTokens.radiusXl),
                    bottomRight: Radius.circular(CiciDesignTokens.radiusXl),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      bgColor.withValues(alpha: 0.0),
                      bgColor.withValues(alpha: 1.0),
                      bgColor.withValues(alpha: 1.0),
                    ],
                    stops: [0.0, 0.9, 1.0],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSampleConversation() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CiciMessageBubble(
          type: MessageType.user,
          text: _t!.ai_sampleUserMessage1,
          time: '10:30',
          showStatus: true,
        ),
        const SizedBox(height: CiciDesignTokens.spaceLg),
        CiciMessageBubble(
          type: MessageType.assistant,
          time: '10:30',
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: _t!.ai_sampleAssistantFound),
                    TextSpan(
                      text: '1',
                      style: TextStyle(
                        color: CiciDesignTokens.primary,
                        fontWeight: CiciDesignTokens.fontWeightBold,
                      ),
                    ),
                    TextSpan(text: ' 条相关笔记：'),
                  ],
                ),
                style: TextStyle(
                  fontSize: CiciDesignTokens.fontSizeBody,
                  color: CiciDesignTokens.getColor(
                    context,
                    CiciDesignTokens.text,
                    CiciDesignTokens.darkText,
                  ),
                ),
              ),
              const SizedBox(height: CiciDesignTokens.spaceMd),
              CiciNoteCardList(
                notes: [
                  CiciNoteCardData(
                    title: _t!.ai_sampleNoteTitle,
                    description: _t!.ai_sampleNoteDesc,
                    date: '2024/04/12',
                    onTap: () {},
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: CiciDesignTokens.space2xl),
        CiciMessageBubble(
          type: MessageType.user,
          text: _t!.ai_sampleUserMessage2,
          time: '10:32',
          showStatus: true,
        ),
        const SizedBox(height: CiciDesignTokens.spaceLg),
        CiciMessageBubble(
          type: MessageType.assistant,
          time: '10:32',
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _t!.ai_sampleAssistantPrinciples,
                style: TextStyle(
                  fontSize: CiciDesignTokens.fontSizeBody,
                  color: CiciDesignTokens.getColor(
                    context,
                    CiciDesignTokens.text,
                    CiciDesignTokens.darkText,
                  ),
                ),
              ),
              const SizedBox(height: CiciDesignTokens.spaceSm),
              Padding(
                padding: const EdgeInsets.only(left: CiciDesignTokens.spaceLg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _t!.ai_samplePrinciple1,
                      style: TextStyle(
                        fontSize: CiciDesignTokens.fontSizeCaption,
                        color: CiciDesignTokens.getColor(
                          context,
                          CiciDesignTokens.text,
                          CiciDesignTokens.darkText,
                        ),
                      ),
                    ),
                    Text(
                      _t!.ai_samplePrinciple2,
                      style: TextStyle(
                        fontSize: CiciDesignTokens.fontSizeCaption,
                        color: CiciDesignTokens.getColor(
                          context,
                          CiciDesignTokens.text,
                          CiciDesignTokens.darkText,
                        ),
                      ),
                    ),
                    Text(
                      _t!.ai_samplePrinciple3,
                      style: TextStyle(
                        fontSize: CiciDesignTokens.fontSizeCaption,
                        color: CiciDesignTokens.getColor(
                          context,
                          CiciDesignTokens.text,
                          CiciDesignTokens.darkText,
                        ),
                      ),
                    ),
                    Text(
                      _t!.ai_samplePrinciple4,
                      style: TextStyle(
                        fontSize: CiciDesignTokens.fontSizeCaption,
                        color: CiciDesignTokens.getColor(
                          context,
                          CiciDesignTokens.text,
                          CiciDesignTokens.darkText,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: CiciDesignTokens.spaceMd),
              Text(
                _t!.ai_sampleAssistantConclusion,
                style: TextStyle(
                  fontSize: CiciDesignTokens.fontSizeCaption,
                  color: CiciDesignTokens.getColor(
                    context,
                    CiciDesignTokens.gray,
                    CiciDesignTokens.darkGray,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInputSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: CiciInput(
        placeholder: _t!.ai_inputPlaceholder,
        onSubmit: (text) => _handleUserMessage(text),
        onStop: _isProcessing ? _handleStop : null,
        controller: _inputController,
        focusNode: _inputFocusNode,
      ),
    );
  }

  void _handleQuickAction(String actionType) {
    if (_t == null) return;
    switch (actionType) {
      case 'search':
        _inputController.text = _t!.ai_quickActionSearchTemplate;
        _inputFocusNode.requestFocus();
        _inputController.selection = TextSelection.fromPosition(
          TextPosition(offset: _inputController.text.indexOf('「') + 1),
        );
        break;
      case 'summarize':
        if (widget.currentNote != null) {
          _handleUserMessage(
            _t!.ai_quickActionSummarizeWithNote(
              title: widget.currentNote!.title,
            ),
          );
        } else {
          _inputController.text = _t!.ai_quickActionSummarizeDefault;
          _inputFocusNode.requestFocus();
        }
        break;
      case 'qa':
        _inputController.text = _t!.ai_quickActionQaTemplate;
        _inputFocusNode.requestFocus();
        break;
    }
  }

  Future<void> _handleNewSession() async {
    if (_isProcessing) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_t!.ai_newSessionTitle),
        content: Text(_t!.ai_newSessionConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(_t!.common_cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(_t!.common_ok),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final notesProvider = context.read<NotesProvider>();
    final agent = notesProvider.ciciAgent;

    // 清空数据库中的所有历史消息
    await _persistenceService.clearAllMessages();

    // 清空 Agent 的内存历史
    agent?.clearHistory();

    if (mounted) {
      _clearChatState();
    }
  }

  Future<void> _handleUserMessage(String message) async {
    if (message.trim().isEmpty || _isProcessing) return;

    final notesProvider = context.read<NotesProvider>();

    // 检查 AI 服务是否已配置
    if (!notesProvider.hasAIConfig) {
      setState(() {
        _normalMessages.add(
          ChatMessage.system(_t?.empty_aiServiceErrorTitle ?? 'AI 服务暂时不可用'),
        );
        _normalMessages.add(
          ChatMessage.assistant(_t?.empty_aiServiceErrorDesc ?? '请稍后重试或检查AI配置'),
        );
      });
      return;
    }

    _isReactInProgress = true;

    // 重置 CancellationToken
    _cancellationToken = CancellationToken();

    final agent = notesProvider.ciciAgent;
    if (agent == null) {
      setState(() {
        _normalMessages.add(
          ChatMessage.system(_t?.empty_aiServiceErrorTitle ?? 'AI 服务暂时不可用'),
        );
        _normalMessages.add(
          ChatMessage.assistant(_t?.empty_aiServiceErrorDesc ?? '请稍后重试或检查AI配置'),
        );
      });
      return;
    }

    // 首次对话时同步历史消息到 Agent（仅此一次）
    if (!_historySyncedToAgent) {
      final historyMessages = await _persistenceService.loadRecentMessages(
        limit: 100,
        loadNote: (noteId) async => await notesProvider.getNoteById(noteId),
      );
      if (historyMessages.isNotEmpty) {
        agent.addHistoryMessages(historyMessages);
      }
      _historySyncedToAgent = true;
    }

    if (!_hasUserInteracted) {
      _hasUserInteracted = true;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kHasUserInteractedKey, true);
    }

    _inputController.clear();
    _streamingMessageId = null;
    _toolLogEntries.clear();
    _currentToolLogIndex = -1;

    // 重置智能滚动状态
    _shouldAutoScroll = true;

    // Step 1: 用户消息固化到普通列表
    final userMessage = ChatMessage.user(message);
    setState(() {
      _isProcessing = true;
      _normalMessages.add(userMessage);
    });

    // 异步保存用户消息到数据库
    agent.saveMessageToPersistence(userMessage);

    // 滚动到底部并添加监听
    _scrollToBottom();
    _attachScrollListener();

    // Step 2: 创建思考指示器（复用实例，不清空重建）
    setState(() {
      _thinkingIndicator = CiciThinkingIndicator(
        thinkingContent: '正在分析用户需求...',
      );
      _tempWidgets.clear();
      _tempWidgets.add(_thinkingIndicator!);
    });

    try {
      final response = await agent.chatStream(
        message,
        currentNote: widget.currentNote,
        cancellationToken: _cancellationToken,
        onChunk: (chunk) {
          if (_cancellationToken.isCancelled) return;
          if (mounted) {
            setState(() {
              _tempWidgets.clear();

              // 首次收到内容：创建 AI 消息
              if (_streamingMessageId == null) {
                _markUserMessageAsReplied();
                _streamingMessageId = DateTime.now().millisecondsSinceEpoch
                    .toString();
                _normalMessages.add(
                  ChatMessage(
                    id: _streamingMessageId!,
                    role: 'assistant',
                    content: chunk,
                    messageType: CiciMessageType.assistant,
                  ),
                );
              } else {
                // 更新已有的流式消息
                final idx = _normalMessages.indexWhere(
                  (m) => m.id == _streamingMessageId,
                );
                if (idx != -1) {
                  _normalMessages[idx] = ChatMessage(
                    id: _normalMessages[idx].id,
                    role: 'assistant',
                    content: chunk,
                    messageType: CiciMessageType.assistant,
                    timestamp: _normalMessages[idx].timestamp,
                  );
                }
              }
            });
            _scrollToBottom();
          }
        },
        onThinking: (thinking) {
          if (_cancellationToken.isCancelled) return;
          if (mounted) {
            setState(() {
              // 原地更新思考内容，不清空重建
              final idx = _tempWidgets.indexWhere(
                (w) => w is CiciThinkingIndicator,
              );
              if (idx != -1) {
                _thinkingIndicator = CiciThinkingIndicator(
                  thinkingContent: thinking,
                );
                _tempWidgets[idx] = _thinkingIndicator!;
              }
            });
          }
        },
        onToolUpdate: (entry) {
          if (_cancellationToken.isCancelled) return;
          if (mounted) {
            setState(() {
              // 保留思考指示器，只更新工具日志
              final thinkingWidget = _tempWidgets
                  .whereType<CiciThinkingIndicator>()
                  .firstOrNull;
              _tempWidgets.clear();

              // completed 时原地更新对应 entry 的 status/statusLabel/details，不创建新实例
              if (entry.status == ToolStatus.completed) {
                // 检测 note_open 工具完成，立即打开笔记
                if (entry.toolName == 'note_open' && entry.resultData != null) {
                  final targetNote = entry.resultData!['data'] as Note?;
                  if (targetNote != null) {
                    // 立即打开笔记并关闭面板
                    widget.onNoteTap?.call(targetNote);
                    widget.onClose?.call();
                  }
                }

                final existingIdx = _toolLogEntries.lastIndexWhere(
                  (e) =>
                      e.toolName == entry.toolName &&
                      e.status == ToolStatus.calling,
                );
                if (existingIdx != -1) {
                  _toolLogEntries[existingIdx].status = ToolStatus.completed;
                  _toolLogEntries[existingIdx].statusLabel = entry.statusLabel;
                  // 保留原有的 details，不覆盖
                } else {
                  _toolLogEntries.add(entry);
                }
              } else {
                _toolLogEntries.add(entry);
              }

              final toolMsg = ChatMessage.toolExecution(
                entries: List.from(_toolLogEntries),
              );

              // 检查当前消息是否已固化，固化后不允许更新
              if (_currentToolLogIndex != -1 &&
                  _currentToolLogIndex < _normalMessages.length) {
                if (!_normalMessages[_currentToolLogIndex].isFrozen) {
                  _normalMessages[_currentToolLogIndex] = toolMsg;
                }
              } else {
                _normalMessages.add(toolMsg);
                _currentToolLogIndex = _normalMessages.length - 1;
              }

              // 重新添加思考指示器
              if (thinkingWidget != null) {
                _tempWidgets.add(thinkingWidget);
              }
            });
            _scrollToBottom();
          }
        },
      );

      // 检查是否被中断
      if (response.isCancelled) {
        if (mounted) {
          _handleStopUIUpdate();
        }
        return;
      }

      if (mounted) {
        setState(() {
          _tempWidgets.clear();

          // 清理残留的工具条目（异常情况），完成后固化
          if (_toolLogEntries.isNotEmpty &&
              _currentToolLogIndex != -1 &&
              _currentToolLogIndex < _normalMessages.length) {
            final msg = _normalMessages[_currentToolLogIndex];
            if (msg.toolExecutions?.isNotEmpty == true) {
              for (var e in msg.toolExecutions!) {
                if (e.status == ToolStatus.calling) {
                  e.status = ToolStatus.completed;
                  e.statusLabel = '已调用';
                }
                // ReAct 结束后折叠工具日志
                e.isExpanded = false;
              }
              final toolMsg = _normalMessages[_currentToolLogIndex].copyWith(
                isFrozen: true,
              );
              _normalMessages[_currentToolLogIndex] = toolMsg;

              // 异步保存工具执行消息到数据库
              agent.saveMessageToPersistence(toolMsg);
            }
            _currentToolLogIndex = -1;
          }

          // TODO: 后续根据知识库启用状态决定是否显示降级提示
          // 目前文本搜索是正常功能，不需要提示"知识库未启用"
          // if (response.searchMode == 'text') {
          //   final insertIdx = _streamingMessageId != null
          //       ? _normalMessages.indexWhere((m) => m.id == _streamingMessageId)
          //       : _normalMessages.length;
          //   _normalMessages.insert(
          //     insertIdx >= 0 ? insertIdx : _normalMessages.length,
          //     ChatMessage.system('⚠️ 知识库未启用，使用普通文本搜索模式'),
          //   );
          // }

          // 最终化流式消息，完成后固化
          if (_streamingMessageId != null) {
            final idx = _normalMessages.indexWhere(
              (m) => m.id == _streamingMessageId,
            );
            if (idx != -1) {
              final frozenMessage = ChatMessage(
                id: _normalMessages[idx].id,
                role: 'assistant',
                content: response.text,
                messageType: CiciMessageType.assistant,
                timestamp: _normalMessages[idx].timestamp,
                referencedNotes: response.referencedNotes,
                toolCalls: response.toolCalls,
                searchMode: response.searchMode,
                isFrozen: true,
              );
              _normalMessages[idx] = frozenMessage;

              // 异步保存助手消息到数据库
              agent.saveMessageToPersistence(frozenMessage);
            }
          } else if (response.text.isNotEmpty ||
              response.referencedNotes.isNotEmpty) {
            // 没有流式内容但有最终结果（异常情况）
            _normalMessages.add(
              ChatMessage(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                role: 'assistant',
                content: response.text,
                messageType: CiciMessageType.assistant,
                referencedNotes: response.referencedNotes,
                toolCalls: response.toolCalls,
                searchMode: response.searchMode,
              ),
            );
          }

          _isProcessing = false;
          _isReactInProgress = false;
          _streamingMessageId = null;
        });

        _scrollToBottom();
        _detachScrollListener();
      }
    } catch (e) {
      // 如果是中断导致的异常，不显示错误
      if (_cancellationToken.isCancelled) {
        if (mounted) {
          _handleStopUIUpdate();
        }
        return;
      }

      if (mounted) {
        setState(() {
          _tempWidgets.clear();
          _normalMessages.add(ChatMessage.error('AI 回复失败：$e'));
          _isProcessing = false;
          _isReactInProgress = false;
          _streamingMessageId = null;
        });
        _detachScrollListener();
      }
    }
  }

  void _handleStop() {
    if (!_isProcessing) return;

    // 取消 CancellationToken
    _cancellationToken.cancel();

    // 更新 UI
    _handleStopUIUpdate();
  }

  void _handleStopUIUpdate() {
    // 防止重复调用
    if (!_isProcessing && !_isReactInProgress) return;

    setState(() {
      // 添加中断记录而不是修改现有状态
      if (_toolLogEntries.isNotEmpty) {
        // 更新最后一条 calling 状态的记录为"调用中断"
        final lastIndex = _toolLogEntries.length - 1;
        if (_toolLogEntries[lastIndex].status == ToolStatus.calling) {
          _toolLogEntries[lastIndex].status = ToolStatus.failed;
          _toolLogEntries[lastIndex].statusLabel = '调用中断';
        }

        // 添加一条新的中断记录
        _toolLogEntries.add(
          ToolExecutionEntry(
            toolId: 'cancel_${DateTime.now().millisecondsSinceEpoch}',
            toolName: 'system',
            icon: '⛔',
            status: ToolStatus.cancelled,
            statusLabel: '已中断执行',
          ),
        );

        // 折叠所有条目
        for (var e in _toolLogEntries) {
          e.isExpanded = false;
        }

        // 如果消息未固化，更新并固化
        if (_currentToolLogIndex != -1 &&
            _currentToolLogIndex < _normalMessages.length) {
          if (!_normalMessages[_currentToolLogIndex].isFrozen) {
            final existingMsg = _normalMessages[_currentToolLogIndex];
            final updatedMsg = ChatMessage(
              id: existingMsg.id,
              role: existingMsg.role,
              content: existingMsg.content,
              timestamp: existingMsg.timestamp,
              messageType: CiciMessageType.toolExecution,
              toolExecutions: List.from(_toolLogEntries),
              isFrozen: true,
            );
            _normalMessages[_currentToolLogIndex] = updatedMsg;
            final notesProvider = context.read<NotesProvider>();
            notesProvider.ciciAgent?.saveMessageToPersistence(updatedMsg);
          }
        } else {
          // _currentToolLogIndex == -1，创建新消息并固化
          final toolMsg = ChatMessage.toolExecution(
            entries: List.from(_toolLogEntries),
          ).copyWith(isFrozen: true);
          _normalMessages.add(toolMsg);
          final notesProvider = context.read<NotesProvider>();
          notesProvider.ciciAgent?.saveMessageToPersistence(toolMsg);
        }

        _currentToolLogIndex = -1;
      }

      // 移除思考指示器
      _tempWidgets.clear();

      // 添加或更新中断提示
      if (_streamingMessageId == null) {
        _normalMessages.add(ChatMessage.system('操作已被用户中断'));
      } else {
        final idx = _normalMessages.indexWhere(
          (m) => m.id == _streamingMessageId,
        );
        if (idx != -1) {
          _normalMessages[idx] = ChatMessage(
            id: _normalMessages[idx].id,
            role: 'assistant',
            content: '操作已被用户中断',
            messageType: CiciMessageType.assistant,
            timestamp: _normalMessages[idx].timestamp,
            isFrozen: true,
          );
        }
      }

      _isProcessing = false;
      _isReactInProgress = false;
      _streamingMessageId = null;
    });

    _detachScrollListener();

    // 同步中断消息和工具日志到历史记录
    final notesProvider = context.read<NotesProvider>();
    notesProvider.ciciAgent?.addSystemMessage('操作已被用户中断');
    if (_toolLogEntries.isNotEmpty) {
      notesProvider.ciciAgent?.addToolExecution(List.from(_toolLogEntries));
    }

    // 重置 token 供下次使用
    _cancellationToken = CancellationToken();
  }

  void _scrollToBottom() {
    if (!_shouldAutoScroll) return;

    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients && mounted) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _tryScrollToBottom() {
    if (!mounted || !_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 50), () {
        if (mounted) _tryScrollToBottom();
      });
      return;
    }
    _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  Widget _buildMessageBubble(
    ChatMessage msg, {
    bool showStatus = false,
    bool showUndo = false,
  }) {
    switch (msg.messageType) {
      case CiciMessageType.system:
        return CiciSystemMessage(message: msg.content);

      case CiciMessageType.toolExecution:
        if (msg.toolExecutions == null || msg.toolExecutions!.isEmpty) {
          return const SizedBox.shrink();
        }
        final stats = CiciToolExecutionLog.generateCategoryStats(
          msg.toolExecutions!,
        );
        return CiciToolExecutionLog(
          entries: msg.toolExecutions!,
          categoryStats: stats,
          isProcessing: !msg.isFrozen && _isReactInProgress,
          initialExpanded: !msg.isFrozen && _isReactInProgress,
        );

      case CiciMessageType.user:
        return CiciMessageBubble(
          type: MessageType.user,
          text: msg.content,
          copyableText: msg.content,
          time: _formatMessageTime(msg.timestamp),
          showStatus: showStatus,
          showUndo: showUndo,
          onUndo: showUndo ? _revokeLastUserMessage : null,
        );

      case CiciMessageType.assistant:
        return _buildAssistantBubble(msg);
    }
  }

  Widget _buildAssistantBubble(ChatMessage msg) {
    final hasNotes = msg.referencedNotes.isNotEmpty;

    Widget? contentWidget;
    if (hasNotes) {
      contentWidget = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (msg.content.isNotEmpty)
            CiciMessageBubble.buildMarkdown(context, msg.content),
          if (msg.content.isNotEmpty)
            const SizedBox(height: CiciDesignTokens.spaceMd),
          CiciNoteCardList(
            notes: msg.referencedNotes
                .map(
                  (note) => CiciNoteCardData(
                    title: note.title,
                    description:
                        note.summary ??
                        (note.content.length > 100
                            ? '${note.content.substring(0, 100)}...'
                            : note.content),
                    date: _formatDate(note.updatedAt),
                    onTap: widget.onNoteTap != null
                        ? () => widget.onNoteTap!(note)
                        : null,
                  ),
                )
                .toList(),
          ),
        ],
      );
    }

    return CiciMessageBubble(
      type: MessageType.assistant,
      text: hasNotes ? null : msg.content,
      copyableText: msg.content,
      content: contentWidget,
      time: _formatMessageTime(msg.timestamp),
      showStatus: true,
    );
  }

  String _formatMessageTime(DateTime timestamp) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final msgDate = DateTime(timestamp.year, timestamp.month, timestamp.day);
    final diffDays = today.difference(msgDate).inDays;
    final timeStr =
        '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';

    if (diffDays == 0) {
      return timeStr;
    } else if (diffDays == 1) {
      return '${_t!.search_yesterday} $timeStr';
    } else if (diffDays < 7) {
      return '${_t!.search_daysAgo(count: diffDays)} $timeStr';
    } else {
      return '${timestamp.month.toString().padLeft(2, '0')}/${timestamp.day.toString().padLeft(2, '0')} $timeStr';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
  }
}
