import 'package:flutter/material.dart';
import 'package:benhvien7c/core/theme/AppSizes.dart';

class AuthCardShell extends StatelessWidget {
  const AuthCardShell({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.screenHorizontalPadding),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppSizes.cardRadius),
              border: Border.all(color: const Color(0xFFDCEAF8)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x140A4F95),
                  blurRadius: 28,
                  offset: Offset(0, 18),
                ),
              ],
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
