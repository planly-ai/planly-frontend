import 'dart:convert';

import 'package:intl/intl.dart';

class FormSubmissionFormatter {
  const FormSubmissionFormatter._();

  static Map<String, dynamic> decodeCardData(String? cardContent) {
    try {
      final decoded = jsonDecode(cardContent ?? '{}');
      if (decoded is! Map<String, dynamic>) return const {};

      final nestedData = decoded['data'];
      if (nestedData is Map<String, dynamic>) {
        return Map<String, dynamic>.from(nestedData);
      }

      return Map<String, dynamic>.from(decoded);
    } catch (_) {
      return const {};
    }
  }

  static String markSubmitted({
    required String? cardContent,
    required Map<String, dynamic> values,
  }) {
    final decoded = jsonDecode(cardContent ?? '{}');
    final cardData = decoded is Map<String, dynamic>
        ? Map<String, dynamic>.from(decoded)
        : <String, dynamic>{};
    final nestedData = cardData['data'];
    final dataMap = nestedData is Map<String, dynamic>
        ? Map<String, dynamic>.from(nestedData)
        : cardData;

    dataMap['isSubmitted'] = true;
    dataMap['values'] = values;
    if (nestedData is Map<String, dynamic>) {
      cardData['data'] = dataMap;
    }

    return jsonEncode(cardData);
  }

  static String formatSubmissionMessage({
    required Map<String, dynamic> cardData,
    required Map<String, dynamic> values,
  }) {
    final title = (cardData['title'] ?? '').toString().trim();
    final buffer = StringBuffer();
    buffer.writeln(
      '**${title.isEmpty ? 'Form submitted' : '$title submitted'}**',
    );
    buffer.writeln();

    final fields = cardData['fields'] is List
        ? cardData['fields'] as List
        : const [];
    final writtenKeys = <String>{};

    for (final field in fields) {
      if (field is! Map) continue;

      final key = (field['key'] ?? '').toString();
      if (key.isEmpty || !values.containsKey(key)) continue;

      final label = (field['label'] ?? key).toString();
      final type = (field['type'] ?? '').toString();
      final required = field['required'] == true;
      final value = values[key];

      if (!required && _isEmptyValue(value)) continue;

      buffer.writeln('- **$label:** ${_formatValue(value, fieldType: type)}');
      writtenKeys.add(key);
    }

    for (final entry in values.entries) {
      if (writtenKeys.contains(entry.key) || _isEmptyValue(entry.value)) {
        continue;
      }

      buffer.writeln('- **${entry.key}:** ${_formatValue(entry.value)}');
    }

    return buffer.toString().trimRight();
  }

  static bool _isEmptyValue(dynamic value) {
    if (value == null) return true;
    if (value is String) return value.trim().isEmpty;
    if (value is Iterable) return value.isEmpty;
    return false;
  }

  static String _formatValue(dynamic value, {String fieldType = ''}) {
    if (value is Iterable) {
      return value.map((item) => item.toString()).join(', ');
    }

    final text = value?.toString().trim() ?? '';
    if (text.isEmpty) return '-';

    if (fieldType.toUpperCase() == 'DATE_TIME_PICKER') {
      final date = DateTime.tryParse(text);
      if (date != null) {
        return DateFormat('yyyy-MM-dd HH:mm').format(date.toLocal());
      }
    }

    return text.replaceAll(RegExp(r'\s+'), ' ');
  }
}
