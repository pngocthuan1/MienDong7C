import 'package:benhvien7c/core/viewmodels/BaseViewModel.dart';

class TypeFourProcessingViewModel extends BaseViewModel {
  bool _hasForwarded = false;

  bool get hasForwarded => _hasForwarded;

  void markForwarded() {
    if (_hasForwarded) {
      return;
    }

    _hasForwarded = true;
    notifyListeners();
  }
}
