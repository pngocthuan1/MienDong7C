class NotificationReadStatusEntity {
  final String userId;
  final String userName;
  final String userRole;
  final bool isRead;
  final DateTime? readAt;

  const NotificationReadStatusEntity({
    required this.userId,
    required this.userName,
    required this.userRole,
    required this.isRead,
    this.readAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'userName': userName,
      'userRole': userRole,
      'isRead': isRead,
      'readAt': readAt?.toIso8601String(),
    };
  }

  factory NotificationReadStatusEntity.fromJson(Map<String, dynamic> json) {
    return NotificationReadStatusEntity(
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      userRole: json['userRole'] as String,
      isRead: json['isRead'] as bool,
      readAt: json['readAt'] != null ? DateTime.parse(json['readAt'] as String) : null,
    );
  }
}
