import 'package:flutter/foundation.dart';
import 'package:benhvien7c/core/commands/result.dart';

class Command0<T> extends ChangeNotifier {
  final Future<Result<T>> Function() _action;
  bool _running = false;
  Result<T>? _result;
  bool _disposed = false;

  Command0(this._action);

  bool get running => _running;
  Result<T>? get result => _result;

  Future<void> execute() async {
    if (_running || _disposed) return;
    _running = true;
    _result = null;
    _notify();

    try {
      _result = await _action();
    } catch (e, stackTrace) {
      // Phòng hờ nếu _action() (thường là runSafely() từ BaseViewModel)
      // vẫn để lọt exception ra ngoài phạm vi try/catch của nó — ví dụ
      // lỗi bên trong callback result.when(...). Log lại thay vì nuốt
      // im lặng, để không rơi vào trạng thái _result == null vĩnh viễn.
      debugPrint('[Command0] Unhandled error during execute(): $e');
      debugPrintStack(stackTrace: stackTrace);
      _result = Error<T>(e is Exception ? e : Exception(e.toString()), e.toString());
    } finally {
      _running = false;
      _notify();
    }
  }

  void clearResult() {
    _result = null;
    _notify();
  }

  // Gọi notifyListeners() có kiểm tra disposed trước, tránh crash
  // "used after being disposed" nếu ViewModel cha gọi dispose() trong
  // lúc execute() vẫn đang chờ await _action().
  void _notify() {
    if (_disposed) return;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

class Command1<T, P> extends ChangeNotifier {
  final Future<Result<T>> Function(P) _action;
  bool _running = false;
  Result<T>? _result;
  bool _disposed = false;

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
    if (_running || _disposed) return;
    _running = true;
    _result = null;
    _notify();

    try {
      _result = await _action(param);
    } catch (e, stackTrace) {
      debugPrint('[Command1] Unhandled error during execute(): $e');
      debugPrintStack(stackTrace: stackTrace);
      _result = Error<T>(e is Exception ? e : Exception(e.toString()), e.toString());
    } finally {
      _running = false;
      _notify();
    }
  }

  void clearResult() {
    _result = null;
    _notify();
  }

  void _notify() {
    if (_disposed) return;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}