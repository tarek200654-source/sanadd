import 'package:flutter/material.dart';

import '../../../core/theme/app_color.dart';

/// Fixed full-width bottom navigation using SANAD's existing line icons.
class SanadBottomNavigation extends StatelessWidget {
  const SanadBottomNavigation({
    super.key,
    required this.selectedIndex,
    required this.isArabic,
    required this.onSelected,
  });

  static const double height = 56;
  static const double bottomSpacing = 0;
  static const double contentClearance = 12;

  final int selectedIndex;
  final bool isArabic;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final destinations = [
      (id: 'home', label: isArabic ? 'الرئيسية' : 'Home'),
      (id: 'activity', label: isArabic ? 'الأدوية' : 'Medicines'),
      (id: 'health', label: isArabic ? 'الصحة' : 'Health'),
      (id: 'insights', label: isArabic ? 'المؤشرات' : 'Insights'),
      (id: 'settings', label: isArabic ? 'الإعدادات' : 'Settings'),
    ];
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 180);

    return Container(
      height: height + bottomInset,
      padding: EdgeInsets.only(bottom: bottomInset),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE8E8EA), width: .7)),
      ),
      child: Row(
        children: [
          for (var index = 0; index < destinations.length; index++)
            Expanded(
              child: Semantics(
                key: ValueKey('nav-${destinations[index].id}'),
                label: destinations[index].label,
                button: true,
                selected: selectedIndex == index,
                onTap: () => onSelected(index),
                excludeSemantics: true,
                child: Tooltip(
                  message: destinations[index].label,
                  excludeFromSemantics: true,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => onSelected(index),
                      child: AnimatedContainer(
                        duration: duration,
                        curve: Curves.easeOutCubic,
                        color: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CustomPaint(
                              size: const Size.square(23),
                              painter: _NavigationIconPainter(
                                index: index,
                                color: selectedIndex == index
                                    ? AppColor.loginLightText
                                    : AppColor.loginLightSecondaryText,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              destinations[index].label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 10,
                                height: 1.1,
                                fontWeight: selectedIndex == index
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: selectedIndex == index
                                    ? AppColor.loginLightText
                                    : AppColor.loginLightSecondaryText,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// A consistent set of rounded outline icons, drawn at any display density.
class _NavigationIconPainter extends CustomPainter {
  const _NavigationIconPainter({required this.index, required this.color});

  final int index;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 24, size.height / 24);
    final pen = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.65
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    switch (index) {
      case 0:
        final home = Path()
          ..moveTo(9.8, 3.7)
          ..quadraticBezierTo(12, 2, 14.2, 3.7)
          ..lineTo(20.3, 8.5)
          ..quadraticBezierTo(21.3, 9.3, 21, 11)
          ..lineTo(19.4, 19.1)
          ..quadraticBezierTo(19, 21, 17, 21)
          ..lineTo(7, 21)
          ..quadraticBezierTo(5, 21, 4.6, 19.1)
          ..lineTo(3, 11)
          ..quadraticBezierTo(2.7, 9.3, 3.7, 8.5)
          ..close();
        canvas.drawPath(home, pen);
        canvas.drawLine(const Offset(9.5, 16.5), const Offset(14.5, 16.5), pen);
      case 1:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(3, 3, 18, 18),
            const Radius.circular(6),
          ),
          pen,
        );
        canvas.drawPath(
          Path()
            ..moveTo(6, 13)
            ..lineTo(9, 13)
            ..lineTo(11, 8)
            ..lineTo(14, 17)
            ..lineTo(16, 12)
            ..lineTo(18, 12),
          pen,
        );
      case 2:
        canvas.drawPath(
          Path()
            ..moveTo(12, 20.5)
            ..cubicTo(8, 17.5, 3, 13.7, 3, 8.8)
            ..cubicTo(3, 3.2, 9.5, 2.5, 12, 7)
            ..cubicTo(14.5, 2.5, 21, 3.2, 21, 8.8)
            ..cubicTo(21, 13.7, 16, 17.5, 12, 20.5)
            ..close(),
          pen,
        );
      case 3:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(3, 3, 18, 18),
            const Radius.circular(5),
          ),
          pen,
        );
        canvas.drawLine(const Offset(7.5, 16.5), const Offset(7.5, 12.5), pen);
        canvas.drawLine(const Offset(12, 16.5), const Offset(12, 7.5), pen);
        canvas.drawLine(const Offset(16.5, 16.5), const Offset(16.5, 10), pen);
      case 4:
        canvas.drawCircle(const Offset(12, 12), 5.2, pen);
        canvas.drawCircle(const Offset(12, 12), 1.8, pen);
        for (var tooth = 0; tooth < 8; tooth++) {
          canvas.save();
          canvas.translate(12, 12);
          canvas.rotate(tooth * 3.141592653589793 / 4);
          canvas.drawLine(const Offset(0, -7), const Offset(0, -10), pen);
          canvas.restore();
        }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _NavigationIconPainter oldDelegate) =>
      oldDelegate.index != index || oldDelegate.color != color;
}
