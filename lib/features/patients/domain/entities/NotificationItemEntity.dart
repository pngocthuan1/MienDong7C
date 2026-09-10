import 'dart:convert';
import 'package:benhvien7c/core/utils/UserLookupHelper.dart';

class NotificationItemEntity {
  NotificationItemEntity({
    required this.id,
    required this.title,
    required this.message,
    required this.details,
    required this.category,
    required this.timeLabel,
    required this.senderName,
    required this.senderDepartment,
    required this.number,
    required this.createdAt,
    this.isRead = false,
    this.isImportant = false,
    this.attachmentName,
    this.attachmentPath,
    this.isDownloaded = false,
    this.primaryActionLabel,
    this.secondaryActionLabel,
    this.responseLabel,
    this.downloadedAt,
    this.detailRoute,
    this.imagePaths,
    this.recipientNames,
  });

  final String id;
  final String title;
  final String message;
  final String details;
  final String category;
  final String timeLabel;
  final String senderName;
  final String senderDepartment;
  final int number;
  final DateTime createdAt;
  bool isRead;
  bool isImportant;
  final String? attachmentName;
  final String? attachmentPath;
  bool isDownloaded;
  final String? primaryActionLabel;
  final String? secondaryActionLabel;
  final String? responseLabel;
  final DateTime? downloadedAt;
  final String? detailRoute;
  final List<String>? imagePaths;
  final List<String>? recipientNames;

