import 'package:benhvien7c/core/theme/AppColors.dart';
import 'package:benhvien7c/core/theme/AppSizes.dart';
import 'package:flutter/material.dart';

enum AppButtonVariant { primary, tonal, text }

class AppButton extends StatelessWidget {
  const AppButton({
    required this.label,
    required this.onPressed,
    super.key,
    this.isLoading = false,
    this.variant = AppButtonVariant.primary,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final AppButtonVariant variant;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final progressColor = switch (variant) {
      AppButtonVariant.primary => Colors.white,
      AppButtonVariant.tonal => AppColors.primaryDark,
      AppButtonVariant.text => AppColors.primary,
    };

    final child = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isLoading)
          SizedBox(
            height: 18,
            width: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            ),
          )
        else if (icon != null)
          Icon(icon, size: 18),
        if (isLoading || icon != null) const SizedBox(width: 10),
        Text(label),
      ],
    );

    switch (variant) {
      case AppButtonVariant.primary:
        return SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: isLoading ? null : onPressed,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(56),
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.buttonRadius),
              ),
              textStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            child: child,
          ),
        );
      case AppButtonVariant.tonal:
        return SizedBox(
          width: double.infinity,
          child: FilledButton.tonal(
            onPressed: isLoading ? null : onPressed,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primarySoft,
              foregroundColor: AppColors.primaryDark,
              minimumSize: const Size.fromHeight(56),
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.buttonRadius),
              ),
              textStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            child: child,
          ),
        );
      case AppButtonVariant.text:
        return TextButton(
          onPressed: isLoading ? null : onPressed,
          child: child,
        );
    }
  }
}
