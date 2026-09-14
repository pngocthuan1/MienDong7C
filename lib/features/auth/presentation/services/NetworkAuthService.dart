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
        final modeString = rawDataVal?.toString() ?? '';

        final bool isServerStaff = modeString.contains('Staff') || modeString.contains('Employee') || modeString.contains('Admin');
        final bool isVpnActive = info.isVpn;
        final bool isNoiBoWifi = wifiName.toLowerCase().contains('noi bo') || wifiName.toLowerCase().contains('noibo');

        // Cho phép vai trò Nhân viên khi: Server trả về Patient+Staff HOẶC đang bật VPN HOẶC Wi-Fi là "noi bo"
        final isStaffAllowed = isServerStaff || isVpnActive || isNoiBoWifi;

        if (kDebugMode) {
          debugPrint('[NetworkAuthService] modeString: "$modeString", IsVpn: $isVpnActive, SSID: "$wifiName" -> isStaffAllowed: $isStaffAllowed');
        }
        return NetworkAuthResult(
          isInternalNetwork: isStaffAllowed,
          allowEmployeeRole: isStaffAllowed,
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
