import 'package:flutter/material.dart';
import '../core/constants/colors.dart';
import '../core/constants/text_styles.dart';
import '../core/constants/prohibited_keywords.dart';

/// A text field that adds entries as dismissible chips below.
/// Used for Skills and Preferred Tasks in Sign-up Step 2.
class ChipInputField extends StatefulWidget {
  final String label;
  final String hint;
  final List<String> suggestions;
  final List<String> selectedValues;
  final void Function(List<String>) onChanged;
  final int maxChips;

  const ChipInputField({
    super.key,
    required this.label,
    required this.hint,
    required this.suggestions,
    required this.selectedValues,
    required this.onChanged,
    this.maxChips = 10,
  });

  @override
  State<ChipInputField> createState() => _ChipInputFieldState();
}

class _ChipInputFieldState extends State<ChipInputField> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<String> _filtered = [];
  bool _showSuggestions = false;

  String _filterText(String text) {
    String result = text;
    for (String keyword in prohibitedKeywords) {
      result = result.replaceAll(RegExp(keyword, caseSensitive: false), '');
    }
    return result;
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged(String value) {
    String filtered = _filterText(value);
    if (filtered != value) {
      _controller.text = filtered;
      _controller.selection = TextSelection.collapsed(offset: filtered.length);
      value = filtered;
    }
    if (value.isEmpty) {
      setState(() {
        _filtered = [];
        _showSuggestions = false;
      });
      return;
    }
    setState(() {
      _filtered = widget.suggestions
          .where((s) =>
              s.toLowerCase().contains(value.toLowerCase()) &&
              !widget.selectedValues.contains(s))
          .take(5)
          .toList();
      _showSuggestions = _filtered.isNotEmpty;
    });
  }

  void _addChip(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return;
    if (widget.selectedValues.contains(trimmed)) return;
    if (widget.selectedValues.length >= widget.maxChips) return;
    final updated = [...widget.selectedValues, trimmed];
    widget.onChanged(updated);
    _controller.clear();
    setState(() {
      _filtered = [];
      _showSuggestions = false;
    });
  }

  void _removeChip(String value) {
    final updated = widget.selectedValues.where((s) => s != value).toList();
    widget.onChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        RichText(
          text: TextSpan(
            text: widget.label,
            style: AppTextStyles.inputLabel,
            children: const [
              TextSpan(text: '*', style: TextStyle(color: AppColors.primary)),
            ],
          ),
        ),
        const SizedBox(height: 6),

        // Text input
        TextFormField(
          controller: _controller,
          focusNode: _focusNode,
          style: AppTextStyles.inputText,
          textInputAction: TextInputAction.done,
          onChanged: _onTextChanged,
          onFieldSubmitted: _addChip,
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: AppTextStyles.inputHint,
            suffixIcon: GestureDetector(
              onTap: () => _addChip(_controller.text),
              child: const Icon(Icons.add_circle_outline,
                  color: AppColors.primary, size: 22),
            ),
          ),
        ),

        // Autocomplete dropdown
        if (_showSuggestions) ...[
          const SizedBox(height: 4),
          Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderGrey),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.cardShadow,
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: _filtered.map((s) {
                return InkWell(
                  onTap: () => _addChip(s),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        const Icon(Icons.add, size: 16, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text(s, style: AppTextStyles.bodyMedium),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],

        // Chips
        if (widget.selectedValues.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: widget.selectedValues.map((val) {
              return _AppChip(
                label: val,
                onRemove: () => _removeChip(val),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}

class _AppChip extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;

  const _AppChip({required this.label, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.chipBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: AppTextStyles.labelMedium.copyWith(
              color: AppColors.primary,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(
              Icons.close,
              size: 14,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
