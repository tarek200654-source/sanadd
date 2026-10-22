import 'package:flutter/material.dart';

import '../../../domain/models/user_role.dart';

class RoleMark extends StatelessWidget {
  const RoleMark({required this.role, required this.color});

  final UserRole role;
  final Color color;

  @override
  Widget build(BuildContext context) => CustomPaint(
    size: const Size(30, 30),
    painter: _RoleMarkPainter(role: role, color: color),
  );
}

class _RoleMarkPainter extends CustomPainter {
  const _RoleMarkPainter({required this.role, required this.color});

  final UserRole role;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 30;
    canvas.save();
    canvas.scale(scale);
    final line = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    if (role == UserRole.patient) {
      final heart = Path()
        ..moveTo(15, 26)
        ..cubicTo(12, 23, 4, 17, 4, 10)
        ..cubicTo(4, 3, 12, 2, 15, 8)
        ..cubicTo(18, 2, 26, 3, 26, 10)
        ..cubicTo(26, 17, 18, 23, 15, 26);
      canvas.drawPath(heart, line);
      final pulse = Path()
        ..moveTo(7, 15)
        ..lineTo(11, 15)
        ..lineTo(13, 11)
        ..lineTo(16, 19)
        ..lineTo(18, 14)
        ..lineTo(23, 14);
      canvas.drawPath(pulse, line);
    } else {
      canvas.drawCircle(const Offset(10, 9), 3.1, line);
      canvas.drawCircle(const Offset(20, 9), 3.1, line);
      final leftPerson = Path()
        ..moveTo(3, 24)
        ..cubicTo(3, 19, 6, 16, 10, 16)
        ..cubicTo(12, 16, 14, 17, 15, 20);
      final rightPerson = Path()
        ..moveTo(27, 24)
        ..cubicTo(27, 19, 24, 16, 20, 16)
        ..cubicTo(18, 16, 16, 17, 15, 20);
      canvas.drawPath(leftPerson, line);
      canvas.drawPath(rightPerson, line);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _RoleMarkPainter oldDelegate) =>
      oldDelegate.role != role || oldDelegate.color != color;
}
