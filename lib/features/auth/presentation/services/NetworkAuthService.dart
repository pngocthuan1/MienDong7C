import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:benhvien7c/core/network/DioClient.dart';
import 'package:benhvien7c/core/network/NetworkInfoResult.dart';

class NetworkAuthService {
  final DioClient _dioClient;

  NetworkAuthService(this._dioClient);

  Future<NetworkAuthResult> checkInternalNetwork(NetworkInfoResult info) async {
    try {
      final wifiName = info.ssid ?? '';
      if (kDebugMode) {
        debugPrint('[NetworkAuthService] Sending CheckMode with Name: "$wifiName", IsVpn: ${info.isVpn}');
      }

      final payload = {
        'Name': wifiName,
        'IsVpn': info.isVpn,
        'ConnectionType': info.connectionType.name,
        'LocalIp': info.localIp ?? '',
        'GatewayIp': info.gatewayIp ?? '',
        'LocationPermissionGranted': info.locationPermissionGranted,
        'Platform': info.platform,
      };

      final response = await _dioClient.dio.post<Map<String, dynamic>>(
        '/api/AppInfo/CheckMode',
        data: payload,
        options: Options(
          sendTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
        ),
      );

      if (kDebugMode) {
        debugPrint('[NetworkAuthService] Server response status: ${response.statusCode}, data: ${response.data}');
      }

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data!;
        final rawDataVal = data['Data'] ?? data['data'];

        // BẢO MẬT TUYỆT ĐỐI: Quyền truy cập nội bộ CHỈ do Server quyết định.
        // Tuyệt đối không cho phép Client tự ý override bằng tên Wi-Fi (SSID) tự đặt
        // hoặc cờ VPN cục bộ của thiết bị.
        bool isServerStaff = false;
        if (rawDataVal is Map<String, dynamic>) {
          isServerStaff = rawDataVal['allowEmployeeRole'] == true ||
              rawDataVal['isInternalNetwork'] == true ||
              (rawDataVal['mode']?.toString().contains('Staff') ?? false) ||
              (rawDataVal['mode']?.toString().contains('Employee') ?? false);
        } else {
          final modeString = rawDataVal?.toString() ?? '';
          isServerStaff = modeString.contains('Staff') ||
              modeString.contains('Employee') ||
              modeString.contains('Admin');
        }

        if (kDebugMode) {
          debugPrint('[NetworkAuthService] Server verification -> isServerStaff: $isServerStaff');
        }

        return NetworkAuthResult(
          isInternalNetwork: isServerStaff,
          allowEmployeeRole: isServerStaff,
          verifiedBy: 'server_appinfo_checkmode',
        );
      }
      return NetworkAuthResult.deny();
    } catch (e, stack) {
      if (kDebugMode) {
        debugPrint('[NetworkAuthService] Error checking internal network: $e\n$stack');
      }
      return NetworkAuthResult.deny();
    }
  }
}
