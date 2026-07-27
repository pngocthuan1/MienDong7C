import 'package:flutter/foundation.dart';
import 'package:benhvien7c/core/commands/result.dart';

abstract class BaseViewModel extends ChangeNotifier {
  String? _message;
  String? get message => _message;

  void setMessage(String message) {
    _message = message;
    notifyListeners();
  }

  void clearMessage() {
    _message = null;
    notifyListeners();
  }

  Future<Result<T>> runSafely<T>(Future<Result<T>> Function() action) async {
    try {
      return await action();
    } on Exception catch (e) {
      final msg = e.toString();
      setMessage(msg);
      return Error<T>(e, msg);
    } catch (e) {
      final msg = e.toString();
      setMessage(msg);
      return Error<T>(Exception(msg), msg);
    }
  }
}
