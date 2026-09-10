import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:benhvien7c/core/dio/AppLocator.dart';
import 'package:benhvien7c/core/config/environment.dart';
import 'package:benhvien7c/core/widgets/AppResponsiveContainer.dart';

class AboutAppView extends StatefulWidget {
  const AboutAppView({super.key});

  @override
  State<AboutAppView> createState() => _AboutAppViewState();
}

class _AboutAppViewState extends State<AboutAppView> {
  String _version = '1.0.35';
  String _buildNumber = '35';
  String _deviceId = 'Đang tải...';

  @override
  void initState() {
    super.initState();
    _loadDeviceInfo();
  }

  Future<void> _loadDeviceInfo() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final deviceId = await AppLocator.secureStorage.getOrCreateDeviceId();

      if (mounted) {
        setState(() {
          _version = packageInfo.version.isNotEmpty ? packageInfo.version : Environment.appVersion;
          _buildNumber = packageInfo.buildNumber.isNotEmpty ? packageInfo.buildNumber : '35';
          _deviceId = deviceId;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _version = Environment.appVersion;
          _buildNumber = '35';
          _deviceId = Environment.deviceId;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppResponsiveContainer(
      appBar: AppBar(
        backgroundColor: const Color(0xFF3B82F6),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Thông tin phần mềm',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Nhà phát triển', 'Bệnh viện Quân Dân Y Miền Đông'),
            const SizedBox(height: 16),
            _buildInfoRow('Phiên bản', _version),
            const SizedBox(height: 16),
            _buildInfoRow('Số build', _buildNumber),
            const SizedBox(height: 16),
            _buildInfoRow('Hỗ trợ', 'contact@quandanymiendong.vn'),
            const SizedBox(height: 24),
            _buildInfoRow('Device Id', _deviceId),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF475569),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const Text(
          ': ',
          style: TextStyle(
            fontSize: 16,
            color: Color(0xFF475569),
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black,
              fontWeight: FontWeight.w600,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }
}
