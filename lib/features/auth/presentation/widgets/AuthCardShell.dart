import 'package:flutter/material.dart';
import 'package:benhvien7c/core/theme/AppSizes.dart';

class AuthCardShell extends StatelessWidget {
  const AuthCardShell({
    required this.child,
    this.onLogoTap,
    super.key,
  });

  final Widget child;
  final VoidCallback? onLogoTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.screenHorizontalPadding),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 450),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFDBEAFE)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0D1976D2), // shadow-[0_10px_30px_rgba(25,118,210,0.05)]
                  blurRadius: 30,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Shared Logo Placeholder
                GestureDetector(
                  onTap: onLogoTap,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F8FD),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFDBEAFE)),
                    ),
                    child: Column(
                      children: const [
                        Icon(
                          Icons.local_hospital_rounded,
                          size: 44,
                          color: Color(0xFF2563EB),
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Bệnh viện Miền Đông 7C',
                          style: TextStyle(
                            color: Color(0xFF1E3A8A),
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Hệ thống Đăng ký & Đặt lịch khám bệnh',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
