import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_color.dart';

class AuthTextField extends StatelessWidget {
  const AuthTextField({
    super.key,
    required this.controller,
    required this.label,
    this.focusNode,
    this.errorText,
    this.hintText,
    this.keyboardType,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
    this.onEditingComplete,
    this.autofillHints,
    this.inputFormatters,
    this.textDirection,
    this.textCapitalization = TextCapitalization.none,
    this.maxLength,
    this.enabled = true,
    this.prefixIcon,
    this.suffixIcon,
    this.labelAbove = false,
    this.compact = false,
    this.surfaceColor,
    this.outlineColor,
    this.cornerRadius,
  });

  final TextEditingController controller;
  final String label;
  final FocusNode? focusNode;
  final String? errorText;
  final String? hintText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onEditingComplete;
  final Iterable<String>? autofillHints;
  final List<TextInputFormatter>? inputFormatters;
  final TextDirection? textDirection;
  final TextCapitalization textCapitalization;
  final int? maxLength;
  final bool enabled;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool labelAbove;
  final bool compact;
  final Color? surfaceColor;
  final Color? outlineColor;
  final double? cornerRadius;

  @override
  Widget build(BuildContext context) {
    final field = TextField(
      controller: controller,
      focusNode: focusNode,
      enabled: enabled,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      textDirection: textDirection,
      textCapitalization: textCapitalization,
      autofillHints: autofillHints,
      inputFormatters: inputFormatters,
      maxLength: maxLength,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      onEditingComplete: onEditingComplete,
      decoration: InputDecoration(
        labelText: labelAbove ? null : label,
        hintText: hintText,
        errorText: errorText,
        errorMaxLines: 2,
        errorStyle: const TextStyle(fontSize: 12, height: 1.25),
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        counterText: '',
        filled: true,
        fillColor: surfaceColor ?? AppColor.surfaceMuted,
        isDense: compact,
        contentPadding: compact
            ? const EdgeInsetsDirectional.fromSTEB(16, 13, 16, 13)
            : const EdgeInsetsDirectional.fromSTEB(16, 15, 16, 15),
        labelStyle: const TextStyle(
          color: AppColor.textSecondary,
          fontWeight: FontWeight.w500,
        ),
        hintStyle: const TextStyle(
          color: AppColor.mutedText,
          fontSize: 14.5,
          fontWeight: FontWeight.w400,
        ),
        floatingLabelStyle: const TextStyle(
          color: AppColor.textPrimary,
          fontWeight: FontWeight.w700,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            cornerRadius ?? (compact ? 14 : 16),
          ),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            cornerRadius ?? (compact ? 14 : 16),
          ),
          borderSide: compact
              ? BorderSide.none
              : BorderSide(color: outlineColor ?? AppColor.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            cornerRadius ?? (compact ? 14 : 16),
          ),
          borderSide: const BorderSide(color: AppColor.primary, width: 1.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            cornerRadius ?? (compact ? 14 : 16),
          ),
          borderSide: const BorderSide(color: AppColor.alert),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            cornerRadius ?? (compact ? 14 : 16),
          ),
          borderSide: const BorderSide(color: AppColor.alert, width: 1.4),
        ),
      ),
      style: const TextStyle(
        fontSize: 15,
        color: AppColor.textPrimary,
        fontWeight: FontWeight.w500,
      ),
    );
    if (!labelAbove) return field;
    final compactField = compact && errorText == null
        ? SizedBox(height: 54, child: field)
        : field;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          textAlign: TextAlign.start,
          style: const TextStyle(
            color: AppColor.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 7),
        Semantics(label: label, textField: true, child: compactField),
      ],
    );
  }
}

class AuthPasswordField extends StatefulWidget {
  const AuthPasswordField({
    super.key,
    required this.controller,
    required this.label,
    required this.showPasswordLabel,
    required this.hidePasswordLabel,
    this.focusNode,
    this.errorText,
    this.onChanged,
    this.onSubmitted,
    this.onEditingComplete,
    this.textInputAction,
    this.autofillHints,
    this.onFocusChanged,
    this.labelAbove = false,
    this.compact = false,
    this.showLockIcon = false,
    this.surfaceColor,
    this.outlineColor,
    this.cornerRadius,
  });

