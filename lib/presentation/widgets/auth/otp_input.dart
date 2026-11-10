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
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode()..addListener(_handleFocusChanged);
  }

  @override
  void dispose() {
    _focusNode
      ..removeListener(_handleFocusChanged)
      ..dispose();
    _controller.dispose();
    super.dispose();
  }

  void _handleFocusChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final hasError = widget.errorText != null;
    final digits = _controller.text;

    return AutofillGroup(
      onDisposeAction: AutofillContextAction.cancel,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            textField: true,
            label: widget.digitLabel?.call(0) ?? 'Verification code',
            child: Container(
              height: 64,
              decoration: BoxDecoration(
                color: AppColor.otpInputFill,
                borderRadius: BorderRadius.circular(14),
                border: hasError
                    ? Border.all(color: AppColor.alert, width: 1.5)
                    : null,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  IgnorePointer(
                    child: Directionality(
                      textDirection: TextDirection.ltr,
                      child: Row(
                        children: [
                          for (var index = 0; index < 6; index++) ...[
                            Expanded(
                              child: Center(
                                child: Text(
                                  index < digits.length ? digits[index] : '•',
                                  style: TextStyle(
                                    color: index < digits.length
                                        ? AppColor.otpText
                                        : AppColor.otpInputBorder,
                                    fontSize: index < digits.length ? 25 : 20,
                                    height: 1,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                            if (index < 5)
                              Container(
                                width: 1,
                                height: 24,
                                color: AppColor.otpInputBorder,
                              ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: TextField(
                      key: const ValueKey('otp-code-field'),
                      controller: _controller,
                      focusNode: _focusNode,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.done,
                      textAlign: TextAlign.center,
                      textDirection: TextDirection.ltr,
                      autofillHints: const [AutofillHints.oneTimeCode],
                      maxLength: 6,
                      maxLengthEnforcement: MaxLengthEnforcement.enforced,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      showCursor: false,
                      style: const TextStyle(
                        color: Colors.transparent,
                        fontSize: 1,
                        height: 1,
                      ),
                      decoration: const InputDecoration(
                        counterText: '',
                        filled: false,
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onChanged: (value) {
                        setState(() {});
                        widget.onChanged(value);
                      },
                    ),
                  ),
                ],
              ),
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
