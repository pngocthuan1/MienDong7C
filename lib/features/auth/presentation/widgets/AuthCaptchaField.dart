import 'package:flutter/material.dart';
import 'package:benhvien7c/core/theme/AppColors.dart';
import 'package:benhvien7c/core/theme/AppSizes.dart';
import 'package:benhvien7c/core/widgets/AppTextField.dart';

class AuthCaptchaField extends StatelessWidget {
  const AuthCaptchaField({
    required this.controller,
    required this.challenge,
    required this.onRefresh,
    required this.validator,
    super.key,
    this.onChanged,
    this.label = '\u004d\u00e3 x\u00e1c minh',
    this.hintText = '\u004e\u0068\u1eadp \u0111\u00fang m\u00e3 b\u00ean tr\u00ean',
  });

  final TextEditingController controller;
  final String challenge;
  final VoidCallback onRefresh;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final String label;
  final String hintText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.primarySoft,
            borderRadius: BorderRadius.circular(AppSizes.fieldRadius),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.security_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '\u0058\u00e1c minh b\u1ea1n kh\u00f4ng ph\u1ea3i robot',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      challenge,
                      style: const TextStyle(
                        color: AppColors.primaryDark,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '\u004e\u0068\u1eadp l\u1ea1i m\u00e3 b\u00ean d\u01b0\u1edbi',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: '\u0110\u1ed5i m\u00e3 x\u00e1c minh',
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh_rounded),
                color: AppColors.primary,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSizes.itemSpacing),
        AppTextField(
          controller: controller,
          label: label,
          hintText: hintText,
          keyboardType: TextInputType.text,
          textCapitalization: TextCapitalization.characters,
          prefixIcon: Icons.verified_outlined,
          validator: validator,
          textInputAction: TextInputAction.done,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
