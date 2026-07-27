import 'package:benhvien7c/core/commands/command.dart';
import 'package:benhvien7c/core/commands/result.dart';
import 'package:benhvien7c/core/session/AppSessionStore.dart';
import 'package:benhvien7c/features/patients/domain/entities/NotificationItemEntity.dart';
import 'package:benhvien7c/features/patients/domain/entities/NotificationSummaryEntity.dart';
import 'package:benhvien7c/features/patients/domain/repositories/PortalRepository.dart';
import 'package:benhvien7c/features/patients/presentation/viewmodels/BasePortalViewModel.dart';

enum NotificationFilter { all, unread, read, important, veryImportant }

class NotificationViewModel extends BasePortalViewModel {
  NotificationViewModel(
    PortalRepository repository,
    AppSessionStore sessionStore,
  ) : super(repository, sessionStore) {
    loadCommand = Command0<List<NotificationItemEntity>>(_loadNotifications);
  }

  late final Command0<List<NotificationItemEntity>> loadCommand;
  List<NotificationItemEntity> items = const [];
  NotificationSummaryEntity summary = const NotificationSummaryEntity(
    total: 0,
    unread: 0,
    important: 0,
  );

  NotificationFilter selectedFilter = NotificationFilter.all;

  List<NotificationItemEntity> get filteredItems {
    switch (selectedFilter) {
      case NotificationFilter.all:
        return items;
      case NotificationFilter.unread:
        return items.where((e) => !e.isRead).toList();
      case NotificationFilter.read:
        return items.where((e) => e.isRead).toList();
      case NotificationFilter.important:
        return items.where((e) => e.isImportant).toList();
      case NotificationFilter.veryImportant:
        return items.where((e) => e.isImportant && !e.isRead).toList();
    }
  }

  void setFilter(NotificationFilter filter) {
    selectedFilter = filter;
    notifyListeners();
  }

  bool _mutating = false;
  String? _selectedNotificationId;

  bool get isMutating => _mutating;

  NotificationItemEntity? get selectedNotification =>
      _findNotificationById(_selectedNotificationId);

  NotificationItemEntity? notificationById(String notificationId) {
    return _findNotificationById(notificationId);
  }

  Future<Result<List<NotificationItemEntity>>> _loadNotifications() async {
    return runSafely(() async {
      return _reloadState();
    });
  }

  Future<Result<String>> openNotification(String notificationId) async {
    _selectedNotificationId = notificationId;
    return _runMutation(
      () {
        return portalRepository.markNotificationAsRead(role, notificationId);
      },
      keepSelectedId: notificationId,
    );
  }

  Future<Result<String>> markAllAsRead() async {
    return _runMutation(() {
      return portalRepository.markAllNotificationsAsRead(role);
    });
  }

  Future<Result<String>> downloadAttachment(String notificationId, String customFileName) async {
    return _runMutation(
      () {
        return portalRepository.downloadNotificationAttachment(
          role,
          notificationId,
          customFileName,
        );
      },
      keepSelectedId: notificationId,
    );
  }

  Future<Result<String>> respondToNotification(
    String notificationId, {
    required bool approved,
  }) async {
    return _runMutation(
      () {
        return portalRepository.respondToNotification(
          role: role,
          notificationId: notificationId,
          approved: approved,
        );
      },
      keepSelectedId: notificationId,
    );
  }

  Future<Result<String>> deleteNotification(String notificationId) async {
    return _runMutation(
      () async {
        final result = await portalRepository.deleteNotification(role, notificationId);
        return result.when(
          ok: (_) => const Ok('Đã xóa thông báo thành công.'),
          error: (ex, msg) => Error(ex, msg),
        );
      },
      keepSelectedId: null,
    );
  }

  Future<Result<String>> toggleImportant(String notificationId) async {
    return _runMutation(
      () async {
        final result = await portalRepository.toggleImportant(role, notificationId);
        return result.when(
          ok: (_) => const Ok('Đã cập nhật trạng thái quan trọng.'),
          error: (ex, msg) => Error(ex, msg),
        );
      },
      keepSelectedId: notificationId,
    );
  }

  Future<Result<String>> _runMutation(
    Future<Result<String>> Function() action, {
    String? keepSelectedId,
  }) async {
    return runSafely(() async {
      _mutating = true;
      notifyListeners();

      try {
        final result = await action();
        if (result.isOk) {
          await _reloadState(keepSelectedId: keepSelectedId);
        }
        return result;
      } finally {
        _mutating = false;
        notifyListeners();
      }
    });
  }

  Future<Result<List<NotificationItemEntity>>> _reloadState({
    String? keepSelectedId,
  }) async {
    final summaryResult = await portalRepository.loadNotificationSummary(role);
    summaryResult.when(
      ok: (data) {
        summary = data;
      },
      error: (_, message) {
        setMessage(message);
      },
    );

    final notificationsResult = await portalRepository.loadNotifications(role);
    notificationsResult.when(
      ok: (data) {
        items = data;
        _selectedNotificationId = _resolveSelectedId(
          keepSelectedId ?? _selectedNotificationId,
        );
        clearMessage();
        notifyListeners();
      },
      error: (_, message) {
        setMessage(message);
      },
    );

    return notificationsResult;
  }

  String? _resolveSelectedId(String? preferredId) {
    if (preferredId != null && _findNotificationById(preferredId) != null) {
      return preferredId;
    }

    if (_selectedNotificationId != null &&
        _findNotificationById(_selectedNotificationId!) != null) {
      return _selectedNotificationId;
    }

    return null;
  }

  NotificationItemEntity? _findNotificationById(String? notificationId) {
    if (notificationId == null) {
      return null;
    }

    for (final item in items) {
      if (item.id == notificationId) {
        return item;
      }
    }

    return null;
  }

  @override
  void dispose() {
    loadCommand.dispose();
    super.dispose();
  }
}
