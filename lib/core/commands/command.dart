import 'package:flutter/foundation.dart';
import 'package:benhvien7c/core/commands/result.dart';

class Command0<T> extends ChangeNotifier {
  final Future<Result<T>> Function() _action;
  bool _running = false;
  Result<T>? _result;

  Command0(this._action);

  bool get running => _running;
  Result<T>? get result => _result;

  Future<void> execute() async {
    if (_running) return;
    _running = true;
    _result = null;
    notifyListeners();

    try {
      _result = await _action();
    } catch (_) {
      // Result covers errors
    } finally {
      _running = false;
      notifyListeners();
    }
  }

  void clearResult() {
    _result = null;
    notifyListeners();
  }
}

class Command1<T, P> extends ChangeNotifier {
  final Future<Result<T>> Function(P) _action;
  bool _running = false;
  Result<T>? _result;

  Command1(this._action);

  bool get running => _running;
  Result<T>? get result => _result;

  Object? get error {
    final res = _result;
    if (res != null) {
      return res.when(
        ok: (_) => null,
        error: (ex, msg) => msg,
      );
    }
    return null;
  }

  Future<void> execute(P param) async {
    if (_running) return;
    _running = true;
    _result = null;
    notifyListeners();

    try {
      _result = await _action(param);
    } catch (_) {
    } finally {
      _running = false;
      notifyListeners();
    }
  }

  void clearResult() {
    _result = null;
    notifyListeners();
  }
}
