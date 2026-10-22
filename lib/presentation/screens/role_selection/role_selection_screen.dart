import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../../../core/assets/app_assets.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_color.dart';
import '../../../domain/models/user_role.dart';
import '../../../presentation/auth/auth_route_arguments.dart';
import '../../../presentation/widgets/shared_widgets/sanad_button.dart';
import '../../../presentation/widgets/role_selection_widgets/role_picker.dart';
import '../../../utils/routes.dart';

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
      backgroundColor: AppColor.surface,
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
                        AppColor.logoTint,
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
                RolePicker(
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
                cornerRadius: 14,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
