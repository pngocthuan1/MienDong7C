import 'package:flutter/material.dart';

class PasswordMatchIndicator extends StatelessWidget {
  const PasswordMatchIndicator({
    required this.password,
    required this.confirmPassword,
    super.key,
  });

  final String password;
  final String confirmPassword;

  @override
  Widget build(BuildContext context) {
    if (confirmPassword.isEmpty) {
      return const SizedBox.shrink();
    }

    final isMatched = (password == confirmPassword);

    final bgColor = isMatched ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2);
    final borderColor = isMatched ? const Color(0xFFBBF7D0) : const Color(0xFFFECACA);
    final textColor = isMatched ? const Color(0xFF15803D) : const Color(0xFFDC2626);
    final iconData = isMatched ? Icons.check_circle_rounded : Icons.cancel_rounded;
    final message = isMatched
        ? 'Mật khẩu nhập lại đã trùng khớp'
        : 'Mật khẩu nhập lại chưa trùng khớp';

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(
            iconData,
            size: 18,
            color: textColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
