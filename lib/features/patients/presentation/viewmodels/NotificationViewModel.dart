import 'package:benhvien7c/core/commands/command.dart';
import 'package:benhvien7c/core/commands/result.dart';
import 'package:benhvien7c/core/session/AppSessionStore.dart';
import 'package:benhvien7c/features/patients/domain/entities/NotificationItemEntity.dart';
import 'package:benhvien7c/features/patients/domain/entities/NotificationSummaryEntity.dart';
import 'package:benhvien7c/features/patients/domain/entities/NotificationReadStatusEntity.dart';
import 'package:benhvien7c/features/patients/domain/repositories/PortalRepository.dart';
import 'package:benhvien7c/features/patients/presentation/viewmodels/BasePortalViewModel.dart';

enum NotificationFilter { all, unread, read, important, veryImportant }

class NotificationViewModel extends BasePortalViewModel {
  NotificationViewModel(
    PortalRepository repository,
    AppSessionStore sessionStore,
  ) : super(repository, sessionStore) {
    loadCommand = Command0<List<NotificationItemEntity>>(_loadNotifications);
    loadReadStatusCommand = Command1<List<NotificationReadStatusEntity>, String>(_loadReadStatus);
  }

  late final Command0<List<NotificationItemEntity>> loadCommand;
  late final Command1<List<NotificationReadStatusEntity>, String> loadReadStatusCommand;
  List<NotificationItemEntity> items = const [];
  List<NotificationReadStatusEntity> readStatuses = const [];
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
    notifyIfMounted();
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
        final result = await portalRepository.toggleNotificationImportant(role, notificationId);
        return result.when(
          ok: (isImportant) => Ok (isImportant
              ? 'Đã đánh dấu thông báo là quan trọng.'
              : 'Đã bỏ đánh dấu thông báo là quan trọng.'),
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
    // Chặn double-tap / mutation chồng lệnh: nếu đang có 1 thao tác khác
    // (xóa, đánh dấu, mở thông báo...) chạy dở, không cho phép chạy thêm
    // — tránh gửi 2 request song song lên server và tránh _mutating bị
    // 2 luồng ghi đè lẫn nhau (luồng A set false trong khi luồng B vẫn
    // đang chạy, khiến UI hiển thị sai trạng thái loading).
    if (_mutating) {
      const msg = 'Đang xử lý thao tác trước đó, vui lòng đợi.';
      return Error(Exception(msg), msg);
    }

    return runSafely(() async {
      _mutating = true;
      notifyIfMounted();

      try {
        final result = await action();
        if (result.isOk) {
          await _reloadState(keepSelectedId: keepSelectedId);
        }
        return result;
      } finally {
        _mutating = false;
        notifyIfMounted();
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
        final sortedList = List<NotificationItemEntity>.from(data);
        final now = DateTime.now();
        sortedList.sort((a, b) {
          final isAToday = a.createdAt.year == now.year &&
              a.createdAt.month == now.month &&
              a.createdAt.day == now.day;
          final isBToday = b.createdAt.year == now.year &&
              b.createdAt.month == now.month &&
              b.createdAt.day == now.day;

          if (isAToday && !isBToday) return -1;
          if (!isAToday && isBToday) return 1;
          return b.createdAt.compareTo(a.createdAt);
        });

        items = sortedList;
        summary = NotificationSummaryEntity(
          total: sortedList.length,
          unread: sortedList.where((e) => !e.isRead).length,
          important: sortedList.where((e) => e.isImportant).length,
          lastUpdatedLabel: sortedList.isNotEmpty ? sortedList.first.timeLabel : '',
        );
        AppSessionStore.instance.updateNotificationSummary(summary);
        _selectedNotificationId = _resolveSelectedId(
          keepSelectedId ?? _selectedNotificationId,
        );
        clearMessage();
        notifyIfMounted();
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

  Future<Result<List<NotificationReadStatusEntity>>> _loadReadStatus(String notificationId) async {
    return runSafely(() async {
      final res = await portalRepository.loadNotificationReadStatus(notificationId);
      return res.when(
        ok: (data) {
          readStatuses = data;
          notifyListeners();
          return Ok(data);
        },
        error: (ex, msg) => Error(ex, msg),
      );
    });
  }

  @override
  void dispose() {
    loadCommand.dispose();
    loadReadStatusCommand.dispose();
    super.dispose();
  }
}
