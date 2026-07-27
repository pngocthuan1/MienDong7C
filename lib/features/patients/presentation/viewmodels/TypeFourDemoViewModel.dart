import 'package:benhvien7c/core/session/AppSessionStore.dart';
import 'package:benhvien7c/features/patients/domain/repositories/PortalRepository.dart';
import 'package:benhvien7c/features/patients/presentation/viewmodels/BasePortalViewModel.dart';

class TypeFourDemoViewModel extends BasePortalViewModel {
  TypeFourDemoViewModel(
    PortalRepository repository,
    AppSessionStore sessionStore,
  ) : super(repository, sessionStore);

  String get roleSummary => session.isEmployee
      ? 'Tài khoản nhân viên hợp với các luồng kiểm tra phiên, phân quyền hoặc tiếp nhận hồ sơ tự động trước khi vào bước chính.'
      : 'Tài khoản khách hàng hợp với các luồng quét QR, kiểm tra trạng thái hồ sơ hoặc tải dữ liệu ngắn trước khi vào bước chính.';

  String get roleBadge => session.user.role.label;
}
