import 'package:flutter/foundation.dart';
import 'package:benhvien7c/core/commands/result.dart';

abstract class BaseViewModel extends ChangeNotifier {
  String? _message;
  String? get message => _message;
  // Cờ đánh dấu ViewModel đã dispose() hay chưa. Dùng để chặn
  // notifyListeners() gọi sau khi ViewModel đã bị hủy — trường hợp này
  // xảy ra khi 1 async action (network call trong runSafely, hoặc lệnh
  // gọi ở constructor kiểu loadCommand.execute() không await) vẫn đang
  // chạy dở trong lúc người dùng đã rời màn hình và ViewModel bị dispose.
  // Nếu không chặn, notifyListeners() sau dispose sẽ throw ở debug mode:
  // "A ViewModel was used after being disposed."
  bool _isDisposed = false;
  bool get isDisposed => _isDisposed;


  void setMessage(String message) {
    if (_isDisposed) return;
    _message = message;
    notifyListeners();
  }

  void clearMessage() {
    if (_isDisposed) return;
    _message = null;
    notifyListeners();
  }

  /// Gọi thay cho notifyListeners() trực tiếp ở các ViewModel con khi cần
  /// notify sau 1 async gap, để tự động được bảo vệ khỏi dispose-race.
  
  void notifyIfMounted() {
    if (_isDisposed) return;
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

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();  
  }
}
