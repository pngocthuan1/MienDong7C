import 'dart:async';
import 'package:flutter/material.dart';
import 'package:benhvien7c/core/theme/AppColors.dart';
import 'package:benhvien7c/core/widgets/AppNotificationToast.dart';
import 'package:benhvien7c/core/utils/NotificationHelper.dart';

class NotificationPlaygroundView extends StatelessWidget {
  const NotificationPlaygroundView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Thử nghiệm 7 Loại Thông báo',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0.5,
      ),
      body: Container(
        color: const Color(0xFFF8FAFC),
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          children: [
            _buildPlaygroundHeader(),
            const SizedBox(height: 20),
            _buildNotificationCard(
              context,
              number: 1,
              title: '1. AlertDialog (Modal hộp thoại)',
              color: const Color(0xFF0284C7),
              widgetUsed: 'showDialog() + AlertDialog',
              useCase: 'Dùng khi cần xác nhận hành động quan trọng/nguy hiểm (Xóa tài khoản, Hủy lịch khám), hoặc cảnh báo lỗi nghiêm trọng bắt buộc phản hồi.',
              behavior: 'Chặn tương tác màn hình nền, yêu cầu người dùng chọn hành động (Đồng ý/Hủy) mới tắt được.',
              onTest: () => _testAlertDialog(context),
            ),
            const SizedBox(height: 16),
            _buildNotificationCard(
              context,
              number: 2,
              title: '2. SnackBar (Thông báo nhanh ở đáy)',
              color: const Color(0xFF0F766E),
              widgetUsed: 'ScaffoldMessenger.of(context).showSnackBar()',
              useCase: 'Phản hồi nhanh kết quả của hành động vừa thực hiện (Đã lưu nháp, Đã thêm lịch khám) và có thể đi kèm nút "Hoàn tác" (Undo).',
              behavior: 'Xuất hiện ở đáy màn hình, tự động biến mất sau 3-4 giây, không làm gián đoạn trải nghiệm người dùng.',
              onTest: () => _testSnackBar(context),
            ),
            const SizedBox(height: 16),
            _buildNotificationCard(
              context,
              number: 3,
              title: '3. Toast (Thông báo nổi chớp nhoáng)',
              color: const Color(0xFF475569),
              widgetUsed: 'Custom Overlay (Nửa giây tự tắt)',
              useCase: 'Thông báo trạng thái ngắn gọn, ít quan trọng (Đã copy mã khám, Đã cập nhật xong cấu hình, Không có internet nhẹ).',
              behavior: 'Hiển thị lơ lửng ở vị trí linh hoạt (dưới/giữa), tự động tắt sau 1.5 - 2 giây, không chặn tương tác.',
              onTest: () => _testToast(context),
            ),
            const SizedBox(height: 16),
            _buildNotificationCard(
              context,
              number: 4,
              title: '4. BottomSheet (Trượt lên từ đáy)',
              color: const Color(0xFF8B5CF6),
              widgetUsed: 'showModalBottomSheet()',
              useCase: 'Dùng khi cần người dùng chọn nhanh một số tùy chọn phụ (Chọn chụp ảnh từ Camera hay Album, Chọn tài khoản thanh toán).',
              behavior: 'Một bảng lựa chọn trượt từ đáy màn hình lên, có thể bấm ra ngoài để đóng lại dễ dàng.',
              onTest: () => _testBottomSheet(context),
            ),
            const SizedBox(height: 16),
            _buildNotificationCard(
              context,
              number: 5,
              title: '5. MaterialBanner (Dải thông báo cố định)',
              color: const Color(0xFFD97706),
              widgetUsed: 'ScaffoldMessenger.of(context).showMaterialBanner()',
              useCase: 'Cảnh báo thông tin quan trọng kéo dài trên trang hiện tại (App đang offline, Hồ sơ chưa được xác thực BHYT).',
              behavior: 'Nằm cố định trên cùng nội dung, không tự biến mất, bắt buộc bấm nút để đóng nhưng KHÔNG chặn cuộn xem nội dung ở dưới.',
              onTest: () => _testMaterialBanner(context),
            ),
            const SizedBox(height: 16),
            _buildNotificationCard(
              context,
              number: 6,
              title: '6. Custom Overlay (Banner trượt trong App)',
              color: const Color(0xFF0369A1),
              widgetUsed: 'OverlayEntry (AppNotificationToast)',
              useCase: 'Hiển thị các thông báo nhanh dạng biểu ngữ trượt xuống từ đầu ứng dụng khi người dùng đang mở app.',
              behavior: 'Nổi đè lên toàn bộ giao diện, có thể vuốt lên hoặc chạm bất kỳ đâu để tắt nhanh.',
              onTest: () => _testCustomOverlay(context),
            ),
            const SizedBox(height: 16),
            _buildNotificationCard(
              context,
              number: 7,
              title: '7. Local Notification (Thông báo hệ thống)',
              color: const Color(0xFFBE185D),
              widgetUsed: 'awesome_notifications / HTML5 Web',
              useCase: 'Đẩy thông báo từ bên ngoài hệ điều hành khi người dùng không mở app (Nhắc lịch uống thuốc, Nhắc lịch hẹn tái khám định kỳ).',
              behavior: 'Xuất hiện trên thanh trạng thái hệ thống. Khi nhấp vào sẽ tự động mở app và điều hướng đến trang chi tiết thông báo.',
              onTest: () => _testLocalNotification(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaygroundHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline_rounded, color: Color(0xFF1D4ED8)),
              SizedBox(width: 8),
              Text(
                'Hướng dẫn Thử nghiệm',
                style: TextStyle(
                  color: Color(0xFF1E3A8A),
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            'Mỗi loại thông báo (Notification/UI Alert) được thiết kế cho các mục đích và trải nghiệm người dùng (UX) khác nhau. Hãy bấm "Chạy thử (Live Test)" để trực tiếp trải nghiệm sự khác biệt.',
            style: TextStyle(
              color: Color(0xFF1E40AF),
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(
    BuildContext context, {
    required int number,
    required String title,
    required Color color,
    required String widgetUsed,
    required String useCase,
    required String behavior,
    required VoidCallback onTest,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        widgetUsed,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 12),
          _buildMetaRow('Khuyên dùng cho:', useCase),
          const SizedBox(height: 8),
          _buildMetaRow('Hành vi hiển thị:', behavior),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onTest,
              icon: const Icon(Icons.play_circle_outline_rounded, size: 18),
              label: const Text('Chạy thử (Live Test)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Color(0xFF94A3B8),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF334155),
            height: 1.4,
          ),
        ),
      ],
    );
  }

  // --- 1. Test AlertDialog ---
  void _testAlertDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('Hủy Lịch Khám Bệnh?'),
          ],
        ),
        content: const Text(
          'Bạn có chắc chắn muốn hủy lịch hẹn khám tại Khoa Nội tổng quát vào lúc 09:00 ngày mai? Hành động này sẽ giải phóng số lượt khám cho bệnh nhân khác.',
          style: TextStyle(height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Giữ lại lịch'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).clearSnackBars();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Lịch khám bệnh đã được hủy thành công!'),
                  backgroundColor: Color(0xFF0F766E),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            child: const Text('Xác nhận hủy'),
          ),
        ],
      ),
    );
  }

  // --- 2. Test SnackBar ---
  void _testSnackBar(BuildContext context) {
    // Dismiss current material banner to clean layout
    ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
    ScaffoldMessenger.of(context).clearSnackBars(); // Clear SnackBar queue
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Đã lưu nháp thành công Hồ sơ Y khoa mới!'),
        backgroundColor: const Color(0xFF0F766E),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        action: SnackBarAction(
          label: 'Hoàn tác',
          textColor: Colors.amber,
          onPressed: () {
            ScaffoldMessenger.of(context).clearSnackBars();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Đã phục hồi trạng thái trước đó.')),
            );
          },
        ),
        duration: const Duration(seconds: 3),
      ),
    );

    // Force-close Timer after 3 seconds (bypassing any browser hover freeze)
    Timer(const Duration(seconds: 3), () {
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      }
    });
  }

  // --- 3. Test Toast ---
  void _testToast(BuildContext context) {
    final overlay = Overlay.of(context);
    final entry = OverlayEntry(
      builder: (context) => Positioned(
        bottom: 80,
        left: 32,
        right: 32,
        child: Material(
          color: Colors.transparent,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B).withOpacity(0.9),
                borderRadius: BorderRadius.circular(999),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x33000000),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.copy_rounded, color: Colors.white, size: 16),
                  SizedBox(width: 8),
                  Text(
                    'Đã sao chép mã số lịch khám!',
                    style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(entry);
    Future.delayed(const Duration(milliseconds: 1500), () {
      entry.remove();
    });
  }

  // --- 4. Test BottomSheet ---
  void _testBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Nguồn Tải Ảnh Hồ Sơ',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 6),
              const Text(
                'Vui lòng chọn nguồn để cập nhật ảnh chân dung của bạn',
                style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(color: Color(0xFFEFF6FF), shape: BoxShape.circle),
                  child: const Icon(Icons.camera_alt_rounded, color: Colors.blue),
                ),
                title: const Text('Chụp ảnh trực tiếp (Camera)', style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(color: Color(0xFFECFDF5), shape: BoxShape.circle),
                  child: const Icon(Icons.photo_library_rounded, color: Colors.green),
                ),
                title: const Text('Chọn ảnh có sẵn (Gallery)', style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- 5. Test MaterialBanner ---
  void _testMaterialBanner(BuildContext context) {
    ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
    ScaffoldMessenger.of(context).clearMaterialBanners(); // Clear material banners queue
    ScaffoldMessenger.of(context).showMaterialBanner(
      MaterialBanner(
        elevation: 0.5,
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

  // --- 6. Test Custom Overlay ---
  void _testCustomOverlay(BuildContext context) {
    AppNotificationToast.show(
      context,
      title: 'Hồ sơ sức khỏe của bạn đã cập nhật',
      message: 'Kết quả xét nghiệm máu tổng quát đã được cập nhật từ Hệ thống thông tin Bệnh viện (HIS).',
    );
  }

  // --- 7. Test Local Notification ---
  void _testLocalNotification(BuildContext context) {
    NotificationHelper.showNotification(
      id: 'PLAYGROUND-${DateTime.now().millisecondsSinceEpoch}',
      title: 'Nhắc nhở uống thuốc định kỳ',
      body: 'Đến giờ uống thuốc buổi trưa theo toa thuốc số 09 của bạn. Nhấp để xem chi tiết hướng dẫn uống thuốc.',
    );
  }
}
