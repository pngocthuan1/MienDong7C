import 'package:flutter/foundation.dart';
import 'package:benhvien7c/features/auth/domain/entities/AuthSessionEntity.dart';
import 'package:benhvien7c/features/auth/domain/entities/UserRole.dart';
import 'package:benhvien7c/features/patients/domain/entities/NotificationSummaryEntity.dart';

class UserProfileSession {
  final String fullName;
  final String phoneNumber;
  final UserRole role;

  const UserProfileSession({
    required this.fullName,
    required this.phoneNumber,
    required this.role,
  });
}

class AppSessionStore extends ChangeNotifier {
  AppSessionStore._();
  
  static final AppSessionStore instance = AppSessionStore._();

  AuthSessionEntity? _session;
  UserProfileSession? _currentUser;
  NotificationSummaryEntity _notificationSummary = const NotificationSummaryEntity(
    total: 0,
    unread: 0,
    important: 0,
  );

  AuthSessionEntity? get session => _session;
  UserProfileSession? get currentUser => _currentUser;
  NotificationSummaryEntity get notificationSummary => _notificationSummary;

  bool get isEmployee => _currentUser?.role == UserRole.employee;

  void setSession(AuthSessionEntity session, UserProfileSession user) {
    _session = session;
    _currentUser = user;
    notifyListeners();
  }

  void updateNotificationSummary(NotificationSummaryEntity summary) {
    _notificationSummary = summary;
    notifyListeners();
  }

  void updateFullName(String name) {
    if (_currentUser != null && name.trim().isNotEmpty) {
      _currentUser = UserProfileSession(
        fullName: name.trim(),
        phoneNumber: _currentUser!.phoneNumber,
        role: _currentUser!.role,
      );
      notifyListeners();
    }
  }

  void clear() {
    _session = null;
    _currentUser = null;
    _notificationSummary = const NotificationSummaryEntity(
      total: 0,
      unread: 0,
      important: 0,
    );
    notifyListeners();
  }
}
