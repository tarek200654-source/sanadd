import 'package:flutter/material.dart';

import '../shared_widgets/auth_screen_styles.dart';

class LoginScreenSquaresLoading extends StatefulWidget {
  final Color? color;
  const LoginScreenSquaresLoading({this.color});
  @override
  State<LoginScreenSquaresLoading> createState() =>
      _LoginScreenSquaresLoadingState();
}

class _LoginScreenSquaresLoadingState extends State<LoginScreenSquaresLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _anim;
  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.color ?? context.sanadBg;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        3,
        (i) => AnimatedBuilder(
          animation: _anim,
          builder: (context, child) {
            double value = (_anim.value - (i * 0.2)) % 1.0;
            double scale = value < 0.5
                ? 1.0 + (value * 0.6)
                : 1.3 - ((value - 0.5) * 0.6);
            return Transform.scale(
              scale: scale,
              child: Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: c,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
