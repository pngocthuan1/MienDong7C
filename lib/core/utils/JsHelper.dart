import 'package:flutter/foundation.dart';

void executeJsEval(String jsCode) {
  if (kIsWeb && kDebugMode) {
    debugPrint('[JsEval] Web JS Execution (len: ${jsCode.length})');
  }
}
