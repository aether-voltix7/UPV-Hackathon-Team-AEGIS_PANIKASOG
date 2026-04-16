import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/constants/colors.dart';
import '../core/constants/text_styles.dart';
import '../core/constants/prohibited_keywords.dart';

class AppTextField extends StatefulWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final TextInputType keyboardType;
  final bool isPassword;
  final bool readOnly;
  final int maxLines;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final String? prefixText;
  final List<TextInputFormatter>? inputFormatters;
  final void Function(String)? onChanged;
  final void Function()? onTap;
  final FocusNode? focusNode;
  final TextInputAction textInputAction;
  final void Function(String)? onFieldSubmitted;
  final bool autofocus;
  final EdgeInsets? contentPadding;
  final List<String>? prohibitedKeywords;

  const AppTextField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.validator,
    this.keyboardType = TextInputType.text,
    this.isPassword = false,
    this.readOnly = false,
    this.maxLines = 1,
    this.prefixIcon,
    this.suffixIcon,
    this.prefixText,
    this.inputFormatters,
    this.onChanged,
    this.onTap,
    this.focusNode,
    this.textInputAction = TextInputAction.next,
    this.onFieldSubmitted,
    this.autofocus = false,
    this.contentPadding,
    this.prohibitedKeywords,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  bool _obscureText = true;

  String _filterText(String text) {
    String result = text;
    final keywords = widget.prohibitedKeywords ?? prohibitedKeywords;
    for (String keyword in keywords) {
      result = result.replaceAll(RegExp(keyword, caseSensitive: false), '');
    }
    return result;
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
        // Field
        TextFormField(
          controller: widget.controller,
          validator: widget.validator,
          keyboardType: widget.keyboardType,
          obscureText: widget.isPassword && _obscureText,
          readOnly: widget.readOnly,
          maxLines: widget.isPassword ? 1 : widget.maxLines,
          inputFormatters: widget.inputFormatters,
          onChanged: (value) {
            String filtered = _filterText(value);
            if (filtered != value) {
              widget.controller?.text = filtered;
              widget.controller?.selection = TextSelection.collapsed(offset: filtered.length);
            }
            widget.onChanged?.call(filtered);
          },
          onTap: widget.onTap,
          focusNode: widget.focusNode,
          textInputAction: widget.textInputAction,
          onFieldSubmitted: widget.onFieldSubmitted,
          autofocus: widget.autofocus,
          style: AppTextStyles.inputText,
          decoration: InputDecoration(
            hintText: widget.hint,
            contentPadding: widget.contentPadding ??
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            prefixText: widget.prefixText,
            prefixStyle: AppTextStyles.inputText,
            prefixIcon: widget.prefixIcon,
            suffixIcon: widget.isPassword
                ? IconButton(
                    icon: Icon(
                      _obscureText
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: AppColors.hintGrey,
                      size: 20,
                    ),
                    onPressed: () =>
                        setState(() => _obscureText = !_obscureText),
                  )
                : widget.suffixIcon != null
                    ? Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: widget.suffixIcon,
                      )
                    : null,
          ),
        ),
      ],
    );
  }
}

// ─── Search-style input ────────────────────────────────────────────────────────
class AppSearchField extends StatefulWidget {
  final String hint;
  final TextEditingController? controller;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final VoidCallback? onTap;
  final List<String>? prohibitedKeywords;

  const AppSearchField({
    super.key,
    this.hint = 'Search...',
    this.controller,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.prohibitedKeywords,
  });

  @override
  State<AppSearchField> createState() => _AppSearchFieldState();
}

class _AppSearchFieldState extends State<AppSearchField> {
  String _filterText(String text) {
    String result = text;
    final keywords = widget.prohibitedKeywords ?? prohibitedKeywords;
    for (String keyword in keywords) {
      result = result.replaceAll(RegExp(keyword, caseSensitive: false), '');
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      onChanged: (value) {
        String filtered = _filterText(value);
        if (filtered != value) {
          widget.controller?.text = filtered;
          widget.controller?.selection = TextSelection.collapsed(offset: filtered.length);
        }
        widget.onChanged?.call(filtered);
      },
      onFieldSubmitted: widget.onSubmitted,
      onTap: widget.onTap,
      style: AppTextStyles.inputText,
      decoration: InputDecoration(
        hintText: widget.hint,
        hintStyle: AppTextStyles.inputHint,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        prefixIcon:
            const Icon(Icons.search, color: AppColors.hintGrey, size: 20),
        suffixIcon: const Icon(Icons.tune, color: AppColors.hintGrey, size: 20),
        filled: true,
        fillColor: AppColors.lightGrey,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }
}
