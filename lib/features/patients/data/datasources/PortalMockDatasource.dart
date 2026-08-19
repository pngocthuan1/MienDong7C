import 'dart:math';
import 'dart:convert';
import 'package:benhvien7c/core/utils/JsHelper.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:benhvien7c/core/network/ApiException.dart';
import 'package:benhvien7c/features/auth/domain/entities/UserRole.dart';
import 'package:benhvien7c/features/patients/domain/entities/MedicalTicketEntity.dart';
import 'package:benhvien7c/features/patients/domain/entities/NotificationItemEntity.dart';
import 'package:benhvien7c/features/patients/domain/entities/NotificationSummaryEntity.dart';
import 'package:benhvien7c/features/patients/domain/entities/PatientProfileDraftEntity.dart';
import 'package:benhvien7c/features/patients/domain/entities/UserManagementDetailEntity.dart';
import 'package:benhvien7c/features/patients/domain/entities/UserManagementHistoryEntity.dart';
import 'package:benhvien7c/features/patients/domain/entities/UserManagementUserEntity.dart';
import 'package:benhvien7c/features/patients/domain/entities/UserManagementVisitStatus.dart';
import 'package:benhvien7c/features/patients/domain/entities/NotificationReadStatusEntity.dart';

class PortalMockDatasource {
  PortalMockDatasource();

  static final List<UserManagementUserEntity> _managedUsers = List.unmodifiable(
    _buildManagedUsers(),
  );

  static final Map<UserRole, List<NotificationItemEntity>> _notificationStore = {
    UserRole.customer: _buildCustomerNotifications(),
    UserRole.employee: _buildEmployeeNotifications(),
  };

  static bool _cacheInitialized = false;

  Future<void> _initCacheIfNeeded() async {
    if (_cacheInitialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      for (final role in UserRole.values) {
        final key = 'cached_notifications_${role.name}';
        final cachedJson = prefs.getString(key);
        if (cachedJson != null) {
          final List<dynamic> decoded = jsonDecode(cachedJson);
          final list = decoded
              .map((item) => NotificationItemEntity.fromJson(item as Map<String, dynamic>))
              .toList();
          _notificationStore[role] = list;
        } else {
          await _saveToCache(role);
        }
      }
      _cacheInitialized = true;
    } catch (_) {}
  }

