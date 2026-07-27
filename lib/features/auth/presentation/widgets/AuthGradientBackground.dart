import 'package:flutter/material.dart';
import 'package:benhvien7c/core/theme/AppColors.dart';

class AuthGradientBackground extends StatelessWidget {
  const AuthGradientBackground({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFE8F5FF),
                  Color(0xFFF7FBFF),
                  Color(0xFFDFF1FF),
                ],
              ),
            ),
          ),
          Positioned(
            top: -60,
            right: -20,
            child: _GlowBubble(
              size: 180,
              color: AppColors.primary.withValues(alpha: 0.10),
            ),
          ),
          Positioned(
            bottom: 80,
            left: -40,
            child: _GlowBubble(
              size: 140,
              color: AppColors.accent.withValues(alpha: 0.12),
            ),
          ),
          SafeArea(child: child),
        ],
      ),
    );
  }
}

class _GlowBubble extends StatelessWidget {
  const _GlowBubble({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}
