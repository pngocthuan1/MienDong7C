import 'package:flutter/material.dart';
import 'package:benhvien7c/core/commands/command.dart';
import 'package:benhvien7c/core/commands/result.dart';
import 'package:benhvien7c/core/session/AppSessionStore.dart';
import 'package:benhvien7c/features/patients/domain/entities/UserManagementUserEntity.dart';
import 'package:benhvien7c/features/patients/domain/entities/UserManagementVisitStatus.dart';
import 'package:benhvien7c/features/patients/domain/repositories/PortalRepository.dart';
import 'package:benhvien7c/features/patients/presentation/viewmodels/BasePortalViewModel.dart';

class UserManagementViewModel extends BasePortalViewModel {
  UserManagementViewModel(
    PortalRepository repository,
    AppSessionStore sessionStore,
  ) : super(repository, sessionStore) {
    loadCommand = Command0<List<UserManagementUserEntity>>(_loadUsers);
  }

  late final Command0<List<UserManagementUserEntity>> loadCommand;
  final searchController = TextEditingController();

  List<UserManagementUserEntity> _users = const [];
  UserManagementVisitStatus? _selectedStatus;

  List<UserManagementUserEntity> get users => _users;
  UserManagementVisitStatus? get selectedStatus => _selectedStatus;

  List<UserManagementUserEntity> get filteredUsers {
    try {
      final query = searchController.text.trim().toLowerCase();
      return _users
          .where((user) {
            final matchesStatus =
                _selectedStatus == null ||
                user.currentStatus == _selectedStatus;
            if (!matchesStatus) {
              return false;
            }

            if (query.isEmpty) {
              return true;
            }

            return user.fullName.toLowerCase().contains(query) ||
                user.phoneNumber.contains(query) ||
                user.patientCode.toLowerCase().contains(query);
          })
          .toList(growable: false);
    } catch (_) {
      return _users;
    }
  }

  Map<UserManagementVisitStatus, int> get statusCounts {
    try {
      final counts = {
        for (final status in UserManagementVisitStatus.values) status: 0,
      };
      for (final user in _users) {
        counts[user.currentStatus] = (counts[user.currentStatus] ?? 0) + 1;
      }
      return counts;
    } catch (_) {
      return {for (final status in UserManagementVisitStatus.values) status: 0};
    }
  }

  int get activeUsersCount {
    try {
      return _users.where((user) => user.currentStatus.isActiveFlow).length;
    } catch (_) {
      return 0;
    }
  }

  int get completedUsersCount {
    try {
      return _users
          .where(
            (user) => user.currentStatus == UserManagementVisitStatus.completed,
          )
          .length;
    } catch (_) {
      return 0;
    }
  }

  int get rejectedUsersCount {
    try {
      return _users
          .where(
            (user) => user.currentStatus == UserManagementVisitStatus.rejected,
          )
          .length;
    } catch (_) {
      return 0;
    }
  }

  void updateSearch(String value) {
    try {
      clearMessage();
      notifyListeners();
    } catch (_) {}
  }

  void selectStatus(UserManagementVisitStatus? status) {
    try {
      if (_selectedStatus == status) {
        return;
      }
      _selectedStatus = status;
      notifyListeners();
    } catch (_) {}
  }

  Future<Result<List<UserManagementUserEntity>>> _loadUsers() async {
    return runSafely(() async {
      if (!session.isEmployee) {
        final error = Exception('Chỉ nhân viên mới được quản lý người dùng.');
        setMessage(error.toString());
        return Error<List<UserManagementUserEntity>>(error, error.toString());
      }

      final result = await portalRepository.loadManagedUsers(role);
      result.when(
        ok: (data) {
          _users = data;
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
    searchController.dispose();
    loadCommand.dispose();
    super.dispose();
  }
}
