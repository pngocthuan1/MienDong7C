import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:benhvien7c/core/config/environment.dart';
import 'package:benhvien7c/core/services/RemoteConfigService.dart';

/// Service kiểm tra phiên bản tối thiểu (Force Update) an toàn:
/// - Mặc định an toàn: không bao giờ chặn người dùng khi mất mạng hoặc lỗi Remote Config.
/// - Sanity Check: Nếu min_supported_version bất thường (lớn hơn bản hiện tại nhưng store_url rỗng),
///   hệ thống sẽ ghi log cảnh báo và KHÔNG chặn người dùng.
class AppVersionCheckService {
  const AppVersionCheckService._();

  /// So sánh hai chuỗi phiên bản dạng SemVer (x.y.z).
  /// Trả về:
  ///   -1 nếu v1 < v2
  ///    0 nếu v1 == v2
  ///    1 nếu v1 > v2
  static int compareSemVer(String v1, String v2) {
    try {
      final cleanV1 = v1.split('+').first.split('-').first.trim();
      final cleanV2 = v2.split('+').first.split('-').first.trim();
      final parts1 = cleanV1.split('.').map((e) => int.tryParse(e) ?? 0).toList();
      final parts2 = cleanV2.split('.').map((e) => int.tryParse(e) ?? 0).toList();

      final maxLen = parts1.length > parts2.length ? parts1.length : parts2.length;
      for (int i = 0; i < maxLen; i++) {
        final p1 = i < parts1.length ? parts1[i] : 0;
        final p2 = i < parts2.length ? parts2[i] : 0;
        if (p1 < p2) return -1;
        if (p1 > p2) return 1;
      }
      return 0;
    } catch (_) {
      return 0;
    }
  }

  /// Kiểm tra xem ứng dụng có bắt buộc phải cập nhật hay không.
  static Future<bool> isForceUpdateRequired() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version.trim().isNotEmpty
          ? packageInfo.version.trim()
          : Environment.appVersion;

      final minVersion = RemoteConfigService.instance.minSupportedVersion.trim();
      final storeUrl = RemoteConfigService.instance.storeUrl.trim();

      // So sánh phiên bản
      final cmp = compareSemVer(currentVersion, minVersion);

      if (cmp < 0) {
        // Phiên bản hiện tại nhỏ hơn phiên bản tối thiểu yêu cầu
        if (storeUrl.isEmpty) {
          // Bất thường: Cấu hình yêu cầu nâng cấp nhưng không cung cấp store_url để người dùng tải
          debugPrint(
            '[AppVersionCheck] CẢNH BÁO CẤU HÌNH BẤT THƯỜNG: min_supported_version ($minVersion) '
            'lớn hơn phiên bản hiện tại ($currentVersion) nhưng store_url rỗng. '
            'Bỏ qua chặn để không làm gián đoạn người dùng.',
          );
          return false;
        }
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('[AppVersionCheck] Lỗi kiểm tra phiên bản (bỏ qua chặn an toàn): $e');
      return false;
    }
  }

  /// Hiển thị hộp thoại bắt buộc cập nhật nếu cần.
  /// Trả về `true` nếu đã hiển thị dialog chặn, `false` nếu phiên bản hợp lệ và có thể đi tiếp.
  static Future<bool> checkAndShowForceUpdateIfNeeded(BuildContext context) async {
    final needed = await isForceUpdateRequired();
    if (!needed || !context.mounted) return false;

    final storeUrl = RemoteConfigService.instance.storeUrl.trim();
    final message = RemoteConfigService.instance.forceUpdateMessage.trim();

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return PopScope(
          canPop: false,
          child: AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.system_update_rounded, color: Color(0xFF0284C7), size: 28),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Cập nhật ứng dụng',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ),
              ],
            ),
            content: Text(
              message,
              style: const TextStyle(fontSize: 14, height: 1.4),
            ),
            actions: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0284C7),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () async {
                    if (storeUrl.isNotEmpty) {
                      final uri = Uri.tryParse(storeUrl);
                      if (uri != null) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      }
                    }
                  },
                  child: const Text(
                    'CẬP NHẬT NGAY',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );

    return true;
  }
}
