class NotificationItemEntity {
  const NotificationItemEntity({
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
    this.isDownloaded = false,
    this.primaryActionLabel,
    this.secondaryActionLabel,
    this.responseLabel,
    this.downloadedAt,
    this.detailRoute,
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
  final bool isRead;
  final bool isImportant;
  final String? attachmentName;
  final bool isDownloaded;
  final String? primaryActionLabel;
  final String? secondaryActionLabel;
  final String? responseLabel;
  final DateTime? downloadedAt;
  final String? detailRoute;

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
    bool? isDownloaded,
    String? primaryActionLabel,
    String? secondaryActionLabel,
    String? responseLabel,
    DateTime? downloadedAt,
    String? detailRoute,
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
      isDownloaded: isDownloaded ?? this.isDownloaded,
      primaryActionLabel: primaryActionLabel ?? this.primaryActionLabel,
      secondaryActionLabel: secondaryActionLabel ?? this.secondaryActionLabel,
      responseLabel: responseLabel ?? this.responseLabel,
      downloadedAt: downloadedAt ?? this.downloadedAt,
      detailRoute: detailRoute ?? this.detailRoute,
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
      'isDownloaded': isDownloaded,
      'primaryActionLabel': primaryActionLabel,
      'secondaryActionLabel': secondaryActionLabel,
      'responseLabel': responseLabel,
      'downloadedAt': downloadedAt?.toIso8601String(),
      'detailRoute': detailRoute,
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
      isDownloaded: json['isDownloaded'] as bool? ?? false,
      primaryActionLabel: json['primaryActionLabel'] as String?,
      secondaryActionLabel: json['secondaryActionLabel'] as String?,
      responseLabel: json['responseLabel'] as String?,
      downloadedAt: json['downloadedAt'] != null
          ? DateTime.parse(json['downloadedAt'] as String)
          : null,
      detailRoute: json['detailRoute'] as String?,
    );
  }
}
