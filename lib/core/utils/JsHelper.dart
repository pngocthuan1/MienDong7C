import 'package:flutter/foundation.dart';

void executeJsEval(String jsCode) {
  if (kIsWeb) {
    debugPrint('[JsEval] Web JS Execution: $jsCode');
  }
}
