enum ConnectionType { wifi, mobile, none, unknown }

class NetworkInfoResult {
  final bool locationPermissionGranted;
  final bool locationServiceEnabled; // Only relevant on Android
  final String? ssid;
  final String? bssid;
  final String? localIp;
  final String? gatewayIp; // null on iOS
  final ConnectionType connectionType;
  final bool isVpn;
  final double? latitude;
  final double? longitude;
  final String platform;

  NetworkInfoResult({
    required this.locationPermissionGranted,
    required this.locationServiceEnabled,
    this.ssid,
    this.bssid,
    this.localIp,
    this.gatewayIp,
    required this.connectionType,
    required this.isVpn,
    this.latitude,
    this.longitude,
    required this.platform,
  });

  Map<String, dynamic> toJson() => {
        'Name': ssid ?? '',
        'LocalIp': localIp,
        'GatewayIp': gatewayIp,
        'ConnectionType': connectionType.name,
        'IsVpn': isVpn,
        if (latitude != null) 'Latitude': latitude,
        if (longitude != null) 'Longitude': longitude,
      };
}

class NetworkAuthResult {
  final bool isInternalNetwork;
  final bool allowEmployeeRole;
  final String verifiedBy;

  NetworkAuthResult({
    required this.isInternalNetwork,
    required this.allowEmployeeRole,
    required this.verifiedBy,
  });

  factory NetworkAuthResult.fromJson(Map<String, dynamic> json) {
    return NetworkAuthResult(
      isInternalNetwork: json['isInternalNetwork'] ?? false,
      allowEmployeeRole: json['allowEmployeeRole'] ?? false,
      verifiedBy: json['verifiedBy'] ?? 'unknown',
    );
  }

  // Fail-safe: Default to denying employee role when network is unknown or error occurs
  factory NetworkAuthResult.deny() => NetworkAuthResult(
        isInternalNetwork: false,
        allowEmployeeRole: false,
        verifiedBy: 'client_fallback_deny',
      );
}
