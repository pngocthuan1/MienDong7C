import 'package:benhvien7c/core/viewmodels/BaseViewModel.dart';

class TypeFourResultViewModel extends BaseViewModel {
  List<String> get highlights => const [
        'Bạn đang ở bước C của luồng dạng 4.',
        'Bấm back một lần sẽ quay về bước B vì B vẫn còn nằm trong stack.',
        'Từ bước B bấm back lần nữa mới quay về lại bước A ban đầu.',
      ];
}
