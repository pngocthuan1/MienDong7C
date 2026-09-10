import 'package:benhvien7c/core/commands/command.dart';
import 'package:benhvien7c/core/commands/result.dart';
import 'package:benhvien7c/core/session/AppSessionStore.dart';
import 'package:benhvien7c/features/patients/domain/entities/NotificationSummaryEntity.dart';
import 'package:benhvien7c/features/patients/domain/repositories/PortalRepository.dart';
import 'package:benhvien7c/features/patients/presentation/viewmodels/BasePortalViewModel.dart';

class HomeViewModel extends BasePortalViewModel {
  HomeViewModel(PortalRepository repository, AppSessionStore sessionStore)
    : super(repository, sessionStore) {
    loadCommand = Command0<NotificationSummaryEntity>(_loadSummary);
    loadCommand.execute();
  }

  late final Command0<NotificationSummaryEntity> loadCommand;
  NotificationSummaryEntity summary = const NotificationSummaryEntity(
    total: 0,
    unread: 0,
    important: 0,
  );


  Future<Result<NotificationSummaryEntity>> _loadSummary() async {
    return runSafely(() async {
      final result = await portalRepository.loadNotificationSummary(role);
      result.when(
        ok: (data) {
          if(isDisposed) return;
          summary = data;
          clearMessage();
          notifyListeners();
        },
        error: (_, message) {
          if(isDisposed) return;
          setMessage(message);
          notifyListeners();
        },
      );
      return result;
    });
  }

  @override
  void dispose() {
    loadCommand.dispose();
    super.dispose();
  }
}
