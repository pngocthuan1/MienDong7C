import 'package:flutter/material.dart';
import 'package:benhvien7c/core/theme/AppColors.dart';
import 'package:benhvien7c/core/theme/AppSizes.dart';
import 'package:benhvien7c/features/auth/domain/entities/UserRole.dart';

class AuthRoleSwitcher extends StatelessWidget {
  const AuthRoleSwitcher({
    required this.selectedRole,
    required this.onChanged,
    this.axis = Axis.horizontal,
    super.key,
  });

  final UserRole selectedRole;
  final ValueChanged<UserRole> onChanged;
  final Axis axis;

  @override
  Widget build(BuildContext context) {
    if (axis == Axis.vertical) {
      return _VerticalRoleSwitcher(
        selectedRole: selectedRole,
        onChanged: onChanged,
      );
    }

    return _HorizontalRoleSwitcher(
      selectedRole: selectedRole,
      onChanged: onChanged,
    );
  }
}

class _HorizontalRoleSwitcher extends StatelessWidget {
  const _HorizontalRoleSwitcher({
    required this.selectedRole,
    required this.onChanged,
  });

  final UserRole selectedRole;
  final ValueChanged<UserRole> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(AppSizes.fieldRadius),
        border: Border.all(color: const Color(0xFFD6E6F8)),
      ),
      child: Row(
        children: UserRole.values.map((role) {
          final selected = selectedRole == role;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(role),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: selected ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppSizes.fieldRadius - 2),
                ),
                child: Text(
                  role.label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: selected ? Colors.white : AppColors.primaryDark,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _VerticalRoleSwitcher extends StatelessWidget {
  const _VerticalRoleSwitcher({
    required this.selectedRole,
    required this.onChanged,
  });

  final UserRole selectedRole;
  final ValueChanged<UserRole> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: UserRole.values.map((role) {
        final isLast = role == UserRole.values.last;
        return Padding(
          padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
          child: _VerticalRoleOption(
            role: role,
            selected: selectedRole == role,
            onTap: () => onChanged(role),
          ),
        );
      }).toList(),
    );
  }
}

class _VerticalRoleOption extends StatelessWidget {
  const _VerticalRoleOption({
    required this.role,
    required this.selected,
    required this.onTap,
  });

  final UserRole role;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? AppColors.primarySoft : Colors.white,
          borderRadius: BorderRadius.circular(AppSizes.fieldRadius),
          border: Border.all(
            color: selected ? AppColors.primary : const Color(0xFFD6E6F8),
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: selected ? AppColors.primary : const Color(0xFFF3F8FD),
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: Icon(
                _iconForRole(role),
                color: selected ? Colors.white : AppColors.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    role.label,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _subtitleForRole(role),
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? AppColors.primary : Colors.white,
                border: Border.all(
                  color: selected ? AppColors.primary : const Color(0xFFA7BDD5),
                  width: 2,
                ),
              ),
              child: selected
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

IconData _iconForRole(UserRole role) {
  switch (role) {
    case UserRole.customer:
      return Icons.person_outline_rounded;
    case UserRole.employee:
      return Icons.badge_outlined;
  }
}

String _subtitleForRole(UserRole role) {
  switch (role) {
    case UserRole.customer:
      return 'Dành cho khách hàng đặt lịch và theo dõi hồ sơ.';
    case UserRole.employee:
      return 'Dành cho nhân viên tiếp nhận và hỗ trợ người bệnh.';
  }
}
