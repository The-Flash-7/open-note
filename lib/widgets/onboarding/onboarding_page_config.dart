// Copyright (c) 2026 litongshuai
// SPDX-License-Identifier: MIT OR Apache-2.0

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../l10n/strings.g.dart';
import '../../providers/settings_provider.dart';
import '../../models/ai_provider_config.dart';
import '../../theme/design_tokens.dart';

enum _ButtonState { testConnection, testing, retry, complete }

class OnboardingPageConfig extends StatefulWidget {
  final AIProviderTemplate? template;
  final VoidCallback onComplete;
  final VoidCallback onSkip;

  const OnboardingPageConfig({
    super.key,
    required this.template,
    required this.onComplete,
    required this.onSkip,
  });

  @override
  State<OnboardingPageConfig> createState() => _OnboardingPageConfigState();
}

class _OnboardingPageConfigState extends State<OnboardingPageConfig> {
  final TextEditingController _apiKeyController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _baseUrlController = TextEditingController();
  final TextEditingController _modelInputController = TextEditingController();
  bool _obscureText = true;
  bool _isLoading = false;
  bool _isTesting = false;
  String? _testMessage;
  bool _testSuccess = false;
  _ButtonState _buttonState = _ButtonState.testConnection;
  final List<String> _customModels = [];
  String? _selectedDefaultModel;

  @override
  void dispose() {
    _apiKeyController.dispose();
    _nameController.dispose();
    _baseUrlController.dispose();
    _modelInputController.dispose();
    super.dispose();
  }

