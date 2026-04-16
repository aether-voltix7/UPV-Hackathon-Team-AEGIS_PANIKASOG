import 'package:flutter/services.dart';

// Blocked Keywords
const List<String> prohibitedKeywords = [
  "Hypocrite",
  "Lazy",
  "Angry",
];

class ProhibitedKeywordFormatter extends TextInputFormatter {
  final List<String> keywords;

  const ProhibitedKeywordFormatter([this.keywords = prohibitedKeywords]);

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    String filtered = newValue.text;
    for (final keyword in keywords) {
      filtered = filtered.replaceAll(RegExp(RegExp.escape(keyword), caseSensitive: false), '');
    }
    if (filtered == newValue.text) return newValue;
    return TextEditingValue(
      text: filtered,
      selection: TextSelection.collapsed(offset: filtered.length.clamp(0, filtered.length)),
    );
  }
}
