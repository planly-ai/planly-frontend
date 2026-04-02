import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:planly_ai/app/constants/app_constants.dart';
import 'package:planly_ai/app/utils/responsive_utils.dart';

/// FORM 卡片数据模型
class FormOption {
  final String label;
  final String value;
  final String? color;
  final String? style;

  FormOption({
    required this.label,
    required this.value,
    this.color,
    this.style,
  });

  factory FormOption.fromJson(Map<String, dynamic> json) {
    return FormOption(
      label: json['label'] ?? '',
      value: json['value'] ?? '',
      color: json['color'],
      style: json['style'],
    );
  }
}

class FormField {
  final String key;
  final String label;
  final String type;
  final bool required;
  final String? placeholder;
  final List<FormOption>? options;
  final Map<String, dynamic>? extra;

  FormField({
    required this.key,
    required this.label,
    required this.type,
    required this.required,
    this.placeholder,
    this.options,
    this.extra,
  });

  factory FormField.fromJson(Map<String, dynamic> json) {
    List<FormOption>? options;
    if (json['options'] != null) {
      options = (json['options'] as List)
          .map((e) => FormOption.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    // 提取 extra 字段（拍平所有非标准字段）
    final standardKeys = ['key', 'label', 'type', 'required', 'placeholder', 'options'];
    final extra = <String, dynamic>{};
    json.forEach((key, value) {
      if (!standardKeys.contains(key)) {
        extra[key] = value;
      }
    });

    return FormField(
      key: json['key'] ?? '',
      label: json['label'] ?? '',
      type: json['type'] ?? 'INPUT',
      required: json['required'] ?? false,
      placeholder: json['placeholder'],
      options: options,
      extra: extra.isNotEmpty ? extra : null,
    );
  }
}

class FormCardData {
  final String title;
  final String description;
  final String submitText;
  final List<FormField> fields;
  final bool isSubmitted;
  final Map<String, dynamic>? values;

  FormCardData({
    required this.title,
    required this.description,
    required this.submitText,
    required this.fields,
    this.isSubmitted = false,
    this.values,
  });

  factory FormCardData.fromJson(Map<String, dynamic> json) {
    final fields = (json['fields'] as List? ?? [])
        .map((e) => FormField.fromJson(e as Map<String, dynamic>))
        .toList();

    return FormCardData(
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      submitText: json['submitText'] ?? '提交',
      fields: fields,
      isSubmitted: json['isSubmitted'] ?? false,
      values: json['values'] != null ? Map<String, dynamic>.from(json['values']) : null,
    );
  }
}

/// FORM 卡片组件
class FormCard extends StatefulWidget {
  final FormCardData formData;
  final Function(Map<String, dynamic>)? onSubmit;

  const FormCard({
    super.key,
    required this.formData,
    this.onSubmit,
  });

  factory FormCard.fromJson(Map<String, dynamic> json, {Function(Map<String, dynamic>)? onSubmit}) {
    // 兼容两种结构：一种是包含 data 键的完整卡片 JSON，一种是直接的表单数据 JSON
    final data = json.containsKey('data') ? (json['data'] as Map<String, dynamic>? ?? {}) : json;
    final formData = FormCardData.fromJson(data);
    return FormCard(
      formData: formData,
      onSubmit: onSubmit,
    );
  }

  @override
  State<FormCard> createState() => _FormCardState();
}

class _FormCardState extends State<FormCard> {
  final _formKey = GlobalKey<FormState>();
  final _fieldValues = <String, dynamic>{};
  bool _isSubmitted = false;

  @override
  void initState() {
    super.initState();
    _isSubmitted = widget.formData.isSubmitted;
    if (widget.formData.values != null) {
      _fieldValues.addAll(widget.formData.values!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: AppConstants.elevationLow,
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingM),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(context),
              const SizedBox(height: AppConstants.spacingM),
              if (widget.formData.description.isNotEmpty) ...[
                Text(
                  widget.formData.description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: ResponsiveUtils.getResponsiveFontSize(context, 14),
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppConstants.spacingM),
              ],
              ..._buildFields(context),
              const SizedBox(height: AppConstants.spacingM),
              _buildSubmitButton(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final color = colorScheme.primary;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(AppConstants.spacingXS),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
          ),
          child: Icon(
            Icons.assignment_outlined,
            size: AppConstants.iconSizeMedium,
            color: color,
          ),
        ),
        const SizedBox(width: AppConstants.spacingS),
        Expanded(
          child: Text(
            widget.formData.title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontSize: ResponsiveUtils.getResponsiveFontSize(context, 16),
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
              letterSpacing: -0.3,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  List<Widget> _buildFields(BuildContext context) {
    return widget.formData.fields.map((field) {
      return Padding(
        padding: const EdgeInsets.only(bottom: AppConstants.spacingM),
        child: _buildField(context, field),
      );
    }).toList();
  }

  Widget _buildField(BuildContext context, FormField field) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // 字段标签
    final labelWidget = Row(
      children: [
        Text(
          field.label,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontSize: ResponsiveUtils.getResponsiveFontSize(context, 14),
            fontWeight: FontWeight.w500,
            color: colorScheme.onSurface,
          ),
        ),
        if (field.required) ...[
          const SizedBox(width: 4),
          Text(
            '*',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.error,
              fontSize: ResponsiveUtils.getResponsiveFontSize(context, 14),
            ),
          ),
        ],
      ],
    );

    // 根据字段类型渲染不同的输入控件
    Widget inputWidget;
    switch (field.type.toUpperCase()) {
      case 'INPUT':
        inputWidget = _buildInputField(context, field);
        break;
      case 'TEXTAREA':
        inputWidget = _buildTextareaField(context, field);
        break;
      case 'CHECKBOX':
        inputWidget = _buildCheckboxField(context, field);
        break;
      case 'RADIO':
        inputWidget = _buildRadioField(context, field);
        break;
      case 'DROPDOWN':
        inputWidget = _buildDropdownField(context, field);
        break;
      case 'DATE_TIME_PICKER':
        inputWidget = _buildDateTimePickerField(context, field);
        break;
      default:
        // 未知类型降级为 INPUT
        inputWidget = _buildInputField(context, field);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        labelWidget,
        const SizedBox(height: AppConstants.spacingXS),
        inputWidget,
      ],
    );
  }

  Widget _buildInputField(BuildContext context, FormField field) {
    return TextFormField(
      initialValue: _fieldValues[field.key]?.toString(),
      enabled: !_isSubmitted,
      decoration: InputDecoration(
        hintText: field.placeholder,
        hintStyle: TextStyle(
          fontSize: ResponsiveUtils.getResponsiveFontSize(context, 14),
          color: Theme.of(context).colorScheme.outline,
        ),
        filled: _isSubmitted,
        fillColor: _isSubmitted
            ? Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppConstants.spacingM,
          vertical: AppConstants.spacingS,
        ),
      ),
      style: TextStyle(
        fontSize: ResponsiveUtils.getResponsiveFontSize(context, 14),
        color: _isSubmitted ? Theme.of(context).colorScheme.onSurfaceVariant : null,
      ),
      validator: (value) {
        if (field.required && (value == null || value.isEmpty)) {
          return '${field.label}${'form_cannot_be_empty'.tr}';
        }
        return null;
      },
      onSaved: (value) {
        _fieldValues[field.key] = value;
      },
    );
  }

