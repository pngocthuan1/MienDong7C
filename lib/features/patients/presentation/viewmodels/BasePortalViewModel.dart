import 'package:flutter/widgets.dart';
import 'package:benhvien7c/app/router/RouteNames.dart';
import 'package:benhvien7c/core/session/AppSessionStore.dart';
import 'package:benhvien7c/core/viewmodels/BaseViewModel.dart';
import 'package:benhvien7c/core/widgets/AppNotificationToast.dart';
import 'package:benhvien7c/features/auth/domain/entities/AuthSessionEntity.dart';
import 'package:benhvien7c/features/auth/domain/entities/UserRole.dart';
import 'package:benhvien7c/features/patients/domain/entities/NotificationItemEntity.dart';
import 'package:benhvien7c/features/patients/domain/repositories/PortalRepository.dart';
import 'package:benhvien7c/core/utils/NotificationHelper.dart';

abstract class BasePortalViewModel extends BaseViewModel {
  BasePortalViewModel(this.portalRepository, this.sessionStore);

  final PortalRepository portalRepository;
  final AppSessionStore sessionStore;

  AuthSessionEntity get session => sessionStore.session!;

  UserRole get role => session.user.role;

  Future<void> sendTestNotification(
    BuildContext context, {
    required String title,
    required String message,
    required String details,
    required String category,
    required bool isImportant,
    String? attachmentName,
    String? primaryActionLabel,
    String? secondaryActionLabel,
    String? detailRoute,
    String senderName = 'Phan Quốc Danh',
    String senderDepartment = 'Ban Kế hoạch tổng hợp',
    int number = 33,
  }) async {
    final item = NotificationItemEntity(
      id: 'TEST-${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      message: message,
      details: details,
      category: category,
      timeLabel: 'Vừa xong',
      senderName: senderName,
      senderDepartment: senderDepartment,
      number: number,
      createdAt: DateTime.now(),
      isRead: false,
      isImportant: isImportant,
      attachmentName: attachmentName,
      primaryActionLabel: primaryActionLabel,
      secondaryActionLabel: secondaryActionLabel,
      detailRoute: detailRoute,
    );

    final result = await portalRepository.addTestNotification(role, item);
    result.when(
      ok: (_) {
        AppNotificationToast.show(
          context,
          title: title,
          message: message,
          onTap: () {
            Navigator.pushNamed(
              context,
              RouteNames.notificationDetail,
              arguments: item,
            );
          },
        );
        NotificationHelper.showNotification(
          id: item.id,
          title: title,
          body: message,
        );
      },
      error: (_, errMessage) {
        setMessage(errMessage);
      },
    );
  }
}