  Future<void> _saveToCache(UserRole role) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'cached_notifications_${role.name}';
      final list = _notificationStore[role] ?? [];
      final encoded = jsonEncode(list.map((e) => e.toJson()).toList());
      await prefs.setString(key, encoded);
    } catch (_) {}
  }

  static NotificationItemEntity? getNotificationById(String id) {
    for (final list in _notificationStore.values) {
      for (final item in list) {
        if (item.id == id) {
          return item;
        }
      }
    }
    return null;
  }

  Future<NotificationSummaryEntity> loadNotificationSummary(
    UserRole role,
  ) async {
    await _initCacheIfNeeded();
    await Future<void>.delayed(const Duration(milliseconds: 250));
    final list = _notificationsFor(role);
    await _saveToCache(role);
    return NotificationSummaryEntity.fromNotifications(list);
  }

  Future<List<NotificationItemEntity>> loadNotifications(UserRole role) async {
    await _initCacheIfNeeded();
    await Future<void>.delayed(const Duration(milliseconds: 280));
    final list = _notificationsFor(role);
    await _saveToCache(role);
    return List<NotificationItemEntity>.unmodifiable(list);
  }

  Future<List<NotificationReadStatusEntity>> loadNotificationReadStatus(
    String notificationId,
  ) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));

    final mockRecipients = [
      {'name': 'Nguyễn Văn Nam', 'role': 'Khách hàng', 'userId': 'USR001'},
      {'name': 'Trần Thị Mỹ Linh', 'role': 'Khách hàng', 'userId': 'USR002'},
      {'name': 'Lê Hoàng Long', 'role': 'Bác sĩ', 'userId': 'USR003'},
      {'name': 'Phạm Ngọc Thuận', 'role': 'Khách hàng', 'userId': 'USR004'},
      {'name': 'Nguyễn Hoàng Giang', 'role': 'Khách hàng', 'userId': 'USR005'},
      {'name': 'Lê Nguyễn Gia Hưng', 'role': 'Bác sĩ', 'userId': 'USR006'},
      {'name': 'Trần Văn Cường', 'role': 'Khách hàng', 'userId': 'USR007'},
      {'name': 'Vương Gia Vĩ', 'role': 'Y tá', 'userId': 'USR008'},
      {'name': 'Đặng Ngọc Hoàng', 'role': 'Khách hàng', 'userId': 'USR009'},
      {'name': 'Bùi Thị Xuân', 'role': 'Khách hàng', 'userId': 'USR010'},
      {'name': 'Hoàng Minh Châu', 'role': 'Bác sĩ', 'userId': 'USR011'},
      {'name': 'Lý Tiểu Long', 'role': 'Khách hàng', 'userId': 'USR012'},
    ];

    final rand = Random(notificationId.hashCode);
    final List<NotificationReadStatusEntity> result = [];

    for (final recipient in mockRecipients) {
      final isRead = rand.nextDouble() < 0.65;
      DateTime? readTime;
      if (isRead) {
        readTime = DateTime.now().subtract(Duration(
          hours: rand.nextInt(36),
          minutes: rand.nextInt(60),
        ));
      }
      result.add(NotificationReadStatusEntity(
        userId: recipient['userId']!,
        userName: recipient['name']!,
        userRole: recipient['role']!,
        isRead: isRead,
        readAt: readTime,
      ));
    }

    result.sort((a, b) {
      if (a.isRead && !b.isRead) return -1;
      if (!a.isRead && b.isRead) return 1;
      if (a.isRead && b.isRead && a.readAt != null && b.readAt != null) {
        return b.readAt!.compareTo(a.readAt!);
      }
      return a.userName.compareTo(b.userName);
    });

    return result;
  }

  Future<String> markNotificationAsRead(
    UserRole role,
    String notificationId,
  ) async {
    await _initCacheIfNeeded();
    await Future<void>.delayed(const Duration(milliseconds: 200));
    final item = _updateNotification(
      role,
      notificationId,
      (notification) => notification.copyWith(isRead: true),
    );

    if (item == null) {
      throw ApiException.validation('Không tìm thấy thông báo cần xác nhận.');
    }

    await _saveToCache(role);

    return item.isRead
        ? 'Thông báo đã được đánh dấu đã đọc.'
        : 'Không thể cập nhật trạng thái thông báo.';
  }

  Future<String> markAllNotificationsAsRead(UserRole role) async {
    await _initCacheIfNeeded();
    await Future<void>.delayed(const Duration(milliseconds: 250));
    final notifications = _notificationStore[role];
    if (notifications == null) {
      throw ApiException.validation('Không tìm thấy danh sách thông báo.');
    }

    for (var index = 0; index < notifications.length; index++) {
      notifications[index] = notifications[index].copyWith(isRead: true);
    }

    await _saveToCache(role);

    return 'Tất cả thông báo đã được đánh dấu đã đọc.';
  }

  Future<String> downloadNotificationAttachment(
    UserRole role,
    String notificationId,
    String customFileName,
  ) async {
    await _initCacheIfNeeded();
    await Future<void>.delayed(const Duration(milliseconds: 240));
    final item = _findNotification(role, notificationId);
    if (item == null) {
      throw ApiException.validation('Không tìm thấy tài liệu cần tải.');
    }

    if (item.attachmentName == null || item.attachmentName!.trim().isEmpty) {
      throw ApiException.validation('Thông báo này không có tài liệu đính kèm.');
    }

    if (item.isDownloaded) {
      throw ApiException.validation('Tài liệu này đã được tải rồi.');
    }

    // Generate standard HTML content that WPS Office and MS Word read perfectly with UTF-8
    final htmlContent = '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <style>
    body {
      font-family: 'Arial', sans-serif;
      line-height: 1.6;
      color: #333333;
      margin: 40px;
    }
    .header {
      color: #2F7DE1;
      font-size: 20px;
      font-weight: bold;
      border-bottom: 2px solid #2F7DE1;
      padding-bottom: 8px;
      margin-bottom: 20px;
    }
    .meta-table {
      width: 100%;
      margin-bottom: 20px;
      border-collapse: collapse;
    }
    .meta-table td {
      padding: 6px 0;
      font-size: 15px;
      vertical-align: top;
    }
    .meta-label {
      color: #666666;
      font-weight: bold;
      width: 120px;
    }
    .meta-value {
      color: #111111;
    }
    .divider {
      border-top: 1px dashed #cccccc;
      margin: 20px 0;
    }
    .content-box {
      background-color: #F5F9FF;
      border-left: 4px solid #2F7DE1;
      padding: 15px;
      font-size: 15px;
      color: #222222;
      white-space: pre-wrap;
    }
  </style>
</head>
<body>
  <div class="header">CHI TIẾT THÔNG BÁO</div>
  <table class="meta-table">
    <tr>
      <td class="meta-label">Người gửi:</td>
      <td class="meta-value"><strong>${item.senderName}</strong></td>
    </tr>
    <tr>
      <td class="meta-label">Nơi gửi:</td>
      <td class="meta-value">${item.senderDepartment}</td>
    </tr>
    <tr>
      <td class="meta-label">Ngày gửi:</td>
      <td class="meta-value">${item.timeLabel}</td>
    </tr>
  </table>
  <div class="divider"></div>
  <div class="content-box"><strong>Nội dung:</strong><br/><br/>${item.details.replaceAll('\n', '<br/>')}</div>
</body>
</html>
''';

    final base64Data = base64Encode(utf8.encode(htmlContent));
    final escapedFileName = customFileName.replaceAll('"', '\\"');

    // Trigger real download on Web using native showSaveFilePicker if available
    if (kIsWeb) {
      try {
        executeJsEval(
          '''
          (async () => {
            var base64Data = "$base64Data";
            var suggestedName = "$escapedFileName";
            
            if (window.showSaveFilePicker) {
              try {
                const handle = await window.showSaveFilePicker({
                  suggestedName: suggestedName,
                  types: [{
                    description: 'Word Document (.docx)',
                    accept: {
                      'application/vnd.openxmlformats-officedocument.wordprocessingml.document': ['.docx']
                    }
                  }]
                });
                const writable = await handle.createWritable();
                const byteCharacters = atob(base64Data);
                const byteNumbers = new Uint8Array(byteCharacters.length);
                for (let i = 0; i < byteCharacters.length; i++) {
                  byteNumbers[i] = byteCharacters.charCodeAt(i);
                }
                await writable.write(byteNumbers);
                await writable.close();
                return;
              } catch (err) {
                if (err.name === 'AbortError') {
                  return;
                }
              }
            }
            
            // Standard fallback download link
            var link = document.createElement("a");
            link.download = suggestedName;
            link.href = "data:text/html;charset=utf-8;base64," + base64Data;
            document.body.appendChild(link);
            link.click();
            document.body.removeChild(link);
          })()
          '''
        );
      } catch (_) {}
    }

    _replaceNotification(
      role,
      notificationId,
      item.copyWith(
        isDownloaded: true,
        isRead: true,
        downloadedAt: DateTime.now(),
        attachmentName: customFileName,
      ),
    );

    await _saveToCache(role);

    return 'Đã tải $customFileName.';
  }

  Future<String> respondToNotification({
    required UserRole role,
    required String notificationId,
    required bool approved,
  }) async {
    await _initCacheIfNeeded();
    await Future<void>.delayed(const Duration(milliseconds: 240));
    final item = _findNotification(role, notificationId);
    if (item == null) {
      throw ApiException.validation('Không tìm thấy thông báo cần xử lý.');
    }

    _replaceNotification(
      role,
      notificationId,
      item.copyWith(
        isRead: true,
        responseLabel: approved ? 'Đã đồng ý' : 'Đã hủy',
      ),
    );

    await _saveToCache(role);

    return approved
        ? 'Bạn đã đồng ý thông báo này.'
        : 'Bạn đã hủy thông báo này.';
  }

  Future<void> addTestNotification(UserRole role, NotificationItemEntity item) async {
    await _initCacheIfNeeded();
    final notifications = _notificationStore[role];
    if (notifications != null) {
      notifications.insert(0, item);
      await _saveToCache(role);
    }
  }

  Future<void> deleteNotification(UserRole role, String notificationId) async {
    await _initCacheIfNeeded();
    final notifications = _notificationStore[role];
    if (notifications != null) {
      notifications.removeWhere((item) => item.id == notificationId);
      await _saveToCache(role);
    }
  }



  Future<void> toggleImportant(UserRole role, String notificationId) async {
    await _initCacheIfNeeded();
    final notifications = _notificationStore[role];
    if (notifications != null) {
      final index = notifications.indexWhere((item) => item.id == notificationId);
      if (index >= 0) {
        final current = notifications[index];
        notifications[index] = current.copyWith(isImportant: !current.isImportant);
        await _saveToCache(role);
      }
    }
  }

  Future<MedicalTicketEntity> loadSampleMedicalTicket(
    UserRole role,
    String patientName,
  ) async {
    await Future<void>.delayed(const Duration(milliseconds: 280));
    return _buildTicket(
      role: role,
      patientName: patientName,
      birthYear: '1997',
      gender: 'Nữ',
      phoneNumber: '0902333444',
      identifier: '22134096',
    );
  }

  Future<MedicalTicketEntity> createMedicalTicket(
    UserRole role,
    PatientProfileDraftEntity draft, {
    String? department,
    String? selectedDate,
    String? selectedTime,
    String? symptom,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));

    final prefs = await SharedPreferences.getInstance();
    String resolvedPatientCode = '';

    // 1. Check if we already have a saved profile with the same Name, Birth Year and Gender
    try {
      final profilesJson = prefs.getString('cached_patient_profiles');
      if (profilesJson != null) {
        final List<dynamic> decoded = jsonDecode(profilesJson);
        for (final item in decoded) {
          final name = item['fullName'] as String? ?? '';
          final year = item['birthYear'] as String? ?? '';
          final g = item['gender'] as String? ?? '';
          final code = item['identifier'] as String? ?? '';
          if (name.toUpperCase() == draft.fullName.toUpperCase() &&
              year == draft.birthYear &&
              g == draft.gender &&
              RegExp(r'^\d{8}$').hasMatch(code)) {
            resolvedPatientCode = code;
            break;
          }
        }
      }
    } catch (_) {}

    // 2. If not found, check if draft.identifier is already a valid 8-digit numeric code
    if (resolvedPatientCode.isEmpty) {
      final cleanId = draft.identifier.trim();
      if (RegExp(r'^\d{8}$').hasMatch(cleanId)) {
        resolvedPatientCode = cleanId;
      } else {
        // Generate a new, unique 8-digit numeric Mã BN
        final random = Random();
        final codeBuffer = StringBuffer();
        for (int i = 0; i < 8; i++) {
          codeBuffer.write(random.nextInt(10));
        }
        resolvedPatientCode = codeBuffer.toString();
      }
    }

    final ticket = _buildTicket(
      role: role,
      patientName: draft.fullName,
      birthYear: draft.birthYear,
      gender: draft.gender,
      phoneNumber: draft.phoneNumber,
      identifier: resolvedPatientCode,
      department: department,
      selectedDate: selectedDate,
      selectedTime: selectedTime,
      symptom: symptom,
    );

    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'cached_medical_tickets_${role.name}';
      final cachedJson = prefs.getString(key);
      List<MedicalTicketEntity> list = [];
      if (cachedJson != null) {
        final List<dynamic> decoded = jsonDecode(cachedJson);
        list = decoded.map((item) => MedicalTicketEntity.fromJson(item as Map<String, dynamic>)).toList();
      }
      list.insert(0, ticket);
      final encoded = jsonEncode(list.map((e) => e.toJson()).toList());
      await prefs.setString(key, encoded);
    } catch (_) {}

    return ticket;
  }

  Future<List<MedicalTicketEntity>> loadMedicalTickets(UserRole role) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'cached_medical_tickets_${role.name}';
      final cachedJson = prefs.getString(key);
      if (cachedJson != null) {
        final List<dynamic> decoded = jsonDecode(cachedJson);
        final list = decoded.map((item) => MedicalTicketEntity.fromJson(item as Map<String, dynamic>)).toList();
        
        final now = DateTime.now();
        bool dirty = false;
        final updatedList = list.map((ticket) {
          bool passed = ticket.isPast;
          if (ticket.selectedDate != null && ticket.selectedTime != null) {
            try {
              final dateParts = ticket.selectedDate!.split('/');
              if (dateParts.length == 3) {
                final ticketDay = DateTime(
                  int.parse(dateParts[2]),
                  int.parse(dateParts[1]),
                  int.parse(dateParts[0]),
                );
                final today = DateTime(now.year, now.month, now.day);
                if (ticketDay.isBefore(today)) {
                  passed = true;
                } else if (ticketDay.isAfter(today)) {
                  passed = false;
                } else if (ticketDay.isAtSameMomentAs(today)) {
                  final startPart = ticket.selectedTime!.split('-')[0].trim().toLowerCase();
                  int hr = 0;
                  int min = 0;
                  if (startPart.contains('g')) {
                    final parts = startPart.split('g');
                    hr = int.parse(parts[0]);
                    min = parts[1].isEmpty ? 0 : int.parse(parts[1]);
                  } else if (startPart.contains(':')) {
                    final parts = startPart.split(':');
                    hr = int.parse(parts[0]);
                    min = int.parse(parts[1]);
                  }
                  final ticketTime = DateTime(now.year, now.month, now.day, hr, min);
                  passed = ticketTime.isBefore(now);
                }
              }
            } catch (_) {}
          }
          if (ticket.isPast != passed) {
            dirty = true;
            return ticket.copyWith(isPast: passed);
          }
          return ticket;
        }).toList();

        if (dirty) {
          final encoded = jsonEncode(updatedList.map((e) => e.toJson()).toList());
          await prefs.setString(key, encoded);
        }
        return updatedList;
      } else {
        // Cache is empty: pre-populate with default mock tickets covering upcoming, past, and deleted status
        final now = DateTime.now();
        final tomorrow = now.add(const Duration(days: 1));
        final nextWeek = now.add(const Duration(days: 5));
        final past1 = now.subtract(const Duration(days: 3));
        final past2 = now.subtract(const Duration(days: 7));
        final deletedDay = now.subtract(const Duration(days: 2));

        String fmt(DateTime dt) => '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';

        final t1 = _buildTicket(
          role: role,
          patientName: 'PHẠM NGỌC THUẬN',
          birthYear: '1997',
          gender: 'Nam',
          phoneNumber: '0902333444',
          identifier: '12345678',
          selectedDate: fmt(tomorrow),
          selectedTime: '08g00 - 08g30',
        );
        final t2 = _buildTicket(
          role: role,
          patientName: 'NGUYỄN VÂN NAM',
          birthYear: '1995',
          gender: 'Nam',
          phoneNumber: '0902333444',
          identifier: '97192187',
          selectedDate: fmt(nextWeek),
          selectedTime: '10g30 - 11g00',
        );
        final t3 = _buildTicket(
          role: role,
          patientName: 'LÊ NGUYỄN GIA HƯNG',
          birthYear: '1989',
          gender: 'Nam',
          phoneNumber: '0987654321',
          identifier: '07641190',
          selectedDate: fmt(past1),
          selectedTime: '14g00 - 14g30',
        );
        final t4 = _buildTicket(
          role: role,
          patientName: 'TRẦN THỊ MAI',
          birthYear: '1992',
          gender: 'Nữ',
          phoneNumber: '0912345678',
          identifier: '88765432',
          selectedDate: fmt(past2),
          selectedTime: '09g00 - 09g30',
        );
        final t5 = _buildTicket(
          role: role,
          patientName: 'HOÀNG VĂN THÁI',
          birthYear: '1985',
          gender: 'Nam',
          phoneNumber: '0933445566',
          identifier: '55443322',
          selectedDate: fmt(deletedDay),
          selectedTime: '15g30 - 16g00',
        ).copyWith(isDeleted: true);

        final defaultList = [t1, t2, t3, t4, t5];
        final encoded = jsonEncode(defaultList.map((e) => e.toJson()).toList());
        await prefs.setString(key, encoded);
        return defaultList;
      }
    } catch (_) {}
    return [];
  }

  Future<void> softDeleteMedicalTicket(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      for (final role in UserRole.values) {
        final key = 'cached_medical_tickets_${role.name}';
        final cachedJson = prefs.getString(key);
        if (cachedJson != null) {
          final List<dynamic> decoded = jsonDecode(cachedJson);
          final list = decoded.map((item) => MedicalTicketEntity.fromJson(item as Map<String, dynamic>)).toList();
          final index = list.indexWhere((element) => element.id == id);
          if (index >= 0) {
            list[index] = list[index].copyWith(isDeleted: true);
            final encoded = jsonEncode(list.map((e) => e.toJson()).toList());
            await prefs.setString(key, encoded);
            break;
          }
        }
      }
    } catch (_) {}
  }

  Future<void> restoreMedicalTicket(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      for (final role in UserRole.values) {
        final key = 'cached_medical_tickets_${role.name}';
        final cachedJson = prefs.getString(key);
        if (cachedJson != null) {
          final List<dynamic> decoded = jsonDecode(cachedJson);
          final list = decoded.map((item) => MedicalTicketEntity.fromJson(item as Map<String, dynamic>)).toList();
          final index = list.indexWhere((element) => element.id == id);
          if (index >= 0) {
            list[index] = list[index].copyWith(isDeleted: false);
            final encoded = jsonEncode(list.map((e) => e.toJson()).toList());
            await prefs.setString(key, encoded);
            break;
          }
        }
      }
    } catch (_) {}
  }

  Future<List<PatientProfileDraftEntity>> loadPatientProfiles() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'cached_patient_profiles';
      final cachedJson = prefs.getString(key);
      if (cachedJson != null) {
        final List<dynamic> decoded = jsonDecode(cachedJson);
        return decoded
            .map((item) => PatientProfileDraftEntity.fromJson(item as Map<String, dynamic>))
            .where((p) => !p.isDeleted)
            .toList();
      }
    } catch (_) {}
    return [];
  }

  Future<void> savePatientProfile(PatientProfileDraftEntity profile) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'cached_patient_profiles';
      final cachedJson = prefs.getString(key);
      List<PatientProfileDraftEntity> list = [];
      if (cachedJson != null) {
        final List<dynamic> decoded = jsonDecode(cachedJson);
        list = decoded.map((item) => PatientProfileDraftEntity.fromJson(item as Map<String, dynamic>)).toList();
      }
      
      final idx = list.indexWhere((element) => element.identifier == profile.identifier && profile.identifier.isNotEmpty);
      if (idx >= 0) {
        list[idx] = profile.copyWith(isDeleted: false);
      } else {
        list.insert(0, profile.copyWith(isDeleted: false));
      }
      
      final encoded = jsonEncode(list.map((e) => e.toJson()).toList());
      await prefs.setString(key, encoded);
    } catch (_) {}
  }

  Future<void> softDeletePatientProfile(PatientProfileDraftEntity profile) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'cached_patient_profiles';

      final deletedKeySet = (prefs.getStringList('deleted_patient_profile_keys') ?? []).toSet();
      final pKey = (profile.identifier.isNotEmpty && profile.identifier != 'N/A')
          ? profile.identifier.trim().toLowerCase()
          : '${profile.fullName.trim().toLowerCase()}_${profile.birthYear.trim()}_${profile.phoneNumber.trim()}';

      deletedKeySet.add(pKey);
      await prefs.setStringList('deleted_patient_profile_keys', deletedKeySet.toList());

      final cachedJson = prefs.getString(key);
      if (cachedJson != null) {
        final List<dynamic> decoded = jsonDecode(cachedJson);
        final list = decoded.map((item) => PatientProfileDraftEntity.fromJson(item as Map<String, dynamic>)).toList();
        list.removeWhere((element) {
          if (profile.identifier.isNotEmpty && profile.identifier != 'N/A' && element.identifier == profile.identifier) {
            return true;
          }
          final keyEl = '${element.fullName.trim().toLowerCase()}_${element.birthYear.trim()}_${element.phoneNumber.trim()}';
          return keyEl == pKey;
        });
        final encoded = jsonEncode(list.map((e) => e.toJson()).toList());
        await prefs.setString(key, encoded);
      }
    } catch (_) {}
  }

  Future<List<UserManagementUserEntity>> loadManagedUsers(UserRole role) async {
    await Future<void>.delayed(const Duration(milliseconds: 380));
    _ensureEmployeeRole(role);
    return _managedUsers;
  }

  Future<UserManagementDetailEntity> loadManagedUserDetail(
    UserRole role,
    String userId,
  ) async {
    await Future<void>.delayed(const Duration(milliseconds: 320));
    _ensureEmployeeRole(role);

    final userIndex = _managedUsers.indexWhere(
      (element) => element.id == userId,
    );
    if (userIndex < 0) {
      throw ApiException.validation('Không tìm thấy hồ sơ người dùng cần xem.');
    }

    final user = _managedUsers[userIndex];
    return UserManagementDetailEntity(
      user: user,
      address: _buildAddress(userIndex),
      insuranceCode: 'BHYT${(880000000000 + userIndex).toString()}',
      createdAtText: _formatDateTime(
        DateTime.now().subtract(Duration(days: 520 + (userIndex % 180))),
      ),
      emergencyContact:
          'Người thân ${user.fullName.split(' ').last} - 09${(30000000 + userIndex).toString().padLeft(8, '0')}',
      note: user.currentStatus == UserManagementVisitStatus.rejected
          ? 'Hồ sơ hiện cần nhân viên kiểm tra lại giấy tờ trước khi tiếp nhận lượt mới.'
          : 'Hồ sơ đã sẵn sàng để nhân viên theo dõi, xác nhận và đối chiếu lịch sử khám.',
      histories: _buildHistories(userIndex, user),
    );
  }

  MedicalTicketEntity _buildTicket({
    required UserRole role,
    required String patientName,
    required String birthYear,
    required String gender,
    required String phoneNumber,
    required String identifier,
    String? department,
    String? selectedDate,
    String? selectedTime,
    String? symptom,
  }) {
    final now = DateTime.now();
    final queueNumber = (Random().nextInt(899) + 100).toString();
    final patientCode = identifier.isEmpty
        ? (Random().nextInt(8999999) + 1000000).toString()
        : identifier;

    final scheduleDate = selectedDate ?? _formatDate(now);
    final timeStr = selectedTime ?? '14:30 - 15:00';
    final createdTime = _formatDateTime(now);
    
    bool isPast = false;
    if (selectedDate != null && selectedTime != null) {
      try {
        final dateParts = selectedDate.split('/');
        if (dateParts.length == 3) {
          final ticketDay = DateTime(
            int.parse(dateParts[2]),
            int.parse(dateParts[1]),
            int.parse(dateParts[0]),
          );
          final today = DateTime(now.year, now.month, now.day);
          if (ticketDay.isBefore(today)) {
            isPast = true;
          } else if (ticketDay.isAtSameMomentAs(today)) {
            final startPart = timeStr.split('-')[0].trim().toLowerCase();
            int hr = 0;
            int min = 0;
            if (startPart.contains('g')) {
              final parts = startPart.split('g');
              hr = int.parse(parts[0]);
              min = parts[1].isEmpty ? 0 : int.parse(parts[1]);
            } else if (startPart.contains(':')) {
              final parts = startPart.split(':');
              hr = int.parse(parts[0]);
              min = int.parse(parts[1]);
            }
            final ticketTime = DateTime(now.year, now.month, now.day, hr, min);
            if (ticketTime.isBefore(now)) {
              isPast = true;
            }
          }
        }
      } catch (_) {}
    }

    final String room = department ?? (role == UserRole.customer ? 'Phòng khám 1' : 'Quầy tiếp nhận 2');
    final String service = department != null ? 'Khám chuyên khoa' : 'Tiếp nhận ngoại trú';

    return MedicalTicketEntity(
      id: '${now.millisecondsSinceEpoch}_${Random().nextInt(100)}',
      hospitalName: 'Bệnh viện Quân Dân Y Miền Đông',
      hospitalAddress: '50 Lê Văn Việt, P. Hiệp Phú, TP. Thủ Đức',
      ticketTitle: 'PHIẾU KHÁM BỆNH',
      roomName: room,
      serviceName: service,
      queueNumber: queueNumber,
      scheduleText: '$scheduleDate, $timeStr',
      patientName: patientName.toUpperCase(),
      gender: gender,
      birthYear: birthYear,
      address: 'TP. Thủ Đức, TP. Hồ Chí Minh',
      insuranceText: identifier.isNotEmpty ? 'Có BHYT' : 'Không có BHYT',
      patientCode: patientCode,
      createdAtText: createdTime,
      note: 'Vui lòng đến trước giờ hẹn 15 phút để làm thủ tục.',
      symptom: symptom,
      phoneNumber: phoneNumber,
      department: room,
      selectedDate: selectedDate,
      selectedTime: selectedTime,
      isDeleted: false,
      isPast: isPast,
    );
  }

  static List<UserManagementUserEntity> _buildManagedUsers() {
    const ho = ['Nguyễn', 'Trần', 'Lê', 'Phạm', 'Hoàng', 'Võ', 'Đặng', 'Bùi'];
    const dem = [
      'Minh',
      'Anh',
      'Quang',
      'Thảo',
      'Thanh',
      'Ngọc',
      'Gia',
      'Phương',
    ];
    const ten = [
      'Huy',
      'Linh',
      'Nam',
      'Vy',
      'Khánh',
      'Trâm',
      'Đức',
      'An',
      'Mai',
      'Khoa',
    ];
    const departments = [
      'Nội tổng quát',
      'Tai Mũi Họng',
      'Tim mạch',
      'Chẩn đoán hình ảnh',
      'Xét nghiệm',
      'Ngoại chấn thương',
    ];
    final statuses = UserManagementVisitStatus.values;

    return List<UserManagementUserEntity>.generate(1000, (index) {
      final status = statuses[index % statuses.length];
      final name =
          '${ho[index % ho.length]} ${dem[(index ~/ 3) % dem.length]} ${ten[(index * 2) % ten.length]}';
      final lastVisit = DateTime.now().subtract(
        Duration(
          days: (index % 64) + 1,
          hours: index % 11,
          minutes: index % 50,
        ),
      );

      return UserManagementUserEntity(
        id: 'USR-${(index + 1).toString().padLeft(4, '0')}',
        patientCode: 'BN${(23000000 + index).toString()}',
        fullName: name,
        phoneNumber: '09${(20000000 + index).toString().padLeft(8, '0')}',
        email: 'nguoidung${index + 1}@hpshospital.vn',
        gender: index.isEven ? 'Nam' : 'Nữ',
        birthYear: '${1980 + (index % 25)}',
        currentStatus: status,
        lastVisitText: _formatDateTime(lastVisit),
        totalVisits: 2 + (index % 15),
        currentDepartmentName: departments[index % departments.length],
      );
    });
  }

  List<UserManagementHistoryEntity> _buildHistories(
    int seed,
    UserManagementUserEntity user,
  ) {
    const departments = [
      'Nội tổng quát',
      'Tai Mũi Họng',
      'Khám sức khỏe',
      'Tim mạch',
      'Ngoại chấn thương',
      'Nhi tổng quát',
      'Da liễu',
    ];
    const services = [
      'Khám chuyên khoa',
      'Tái khám',
      'Khám theo BHYT',
      'Khám tổng quát',
      'Khám theo yêu cầu',
    ];
    const doctors = [
      'BS. Trần Minh Khánh',
      'BS. Lê Thu Hà',
      'BS. Võ Đức Tín',
      'BS. Nguyễn Hải An',
      'BS. Phạm Khánh Linh',
    ];
    final fallbackStatuses = [
      UserManagementVisitStatus.completed,
      UserManagementVisitStatus.rejected,
      UserManagementVisitStatus.canceled,
      UserManagementVisitStatus.noShow,
      UserManagementVisitStatus.pendingApproval,
      UserManagementVisitStatus.scheduled,
      UserManagementVisitStatus.waitingForExamination,
      UserManagementVisitStatus.inProgress,
    ];
    final count = 8 + (seed % 7);

    return List<UserManagementHistoryEntity>.generate(count, (index) {
      final appointmentStart = DateTime.now().subtract(
        Duration(days: (index * 13) + (seed % 6) + 1, hours: (index * 2) % 6),
      );
      final appointmentEnd = appointmentStart.add(const Duration(minutes: 45));
      final status = index == 0
          ? user.currentStatus
          : fallbackStatuses[(seed + index) % fallbackStatuses.length];

      return UserManagementHistoryEntity(
        id: '${user.id}-VISIT-${index + 1}',
        registeredAtText: _formatDateTime(
          appointmentStart.subtract(const Duration(days: 2, hours: 3)),
        ),
        appointmentTimeText:
            '${_formatDate(appointmentStart)} ${_formatTime(appointmentStart)} - ${_formatTime(appointmentEnd)}',
        statusUpdatedAtText: _formatDateTime(
          appointmentStart.add(Duration(minutes: 15 + (index * 5))),
        ),
        departmentName: departments[(seed + index) % departments.length],
        serviceName: services[(seed + (index * 2)) % services.length],
        doctorName: doctors[(seed + index) % doctors.length],
        status: status,
        note: _noteForStatus(status),
        rejectionReason: status == UserManagementVisitStatus.rejected
            ? 'Thiếu giấy tờ BHYT hoặc thông tin không trùng khớp với hồ sơ gốc.'
            : null,
      );
    });
  }

  static List<NotificationItemEntity> _buildCustomerNotifications() {
    return _buildEmployeeNotifications();
  }

  static List<NotificationItemEntity> _buildEmployeeNotifications() {
    return [
      NotificationItemEntity(
        id: 'NOTI-032',
        title: 'GĐBV NGÀY 30/06/2026',
        message: 'GĐBV NGÀY 30/06/2026',
        details: 'GĐBV NGÀY 30/06/2026',
        category: 'announcement',
        timeLabel: '30/06/2026 15:02:02',
        senderName: 'Ban giám đốc',
        senderDepartment: 'Ban Giám đốc',
        number: 32,
        createdAt: DateTime(2026, 6, 30, 15, 2, 2),
        isRead: true,
        attachmentName: 'gdbv-30-06.docx',
      ),
      NotificationItemEntity(
        id: 'NOTI-031',
        title: 'THÔNG BÁO: LỊCH LÀM VIỆC - TUẦN 27',
        message: 'THÔNG BÁO: LỊCH LÀM VIỆC - TUẦN 27',
        details: 'THÔNG BÁO: LỊCH LÀM VIỆC - TUẦN 27',
        category: 'document',
        timeLabel: '29/06/2026 08:47:40',
        senderName: 'Phan Quốc Danh',
        senderDepartment: 'Ban Kế hoạch tổng hợp',
        number: 31,
        createdAt: DateTime(2026, 6, 29, 8, 47, 40),
        isRead: true,
        attachmentName: 'lich-lam-viec-tuan-27.docx',
      ),
      NotificationItemEntity(
        id: 'NOTI-030',
        title: 'THÔNG BÁO: Kế hoạch số 740 /KH-BV',
        message: 'Kế hoạch số 740 /KH-BV ngày 25/6/2026 về việc tổ chức KSK CB, SQ, SQCN, CS Trường Quân Sự QK7 năm 2026',
        details: 'THÔNG BÁO\nKế hoạch số 740 /KH-BV ngày 25/6/2026 về việc tổ chức KSK CB, SQ, SQCN, CS Trường Quân Sự QK7 năm 2026',
        category: 'document',
        timeLabel: '28/06/2026 08:46:09',
        senderName: 'Huỳnh Ngọc Hân',
        senderDepartment: 'Khám sức khỏe',
        number: 30,
        createdAt: DateTime(2026, 6, 28, 8, 46, 9),
        isRead: false,
        attachmentName: '30.docx',
      ),
      NotificationItemEntity(
        id: 'NOTI-029',
        title: 'THÔNG BÁO: Kế hoạch số 675 /KH-BV',
        message: 'Kế hoạch số 675 /KH-BV ngày 10.6.2026 về việc tổ chức KSK cán bộ nhân viên Cảng ICD Tây Nam năm 2026',
        details: 'THÔNG BÁO\nKế hoạch số 675 /KH-BV ngày 10.6.2026 về việc tổ chức KSK cán bộ nhân viên Cảng ICD Tây Nam năm 2026',
        category: 'document',
        timeLabel: '26/06/2026 10:57:14',
        senderName: 'Huỳnh Ngọc Hân',
        senderDepartment: 'Khám sức khỏe',
        number: 29,
        createdAt: DateTime(2026, 6, 26, 10, 57, 14),
        isRead: false,
        attachmentName: '29.docx',
      ),
      NotificationItemEntity(
        id: 'NOTI-028',
        title: 'THÔNG BÁO: V/v tiêm chủng bổ sung cho nhân viên y tế',
        message: 'Chi tiết kế hoạch tiêm chủng bổ sung phòng ngừa dịch bệnh cho toàn thể nhân viên y tế trong quý 3.',
        details: 'THÔNG BÁO\nV/v tiêm chủng bổ sung cho nhân viên y tế toàn bệnh viện nhằm đảm bảo an toàn phòng chống dịch.',
        category: 'reminder',
        timeLabel: '23/06/2026 14:15:22',
        senderName: 'Phan Quốc Danh',
        senderDepartment: 'Ban Kế hoạch tổng hợp',
        number: 28,
        createdAt: DateTime(2026, 6, 23, 14, 15, 22),
        isRead: false,
        attachmentName: 'tiem-chung-bo-sung.docx',
      ),
      NotificationItemEntity(
        id: 'NOTI-027',
        title: 'THÔNG BÁO: Lịch trực luân phiên tháng 7',
        message: 'Phát hành lịch trực luân phiên trực cấp cứu và các khoa lâm sàng cho tháng 7 năm 2026.',
        details: 'THÔNG BÁO\nLịch trực luân phiên các khoa phòng tháng 7/2026 đã sẵn sàng để đối chiếu.',
        category: 'document',
        timeLabel: '23/06/2026 09:30:00',
        senderName: 'Lê Thu Hà',
        senderDepartment: 'Khoa Nội',
        number: 27,
        createdAt: DateTime(2026, 6, 23, 9, 30, 0),
        isRead: false,
        attachmentName: 'lich-truc-thang-7.docx',
      ),
    ];
  }

  List<NotificationItemEntity> _notificationsFor(UserRole role) {
    final list = _notificationStore[role];
    if (list == null) {
      return const [];
    }

    final now = DateTime.now();
    final sysTodayId = 'SYS-TODAY-${now.year}-${now.month}-${now.day}';

    // Check if there are other notifications today (excluding the summary itself)
    final hasOtherTodayNotification = list.any((item) =>
        item.id != sysTodayId &&
        item.createdAt.year == now.year &&
        item.createdAt.month == now.month &&
        item.createdAt.day == now.day);

    if (!hasOtherTodayNotification) {
      final hasSysToday = list.any((item) => item.id == sysTodayId);
      if (!hasSysToday) {
        final today2359 = DateTime(now.year, now.month, now.day, 23, 59, 0);
        final dateStr = '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
        
        int nextNumber = 1;
        if (list.isNotEmpty) {
          nextNumber = list.map((e) => e.number).reduce((a, b) => a > b ? a : b) + 1;
        }

        final defaultItem = NotificationItemEntity(
          id: sysTodayId,
          title: 'CẬP NHẬT HỆ THỐNG HẰNG NGÀY',
          message: 'Hệ thống tự động ghi nhận không có thông báo mới trong ngày hôm nay.',
          details: 'THÔNG BÁO HẰNG NGÀY\n\nHệ thống tự động ghi nhận tài khoản của bạn không có bất kỳ thông báo mới nào được gửi đến trong ngày hôm nay ($dateStr). Toàn bộ dịch vụ bệnh viện vẫn đang hoạt động ổn định.',
          category: 'announcement',
          timeLabel: '23:59:00',
          senderName: 'Hệ thống',
          senderDepartment: 'Hệ thống tự động',
          number: nextNumber,
          createdAt: today2359,
          isRead: false,
          attachmentName: 'sys-today.docx',
        );
        list.insert(0, defaultItem);
      }
    } else {
      // If there are other notifications today, clean up the 23:59 summary
      list.removeWhere((item) => item.id == sysTodayId);
    }

    return list;
  }

  NotificationItemEntity? _findNotification(
    UserRole role,
    String notificationId,
  ) {
    final notifications = _notificationStore[role];
    if (notifications == null) {
      return null;
    }

    for (final item in notifications) {
      if (item.id == notificationId) {
        return item;
      }
    }

    return null;
  }

  NotificationItemEntity? _updateNotification(
    UserRole role,
    String notificationId,
    NotificationItemEntity Function(NotificationItemEntity item) updater,
  ) {
    final notifications = _notificationStore[role];
    if (notifications == null) {
      return null;
    }

    for (var index = 0; index < notifications.length; index++) {
      final current = notifications[index];
      if (current.id != notificationId) {
        continue;
      }

      final updated = updater(current);
      notifications[index] = updated;
      return updated;
    }

    return null;
  }

  void _replaceNotification(
    UserRole role,
    String notificationId,
    NotificationItemEntity updated,
  ) {
    final notifications = _notificationStore[role];
    if (notifications == null) {
      return;
    }

    for (var index = 0; index < notifications.length; index++) {
      if (notifications[index].id == notificationId) {
        notifications[index] = updated;
        return;
      }
    }
  }

  void _ensureEmployeeRole(UserRole role) {
    if (role != UserRole.employee) {
      throw ApiException.validation(
        'Chức năng này chỉ dành cho tài khoản nhân viên.',
      );
    }
  }

  static String _noteForStatus(UserManagementVisitStatus status) {
    return switch (status) {
      UserManagementVisitStatus.pendingApproval =>
        'Hồ sơ đang chờ nhân viên xác nhận thông tin trước khi xếp lịch.',
      UserManagementVisitStatus.scheduled =>
        'Lịch khám đã được tạo và đang chờ người bệnh đến đúng khung giờ.',
      UserManagementVisitStatus.waitingForExamination =>
        'Người bệnh đã check-in và đang chờ vào phòng khám.',
      UserManagementVisitStatus.inProgress =>
        'Bác sĩ đang thực hiện thăm khám và cập nhật chỉ định.',
      UserManagementVisitStatus.completed =>
        'Ca khám đã hoàn tất và có kết luận sơ bộ trong hệ thống.',
      UserManagementVisitStatus.rejected =>
        'Yêu cầu khám bị từ chối do hồ sơ chưa hợp lệ hoặc thiếu thông tin.',
      UserManagementVisitStatus.canceled =>
        'Lịch khám đã được hủy theo yêu cầu từ người bệnh hoặc quầy tiếp nhận.',
      UserManagementVisitStatus.noShow =>
        'Người bệnh không đến khám theo khung giờ đã đăng ký.',
    };
  }

  static String _buildAddress(int index) {
    const wards = [
      'Phường Hiệp Bình',
      'Phường Linh Đông',
      'Phường Long Bình',
      'Phường Tăng Nhơn Phú',
      'Phường Bình Thọ',
    ];
    return '${12 + (index % 140)} đường số ${(index % 29) + 1}, ${wards[index % wards.length]}, TP. Thủ Đức';
  }

  static String _formatDateTime(DateTime value) {
    return '${_formatDate(value)} ${_formatTime(value)}';
  }

  static String _formatDate(DateTime value) {
    return '${_two(value.day)}/${_two(value.month)}/${value.year}';
  }

  static String _formatTime(DateTime value) {
    return '${_two(value.hour)}:${_two(value.minute)}';
  }

  static String _two(int value) => value.toString().padLeft(2, '0');
}
