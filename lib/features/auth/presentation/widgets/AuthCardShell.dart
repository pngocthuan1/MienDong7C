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
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F8FD),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFDBEAFE)),
                  ),
                  child: Column(
                    children: const [
                      Icon(
                        Icons.add_photo_alternate_outlined,
                        size: 40,
                        color: Color(0xFF2563EB),
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Vị trí chèn logo bệnh viện',
                        style: TextStyle(
                          color: Color(0xFF1E3A8A),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Bạn có thể thay khung này\nbằng ảnh logo sau.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 14,
                        ),
                      ),
                    ],
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
