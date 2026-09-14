import 'package:benhvien7c/core/theme/AppColors.dart';
import 'package:benhvien7c/core/widgets/AppNotificationToast.dart';
import 'package:benhvien7c/core/services/FirebaseTokenService.dart';
import 'package:flutter/material.dart';

class NotificationHelper {
  const NotificationHelper._();

  // --- 1. Success Toast ---
  static void showSuccessToast(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message, style: const TextStyle(fontSize: 14))),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // --- 2. Error Toast ---
  static void showErrorToast(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message, style: const TextStyle(fontSize: 14))),
          ],
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  // --- 3. Warning Toast ---
  static void showWarningToast(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.black87),
            const SizedBox(width: 12),
            Expanded(child: Text(message, style: const TextStyle(color: Colors.black87, fontSize: 14))),
          ],
        ),
        backgroundColor: const Color(0xFFFFCC00),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // --- 4. Persistent Material Banner (Offline Mode) ---
  static void showOfflineBanner(BuildContext context) {
    ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
    ScaffoldMessenger.of(context).showMaterialBanner(
      MaterialBanner(
        content: const Row(
          children: [
            Icon(Icons.wifi_off_rounded, color: Colors.white),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Mất kết nối mạng. Bạn đang duyệt thông tin ở chế độ ngoại tuyến (Offline).',
                style: TextStyle(color: Colors.white, fontSize: 13, height: 1.4),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFD97706),
        actions: [
          TextButton(
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
            },
            child: const Text(
              'BỎ QUA',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // --- 5. Custom Overlay Toast ---
  static void showCustomOverlay(BuildContext context, {required String title, required String message}) {
    AppNotificationToast.show(
      context,
      title: title,
      message: message,
    );
  }

  // --- 6. Local Notification (Simulated/Stub) ---
  static void showNotification({
    required String id,
    required String title,
    required String body,
  }) {
    // In-app log simulation
    debugPrint('[Local Notification] ID: $id, Title: $title, Body: $body');
    // Local notifications can be hooked to flutter_local_notifications package in production.
  }

  // --- 7. Confirmation Dialog ---
  static void showConfirmationDialog(
    BuildContext context, {
    required String title,
    required String content,
    required VoidCallback onConfirm,
    String confirmLabel = 'XÁC NHẬN',
    String cancelLabel = 'HỦY',
  }) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          content: Text(content),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(cancelLabel, style: const TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                onConfirm();
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: Text(confirmLabel, style: const TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  static String? get fcmToken => FirebaseTokenService.instance.fcmToken;
}
