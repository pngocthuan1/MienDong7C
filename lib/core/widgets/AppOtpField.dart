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
                height: 56,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: TextField(
                        controller: widget.controller,
                        focusNode: _focusNode,
                        autofocus: widget.autofocus,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.done,
                        inputFormatters: AppInputFormatters.otp,
                        maxLength: 6,
                        showCursor: false,
                        style: const TextStyle(color: Colors.transparent, fontSize: 18),
                        decoration: const InputDecoration(
                          counterText: '',
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                          fillColor: Colors.transparent,
                          filled: false,
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
                    Positioned.fill(
                      child: IgnorePointer(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final totalWidth = constraints.maxWidth;
                            const count = 6;
                            const idealBoxWidth = 48.0;
                            const minSpacing = 4.0;
                            const maxSpacing = 8.0;

                            double boxWidth = (totalWidth - (minSpacing * (count - 1))) / count;
                            if (boxWidth > idealBoxWidth) {
                              boxWidth = idealBoxWidth;
                            }

                            double spacing = (totalWidth - (boxWidth * count)) / (count - 1);
                            if (spacing > maxSpacing) {
                              spacing = maxSpacing;
                            }
                            if (spacing < 0) spacing = 0;

                            return FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.center,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(count, (index) {
                                  final text = widget.controller.text;
                                  final char = index < text.length ? text[index] : '';
                                  final isActive = _focusNode.hasFocus &&
                                      (index == text.length || (text.length == 6 && index == 5));

                                  return Container(
                                    margin: EdgeInsets.only(
                                      right: index == count - 1 ? 0 : spacing,
                                    ),
                                    width: boxWidth,
                                    height: 54,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: isActive
                                            ? AppColors.primary
                                            : const Color(0xFFE2E8F0),
                                        width: isActive ? 1.5 : 1.0,
                                      ),
                                    ),
                                    child: Text(
                                      char,
                                      style: const TextStyle(
                                        color: Color(0xFF1E293B),
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  );
                                }),
                              ),
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