  final TextEditingController controller;
  final String label;
  final String showPasswordLabel;
  final String hidePasswordLabel;
  final FocusNode? focusNode;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onEditingComplete;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final ValueChanged<bool>? onFocusChanged;
  final bool labelAbove;
  final bool compact;
  final bool showLockIcon;
  final Color? surfaceColor;
  final Color? outlineColor;
  final double? cornerRadius;

  @override
  State<AuthPasswordField> createState() => _AuthPasswordFieldState();
}

class _AuthPasswordFieldState extends State<AuthPasswordField> {
  bool _obscureText = true;
  bool _hasFocus = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    widget.focusNode?.removeListener(_handleFocusChanged);
    widget.focusNode?.addListener(_handleFocusChanged);
  }

  @override
  void dispose() {
    widget.focusNode?.removeListener(_handleFocusChanged);
    super.dispose();
  }

  void _handleFocusChanged() {
    if (!mounted) return;
    final hasFocus = widget.focusNode?.hasFocus ?? false;
    if (_hasFocus == hasFocus) return;
    setState(() => _hasFocus = hasFocus);
    widget.onFocusChanged?.call(hasFocus);
  }

  @override
  Widget build(BuildContext context) {
    final field = TextField(
      controller: widget.controller,
      focusNode: widget.focusNode,
      obscureText: _obscureText,
      keyboardType: TextInputType.visiblePassword,
      textDirection: TextDirection.ltr,
      textInputAction: widget.textInputAction,
      autofillHints: widget.autofillHints,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      onEditingComplete: widget.onEditingComplete,
      decoration: InputDecoration(
        labelText: widget.labelAbove ? null : widget.label,
        errorText: widget.errorText,
        errorMaxLines: 2,
        errorStyle: const TextStyle(fontSize: 12, height: 1.25),
        filled: true,
        fillColor: widget.surfaceColor ?? AppColor.surfaceMuted,
        isDense: widget.compact,
        contentPadding: widget.compact
            ? const EdgeInsetsDirectional.fromSTEB(16, 13, 6, 13)
            : const EdgeInsetsDirectional.fromSTEB(16, 15, 8, 15),
        labelStyle: const TextStyle(
          color: AppColor.textSecondary,
          fontWeight: FontWeight.w500,
        ),
        floatingLabelStyle: const TextStyle(
          color: AppColor.textPrimary,
          fontWeight: FontWeight.w700,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            widget.cornerRadius ?? (widget.compact ? 14 : 16),
          ),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            widget.cornerRadius ?? (widget.compact ? 14 : 16),
          ),
          borderSide: widget.compact
              ? BorderSide.none
              : BorderSide(color: widget.outlineColor ?? AppColor.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            widget.cornerRadius ?? (widget.compact ? 14 : 16),
          ),
          borderSide: const BorderSide(color: AppColor.primary, width: 1.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            widget.cornerRadius ?? (widget.compact ? 14 : 16),
          ),
          borderSide: const BorderSide(color: AppColor.alert),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            widget.cornerRadius ?? (widget.compact ? 14 : 16),
          ),
          borderSide: const BorderSide(color: AppColor.alert, width: 1.4),
        ),
        prefixIcon: widget.showLockIcon
            ? const Icon(
                Icons.lock_outline_rounded,
                size: 19,
                color: AppColor.textSecondary,
              )
            : null,
        suffixIcon: Semantics(
          button: true,
          label: _obscureText
              ? widget.showPasswordLabel
              : widget.hidePasswordLabel,
          child: IconButton(
            onPressed: () => setState(() => _obscureText = !_obscureText),
            tooltip: _obscureText
                ? widget.showPasswordLabel
                : widget.hidePasswordLabel,
            icon: Icon(
              _obscureText
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              color: AppColor.textSecondary,
            ),
          ),
        ),
      ),
      style: const TextStyle(
        fontSize: 15,
        color: AppColor.textPrimary,
        fontWeight: FontWeight.w500,
      ),
    );
    if (!widget.labelAbove) return field;
    final compactField = widget.compact && widget.errorText == null
        ? SizedBox(height: 54, child: field)
        : field;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.label,
          textAlign: TextAlign.start,
          style: const TextStyle(
            color: AppColor.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 7),
        Semantics(label: widget.label, textField: true, child: compactField),
      ],
    );
  }
}
