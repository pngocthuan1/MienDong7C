import 'package:benhvien7c/features/patients/presentation/viewmodels/BasePortalViewModel.dart';
import 'package:benhvien7c/features/patients/domain/repositories/PortalRepository.dart';
import 'package:benhvien7c/core/session/AppSessionStore.dart';

class DevTestingViewModel extends BasePortalViewModel {
  DevTestingViewModel(
    PortalRepository repository,
    AppSessionStore sessionStore,
  ) : super(repository, sessionStore);
}
