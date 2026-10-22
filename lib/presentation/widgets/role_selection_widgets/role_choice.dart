import 'package:flutter/material.dart';

import '../../../core/theme/app_color.dart';
import '../../../domain/models/user_role.dart';

import 'role_mark.dart';

class RoleChoice extends StatelessWidget {
  const RoleChoice({
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
            color: selected ? AppColor.roleSelectedSurface : AppColor.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? AppColor.roleAccent : AppColor.transparent,
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
                  color: selected
                      ? AppColor.roleSelectedIconSurface
                      : AppColor.roleIconSurface,
                ),
                child: RoleMark(
                  role: role,
                  color: selected
                      ? AppColor.roleAccent
                      : AppColor.textSecondary,
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
                  color: selected ? AppColor.roleAccent : AppColor.transparent,
                  border: Border.all(
                    color: selected ? AppColor.roleAccent : AppColor.border,
                    width: 1.5,
                  ),
                ),
                child: selected
                    ? const Icon(
                        Icons.check_rounded,
                        color: AppColor.surface,
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
