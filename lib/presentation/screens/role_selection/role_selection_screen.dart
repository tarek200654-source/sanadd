import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../../../core/assets/app_assets.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_color.dart';
import '../../../domain/models/user_role.dart';
import '../../../presentation/auth/auth_route_arguments.dart';
import '../../../presentation/widgets/sanad_button.dart';
import '../../../utils/routes.dart';

const _roleAccent = Color(0xFF40566D);
const _roleSelectedSurface = Color(0xFFF1F4F7);
const _roleIconSurface = Color(0xFFE5EBF0);

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  static const routeName = '/role-selection';

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  UserRole _selectedRole = UserRole.patient;

  void _selectRole(UserRole role) {
    if (_selectedRole == role) return;
    setState(() => _selectedRole = role);
  }

  void _continue() {
    Navigator.pushNamed(
      context,
      AppRoutes.login,
      arguments: AuthRouteArguments(role: _selectedRole),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxHeight < 700;
            final content = Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Keep the original SANAD mark and its placement unchanged.
                Center(
                  child: SizedBox(
                    width: (constraints.maxWidth * .34)
                        .clamp(104.0, 128.0)
                        .toDouble(),
                    height: compact ? 122 : 144,
                    child: ColorFiltered(
                      colorFilter: const ColorFilter.mode(
                        Colors.black,
                        BlendMode.srcIn,
                      ),
                      child: Image.asset(
                        AppAssets.sanadLogo,
                        fit: BoxFit.contain,
                        semanticLabel: 'SANAD logo',
                      ),
                    ),
                  ),
                ),
                SizedBox(height: compact ? 4 : 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: compact ? 112 : 142,
                      height: compact ? 112 : 142,
                      child: Lottie.asset(
                        AppAssets.roleSelectionLottie,
                        fit: BoxFit.contain,
                        repeat: true,
                      ),
                    ),
                    SizedBox(width: compact ? 8 : 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            l10n.roleTitle,
                            textAlign: TextAlign.start,
                            style: TextStyle(
                              color: AppColor.textPrimary,
                              fontSize: compact ? 23 : 26,
                              fontWeight: FontWeight.w700,
                              height: 1.2,
                            ),
                          ),
                          SizedBox(height: compact ? 6 : 9),
                          Text(
                            l10n.roleSubtitle,
                            textAlign: TextAlign.start,
                            style: TextStyle(
                              color: AppColor.textSecondary,
                              fontSize: compact ? 12 : 13,
                              height: 1.45,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: compact ? 6 : 12),
                _RolePicker(
                  patientTitle: l10n.patient,
                  patientDescription: l10n.patientDescription,
                  caregiverTitle: l10n.caregiver,
                  caregiverDescription: l10n.caregiverDescription,
                  selectedRole: _selectedRole,
                  compact: compact,
                  onSelected: _selectRole,
                ),
              ],
            );

            return SingleChildScrollView(
              padding: EdgeInsetsDirectional.fromSTEB(
                18,
                compact ? 6 : 12,
                18,
                compact ? 12 : 18,
              ),
              child: content,
            );
          },
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(18, 8, 18, 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.roleHelper,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColor.mutedText,
                  fontSize: 12,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 8),
              SanadButton(
                label: l10n.continueLabel,
                onPressed: _continue,
                icon: null,
                fontSize: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RolePicker extends StatelessWidget {
  const _RolePicker({
    required this.patientTitle,
    required this.patientDescription,
    required this.caregiverTitle,
    required this.caregiverDescription,
    required this.selectedRole,
    required this.compact,
    required this.onSelected,
  });

  final String patientTitle;
  final String patientDescription;
  final String caregiverTitle;
  final String caregiverDescription;
  final UserRole selectedRole;
  final bool compact;
  final ValueChanged<UserRole> onSelected;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      _RoleChoice(
        role: UserRole.patient,
        title: patientTitle,
        description: patientDescription,
        selected: selectedRole == UserRole.patient,
        compact: compact,
        onTap: () => onSelected(UserRole.patient),
      ),
      SizedBox(height: compact ? 9 : 12),
      _RoleChoice(
        role: UserRole.caregiver,
        title: caregiverTitle,
        description: caregiverDescription,
        selected: selectedRole == UserRole.caregiver,
        compact: compact,
        onTap: () => onSelected(UserRole.caregiver),
      ),
    ],
  );
}

class _RoleChoice extends StatelessWidget {
  const _RoleChoice({
    required this.role,
    required this.title,
    required this.description,
    required this.selected,
    required this.compact,
    required this.onTap,
  });

  final UserRole role;
  final String title;
  final String description;
  final bool selected;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: title,
      child: InkWell(
        key: ValueKey('role-option-${role.value}'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          constraints: BoxConstraints(minHeight: compact ? 88 : 98),
          padding: EdgeInsetsDirectional.fromSTEB(
            compact ? 13 : 16,
            compact ? 12 : 14,
            compact ? 13 : 16,
            compact ? 12 : 14,
          ),
          decoration: BoxDecoration(
            color: selected ? _roleSelectedSurface : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? _roleAccent : Colors.transparent,
              width: 1.2,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: compact ? 44 : 48,
                height: compact ? 44 : 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? _roleIconSurface : const Color(0xFFF0F3F5),
                ),
                child: _RoleMark(
                  role: role,
                  color: selected ? _roleAccent : AppColor.textSecondary,
                ),
              ),
              SizedBox(width: compact ? 12 : 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: AppColor.textPrimary,
                        fontSize: compact ? 16 : 17,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        color: AppColor.textSecondary,
                        fontSize: compact ? 11 : 12,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: compact ? 10 : 12),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 23,
                height: 23,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? _roleAccent : Colors.transparent,
                  border: Border.all(
                    color: selected ? _roleAccent : AppColor.border,
                    width: 1.5,
                  ),
                ),
                child: selected
                    ? const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 14,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleMark extends StatelessWidget {
  const _RoleMark({required this.role, required this.color});

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
