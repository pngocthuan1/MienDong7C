import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTextField extends StatelessWidget {
  const AppTextField({
    required this.controller,
    required this.label,
    super.key,
    this.hintText,
    this.keyboardType,
    this.textCapitalization,
    this.prefixIcon,
    this.validator,
    this.inputFormatters,
    this.textInputAction,
    this.onChanged,
    this.readOnly = false,
    this.readOnlyMessage,
    this.autovalidateMode,
  });

  final TextEditingController controller;
  final String label;
  final String? hintText;
  final TextInputType? keyboardType;
  final TextCapitalization? textCapitalization;
  final IconData? prefixIcon;
  final String? Function(String?)? validator;
  final List<TextInputFormatter>? inputFormatters;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final bool readOnly;
  final String? readOnlyMessage;
  final AutovalidateMode? autovalidateMode;

  Widget _buildLabelWidget(String text) {
    if (!text.contains('*')) {
      return Text(text);
    }
    final parts = text.split('*');
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: parts[0].trimRight()),
          const TextSpan(
            text: ' *',
            style: TextStyle(
              color: Color(0xFFEF4444),
              fontWeight: FontWeight.bold,
            ),
          ),
          if (parts.length > 1 && parts[1].isNotEmpty)
            TextSpan(text: parts[1]),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization ?? TextCapitalization.none,
      validator: validator,
      autovalidateMode: autovalidateMode,
      inputFormatters: inputFormatters,
      textInputAction: textInputAction,
      onChanged: onChanged,
      readOnly: readOnly,
      onTap: () {
        if (readOnly) {
          final message = readOnlyMessage ?? 'Không thể thay đổi hoặc xóa thông tin định danh của hồ sơ đã lưu.';
          if (message.isNotEmpty) {
            ScaffoldMessenger.of(context).clearSnackBars();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(message),
                backgroundColor: const Color(0xFFD97706),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        }
      },
      decoration: InputDecoration(
        label: _buildLabelWidget(label),
        floatingLabelBehavior: FloatingLabelBehavior.never,
        hintText: hintText,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
        filled: readOnly,
        fillColor: readOnly ? const Color(0xFFF1F5F9) : null,
        errorMaxLines: 5,
        errorStyle: const TextStyle(
          color: Color(0xFFEF4444),
          fontSize: 12.5,
          height: 1.35,
        ),
      ),
    );
  }
}
