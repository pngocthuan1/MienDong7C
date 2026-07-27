import 'package:flutter/material.dart';
import 'package:benhvien7c/core/theme/AppColors.dart';

class HomeActionCard extends StatelessWidget {
  const HomeActionCard({
    required this.title,
    required this.icon,
    required this.onTap,
    super.key,
    this.badgeCount,
    this.gradient,
  });

  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final int? badgeCount;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 188,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: const Color(0xFF6AA6E8)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x120A4F95),
                blurRadius: 22,
                offset: Offset(0, 14),
              ),
            ],
          ),
          child: Stack(
            children: [
              Align(
                alignment: Alignment.topRight,
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient:
                        gradient ??
                        const LinearGradient(
                          colors: [Color(0xFFDDF0FF), Color(0xFFF8FCFF)],
                        ),
                  ),
                ),
              ),
              if (badgeCount != null)
                Align(
                  alignment: Alignment.topRight,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.mail_outline_rounded,
                          color: Colors.lightGreenAccent,
                          size: 22,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '$badgeCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 22,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: Icon(icon, size: 78, color: AppColors.primary),
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