  NotificationItemEntity copyWith({
    String? id,
    String? title,
    String? message,
    String? details,
    String? category,
    String? timeLabel,
    String? senderName,
    String? senderDepartment,
    int? number,
    DateTime? createdAt,
    bool? isRead,
    bool? isImportant,
    String? attachmentName,
    String? attachmentPath,
    bool? isDownloaded,
    String? primaryActionLabel,
    String? secondaryActionLabel,
    String? responseLabel,
    DateTime? downloadedAt,
    String? detailRoute,
    List<String>? imagePaths,
    List<String>? recipientNames,
  }) {
    return NotificationItemEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      details: details ?? this.details,
      category: category ?? this.category,
      timeLabel: timeLabel ?? this.timeLabel,
      senderName: senderName ?? this.senderName,
      senderDepartment: senderDepartment ?? this.senderDepartment,
      number: number ?? this.number,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      isImportant: isImportant ?? this.isImportant,
      attachmentName: attachmentName ?? this.attachmentName,
      attachmentPath: attachmentPath ?? this.attachmentPath,
      isDownloaded: isDownloaded ?? this.isDownloaded,
      primaryActionLabel: primaryActionLabel ?? this.primaryActionLabel,
      secondaryActionLabel: secondaryActionLabel ?? this.secondaryActionLabel,
      responseLabel: responseLabel ?? this.responseLabel,
      downloadedAt: downloadedAt ?? this.downloadedAt,
      detailRoute: detailRoute ?? this.detailRoute,
      imagePaths: imagePaths ?? this.imagePaths,
      recipientNames: recipientNames ?? this.recipientNames,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'details': details,
      'category': category,
      'timeLabel': timeLabel,
      'senderName': senderName,
      'senderDepartment': senderDepartment,
      'number': number,
      'createdAt': createdAt.toIso8601String(),
      'isRead': isRead,
      'isImportant': isImportant,
      'attachmentName': attachmentName,
      'attachmentPath': attachmentPath,
      'isDownloaded': isDownloaded,
      'primaryActionLabel': primaryActionLabel,
      'secondaryActionLabel': secondaryActionLabel,
      'responseLabel': responseLabel,
      'downloadedAt': downloadedAt?.toIso8601String(),
      'detailRoute': detailRoute,
      'imagePaths': imagePaths,
      'recipientNames': recipientNames,
    };
  }

  factory NotificationItemEntity.fromJson(Map<String, dynamic> json) {
    return NotificationItemEntity(
      id: json['id'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      details: json['details'] as String,
      category: json['category'] as String,
      timeLabel: json['timeLabel'] as String,
      senderName: json['senderName'] as String,
      senderDepartment: json['senderDepartment'] as String,
      number: json['number'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
      isRead: json['isRead'] as bool? ?? false,
      isImportant: json['isImportant'] as bool? ?? false,
      attachmentName: json['attachmentName'] as String?,
      attachmentPath: json['attachmentPath'] as String?,
      isDownloaded: json['isDownloaded'] as bool? ?? false,
      primaryActionLabel: json['primaryActionLabel'] as String?,
      secondaryActionLabel: json['secondaryActionLabel'] as String?,
      responseLabel: json['responseLabel'] as String?,
      downloadedAt: json['downloadedAt'] != null
          ? DateTime.parse(json['downloadedAt'] as String)
          : null,
      detailRoute: json['detailRoute'] as String?,
      imagePaths: (json['imagePaths'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
      recipientNames: (json['recipientNames'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
    );
  }

  String get compositeKey {
    final yy = (createdAt.year % 100).toString().padLeft(2, '0');
    final mm = createdAt.month.toString().padLeft(2, '0');
    return '${yy}${mm}_$id';
  }

  factory NotificationItemEntity.fromApiJson(Map<String, dynamic> json) {
    final rawId = json['id']?.toString() ?? '0';
    final rawNoiDung = json['NoiDung'] as String? ?? '';
    final rawNgayGui = json['NgayGui'] as String? ?? DateTime.now().toIso8601String();
    final parsedDate = DateTime.tryParse(rawNgayGui) ?? DateTime.now();

    final rawFile = json['File'] as String?;
    final rawFileUrl = json['FileDinhKem'] as String?;

    String? attachName;
    if (rawFile != null && rawFile.trim().isNotEmpty) {
      attachName = rawFile.trim();
    } else if (rawFileUrl != null && rawFileUrl.trim().isNotEmpty) {
      if (rawFileUrl.contains('fileName=')) {
        attachName = rawFileUrl.split('fileName=').last.split('&').first;
      }
      if (attachName == null || attachName.trim().isEmpty || attachName.startsWith('http')) {
        attachName = rawFileUrl.split('/').last.split('?').first;
      }
    }

    String? attachPath;
    if (rawFileUrl != null && rawFileUrl.trim().isNotEmpty) {
      attachPath = rawFileUrl.trim();
    } else if (attachName != null && attachName.isNotEmpty) {
      final mm = parsedDate.month.toString().padLeft(2, '0');
      final yy = parsedDate.year.toString().substring(2);
      attachPath = 'https://api.miendong7c.vn/api/File/Download?fileId=$rawId&fileName=$attachName&groupId=hospi$mm$yy';
    }

    List<String>? recipientList;
    final rawNoiNhan = json['NoiNhan'];
    if (rawNoiNhan != null) {
      if (rawNoiNhan is List) {
        recipientList = rawNoiNhan.map((e) => UserLookupHelper.lookupName(e.toString())).toList();
      } else if (rawNoiNhan is String && rawNoiNhan.trim().isNotEmpty) {
        final str = rawNoiNhan.trim();
        if (str.startsWith('[')) {
          try {
            final decoded = jsonDecode(str);
            if (decoded is List) {
              recipientList = decoded.map((e) {
                if (e is Map<String, dynamic>) {
                  final raw = e['MaVaTen']?.toString() ?? e['Ten']?.toString() ?? e['UserId']?.toString() ?? e.toString();
                  return UserLookupHelper.lookupName(raw);
                }
                return UserLookupHelper.lookupName(e.toString());
              }).toList();
            }
          } catch (_) {}
        }
        if (recipientList == null || recipientList.isEmpty) {
          final parts = str.split(';').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
          if (parts.isNotEmpty) {
            recipientList = parts.map((p) => UserLookupHelper.lookupName(p)).toList();
          }
        }
      }
    }

    return NotificationItemEntity(
      id: rawId,
      title: (json['TieuDe'] as String?)?.isNotEmpty == true
          ? json['TieuDe'] as String
          : (json['Ma'] != null ? 'Thông báo số ${json['Ma']}' : 'Thông báo mới'),
      message: rawNoiDung,
      details: rawNoiDung,
      category: 'Thông báo nội bộ',
      timeLabel: '${parsedDate.day.toString().padLeft(2, '0')}/${parsedDate.month.toString().padLeft(2, '0')}/${parsedDate.year}',
      senderName: json['NguoiGui'] as String? ?? 'Hệ thống',
      senderDepartment: (json['NoiGui'] != null && json['NoiGui'].toString().trim().isNotEmpty && json['NoiGui'].toString() != '1' && json['NoiGui'].toString() != 'Khoa Khám Bệnh')
          ? json['NoiGui'].toString()
          : 'Hệ thống thông báo nội bộ',
      number: int.tryParse(json['Ma']?.toString() ?? rawId) ?? 0,
      createdAt: parsedDate,
      isRead: (json['TrangThai'] as int? ?? 0) != 1,
      isImportant: false,
      attachmentName: attachName,
      attachmentPath: attachPath,
      isDownloaded: false,
      recipientNames: recipientList,
    );
  }
}
