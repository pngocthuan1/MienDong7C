import 'package:benhvien7c/core/commands/command.dart';
import 'package:benhvien7c/core/commands/result.dart';
import 'package:benhvien7c/core/session/AppSessionStore.dart';
import 'package:benhvien7c/features/patients/domain/entities/UserManagementDetailEntity.dart';
import 'package:benhvien7c/features/patients/domain/entities/UserManagementVisitStatus.dart';
import 'package:benhvien7c/features/patients/domain/repositories/PortalRepository.dart';
import 'package:benhvien7c/features/patients/presentation/viewmodels/BasePortalViewModel.dart';

class UserManagementDetailViewModel extends BasePortalViewModel {
  UserManagementDetailViewModel(
    PortalRepository repository,
    AppSessionStore sessionStore, {
    required this.userId,
  }) : super(repository, sessionStore) {
    loadCommand = Command0<UserManagementDetailEntity>(_loadDetail);
  }

  final String userId;
  late final Command0<UserManagementDetailEntity> loadCommand;

  UserManagementDetailEntity? detail;

  Map<UserManagementVisitStatus, int> get historyStatusCounts {
    try {
      final counts = {
        for (final status in UserManagementVisitStatus.values) status: 0,
      };
      for (final history in detail?.histories ?? const []) {
        counts[history.status] = (counts[history.status] ?? 0) + 1;
      }
      return counts;
    } catch (_) {
      return {for (final status in UserManagementVisitStatus.values) status: 0};
    }
  }

  Future<Result<UserManagementDetailEntity>> _loadDetail() async {
    return runSafely(() async {
      if (!session.isEmployee) {
        final error = Exception(
          'Chỉ nhân viên mới được xem chi tiết người dùng.',
        );
        setMessage(error.toString());
        return Error<UserManagementDetailEntity>(error, error.toString());
      }

      final result = await portalRepository.loadManagedUserDetail(role, userId);
      result.when(
        ok: (data) {
          detail = data;
          clearMessage();
          notifyListeners();
        },
        error: (_, message) {
          setMessage(message);
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