  Widget _buildTextareaField(BuildContext context, FormField field) {
    return TextFormField(
      initialValue: _fieldValues[field.key]?.toString(),
      enabled: !_isSubmitted,
      decoration: InputDecoration(
        hintText: field.placeholder,
        hintStyle: TextStyle(
          fontSize: ResponsiveUtils.getResponsiveFontSize(context, 14),
          color: Theme.of(context).colorScheme.outline,
        ),
        filled: _isSubmitted,
        fillColor: _isSubmitted
            ? Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppConstants.spacingM,
          vertical: AppConstants.spacingM,
        ),
      ),
      style: TextStyle(
        fontSize: ResponsiveUtils.getResponsiveFontSize(context, 14),
        color: _isSubmitted ? Theme.of(context).colorScheme.onSurfaceVariant : null,
      ),
      maxLines: 4,
      minLines: 3,
      validator: (value) {
        if (field.required && (value == null || value.isEmpty)) {
          return '${field.label}${'form_cannot_be_empty'.tr}';
        }
        return null;
      },
      onSaved: (value) {
        _fieldValues[field.key] = value;
      },
    );
  }

  Widget _buildCheckboxField(BuildContext context, FormField field) {
    final colorScheme = Theme.of(context).colorScheme;
    final currentValue = _fieldValues[field.key] as List<String>? ?? [];

    return Wrap(
      spacing: AppConstants.spacingM,
      runSpacing: AppConstants.spacingS,
      children: (field.options ?? []).map((option) {
        final isSelected = currentValue.contains(option.value);
        return InkWell(
          onTap: _isSubmitted
              ? null
              : () {
                  setState(() {
                    if (isSelected) {
                      currentValue.remove(option.value);
                    } else {
                      currentValue.add(option.value);
                    }
                    _fieldValues[field.key] = currentValue;
                  });
                },
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.spacingM,
              vertical: AppConstants.spacingS,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? (_isSubmitted
                      ? colorScheme.surfaceContainerHighest
                      : colorScheme.primaryContainer)
                  : colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
              border: Border.all(
                color: isSelected
                    ? (_isSubmitted ? colorScheme.outline : colorScheme.primary)
                    : colorScheme.outline.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isSelected ? Icons.check_box : Icons.check_box_outline_blank,
                  size: AppConstants.iconSizeSmall,
                  color: isSelected
                      ? (_isSubmitted
                          ? colorScheme.outline
                          : colorScheme.primary)
                      : colorScheme.onSurfaceVariant.withValues(alpha: _isSubmitted ? 0.5 : 1.0),
                ),
                const SizedBox(width: AppConstants.spacingXS),
                Text(
                  option.label,
                  style: TextStyle(
                    fontSize: ResponsiveUtils.getResponsiveFontSize(context, 14),
                    color: isSelected
                        ? (_isSubmitted
                            ? colorScheme.onSurfaceVariant
                            : colorScheme.onPrimaryContainer)
                        : colorScheme.onSurface.withValues(alpha: _isSubmitted ? 0.5 : 1.0),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRadioField(BuildContext context, FormField field) {
    final colorScheme = Theme.of(context).colorScheme;
    final currentValue = _fieldValues[field.key] as String?;

    return Wrap(
      spacing: AppConstants.spacingM,
      runSpacing: AppConstants.spacingS,
      children: (field.options ?? []).map((option) {
        final isSelected = currentValue == option.value;
        return InkWell(
          onTap: _isSubmitted
              ? null
              : () {
                  setState(() {
                    _fieldValues[field.key] = option.value;
                  });
                },
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.spacingM,
              vertical: AppConstants.spacingS,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? (_isSubmitted
                      ? colorScheme.surfaceContainerHighest
                      : colorScheme.primaryContainer)
                  : colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
              border: Border.all(
                color: isSelected
                    ? (_isSubmitted ? colorScheme.outline : colorScheme.primary)
                    : colorScheme.outline.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                  size: AppConstants.iconSizeSmall,
                  color: isSelected
                      ? (_isSubmitted
                          ? colorScheme.outline
                          : colorScheme.primary)
                      : colorScheme.onSurfaceVariant.withValues(alpha: _isSubmitted ? 0.5 : 1.0),
                ),
                const SizedBox(width: AppConstants.spacingXS),
                Text(
                  option.label,
                  style: TextStyle(
                    fontSize: ResponsiveUtils.getResponsiveFontSize(context, 14),
                    color: isSelected
                        ? (_isSubmitted
                            ? colorScheme.onSurfaceVariant
                            : colorScheme.onPrimaryContainer)
                        : colorScheme.onSurface.withValues(alpha: _isSubmitted ? 0.5 : 1.0),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDropdownField(BuildContext context, FormField field) {
    final colorScheme = Theme.of(context).colorScheme;
    final currentValue = _fieldValues[field.key] as String?;

    return DropdownButtonFormField<String>(
      initialValue: currentValue,
      decoration: InputDecoration(
        filled: _isSubmitted,
        fillColor: _isSubmitted
            ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppConstants.spacingM,
          vertical: AppConstants.spacingS,
        ),
      ),
      hint: Text(
        field.placeholder ?? 'form_please_select'.tr,
        style: TextStyle(
          fontSize: ResponsiveUtils.getResponsiveFontSize(context, 14),
          color: colorScheme.outline.withValues(alpha: _isSubmitted ? 0.5 : 1.0),
        ),
      ),
      items: (field.options ?? []).map((option) {
        return DropdownMenuItem(
          value: option.value,
          child: Text(
            option.label,
            style: TextStyle(
              fontSize: ResponsiveUtils.getResponsiveFontSize(context, 14),
              color: _isSubmitted ? colorScheme.onSurfaceVariant : null,
            ),
          ),
        );
      }).toList(),
      onChanged: _isSubmitted
          ? null
          : (value) {
              setState(() {
                _fieldValues[field.key] = value;
              });
            },
      validator: (value) {
        if (field.required && value == null) {
          return '${field.label}不能为空';
        }
        return null;
      },
    );
  }

  Widget _buildDateTimePickerField(BuildContext context, FormField field) {
    final colorScheme = Theme.of(context).colorScheme;
    final currentValue = _fieldValues[field.key] as String?;

    return InkWell(
      onTap: _isSubmitted
          ? null
          : () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: currentValue != null
                    ? DateTime.tryParse(currentValue) ?? DateTime.now()
                    : DateTime.now(),
                firstDate: DateTime(1900),
                lastDate: DateTime(2100),
              );

              if (picked != null && context.mounted) {
                final timePicked = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.now(),
                );

                if (timePicked != null && context.mounted) {
                  final dateTime = DateTime(
                    picked.year,
                    picked.month,
                    picked.day,
                    timePicked.hour,
                    timePicked.minute,
                  );
                  // ISO 8601 格式
                  final isoString = dateTime.toIso8601String().split('.').first;
                  setState(() {
                    _fieldValues[field.key] = isoString;
                  });
                }
              }
            },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.spacingM,
          vertical: AppConstants.spacingS,
        ),
        decoration: BoxDecoration(
          color: _isSubmitted
              ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
              : null,
          border: Border.all(
            color: colorScheme.outline.withValues(alpha: 0.3),
          ),
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today,
              size: AppConstants.iconSizeSmall,
              color: colorScheme.onSurfaceVariant.withValues(alpha: _isSubmitted ? 0.5 : 1.0),
            ),
            const SizedBox(width: AppConstants.spacingM),
            Expanded(
              child: Text(
                currentValue ?? field.placeholder ?? 'form_please_select_datetime'.tr,
                style: TextStyle(
                  fontSize: ResponsiveUtils.getResponsiveFontSize(context, 14),
                  color: currentValue != null
                      ? (_isSubmitted ? colorScheme.onSurfaceVariant : colorScheme.onSurface)
                      : colorScheme.outline.withValues(alpha: _isSubmitted ? 0.5 : 1.0),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: double.infinity,
      height: 48,
      child: FilledButton.icon(
        onPressed: _isSubmitted ? null : _handleSubmit,
        icon: Icon(_isSubmitted ? Icons.check_circle : Icons.send, size: 18),
        label: Text(
          _isSubmitted ? 'form_submitted'.tr : widget.formData.submitText,
          style: TextStyle(
            fontSize: ResponsiveUtils.getResponsiveFontSize(context, 14),
            fontWeight: FontWeight.w600,
          ),
        ),
        style: FilledButton.styleFrom(
          backgroundColor: _isSubmitted ? colorScheme.outline : colorScheme.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
          ),
        ),
      ),
    );
  }

  void _handleSubmit() {
    if (_formKey.currentState?.validate() ?? false) {
      _formKey.currentState?.save();

      // 调用外部回调
      widget.onSubmit?.call(_fieldValues);

      setState(() {
        _isSubmitted = true;
      });
    }
  }
}

/// Preview main function for testing
void main() {
  runApp(const FormCardTestApp());
}

class FormCardTestApp extends StatelessWidget {
  const FormCardTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.deepPurple,
        brightness: Brightness.light,
      ),
      home: Scaffold(
        appBar: AppBar(title: Text('form_card_preview'.tr), centerTitle: true),
        backgroundColor: Colors.grey[100],
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              FormCard(
                formData: FormCardData(
                  title: '马拉松规划前置信息',
                  description: '请先补充基础情况，方便生成个性化训练计划',
                  submitText: '提交',
                  fields: [
                    FormField(
                      key: 'age',
                      label: '年龄',
                      type: 'INPUT',
                      required: true,
                      placeholder: '请输入年龄',
                    ),
                    FormField(
                      key: 'gender',
                      label: '性别',
                      type: 'RADIO',
                      required: true,
                      options: [
                        FormOption(label: '男', value: 'male'),
                        FormOption(label: '女', value: 'female'),
                      ],
                    ),
                    FormField(
                      key: 'weekly_running_km',
                      label: '当前周跑量 (km)',
                      type: 'INPUT',
                      required: true,
                    ),
                    FormField(
                      key: 'target_race_date',
                      label: '目标比赛日期',
                      type: 'DATE_TIME_PICKER',
                      required: true,
                    ),
                    FormField(
                      key: 'injury_history',
                      label: '伤病史',
                      type: 'TEXTAREA',
                      required: false,
                    ),
                  ],
                ),
                onSubmit: (data) {
                  debugPrint('Form submitted: $data');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
