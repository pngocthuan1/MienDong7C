import 'package:benhvien7c/core/theme/AppColors.dart';
import 'package:benhvien7c/core/utils/AppInputFormatters.dart';
import 'package:flutter/material.dart';

class AppOtpField extends StatefulWidget {
  const AppOtpField({
    required this.controller,
    super.key,
    this.validator,
    this.onChanged,
    this.autofocus = false,
  });

  final TextEditingController controller;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final bool autofocus;

  @override
  State<AppOtpField> createState() => _AppOtpFieldState();
}

class _AppOtpFieldState extends State<AppOtpField> {
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode()..addListener(_handleFocusChanged);
    widget.controller.addListener(_handleTextChanged);
  }

  @override
  void didUpdateWidget(covariant AppOtpField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller == widget.controller) {
      return;
    }

    oldWidget.controller.removeListener(_handleTextChanged);
    widget.controller.addListener(_handleTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleTextChanged);
    _focusNode
      ..removeListener(_handleFocusChanged)
      ..dispose();
    super.dispose();
  }

  void _handleFocusChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _handleTextChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return FormField<String>(
      initialValue: widget.controller.text,
      validator: widget.validator,
      builder: (field) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () => _focusNode.requestFocus(),
              child: SizedBox(
                height: 60,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Opacity(
                        opacity: 0,
                        child: TextField(
                          controller: widget.controller,
                          focusNode: _focusNode,
                          autofocus: widget.autofocus,
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.done,
                          inputFormatters: AppInputFormatters.otp,
                          maxLength: 6,
                          showCursor: false,
                          style: const TextStyle(color: Colors.transparent),
                          decoration: const InputDecoration(
                            counterText: '',
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                          onChanged: (value) {
                            field.didChange(value);
                            if (field.hasError) {
                              field.validate();
                            }
                            widget.onChanged?.call(value);
                          },
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: IgnorePointer(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            const spacing = 8.0;
                            final boxWidth =
                                ((constraints.maxWidth - (spacing * 5)) / 6)
                                    .clamp(42.0, 56.0);

                            return Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(6, (index) {
                                final text = widget.controller.text;
                                final char = index < text.length
                                    ? text[index]
                                    : '';
                                final isActive =
                                    _focusNode.hasFocus &&
                                    (index == text.length ||
                                        (text.length == 6 && index == 5));
                                final isFilled = char.isNotEmpty;

                                return Padding(
                                  padding: EdgeInsets.only(
                                    right: index == 5 ? 0 : spacing,
                                  ),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 180),
                                    width: boxWidth,
                                    height: 48,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: isFilled
                                          ? const Color(0xFFF3F7FF)
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isActive
                                            ? AppColors.primary
                                            : const Color(0xFFD8E1F2),
                                        width: isActive ? 1.6 : 1,
                                      ),
                                    ),
                                    child: Text(
                                      char,
                                      style: const TextStyle(
                                        color: AppColors.textPrimary,
                                        fontSize: 22,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (field.hasError) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  field.errorText ?? '',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