  String _getProviderUrl(String name) {
    switch (name) {
      case 'DeepSeek':
        return 'https://platform.deepseek.com/';
      case 'OpenAI':
        return 'https://platform.openai.com/api-keys';
      case '阿里云百炼Token Plan':
      case '阿里云百炼Coding Plan':
        return 'https://bailian.console.aliyun.com/';
      case '火山方舟Coding Plan':
        return 'https://www.volcengine.com/activity/codingplan';
      case '火山豆包':
        return 'https://www.volcengine.com/product/doubao';
      case 'Claude':
        return 'https://console.anthropic.com/';
      case '智谱GLM Coding Plan':
        return 'https://bigmodel.cn/glm-coding';
      case '智谱GLM':
        return 'https://open.bigmodel.cn/';
      case '腾讯混元':
        return 'https://cloud.tencent.com/product/tokenhub';
      case '百度千帆':
        return 'https://cloud.baidu.com/product-s/qianfan_home';
      case 'Moonshot':
        return 'https://platform.moonshot.cn/';
      default:
        return '';
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _handleTestConnection() async {
    if (widget.template == null) {
      setState(() {
        _testMessage = t.onboarding_errorSelectVendorFirst;
        _testSuccess = false;
        _buttonState = _ButtonState.testConnection;
      });
      return;
    }

    if (_apiKeyController.text.isEmpty) {
      setState(() {
        _testMessage = t.onboarding_errorEnterApiKey;
        _testSuccess = false;
        _buttonState = _ButtonState.testConnection;
      });
      return;
    }

    final template = widget.template!;
    final isCustomTemplate =
        template.baseUrl.isEmpty && template.models.isEmpty;

    AIProviderTemplate effectiveTemplate;

    if (isCustomTemplate) {
      if (_nameController.text.isEmpty) {
        setState(() {
          _testMessage = t.onboarding_errorEnterVendorName;
          _testSuccess = false;
          _buttonState = _ButtonState.testConnection;
        });
        return;
      }

      if (_baseUrlController.text.isEmpty) {
        setState(() {
          _testMessage = t.onboarding_errorEnterApiUrl;
          _testSuccess = false;
          _buttonState = _ButtonState.testConnection;
        });
        return;
      }

      if (_customModels.isEmpty) {
        setState(() {
          _testMessage = t.onboarding_errorAddModel;
          _testSuccess = false;
          _buttonState = _ButtonState.testConnection;
        });
        return;
      }

      effectiveTemplate = AIProviderTemplate(
        name: _nameController.text,
        displayName: _nameController.text,
        baseUrl: _baseUrlController.text,
        models: _customModels,
        defaultModel: _selectedDefaultModel ?? _customModels.first,
        description: t.onboarding_configCustomTitle,
      );
    } else {
      effectiveTemplate = template;
    }

    final tempConfig = effectiveTemplate.toConfig(
      id: 'test_${DateTime.now().millisecondsSinceEpoch}',
      apiKey: _apiKeyController.text,
    );

    setState(() {
      _isTesting = true;
      _testMessage = null;
      _testSuccess = false;
      _buttonState = _ButtonState.testing;
    });

    try {
      final settingsProvider = context.read<SettingsProvider>();
      final success = await settingsProvider.testConnection(tempConfig);

      if (!mounted) return;

      setState(() {
        _isTesting = false;
        _testSuccess = success;
        _testMessage = success
            ? t.onboarding_connectionSuccess
            : (settingsProvider.errorMessage ?? t.onboarding_connectionFailed);
        _buttonState = success ? _ButtonState.complete : _ButtonState.retry;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isTesting = false;
          _testSuccess = false;
          _testMessage = t.onboarding_testException(error: e);
          _buttonState = _ButtonState.retry;
        });
      }
    }
  }

  Future<void> _handleCompleteConfig() async {
    final template = widget.template!;
    final isCustomTemplate =
        template.baseUrl.isEmpty && template.models.isEmpty;

    AIProviderTemplate effectiveTemplate;

    if (isCustomTemplate) {
      effectiveTemplate = AIProviderTemplate(
        name: _nameController.text,
        displayName: _nameController.text,
        baseUrl: _baseUrlController.text,
        models: _customModels,
        defaultModel: _selectedDefaultModel ?? _customModels.first,
        description: t.onboarding_configCustomTitle,
      );
    } else {
      effectiveTemplate = template;
    }

    setState(() => _isLoading = true);

    try {
      final settingsProvider = context.read<SettingsProvider>();
      await settingsProvider.createProviderFromTemplate(
        effectiveTemplate,
        _apiKeyController.text,
        true,
      );
      await settingsProvider.setOnboardingShown();
      widget.onComplete();
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _testSuccess = false;
          _testMessage = t.onboarding_saveConfigFailed(error: e);
          _buttonState = _ButtonState.retry;
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null) {
      _apiKeyController.text = data!.text!;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (widget.template == null) {
      return _buildNullTemplateHint(isDark);
    }

    final template = widget.template!;
    final isCustomTemplate =
        template.baseUrl.isEmpty && template.models.isEmpty;
    final providerUrl = isCustomTemplate ? '' : _getProviderUrl(template.name);

    return Padding(
      padding: EdgeInsets.all(DesignTokens.space16),
      child: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: DesignTokens.space24),
            Text(
              isCustomTemplate
                  ? t.onboarding_configCustomTitle
                  : t.onboarding_configProviderTitle(
                      providerName: template.displayName,
                    ),
              style: TextStyle(
                fontSize: DesignTokens.fontSizeH1,
                fontWeight: DesignTokens.fontWeightBold,
                color: isDark
                    ? DesignTokens.darkTextPrimary
                    : DesignTokens.gray900,
              ),
            ),
            SizedBox(height: DesignTokens.space8),
            Text(
              isCustomTemplate
                  ? t.onboarding_customConfigSubtitle
                  : t.onboarding_providerConfigSubtitle,
              style: TextStyle(
                fontSize: DesignTokens.fontSizeBody,
                color: isDark
                    ? DesignTokens.darkTextSecondary
                    : DesignTokens.gray500,
              ),
            ),
            SizedBox(height: DesignTokens.space24),
            if (isCustomTemplate) ...[
              _buildCustomProviderNameInput(isDark),
              SizedBox(height: DesignTokens.space12),
              _buildCustomBaseUrlInput(isDark),
              SizedBox(height: DesignTokens.space12),
              _buildCustomModelsInput(isDark),
              SizedBox(height: DesignTokens.space12),
            ] else ...[
              _buildInfoCard(isDark),
              SizedBox(height: DesignTokens.space16),
            ],
            _buildApiKeyInput(isDark),

            if (_testMessage != null) ...[
              SizedBox(height: DesignTokens.space12),
              Container(
                padding: EdgeInsets.all(DesignTokens.space12),
                decoration: BoxDecoration(
                  color: _testSuccess
                      ? (isDark
                            ? DesignTokens.darkSuccessBackground
                            : DesignTokens.successBackground)
                      : (isDark
                            ? DesignTokens.darkErrorBackground
                            : DesignTokens.errorBackground),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusMD),
                  border: Border.all(
                    color: _testSuccess
                        ? DesignTokens.success500
                        : DesignTokens.error500,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _testSuccess ? Icons.check_circle : Icons.error,
                      size: DesignTokens.iconSizeStandard,
                      color: _testSuccess
                          ? DesignTokens.success500
                          : DesignTokens.error500,
                    ),
                    SizedBox(width: DesignTokens.space8),
                    Expanded(
                      child: Text(
                        _testMessage!,
                        style: TextStyle(
                          fontSize: DesignTokens.fontSizeBody,
                          color: _testSuccess
                              ? DesignTokens.success700
                              : DesignTokens.error700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            if (!isCustomTemplate && providerUrl.isNotEmpty) ...[
              SizedBox(height: DesignTokens.space12),
              _buildProviderLink(providerUrl, isDark),
            ],

            SizedBox(height: DesignTokens.space24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (_isTesting || _isLoading)
                    ? null
                    : (_buttonState == _ButtonState.complete
                          ? _handleCompleteConfig
                          : _handleTestConnection),
                style: ElevatedButton.styleFrom(
                  backgroundColor: DesignTokens.primary500,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: isDark
                      ? DesignTokens.darkBorder
                      : DesignTokens.gray300,
                  padding: EdgeInsets.symmetric(vertical: DesignTokens.space12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(DesignTokens.radiusMD),
                  ),
                ),
                child: _isTesting
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          ),
                          SizedBox(width: DesignTokens.space8),
                          Text(t.onboarding_testingConnection),
                        ],
                      )
                    : _isLoading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : Text(
                        _buttonState == _ButtonState.testConnection
                            ? t.onboarding_testConnection
                            : _buttonState == _ButtonState.retry
                            ? t.common_retry
                            : t.onboarding_completeConfig,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNullTemplateHint(bool isDark) {
    return Padding(
      padding: EdgeInsets.all(DesignTokens.space16),
      child: Column(
        children: [
          Spacer(),
          Icon(Icons.info_outline, size: 48, color: DesignTokens.gray400),
          SizedBox(height: DesignTokens.space8),
          Text(
            t.onboarding_noProviderSelected,
            style: TextStyle(
              fontSize: DesignTokens.fontSizeH3,
              fontWeight: DesignTokens.fontWeightSemiBold,
              color: isDark
                  ? DesignTokens.darkTextPrimary
                  : DesignTokens.gray900,
            ),
          ),
          SizedBox(height: DesignTokens.space4),
          Text(
            t.onboarding_returnToSelectProvider,
            style: TextStyle(
              fontSize: DesignTokens.fontSizeBody,
              color: isDark
                  ? DesignTokens.darkTextSecondary
                  : DesignTokens.gray500,
            ),
          ),
          Spacer(),
        ],
      ),
    );
  }

  Widget _buildInfoCard(bool isDark) {
    final template = widget.template!;

    return Container(
      padding: EdgeInsets.all(DesignTokens.space12),
      decoration: BoxDecoration(
        color: isDark ? DesignTokens.darkSurface : DesignTokens.gray50,
        borderRadius: BorderRadius.circular(DesignTokens.radiusLG),
        border: Border.all(
          color: isDark ? DesignTokens.darkBorder : DesignTokens.gray200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow(t.onboarding_vendorLabel, template.displayName, isDark),
          SizedBox(height: DesignTokens.space6),
          _buildInfoRow('API地址', template.baseUrl, isDark),
          if (template.models.isNotEmpty) ...[
            SizedBox(height: DesignTokens.space6),
            _buildInfoRow(
              t.onboarding_presetModelsLabel,
              template.models.take(3).join(', ') +
                  (template.models.length > 3 ? '...' : ''),
              isDark,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 70,
          child: Text(
            label,
            style: TextStyle(
              fontSize: DesignTokens.fontSizeSmall,
              color: isDark
                  ? DesignTokens.darkTextSecondary
                  : DesignTokens.gray500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: DesignTokens.fontSizeSmall,
              color: isDark
                  ? DesignTokens.darkTextPrimary
                  : DesignTokens.gray900,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildApiKeyInput(bool isDark) {
    final isReadOnly = _buttonState == _ButtonState.complete;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t.onboarding_apiKeyLabel,
          style: TextStyle(
            fontSize: DesignTokens.fontSizeBody,
            fontWeight: DesignTokens.fontWeightMedium,
            color: isDark ? DesignTokens.darkTextPrimary : DesignTokens.gray900,
          ),
        ),
        SizedBox(height: DesignTokens.space6),
        TextField(
          controller: _apiKeyController,
          obscureText: _obscureText,
          enabled: !isReadOnly,
          decoration: InputDecoration(
            hintText: isReadOnly
                ? t.onboarding_apiKeyVerifiedHint
                : t.onboarding_apiKeyHint,
            hintStyle: TextStyle(
              color: isDark
                  ? DesignTokens.darkTextSecondary
                  : DesignTokens.gray400,
            ),
            filled: true,
            fillColor: isReadOnly
                ? (isDark
                      ? DesignTokens.darkSurface.withValues(alpha: 0.5)
                      : DesignTokens.gray100)
                : (isDark ? DesignTokens.darkSurface : Colors.white),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DesignTokens.radiusMD),
              borderSide: BorderSide(
                color: isDark ? DesignTokens.darkBorder : DesignTokens.gray300,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DesignTokens.radiusMD),
              borderSide: BorderSide(
                color: isDark ? DesignTokens.darkBorder : DesignTokens.gray300,
              ),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DesignTokens.radiusMD),
              borderSide: BorderSide(
                color: isDark ? DesignTokens.darkBorder : DesignTokens.gray300,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DesignTokens.radiusMD),
              borderSide: BorderSide(color: DesignTokens.primary500, width: 2),
            ),
            suffixIcon: isReadOnly
                ? Icon(
                    Icons.lock,
                    size: DesignTokens.iconSizeStandard,
                    color: DesignTokens.gray400,
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          _obscureText
                              ? Icons.visibility
                              : Icons.visibility_off,
                          size: DesignTokens.iconSizeStandard,
                          color: isDark
                              ? DesignTokens.darkTextSecondary
                              : DesignTokens.gray500,
                        ),
                        onPressed: () {
                          setState(() => _obscureText = !_obscureText);
                        },
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.paste,
                          size: DesignTokens.iconSizeStandard,
                          color: isDark
                              ? DesignTokens.darkTextSecondary
                              : DesignTokens.gray500,
                        ),
                        onPressed: _pasteFromClipboard,
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildProviderLink(String url, bool isDark) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => _launchUrl(url),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.open_in_new,
              size: DesignTokens.iconSizeSmall,
              color: DesignTokens.primary500,
            ),
            SizedBox(width: DesignTokens.space4),
            Text(
              t.onboarding_getApiKey,
              style: TextStyle(
                fontSize: DesignTokens.fontSizeSmall,
                color: DesignTokens.primary500,
                decoration: TextDecoration.underline,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomProviderNameInput(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t.onboarding_vendorNameLabel,
          style: TextStyle(
            fontSize: DesignTokens.fontSizeBody,
            fontWeight: DesignTokens.fontWeightMedium,
            color: isDark ? DesignTokens.darkTextPrimary : DesignTokens.gray900,
          ),
        ),
        SizedBox(height: DesignTokens.space6),
        TextField(
          controller: _nameController,
          decoration: InputDecoration(
            hintText: t.onboarding_vendorNameHint,
            hintStyle: TextStyle(
              color: isDark
                  ? DesignTokens.darkTextSecondary
                  : DesignTokens.gray400,
            ),
            filled: true,
            fillColor: isDark ? DesignTokens.darkSurface : Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DesignTokens.radiusMD),
              borderSide: BorderSide(
                color: isDark ? DesignTokens.darkBorder : DesignTokens.gray300,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DesignTokens.radiusMD),
              borderSide: BorderSide(
                color: isDark ? DesignTokens.darkBorder : DesignTokens.gray300,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DesignTokens.radiusMD),
              borderSide: BorderSide(color: DesignTokens.primary500, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCustomBaseUrlInput(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t.onboarding_apiUrlLabel,
          style: TextStyle(
            fontSize: DesignTokens.fontSizeBody,
            fontWeight: DesignTokens.fontWeightMedium,
            color: isDark ? DesignTokens.darkTextPrimary : DesignTokens.gray900,
          ),
        ),
        SizedBox(height: DesignTokens.space6),
        TextField(
          controller: _baseUrlController,
          decoration: InputDecoration(
            hintText: t.onboarding_apiUrlInputHint,
            hintStyle: TextStyle(
              color: isDark
                  ? DesignTokens.darkTextSecondary
                  : DesignTokens.gray400,
            ),
            filled: true,
            fillColor: isDark ? DesignTokens.darkSurface : Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DesignTokens.radiusMD),
              borderSide: BorderSide(
                color: isDark ? DesignTokens.darkBorder : DesignTokens.gray300,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DesignTokens.radiusMD),
              borderSide: BorderSide(
                color: isDark ? DesignTokens.darkBorder : DesignTokens.gray300,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DesignTokens.radiusMD),
              borderSide: BorderSide(color: DesignTokens.primary500, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCustomModelsInput(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t.onboarding_modelListLabel,
          style: TextStyle(
            fontSize: DesignTokens.fontSizeBody,
            fontWeight: DesignTokens.fontWeightMedium,
            color: isDark ? DesignTokens.darkTextPrimary : DesignTokens.gray900,
          ),
        ),
        SizedBox(height: DesignTokens.space6),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _modelInputController,
                decoration: InputDecoration(
                  hintText: t.onboarding_modelInputHint,
                  hintStyle: TextStyle(
                    color: isDark
                        ? DesignTokens.darkTextSecondary
                        : DesignTokens.gray400,
                  ),
                  filled: true,
                  fillColor: isDark ? DesignTokens.darkSurface : Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(DesignTokens.radiusMD),
                    borderSide: BorderSide(
                      color: isDark
                          ? DesignTokens.darkBorder
                          : DesignTokens.gray300,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(DesignTokens.radiusMD),
                    borderSide: BorderSide(
                      color: isDark
                          ? DesignTokens.darkBorder
                          : DesignTokens.gray300,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(DesignTokens.radiusMD),
                    borderSide: BorderSide(
                      color: DesignTokens.primary500,
                      width: 2,
                    ),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: DesignTokens.space12,
                    vertical: DesignTokens.space8,
                  ),
                ),
                onSubmitted: (_) => _addModel(),
              ),
            ),
            SizedBox(width: DesignTokens.space8),
            ElevatedButton(
              onPressed: _addModel,
              style: ElevatedButton.styleFrom(
                backgroundColor: DesignTokens.primary500,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: DesignTokens.space12,
                  vertical: DesignTokens.space8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(DesignTokens.radiusMD),
                ),
              ),
              child: Text(t.onboarding_addModel),
            ),
          ],
        ),
        if (_customModels.isNotEmpty) ...[
          SizedBox(height: DesignTokens.space8),
          Container(
            constraints: BoxConstraints(maxHeight: 120),
            decoration: BoxDecoration(
              color: isDark ? DesignTokens.darkSurface : DesignTokens.gray50,
              borderRadius: BorderRadius.circular(DesignTokens.radiusMD),
              border: Border.all(
                color: isDark ? DesignTokens.darkBorder : DesignTokens.gray200,
              ),
            ),
            child: ListView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.all(DesignTokens.space8),
              itemCount: _customModels.length,
              itemBuilder: (context, index) {
                final model = _customModels[index];
                return Container(
                  margin: EdgeInsets.only(bottom: DesignTokens.space4),
                  padding: EdgeInsets.symmetric(
                    horizontal: DesignTokens.space8,
                    vertical: DesignTokens.space6,
                  ),
                  decoration: BoxDecoration(
                    color: isDark ? DesignTokens.darkBackground : Colors.white,
                    borderRadius: BorderRadius.circular(DesignTokens.radiusSM),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          model,
                          style: TextStyle(
                            fontSize: DesignTokens.fontSizeSmall,
                            color: isDark
                                ? DesignTokens.darkTextPrimary
                                : DesignTokens.gray900,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () => _removeModel(index),
                        child: Icon(
                          Icons.close,
                          size: 16,
                          color: isDark
                              ? DesignTokens.darkTextSecondary
                              : DesignTokens.gray500,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          SizedBox(height: DesignTokens.space12),
          Text(
            t.onboarding_defaultModelLabel,
            style: TextStyle(
              fontSize: DesignTokens.fontSizeBody,
              fontWeight: DesignTokens.fontWeightMedium,
              color: isDark
                  ? DesignTokens.darkTextPrimary
                  : DesignTokens.gray900,
            ),
          ),
          SizedBox(height: DesignTokens.space6),
          Container(
            padding: EdgeInsets.symmetric(horizontal: DesignTokens.space12),
            decoration: BoxDecoration(
              color: isDark ? DesignTokens.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(DesignTokens.radiusMD),
              border: Border.all(
                color: isDark ? DesignTokens.darkBorder : DesignTokens.gray300,
              ),
            ),
            child: DropdownButton<String>(
              value: _selectedDefaultModel,
              isExpanded: true,
              hint: Text(
                t.onboarding_selectDefaultModel,
                style: TextStyle(
                  color: isDark
                      ? DesignTokens.darkTextSecondary
                      : DesignTokens.gray400,
                ),
              ),
              underline: SizedBox(),
              items: _customModels.map((model) {
                return DropdownMenuItem(value: model, child: Text(model));
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedDefaultModel = value);
              },
            ),
          ),
        ],
      ],
    );
  }

  void _addModel() {
    final model = _modelInputController.text.trim();
    if (model.isNotEmpty && !_customModels.contains(model)) {
      setState(() {
        _customModels.add(model);
        _modelInputController.clear();
        _selectedDefaultModel ??= model;
      });
    }
  }

  void _removeModel(int index) {
    setState(() {
      final removed = _customModels.removeAt(index);
      if (_selectedDefaultModel == removed) {
        _selectedDefaultModel = _customModels.isNotEmpty
            ? _customModels.first
            : null;
      }
    });
  }
}
