import 'package:flutter/foundation.dart';
import 'package:benhvien7c/features/auth/domain/entities/AuthSessionEntity.dart';
import 'package:benhvien7c/features/auth/domain/entities/UserRole.dart';

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

  AuthSessionEntity? get session => _session;
  UserProfileSession? get currentUser => _currentUser;

  bool get isEmployee => _currentUser?.role == UserRole.employee;

  void setSession(AuthSessionEntity session, UserProfileSession user) {
    _session = session;
    _currentUser = user;
    notifyListeners();
  }

  void clear() {
    _session = null;
    _currentUser = null;
    notifyListeners();
  }
}
