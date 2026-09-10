import 'package:flutter/material.dart';
import 'package:benhvien7c/core/theme/AppColors.dart';
import 'package:benhvien7c/core/theme/AppSizes.dart';
import 'package:benhvien7c/core/utils/Validators.dart';

class PasswordRuleBox extends StatelessWidget {
  const PasswordRuleBox({required this.password, super.key});

  final String password;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(AppSizes.fieldRadius),
        border: Border.all(color: const Color(0xFFD8E7F6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Mật khẩu nên bao gồm',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(height: 10),
          _RuleItem(
            isValid: Validators.hasMinPasswordLength(password),
            label: 'Tối thiểu 8 ký tự',
          ),
          _RuleItem(
            isValid: Validators.startsWithUppercase(password),
            label: 'Ít nhất 1 chữ hoa ở đầu',
          ),
          _RuleItem(
            isValid: Validators.hasNumber(password),
            label: 'Ít nhất 1 chữ số',
          ),
          _RuleItem(
            isValid: Validators.hasSpecialChar(password),
            label: 'Ít nhất 1 ký tự đặc biệt',
          ),
        ],
      ),
    );
  }
}

class _RuleItem extends StatelessWidget {
  const _RuleItem({required this.isValid, required this.label});

  final bool isValid;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Icon(
            isValid ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
            size: 18,
            color: isValid ? AppColors.success : AppColors.textSecondary,
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              color: isValid ? AppColors.primaryDark : AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
