import 'package:flutter/services.dart';

class AppInputFormatters {
  const AppInputFormatters._();

  static final List<TextInputFormatter> phoneNumber = [
    FilteringTextInputFormatter.digitsOnly,
    LengthLimitingTextInputFormatter(10),
  ];

  static final List<TextInputFormatter> otp = [
    FilteringTextInputFormatter.digitsOnly,
    LengthLimitingTextInputFormatter(6),
  ];
}
