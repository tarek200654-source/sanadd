import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_color.dart';

class OtpInput extends StatefulWidget {
  const OtpInput({
    super.key,
    required this.onChanged,
    this.errorText,
    this.digitLabel,
  });

  final ValueChanged<String> onChanged;
  final String? errorText;
  final String Function(int index)? digitLabel;

  @override
  State<OtpInput> createState() => _OtpInputState();
}

class _OtpInputState extends State<OtpInput> {
  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;
  late final List<String> _previousValues;
  bool _isDistributing = false;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(6, (_) => TextEditingController());
    _focusNodes = List.generate(6, (_) => FocusNode());
    _previousValues = List.filled(6, '');
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  String get _code => _controllers.map((controller) => controller.text).join();

  void _notifyChanged() {
    if (!_isDistributing) widget.onChanged(_code);
  }

  void _setControllerValue(int index, String value) {
    _controllers[index].value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
  }

  void _handleChanged(int index, String value) {
    if (_isDistributing) return;
    final digits = value.replaceAll(RegExp(r'\D'), '');
    final previousValue = _previousValues[index];
    if (digits.length > 1) {
      if (previousValue.isNotEmpty && digits.length < 6) {
        final replacement = digits.substring(digits.length - 1);
        _setControllerValue(index, replacement);
        _previousValues[index] = replacement;
        if (index < 5) _focusNodes[index + 1].requestFocus();
        _notifyChanged();
        return;
      }

      final isCompletePaste = digits.length >= 6;
      final pastedDigits = isCompletePaste ? digits.substring(0, 6) : digits;
      final startIndex = isCompletePaste ? 0 : index;
      _isDistributing = true;
      if (isCompletePaste) {
        for (var clearIndex = 0; clearIndex < 6; clearIndex++) {
          _setControllerValue(clearIndex, '');
          _previousValues[clearIndex] = '';
        }
      }
      for (
        var offset = 0;
        offset < pastedDigits.length && startIndex + offset < 6;
        offset++
      ) {
        final targetIndex = startIndex + offset;
        _setControllerValue(targetIndex, pastedDigits[offset]);
        _previousValues[targetIndex] = pastedDigits[offset];
      }
      if (isCompletePaste) {
        for (
          var clearIndex = pastedDigits.length;
          clearIndex < 6;
          clearIndex++
        ) {
          _setControllerValue(clearIndex, '');
          _previousValues[clearIndex] = '';
        }
      }
      _isDistributing = false;
      final lastIndex = (startIndex + pastedDigits.length - 1).clamp(0, 5);
      _focusNodes[lastIndex].requestFocus();
      _notifyChanged();
      return;
    }

    if (digits.isEmpty) {
      _setControllerValue(index, '');
      _previousValues[index] = '';
      if (index > 0) _focusNodes[index - 1].requestFocus();
      _notifyChanged();
      return;
    }

    _previousValues[index] = digits;
    if (index < 5) {
      _focusNodes[index + 1].requestFocus();
    } else {
      _focusNodes[index].unfocus();
    }
    _notifyChanged();
  }

  void _handleBackspace(int index) {
    if (_controllers[index].text.isNotEmpty) {
      _setControllerValue(index, '');
      _previousValues[index] = '';
      if (index > 0) _focusNodes[index - 1].requestFocus();
    } else if (index > 0) {
      _setControllerValue(index - 1, '');
      _previousValues[index - 1] = '';
      _focusNodes[index - 1].requestFocus();
    }
    _notifyChanged();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: widget.errorText,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Directionality(
            textDirection: TextDirection.ltr,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final cellWidth = ((constraints.maxWidth - 35) / 6).clamp(
                  24.0,
                  44.0,
                );
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(6, (index) {
                    final label =
                        widget.digitLabel?.call(index) ??
                        'Verification code digit ${index + 1}';
                    return SizedBox(
                      key: ValueKey('otp-cell-$index'),
                      width: cellWidth,
                      height: 66,
                      child: CallbackShortcuts(
                        bindings: <ShortcutActivator, VoidCallback>{
                          const SingleActivator(
                            LogicalKeyboardKey.backspace,
                          ): () =>
                              _handleBackspace(index),
                        },
                        child: Semantics(
                          textField: true,
                          label: label,
                          child: TextField(
                            key: ValueKey('otp-input-$index'),
                            controller: _controllers[index],
                            focusNode: _focusNodes[index],
                            keyboardType: TextInputType.number,
                            textInputAction: index == 5
                                ? TextInputAction.done
                                : TextInputAction.next,
                            textAlign: TextAlign.center,
                            textDirection: TextDirection.ltr,
                            autofillHints: index == 0
                                ? const [AutofillHints.oneTimeCode]
                                : null,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            style: const TextStyle(
                              color: AppColor.textPrimary,
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                            ),
                            decoration: InputDecoration(
                              counterText: '',
                              filled: true,
                              fillColor: AppColor.otpInputFill,
                              contentPadding: EdgeInsets.zero,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(
                                  color: AppColor.otpInputBorder,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(
                                  color: AppColor.otpInputBorder,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(
                                  color: AppColor.textPrimary,
                                  width: 1.4,
                                ),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(
                                  color: AppColor.alert,
                                ),
                              ),
                            ),
                            onChanged: (value) => _handleChanged(index, value),
                          ),
                        ),
                      ),
                    );
                  }),
                );
              },
            ),
          ),
          if (widget.errorText != null) ...[
            const SizedBox(height: 7),
            Text(
              widget.errorText!,
              textAlign: TextAlign.start,
              style: const TextStyle(
                color: AppColor.alert,
                fontSize: 12,
                height: 1.25,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
