import 'package:flutter/material.dart';

import '../../../domain/models/user_role.dart';
import 'role_choice.dart';

class RolePicker extends StatelessWidget {
  const RolePicker({
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
      RoleChoice(
        role: UserRole.patient,
        title: patientTitle,
        description: patientDescription,
        selected: selectedRole == UserRole.patient,
        compact: compact,
        onTap: () => onSelected(UserRole.patient),
      ),
      SizedBox(height: compact ? 9 : 12),
      RoleChoice(
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
