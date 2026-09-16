import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'NetworkInfoResult.dart';

class NetworkInfoService {
  final NetworkInfo _networkInfo = NetworkInfo();
  final Connectivity _connectivity = Connectivity();

  Future<NetworkInfoResult> collectNetworkInfo() async {
    final connectionType = await _getConnectionType();

    // Check if device is connected to VPN
    final isVpn = await _checkIsVpn();

    final isAndroid = !kIsWeb && Platform.isAndroid;
    final platformName = kIsWeb ? 'web' : (isAndroid ? 'android' : 'ios');

    // If not connected to Wi-Fi and not VPN, return early without prompting location permissions
    if (connectionType != ConnectionType.wifi && !isVpn) {
      return NetworkInfoResult(
        locationPermissionGranted: false,
        locationServiceEnabled: false,
        connectionType: connectionType,
        isVpn: isVpn,
        platform: platformName,
      );
    }

    // Yêu cầu cấp quyền đọc thông tin Wi-Fi (SSID) và mạng
    bool isPermissionGranted = false;
    bool isLocationServiceEnabled = true;
    try {
      if (isAndroid) {
        isLocationServiceEnabled = await Permission.location.serviceStatus.isEnabled;
      }
      var status = await Permission.locationWhenInUse.status;
      if (!status.isGranted && !status.isPermanentlyDenied) {
        status = await Permission.locationWhenInUse.request();
      }
      isPermissionGranted = status.isGranted;
    } catch (_) {}

    String? ssid;
    String? bssid;
    String? localIp;
    String? gatewayIp;

    // Always attempt to get Wi-Fi Name (SSID)
    try {
      ssid = await _networkInfo.getWifiName();
      if (ssid != null) {
        ssid = ssid.replaceAll('"', '').trim();
        if (ssid == '<unknown ssid>' || ssid == 'null' || ssid.isEmpty) {
          ssid = null;
        }
      }
    } catch (_) {}

    try {
      bssid = await _networkInfo.getWifiBSSID();
      if (bssid == '02:00:00:00:00:00') {
        bssid = null;
      }
    } catch (_) {}

    // Local IP: Available on both Android and iOS without location permission
    try {
      localIp = await _networkInfo.getWifiIP();
    } catch (_) {}

    // Gateway IP: Reliable on Android. On iOS, public APIs do not provide a reliable gateway IP,
    // so we explicitly leave it null on iOS.
    if (isAndroid) {
      try {
        gatewayIp = await _networkInfo.getWifiGatewayIP();
      } catch (_) {}
    } else {
      gatewayIp = null;
    }

    return NetworkInfoResult(
      locationPermissionGranted: isPermissionGranted,
      locationServiceEnabled: isLocationServiceEnabled,
      ssid: ssid,
      bssid: bssid,
      localIp: localIp,
      gatewayIp: gatewayIp,
      connectionType: connectionType,
      isVpn: isVpn,
      latitude: null,
      longitude: null,
      platform: platformName,
    );
  }

  Future<bool> _checkIsVpn() async {
    try {
      final results = await _connectivity.checkConnectivity();
      return results.contains(ConnectivityResult.vpn);
    } catch (_) {
      return false;
    }
  }

  Future<ConnectionType> _getConnectionType() async {
    try {
      final results = await _connectivity.checkConnectivity();
      if (results.contains(ConnectivityResult.wifi)) return ConnectionType.wifi;
      if (results.contains(ConnectivityResult.mobile)) return ConnectionType.mobile;
      if (results.contains(ConnectivityResult.none)) return ConnectionType.none;
    } catch (_) {}
    return ConnectionType.unknown;
  }
}
