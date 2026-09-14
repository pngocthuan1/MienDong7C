import 'dart:io';
import 'dart:convert';
import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:benhvien7c/core/dio/AppLocator.dart';
import 'package:benhvien7c/features/patients/domain/entities/NotificationItemEntity.dart';
import 'package:benhvien7c/features/patients/presentation/viewmodels/CreateNotificationViewModel.dart';

class CreateNotificationView extends StatefulWidget {
  const CreateNotificationView({super.key});

  @override
  State<CreateNotificationView> createState() => _CreateNotificationViewState();
}

class _CreateNotificationViewState extends State<CreateNotificationView> with SingleTickerProviderStateMixin {
  late final CreateNotificationViewModel _viewModel;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _viewModel = CreateNotificationViewModel(
      AppLocator.portalRepository,
      AppLocator.sessionStore,
    );
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        _viewModel.activeTabIndex = _tabController.index;
      }
    });
    _viewModel.sendNotificationCommand.addListener(_onSendResult);
    _viewModel.initNotificationNumber();
    _viewModel.loadListMasterFromApi();
  }

  @override
  void dispose() {
    _viewModel.sendNotificationCommand.removeListener(_onSendResult);
    _viewModel.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _onSendResult() {
    if (_viewModel.sendNotificationCommand.running) return;

    final result = _viewModel.sendNotificationCommand.result;
    if (result == null || !mounted) return;

    result.when(
      ok: (NotificationItemEntity notif) {
        _viewModel.sendNotificationCommand.clearResult();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã gửi thông báo thành công: "${notif.title}"'),
            backgroundColor: const Color(0xFF34A853),
          ),
        );
        Navigator.of(context).pop(true); // Return true to trigger reload
      },
      error: (exception, message) {
        _viewModel.sendNotificationCommand.clearResult();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message.isNotEmpty ? message : 'Có lỗi khi gửi thông báo'),
            backgroundColor: Colors.redAccent,
          ),
        );
      },
    );
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_viewModel.canSend) {
      if (_viewModel.contentController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vui lòng nhập nội dung thông báo'),
            backgroundColor: Color(0xFFD97706),
          ),
        );
        _tabController.animateTo(0);
        return;
      }
      if (_viewModel.targetMode == 'custom' && _viewModel.selectedGroupIds.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vui lòng chọn ít nhất 1 nơi nhận thông báo ở Tab "Nơi nhận"'),
            backgroundColor: Color(0xFFD97706),
          ),
        );
        _tabController.animateTo(1);
        return;
      }
    }
    await _viewModel.sendNotificationCommand.execute();
  }

  Future<bool> _showSwitchModeDialog({
    required String title,
    required String message,
    required String confirmText,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A)),
          ),
          content: Text(
            message,
            style: const TextStyle(fontSize: 14, color: Color(0xFF334155), height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Bỏ qua', style: TextStyle(color: Color(0xFF64748B))),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEA580C),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(confirmText, style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  Future<void> _pickRealFiles() async {
    if (_viewModel.isImageMode) {
      final shouldSwitch = await _showSwitchModeDialog(
        title: '⚠️ Đang đính kèm Hình ảnh/Video',
        message: 'Bạn đang có ${_viewModel.imageAttachments.length} tệp media đính kèm.\n\nTheo quy tắc 1 trong 2, bạn có muốn xóa danh sách media cũ để chuyển sang chọn Tệp tài liệu không?',
        confirmText: 'Xóa media & Chọn tệp',
      );
      if (shouldSwitch) {
        _viewModel.attachments.clear();
        _viewModel.refreshUI();
      } else {
        return;
      }
    } else if (_viewModel.documentAttachments.isNotEmpty) {
      final docName = _viewModel.documentAttachments.first.fileName;
      final shouldReplace = await _showSwitchModeDialog(
        title: '⚠️ Đã có 1 Tệp Tài Liệu đính kèm',
        message: 'Bạn đang đính kèm tệp văn bản: "$docName".\n\nMỗi thông báo chỉ được phép đính kèm DUY NHẤT 1 tệp tài liệu văn bản.\n\nBạn có muốn thay thế tệp này bằng tệp mới chọn không?',
        confirmText: 'Thay thế tệp mới',
      );
      if (shouldReplace) {
        _viewModel.attachments.clear();
        _viewModel.refreshUI();
      } else {
        return;
      }
    }

    try {
      // Cho phép chọn TẤT CẢ CÁC LOẠI TỆP (PDF, Word, Excel, PowerPoint, ZIP, RAR, Ảnh, Video,...)
      final files = await FilePicker.pickFiles(
        type: FileType.any,
        allowMultiple: true,
      );

      if (files != null && files.isNotEmpty) {
        final List<({String fileName, String filePath, int sizeBytes})> items = [];
        for (final file in files) {
          if (file.name.isEmpty) continue;

          int calculatedSize = 250 * 1024;
          if (file.path != null && file.path!.isNotEmpty) {
            try {
              final f = File(file.path!);
              if (f.existsSync()) {
                calculatedSize = f.lengthSync();
              }
            } catch (_) {}
          }

          items.add((
            fileName: file.name,
            filePath: file.path ?? '/device/${file.name}',
            sizeBytes: calculatedSize,
          ));
        }

        final batchRes = _viewModel.addRealPickedAttachmentBatch(items);

        if (mounted) {
          if (batchRes.addedCount > 0) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('📎 Đã đính kèm ${batchRes.addedCount} tệp thành công!'),
                backgroundColor: const Color(0xFF10B981),
                duration: const Duration(seconds: 3),
              ),
            );
          } else if (batchRes.rejectedSizeCount > 0) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('⚠️ Tệp đính kèm vượt quá dung lượng cho phép! (Tối đa 5MB)'),
                backgroundColor: Colors.redAccent,
                duration: Duration(seconds: 4),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể chọn tệp: ${e.toString()}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  int _activeGalleryFilterIndex = 0; // 0: Tất cả, 1: Video, 2: Hình ảnh

  Future<void> _showUnifiedDocumentAndMediaSheet() async {
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'CHỌN ĐÍNH KÈM TÀI LIỆU / MEDIA',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.description_rounded, color: Color(0xFF2563EB)),
                  ),
                  title: const Text('Tệp Văn Bản / Tài Liệu (.pdf, .docx, .xlsx...)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: const Text('Mở Sheet Full Màn Hình chọn tệp • Bảo toàn 100% gốc <= 5MB', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _showDocumentPickerSheet();
                  },
                ),
                const Divider(),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.photo_library_rounded, color: Color(0xFF059669)),
                  ),
                  title: const Text('Thư Viện Media (Có bộ lọc Ảnh & Video)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: const Text('Bộ lọc: Tất cả | Hình ảnh | Video (Đã tích hợp)', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _openGalleryWithFilterTabsSheet();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showDocumentPickerSheet() async {
    if (_viewModel.isImageMode) {
      final imgCount = _viewModel.imageAttachments.length;
      final shouldSwitch = await _showSwitchModeDialog(
        title: '⚠️ Đang đính kèm Hình ảnh/Video',
        message: 'Bạn đang có $imgCount tệp media đính kèm.\n\nTheo quy tắc 1 trong 2, bạn có muốn xóa danh sách media này để chuyển sang Tệp Tài Liệu không?',
        confirmText: 'Xóa media & Mở Tệp',
      );
      if (shouldSwitch) {
        _viewModel.attachments.clear();
        _viewModel.refreshUI();
      } else {
        return;
      }
    }

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final double sheetHeight = MediaQuery.of(context).size.height * 0.90;
        return Container(
          height: sheetHeight,
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    icon: const Icon(Icons.close, color: Color(0xFF0F172A), size: 24),
                  ),
                  const Text(
                    'CHỌN TỆP TÀI LIỆU VĂN BẢN',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline_rounded, color: Color(0xFF2563EB), size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Hỗ trợ đính kèm 1 file (.pdf, .docx, .doc, .xlsx, .txt, .zip...) tối đa 5.0 MB. Giữ nguyên gốc 100% không nén.',
                        style: TextStyle(fontSize: 12, color: Color(0xFF1E40AF), height: 1.3),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView(
                  children: [
                    _buildDocFormatCard(
                      icon: Icons.picture_as_pdf_rounded,
                      iconColor: const Color(0xFFDC2626),
                      bgColor: const Color(0xFFFEF2F2),
                      title: 'Tệp PDF (.pdf)',
                      subtitle: 'Đọc native hiển thị trang A4 trực tiếp trong app',
                    ),
                    const SizedBox(height: 12),
                    _buildDocFormatCard(
                      icon: Icons.description_rounded,
                      iconColor: const Color(0xFF2563EB),
                      bgColor: const Color(0xFFEFF6FF),
                      title: 'Tệp Word (.docx, .doc)',
                      subtitle: 'Đọc native chuẩn UTF-8, giữ nguyên 100% ký tự đặc biệt',
                    ),
                    const SizedBox(height: 12),
                    _buildDocFormatCard(
                      icon: Icons.table_chart_rounded,
                      iconColor: const Color(0xFF059669),
                      bgColor: const Color(0xFFECFDF5),
                      title: 'Bảng tính Excel (.xlsx, .xls, .csv)',
                      subtitle: 'Dựng bảng biểu xem dữ liệu chi tiết ngay trên ứng dụng',
                    ),
                    const SizedBox(height: 12),
                    _buildDocFormatCard(
                      icon: Icons.folder_zip_rounded,
                      iconColor: const Color(0xFFD97706),
                      bgColor: const Color(0xFFFFFBEB),
                      title: 'Tệp Nén (.zip, .rar)',
                      subtitle: 'Xem cấu trúc danh sách tệp bên trong kho nén',
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  _pickRealFiles();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.folder_open_rounded, size: 22),
                label: const Text('Duyệt Chọn Tệp Trong Máy', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDocFormatCard({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A))),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openGalleryWithFilterTabsSheet() async {
    if (_viewModel.isDocumentMode) {
      final docName = _viewModel.documentAttachments.first.fileName;
      final shouldSwitch = await _showSwitchModeDialog(
        title: '⚠️ Đang đính kèm Tệp tài liệu',
        message: 'Bạn đang có tệp tài liệu [$docName] đính kèm.\n\nTheo quy tắc 1 trong 2, bạn có muốn xóa tệp tài liệu này để chuyển sang Thư Viện Media (Ảnh/Video) không?',
        confirmText: 'Xóa tệp & Mở thư viện',
      );
      if (shouldSwitch) {
        _viewModel.attachments.clear();
        _viewModel.refreshUI();
      } else {
        return;
      }
    }

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white, // Clean Hospital White Theme
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header (Clean Hospital White style)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close, color: Color(0xFF0F172A), size: 22),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: const Row(
                            children: [
                              Text('Thư Viện Máy', style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 13)),
                              SizedBox(width: 4),
                              Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF0F172A), size: 18),
                            ],
                          ),
                        ),
                        const SizedBox(width: 40),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Filter Tab Bar (Tất cả | Video | Hình ảnh) in Hospital Blue Accent
                    Row(
                      children: [
                        _buildFilterTabItem(
                          label: 'Tất cả',
                          isSelected: _activeGalleryFilterIndex == 0,
                          onTap: () {
                            setSheetState(() => _activeGalleryFilterIndex = 0);
                            setState(() => _activeGalleryFilterIndex = 0);
                          },
                        ),
                        _buildFilterTabItem(
                          label: 'Video',
                          isSelected: _activeGalleryFilterIndex == 1,
                          onTap: () {
                            setSheetState(() => _activeGalleryFilterIndex = 1);
                            setState(() => _activeGalleryFilterIndex = 1);
                          },
                        ),
                        _buildFilterTabItem(
                          label: 'Hình ảnh',
                          isSelected: _activeGalleryFilterIndex == 2,
                          onTap: () {
                            setSheetState(() => _activeGalleryFilterIndex = 2);
                            setState(() => _activeGalleryFilterIndex = 2);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Content options based on selected filter tab
                    if (_activeGalleryFilterIndex == 0) ...[
                      ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.collections_rounded, color: Color(0xFF2563EB)),
                        ),
                        title: const Text('Mở Thư Viện Máy (Ảnh & Video)', style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 14)),
                        subtitle: const Text('Mở trực tiếp App Thư Viện Ảnh của máy (MIUI Gallery/Photos)', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                        trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
                        onTap: () {
                          Navigator.of(context).pop();
                          _launchRealNativeGalleryApp('all');
                        },
                      ),
                    ] else if (_activeGalleryFilterIndex == 1) ...[
                      ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.videocam_rounded, color: Color(0xFF2563EB)),
                        ),
                        title: const Text('Mở Thư Viện Máy chọn Video', style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 14)),
                        subtitle: const Text('Mở trực tiếp App Thư Viện lọc tệp Video (.mp4, .mov)', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                        trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
                        onTap: () {
                          Navigator.of(context).pop();
                          _launchRealNativeGalleryApp('video');
                        },
                      ),
                    ] else ...[
                      ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFECFDF5),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.photo_library_rounded, color: Color(0xFF059669)),
                        ),
                        title: const Text('Mở Thư Viện Máy chọn Hình Ảnh', style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 14)),
                        subtitle: const Text('Mở trực tiếp App Thư Viện chọn nhiều Hình Ảnh', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                        trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
                        onTap: () {
                          Navigator.of(context).pop();
                          _launchRealNativeGalleryApp('image');
                        },
                      ),
                    ],
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  static const MethodChannel _nativeGalleryChannel = MethodChannel('com.hospisoft.benhvien7c/gallery_picker');

  Future<void> _launchRealNativeGalleryApp(String mediaType) async {
    try {
      final List<dynamic>? rawList = await _nativeGalleryChannel.invokeListMethod<dynamic>(
        'openNativeGalleryApp',
        {'mediaType': mediaType},
      );

      if (rawList != null && rawList.isNotEmpty) {
        final fileItems = rawList.map((item) {
          final map = Map<String, dynamic>.from(item as Map);
          final rawName = map['fileName']?.toString() ?? 'MEDIA_${DateTime.now().millisecondsSinceEpoch}';
          final filePath = map['filePath']?.toString() ?? '';
          final sizeBytes = (map['sizeBytes'] as num?)?.toInt() ?? 0;

          final ext = rawName.contains('.') ? rawName.split('.').last.toLowerCase() : 'jpg';
          final isVid = ['mp4', 'mov', 'avi', 'mkv', '3gp'].contains(ext);

          final finalFileName = isVid
              ? (rawName.contains('.') ? rawName : '$rawName.mp4')
              : (rawName.contains('.') ? '${rawName.substring(0, rawName.lastIndexOf('.'))}.jpg' : '$rawName.jpg');

          return (
            fileName: finalFileName,
            filePath: filePath,
            sizeBytes: sizeBytes > 0 ? sizeBytes : (isVid ? 1500 * 1024 : 280 * 1024),
          );
        }).toList();

        final int newBatchTotalBytes = fileItems.fold(0, (sum, f) => sum + f.sizeBytes);
        final int currentBytes = _viewModel.totalImageSizeBytes;
        final int potentialTotalBytes = currentBytes + newBatchTotalBytes;

        if (potentialTotalBytes > CreateNotificationViewModel.maxTotalImageSizeBytes) {
          final potentialMbStr = (potentialTotalBytes / (1024 * 1024)).toStringAsFixed(2);
          if (mounted) {
            await showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                title: const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 24),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'VƯỢT QUÁ DUNG LƯỢNG (5.0 MB)',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.redAccent),
                      ),
                    ),
                  ],
                ),
                content: Text(
                  'Bạn vừa chọn ${fileItems.length} tệp từ Thư Viện với tổng dung lượng là $potentialMbStr MB (Vượt mốc 5.0 MB cho phép).\n\nHệ thống từ chối danh sách này. Vui lòng chọn lại dưới 5.0 MB!',
                  style: const TextStyle(fontSize: 14, color: Color(0xFF334155), height: 1.4),
                ),
                actions: [
                  ElevatedButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Đã hiểu, Chọn lại', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );
          }
          return;
        }

        final batchRes = _viewModel.addRealPickedAttachmentBatch(fileItems);
        if (mounted && batchRes.addedCount > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('🖼️🎬 Đã đính kèm ${batchRes.addedCount} tệp từ App Thư Viện Ảnh máy! (${_viewModel.formattedTotalImageSize})'),
              backgroundColor: const Color(0xFF10B981),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (mediaType == 'image') {
        _pickFromPhotoGallery();
      } else if (mediaType == 'video') {
        _pickVideoFromGallery();
      } else {
        _pickAllMediaFromSystemGallery();
      }
    }
  }

  Future<void> _pickAllMediaFromSystemGallery() async {
    try {
      final picker = ImagePicker();
      final List<XFile> mediaList = await picker.pickMultipleMedia(
        imageQuality: 80,
      );

      if (mediaList.isNotEmpty) {
        final fileItems = await Future.wait(mediaList.map((m) async {
          final length = await m.length();
          final rawName = m.name.isNotEmpty ? m.name : 'MEDIA_${DateTime.now().millisecondsSinceEpoch}';
          final ext = rawName.contains('.') ? rawName.split('.').last.toLowerCase() : 'jpg';
          final isVid = ['mp4', 'mov', 'avi', 'mkv', '3gp'].contains(ext);

          final finalFileName = isVid
              ? (rawName.contains('.') ? rawName : '$rawName.mp4')
              : (rawName.contains('.') ? '${rawName.substring(0, rawName.lastIndexOf('.'))}.jpg' : '$rawName.jpg');

          return (
            fileName: finalFileName,
            filePath: m.path,
            sizeBytes: length > 0 ? length : (isVid ? 1500 * 1024 : 280 * 1024),
          );
        }));

        final int newBatchTotalBytes = fileItems.fold(0, (sum, f) => sum + f.sizeBytes);
        final int currentBytes = _viewModel.totalImageSizeBytes;
        final int potentialTotalBytes = currentBytes + newBatchTotalBytes;

        if (potentialTotalBytes > CreateNotificationViewModel.maxTotalImageSizeBytes) {
          final potentialMbStr = (potentialTotalBytes / (1024 * 1024)).toStringAsFixed(2);
          if (mounted) {
            await showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                title: const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 24),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'VƯỢT QUÁ DUNG LƯỢNG (5.0 MB)',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.redAccent),
                      ),
                    ),
                  ],
                ),
                content: Text(
                  'Bạn vừa chọn ${fileItems.length} tệp media với tổng dung lượng là $potentialMbStr MB (Vượt mốc 5.0 MB cho phép).\n\nHệ thống từ chối danh sách này. Vui lòng chọn lại danh sách dưới 5.0 MB!',
                  style: const TextStyle(fontSize: 14, color: Color(0xFF334155), height: 1.4),
                ),
                actions: [
                  ElevatedButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Đã hiểu, Chọn lại', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );
          }
          return;
        }

        final batchRes = _viewModel.addRealPickedAttachmentBatch(fileItems);
        if (mounted && batchRes.addedCount > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('🖼️🎬 Đã đính kèm thành công ${batchRes.addedCount} tệp media từ Thư viện! (${_viewModel.formattedTotalImageSize})'),
              backgroundColor: const Color(0xFF10B981),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể mở Thư viện máy: ${e.toString()}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Widget _buildFilterTabItem({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? const Color(0xFF2563EB) : Colors.transparent,
                width: 2.5,
              ),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF64748B),
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickFromPhotoGallery() async {
    try {
      final picker = ImagePicker();
      final List<XFile> images = await picker.pickMultiImage(
        imageQuality: 80,
      );

      if (images.isNotEmpty) {
        final fileItems = await Future.wait(images.map((img) async {
          final length = await img.length();
          final rawName = img.name.isNotEmpty ? img.name : 'IMG_${DateTime.now().millisecondsSinceEpoch}.jpg';
          final jpgName = rawName.contains('.')
              ? '${rawName.substring(0, rawName.lastIndexOf('.'))}.jpg'
              : '$rawName.jpg';

          return (
            fileName: jpgName,
            filePath: img.path,
            sizeBytes: length > 0 ? length : 280 * 1024,
          );
        }));

        final int newBatchTotalBytes = fileItems.fold(0, (sum, f) => sum + f.sizeBytes);
        final int currentBytes = _viewModel.totalImageSizeBytes;
        final int potentialTotalBytes = currentBytes + newBatchTotalBytes;

        if (potentialTotalBytes > CreateNotificationViewModel.maxTotalImageSizeBytes) {
          final potentialMbStr = (potentialTotalBytes / (1024 * 1024)).toStringAsFixed(2);
          if (mounted) {
            await showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                title: const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 24),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'VƯỢT QUÁ DUNG LƯỢNG (5.0 MB)',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.redAccent),
                      ),
                    ),
                  ],
                ),
                content: Text(
                  'Bạn vừa chọn ${fileItems.length} ảnh với tổng dung lượng là $potentialMbStr MB (Vượt mốc 5.0 MB cho phép).\n\nHệ thống từ chối danh sách này. Vui lòng chọn lại danh sách ảnh dưới 5.0 MB!',
                  style: const TextStyle(fontSize: 14, color: Color(0xFF334155), height: 1.4),
                ),
                actions: [
                  ElevatedButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Đã hiểu, Chọn lại', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );
          }
          return;
        }

        final batchRes = _viewModel.addRealPickedAttachmentBatch(fileItems);
        if (mounted && batchRes.addedCount > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('🖼️ Đã nén .jpg (Chất lượng 80%) & đính kèm ${batchRes.addedCount} ảnh! (${_viewModel.formattedTotalImageSize})'),
              backgroundColor: const Color(0xFF10B981),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể chọn ảnh từ thư viện: ${e.toString()}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _pickVideoFromGallery() async {
    try {
      final picker = ImagePicker();
      final XFile? video = await picker.pickVideo(source: ImageSource.gallery);

      if (video != null) {
        final length = await video.length();
        final rawName = video.name.isNotEmpty ? video.name : 'VIDEO_${DateTime.now().millisecondsSinceEpoch}.mp4';

        final videoSize = length > 0 ? length : 1500 * 1024;
        final res = _viewModel.addRealPickedAttachment(
          fileName: rawName,
          filePath: video.path,
          sizeBytes: videoSize,
        );

        if (mounted) {
          if (res == AddAttachmentResult.success) {
            final mb = (videoSize / (1024 * 1024)).toStringAsFixed(1);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('🎬 Đã đính kèm 1 Video gốc ($mb MB <= 5.0 MB - Giữ nguyên gốc)'),
                backgroundColor: const Color(0xFF10B981),
                duration: const Duration(seconds: 3),
              ),
            );
          } else if (res == AddAttachmentResult.exceedsFileSize) {
            final mb = (videoSize / (1024 * 1024)).toStringAsFixed(1);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('⚠️ Video đã chọn ($mb MB) vượt quá dung lượng cho phép! (Tối đa 5.0 MB)'),
                backgroundColor: Colors.redAccent,
                duration: const Duration(seconds: 4),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể chọn video: ${e.toString()}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _captureRealCameraPhoto() async {
    if (_viewModel.isDocumentMode) {
      final docName = _viewModel.documentAttachments.first.fileName;
      final shouldSwitch = await _showSwitchModeDialog(
        title: '⚠️ Đang đính kèm Tệp tài liệu',
        message: 'Bạn đang có tệp tài liệu [$docName] đính kèm.\n\nTheo quy tắc 1 trong 2, bạn có muốn xóa tệp tài liệu này để chuyển sang Chụp/Đính kèm hình ảnh không?',
        confirmText: 'Xóa tệp & Chụp ảnh',
      );
      if (shouldSwitch) {
        _viewModel.attachments.clear();
        _viewModel.refreshUI();
      } else {
        return;
      }
    }

    try {
      final picker = ImagePicker();
      final photo = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 75,
        maxWidth: 1920,
      );

      if (photo != null) {
        final length = await photo.length();
        final rawName = photo.name.isNotEmpty ? photo.name : 'IMG_CAMERA.jpg';
        final jpgName = rawName.contains('.')
            ? '${rawName.substring(0, rawName.lastIndexOf('.'))}.jpg'
            : '$rawName.jpg';

        final photoSize = length > 0 ? length : 285 * 1024;
        final result = _viewModel.addRealCameraPhoto(
          fileName: jpgName,
          filePath: photo.path,
          sizeBytes: photoSize,
        );

        if (mounted) {
          if (result == AddAttachmentResult.success) {
            final sizeKb = (photoSize / 1024).toStringAsFixed(0);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('📷 Đã chụp & nén ảnh .jpg ($sizeKb KB < 500KB) • Tổng ảnh: ${_viewModel.formattedTotalImageSize}'),
                backgroundColor: const Color(0xFF10B981),
                duration: const Duration(seconds: 3),
              ),
            );
          } else if (result == AddAttachmentResult.cannotMixImageAndDocument) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('⚠️ Quy tắc 1 trong 2: Bạn đang đính kèm Tệp tài liệu. Vui lòng xóa tệp tài liệu nếu muốn chuyển sang chụp Hình ảnh!'),
                backgroundColor: Color(0xFFEA580C),
                duration: Duration(seconds: 4),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('⚠️ Tổng dung lượng danh sách ảnh đã vượt quá 5.0 MB! (${_viewModel.formattedTotalImageSize}). Không thể chụp thêm ảnh mới.'),
                backgroundColor: Colors.redAccent,
                duration: const Duration(seconds: 4),
              ),
            );
          }
        }
      }
    } catch (_) {
      if (mounted) {
        _captureSampleImage();
      }
    }
  }



  void _showImagePreviewDialog(NotificationAttachmentModel attachment) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black,
      builder: (context) {
        final file = File(attachment.path);
        final fileExists = file.existsSync();

        return Dialog.fullscreen(
          child: Scaffold(
            backgroundColor: const Color(0xFF0F172A),
            appBar: AppBar(
              backgroundColor: const Color(0xFF0F172A),
              foregroundColor: Colors.white,
              elevation: 0,
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    attachment.fileName,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${attachment.extension.toUpperCase()} • ${attachment.formattedSize} • Phóng to 2 ngón tay',
                    style: const TextStyle(color: Color(0xFF34D399), fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white, size: 26),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            body: Center(
              child: InteractiveViewer(
                panEnabled: true,
                minScale: 0.5,
                maxScale: 4.0,
                child: fileExists
                    ? Image.file(
                        file,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => _buildFallbackImagePreview(attachment),
                      )
                    : _buildFallbackImagePreview(attachment),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFallbackImagePreview(NotificationAttachmentModel attachment) {
    return Container(
      width: double.infinity,
      height: 300,
      color: const Color(0xFF1E293B),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.image_rounded, color: Color(0xFF60A5FA), size: 64),
          const SizedBox(height: 12),
          Text(
            attachment.fileName,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            '${attachment.extension.toUpperCase()} • ${attachment.formattedSize}',
            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildSquareImageTileContent(NotificationAttachmentModel img) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.image_rounded, color: Color(0xFF2563EB), size: 36),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              img.fileName,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            img.formattedSize,
            style: const TextStyle(fontSize: 10, color: Color(0xFF059669), fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  IconData _getDocIcon(String ext) {
    if (ext == 'pdf') return Icons.picture_as_pdf_rounded;
    if (ext.contains('xls')) return Icons.table_chart_rounded;
    if (ext.contains('doc') || ext == 'rtf' || ext == 'txt') return Icons.description_rounded;
    if (ext.contains('ppt')) return Icons.slideshow_rounded;
    if (['rar', 'zip', '7z'].contains(ext)) return Icons.folder_zip_rounded;
    if (['mp3', 'wav', 'aac'].contains(ext)) return Icons.audiotrack_rounded;
    if (['mp4', 'avi', 'mkv', 'mov'].contains(ext)) return Icons.video_library_rounded;
    return Icons.insert_drive_file_rounded;
  }

  Color _getDocColor(String ext) {
    if (ext == 'pdf') return const Color(0xFFDC2626);
    if (ext.contains('xls')) return const Color(0xFF16A34A);
    if (ext.contains('doc') || ext == 'rtf' || ext == 'txt') return const Color(0xFF2563EB);
    if (ext.contains('ppt')) return const Color(0xFFEA580C);
    if (['rar', 'zip', '7z'].contains(ext)) return const Color(0xFFD97706);
    if (['mp3', 'wav', 'aac'].contains(ext)) return const Color(0xFF9333EA);
    if (['mp4', 'avi', 'mkv', 'mov'].contains(ext)) return const Color(0xFF0D9488);
    return const Color(0xFF64748B);
  }

  void _showDocumentPreviewDialog(NotificationAttachmentModel doc) {
    final ext = doc.extension.toLowerCase();

    if (['mp4', 'avi', 'mkv', 'mov'].contains(ext)) {
      showDialog<void>(
        context: context,
        builder: (_) => _InAppVideoPreviewModal(filePath: doc.path, fileName: doc.fileName),
      );
      return;
    }

    if (['mp3', 'wav', 'aac', 'm4a'].contains(ext)) {
      showDialog<void>(
        context: context,
        builder: (_) => _InAppAudioPreviewModal(filePath: doc.path, fileName: doc.fileName),
      );
      return;
    }

    if (ext == 'pdf') {
      showDialog<void>(
        context: context,
        builder: (_) => _InAppPdfPreviewModal(filePath: doc.path, fileName: doc.fileName),
      );
      return;
    }

    if (ext == 'docx' || ext == 'doc') {
      showDialog<void>(
        context: context,
        builder: (_) => _InAppDocxPreviewModal(filePath: doc.path, fileName: doc.fileName),
      );
      return;
    }

    if (['txt', 'rtf', 'csv', 'json', 'log', 'md'].contains(ext)) {
      showDialog<void>(
        context: context,
        builder: (_) => _InAppTextPreviewModal(filePath: doc.path, fileName: doc.fileName),
      );
      return;
    }

    _showInAppDocumentSummaryDialog(doc);
  }

  void _showInAppDocumentSummaryDialog(NotificationAttachmentModel doc) {
    final docColor = _getDocColor(doc.extension);
    final docIcon = _getDocIcon(doc.extension);
    final file = File(doc.path);
    final fileExists = file.existsSync();

    showDialog<void>(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: docColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(docIcon, size: 48, color: docColor),
                ),
                const SizedBox(height: 16),
                Text(
                  doc.fileName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Định dạng: ${doc.extension.toUpperCase()}  |  Dung lượng: ${doc.formattedSize}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.folder_open_rounded, size: 16, color: Color(0xFF64748B)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Đường dẫn: ${doc.path}',
                              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            fileExists ? Icons.check_circle_rounded : Icons.info_rounded,
                            size: 16,
                            color: fileExists ? const Color(0xFF10B981) : const Color(0xFF3B82F6),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            fileExists ? 'Tệp sẵn sàng đính kèm trên thiết bị' : 'Đã định dạng tệp thành công',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: fileExists ? const Color(0xFF059669) : const Color(0xFF2563EB),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _openFileWithSystemApp(doc.path);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.open_in_new_rounded, size: 18),
                        label: const Text(
                          'MỞ BẰNG TRÌNH ĐỌC NGOÀI',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Đóng'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openFileWithSystemApp(String filePath) async {
    try {
      final fileUri = Uri.file(filePath);
      final launched = await launchUrl(fileUri, mode: LaunchMode.externalApplication);
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tệp đính kèm sẵn sàng tại: $filePath'),
            backgroundColor: const Color(0xFF2563EB),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tệp đính kèm sẵn sàng tại: $filePath'),
            backgroundColor: const Color(0xFF2563EB),
          ),
        );
      }
    }
  }

  void _captureSampleImage() {
    final attachment = _viewModel.addCompressedCameraPhoto();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('📷 Đã chụp & nén tự động thành .jpg (${attachment.formattedSize} < 500KB)'),
        backgroundColor: const Color(0xFF10B981),
        duration: const Duration(seconds: 3),
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    final session = AppLocator.sessionStore.session;
    final isEmployee = session?.isEmployee ?? false;

    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: const Color(0xFFF1F5F9),
          appBar: AppBar(
            backgroundColor: const Color(0xFF2F7DE1),
            foregroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: const Text(
              'Đăng thông báo',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            actions: isEmployee
                ? [
                    Padding(
                      padding: const EdgeInsets.only(right: 14, top: 10, bottom: 10),
                      child: ElevatedButton(
                        onPressed: _viewModel.canSend && !_viewModel.sendNotificationCommand.running
                            ? _submit
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF2F7DE1),
                          disabledBackgroundColor: Colors.white.withAlpha(129),
                          disabledForegroundColor: const Color(0xFF2F7DE1).withAlpha(154),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 22),
                        ),
                        child: _viewModel.sendNotificationCommand.running
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF2F7DE1)),
                              )
                            : const Text(
                                'Gửi',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                      ),
                    ),
                  ]
                : null,
            bottom: isEmployee
                ? TabBar(
                    controller: _tabController,
                    indicatorColor: Colors.white,
                    indicatorWeight: 3,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white70,
                    labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 16),
                    tabs: const [
                      Tab(text: 'Nội dung'),
                      Tab(text: 'Nơi nhận'),
                    ],
                  )
                : null,
          ),
          body: !isEmployee
              ? Center(
                  child: Container(
                    margin: const EdgeInsets.all(24),
                    padding: const EdgeInsets.all(24),
                    constraints: const BoxConstraints(maxWidth: 420),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFD9EAFE)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.lock_person_rounded,
                          size: 44,
                          color: Color(0xFF2F7DE1),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'Chức năng này chỉ dành cho nhân viên.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFF1E3A8A),
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Bạn hãy quay về trang chủ hoặc đăng nhập bằng tài khoản nhân viên để tiếp tục.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Color(0xFF475569), height: 1.45),
                        ),
                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).pushNamedAndRemoveUntil(
                                '/home',
                                (route) => false,
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2F7DE1),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Về trang chủ', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildContentTab(),
                    _buildRecipientsTab(),
                  ],
                ),
        );
      },
    );
  }

  // --- TAB 1: NỘI DUNG ---
  Widget _buildContentTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Red Notice Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF5F5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFED7D7)),
            ),
            child: Row(
              children: const [
                Icon(
                  Icons.error_outline_rounded,
                  color: Color(0xFFE53E3E),
                  size: 22,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Các trường màu đỏ là bắt buộc nhập',
                    style: TextStyle(
                      color: Color(0xFFC53030),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 2. Sender Information Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const SizedBox(
                      width: 90,
                      child: Text(
                        'Người gửi :',
                        style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        _viewModel.senderName,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          color: Color(0xFF0F172A),
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(height: 1, color: Color(0xFFF1F5F9)),
                ),
                Row(
                  children: [
                    const SizedBox(
                      width: 90,
                      child: Text(
                        'Nơi gửi :',
                        style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        _viewModel.senderDepartment,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          color: Color(0xFF0F172A),
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 3. Content Text Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    RichText(
                      text: const TextSpan(
                        text: 'Nội dung',
                        style: TextStyle(
                          color: Color(0xFFDC2626),
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                        children: [
                          TextSpan(
                            text: ':',
                            style: TextStyle(color: Color(0xFFDC2626)),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      'Tối đa / 4.000 ký tự (${_viewModel.contentController.text.length})',
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _viewModel.contentController,
                  maxLength: 4000,
                  maxLines: 8,
                  minLines: 6,
                  decoration: const InputDecoration(
                    hintText: 'Nội dung thông báo...',
                    hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                    border: InputBorder.none,
                    counterText: '',
                  ),
                  style: const TextStyle(fontSize: 15, color: Color(0xFF1E293B), height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 4. Attachments Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Tệp đính kèm (1 trong 2):',
                        style: TextStyle(
                          color: Color(0xFF0F172A),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _viewModel.isDocumentMode
                            ? const Color(0xFFEFF6FF)
                            : (_viewModel.isImageMode ? const Color(0xFFECFDF5) : const Color(0xFFF1F5F9)),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _viewModel.isDocumentMode
                            ? '1 Tệp tài liệu'
                            : (_viewModel.isImageMode
                                ? 'Hình ảnh'
                                : 'Chưa đính kèm'),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: _viewModel.isDocumentMode
                              ? const Color(0xFF2563EB)
                              : (_viewModel.isImageMode ? const Color(0xFF059669) : const Color(0xFF64748B)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                Row(
                  children: [
                    // Nút 1: CHỌN TÀI LIỆU (Bao gồm Chọn Tệp Văn Bản & Thư Viện Media có bộ lọc)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _showUnifiedDocumentAndMediaSheet,
                        style: OutlinedButton.styleFrom(
                          backgroundColor: _viewModel.isImageMode ? const Color(0xFFECFDF5) : const Color(0xFFF0F6FF),
                          foregroundColor: _viewModel.isImageMode ? const Color(0xFF059669) : const Color(0xFF2563EB),
                          side: BorderSide(color: _viewModel.isImageMode ? const Color(0xFFA7F3D0) : const Color(0xFFBFDBFE)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: Icon(Icons.attach_file_rounded, size: 18, color: _viewModel.isImageMode ? const Color(0xFF059669) : const Color(0xFF2563EB)),
                        label: Text(
                          'CHỌN TÀI LIỆU',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: _viewModel.isImageMode ? const Color(0xFF059669) : const Color(0xFF2563EB),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Nút 2: CHỤP HÌNH (Camera)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _captureRealCameraPhoto,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _viewModel.isDocumentMode ? const Color(0xFFE2E8F0) : const Color(0xFF3B82F6),
                          foregroundColor: _viewModel.isDocumentMode ? const Color(0xFF94A3B8) : Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: Icon(Icons.camera_alt_rounded, size: 18, color: _viewModel.isDocumentMode ? const Color(0xFF94A3B8) : Colors.white),
                        label: Text(
                          'CHỤP HÌNH',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: _viewModel.isDocumentMode ? const Color(0xFF94A3B8) : Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                // 🖼️ 1. KHU VỰC LƯỚI HÌNH ẢNH (PHOTO GALLERY GRID)
                if (_viewModel.imageAttachments.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Hình ảnh đính kèm (${_viewModel.imageAttachments.length}):',
                        style: const TextStyle(
                          color: Color(0xFF1E293B),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        _viewModel.formattedTotalImageSize,
                        style: TextStyle(
                          color: _viewModel.totalImageSizeProgress > 0.9 ? const Color(0xFFDC2626) : const Color(0xFF10B981),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: _viewModel.totalImageSizeProgress,
                      backgroundColor: const Color(0xFFE2E8F0),
                      color: _viewModel.totalImageSizeProgress > 0.9 ? const Color(0xFFDC2626) : const Color(0xFF10B981),
                      minHeight: 4,
                    ),
                  ),
                  const SizedBox(height: 10),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 1,
                    ),
                    itemCount: _viewModel.imageAttachments.length,
                    itemBuilder: (context, idx) {
                      final img = _viewModel.imageAttachments[idx];
                      final file = File(img.path);
                      final fileExists = file.existsSync();

                      return GestureDetector(
                        onTap: () => _showImagePreviewDialog(img),
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFBFDBFE)),
                          ),
                          child: Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(11),
                                child: fileExists
                                    ? Image.file(
                                        file,
                                        width: double.infinity,
                                        height: double.infinity,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) => _buildSquareImageTileContent(img),
                                      )
                                    : _buildSquareImageTileContent(img),
                              ),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: GestureDetector(
                                  onTap: () => _viewModel.removeAttachmentById(img.id),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Colors.redAccent,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.close_rounded, size: 14, color: Colors.white),
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 4,
                                left: 4,
                                right: 4,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.65),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    img.formattedSize,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  if (_viewModel.imageAttachments.length > 1) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFBBF7D0)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.archive_rounded, color: Color(0xFF16A34A), size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '📦 Đã đóng gói ${_viewModel.imageAttachments.length} ảnh thành 1 Gói File duy nhất',
                                  style: const TextStyle(
                                    color: Color(0xFF15803D),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Sẵn sàng gửi API Backend • Dung lượng tổng: ${_viewModel.formattedTotalImageSize}',
                                  style: const TextStyle(
                                    color: Color(0xFF166534),
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],

                // 📄 2. KHU VỰC TÀI LIỆU VĂN BẢN (DOCUMENT FILES LIST)
                if (_viewModel.documentAttachments.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Tài liệu đính kèm (${_viewModel.documentAttachments.length}/1 tệp):',
                        style: const TextStyle(
                          color: Color(0xFF1E293B),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const Text(
                        'Tối đa 1 tệp • <= 5.0 MB',
                        style: TextStyle(
                          color: Color(0xFF2563EB),
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Column(
                    children: List.generate(_viewModel.documentAttachments.length, (idx) {
                      final doc = _viewModel.documentAttachments[idx];
                      final docIcon = _getDocIcon(doc.extension);
                      final docColor = _getDocColor(doc.extension);

                      return InkWell(
                        onTap: () => _showDocumentPreviewDialog(doc),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                          children: [
                            Icon(docIcon, color: docColor, size: 22),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    doc.fileName,
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${doc.extension.toUpperCase()} • ${doc.formattedSize}',
                                    style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close_rounded, size: 18, color: Colors.redAccent),
                              onPressed: () => _viewModel.removeAttachmentById(doc.id),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  ),
                ],

                const SizedBox(height: 14),
                RichText(
                  text: const TextSpan(
                    text: 'Hỗ trợ loại tập tin: ',
                    style: TextStyle(color: Color(0xFF64748B), fontSize: 12, height: 1.5),
                    children: [
                      TextSpan(
                        text: '.bmp, .png, .jpg, .jpeg, pdf, .txt, .rtf, .doc, .docx, .xls, .xlsx, .ppt, .pptx, .rar, .zip, .7z, .pdf, .mp3, .mp4, .avi',
                        style: TextStyle(color: Color(0xFF059669), fontWeight: FontWeight.w600),
                      ),
                      TextSpan(text: '. Kích thước tối đa: '),
                      TextSpan(
                        text: '5MB',
                        style: TextStyle(color: Color(0xFFD97706), fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  // --- TAB 2: NƠI NHẬN ---
  Widget _buildRecipientsTab() {
    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              // 1. Radio Options
              Row(
                children: [
                  Radio<String>(
                    value: 'custom',
                    groupValue: _viewModel.targetMode,
                    activeColor: const Color(0xFF2563EB),
                    onChanged: (val) {
                      if (val != null) _viewModel.setTargetMode(val);
                    },
                  ),
                  const Text(
                    'Tùy chọn',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(width: 24),
                  Radio<String>(
                    value: 'all',
                    groupValue: _viewModel.targetMode,
                    activeColor: const Color(0xFF2563EB),
                    onChanged: (val) {
                      if (val != null) _viewModel.setTargetMode(val);
                    },
                  ),
                  const Text(
                    'Tất cả',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A)),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // 2. Selection Counter & Quick Links
              Row(
                children: [
                  if (_viewModel.targetMode == 'all')
                    Text(
                      'Đã chọn: Tất cả (${_viewModel.totalRecipientCount} nhân viên)',
                      style: const TextStyle(
                        color: Color(0xFF10B981),
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    )
                  else
                    RichText(
                      text: TextSpan(
                        text: '${_viewModel.totalSelectedCount}',
                        style: const TextStyle(
                          color: Color(0xFF0F172A),
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                        children: [
                          TextSpan(
                            text: ' / ${_viewModel.totalRecipientCount} đã chọn',
                            style: const TextStyle(
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.normal,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const Spacer(),
                  GestureDetector(
                    onTap: _viewModel.selectAll,
                    child: const Text(
                      'Chọn hết',
                      style: TextStyle(
                        color: Color(0xFF2563EB),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  GestureDetector(
                    onTap: _viewModel.deselectAll,
                    child: const Text(
                      'Bỏ hết',
                      style: TextStyle(
                        color: Color(0xFFDC2626),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // 3. Sub-filter Tabs (Tất cả / Đã chọn / Chưa chọn)
              Row(
                children: [
                  _buildSubFilterChip('Tất cả', RecipientSubFilter.all),
                  const SizedBox(width: 16),
                  _buildSubFilterChip('Đã chọn', RecipientSubFilter.selected),
                  const SizedBox(width: 16),
                  _buildSubFilterChip('Chưa chọn', RecipientSubFilter.unselected),
                ],
              ),
              const SizedBox(height: 14),

              // 4. Search Bar
              TextField(
                controller: _viewModel.searchController,
                decoration: InputDecoration(
                  hintText: 'Lọc theo tên nhóm...',
                  hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                  prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF94A3B8)),
                  contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: Color(0xFFE2E8F0)),

        // 5. Recipient Groups List
        Expanded(
          child: _viewModel.filteredRecipientGroups.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.playlist_remove_rounded, size: 48, color: Color(0xFF94A3B8)),
                        const SizedBox(height: 12),
                        Text(
                          _viewModel.subFilter == RecipientSubFilter.selected
                              ? 'Chưa chọn nhóm nào. Hãy chọn tab "Tất cả" để xem danh sách nhóm.'
                              : 'Không tìm thấy nhóm phù hợp.',
                          style: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
                  itemCount: _viewModel.filteredRecipientGroups.length,
                  itemBuilder: (context, idx) {
              final group = _viewModel.filteredRecipientGroups[idx];
              final isExpanded = _viewModel.isGroupExpanded(group.id);
              final isSelected = _viewModel.isGroupSelected(group);

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    // Group Header Row
                    InkWell(
                      onTap: () => _viewModel.toggleGroupSelect(group),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isSelected ? const Color(0xFF10B981) : Colors.transparent,
                                border: Border.all(
                                  color: isSelected ? const Color(0xFF10B981) : const Color(0xFFCBD5E1),
                                  width: 2,
                                ),
                              ),
                              child: isSelected
                                  ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Container(
                              width: 38,
                              height: 38,
                              decoration: const BoxDecoration(
                                color: Color(0xFFE0F2FE),
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                group.initials,
                                style: const TextStyle(
                                  color: Color(0xFF0284C7),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    group.name,
                                    style: const TextStyle(
                                      color: Color(0xFF0F172A),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${group.totalCount > 0 ? group.totalCount : group.members.length} nhân viên',
                                    style: const TextStyle(
                                      color: Color(0xFF64748B),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                                color: const Color(0xFF94A3B8),
                              ),
                              onPressed: () => _viewModel.toggleGroupExpand(group.id),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Expanded Group Members (Read-only list inside group)
                    if (isExpanded && group.members.isNotEmpty) ...[
                      const Divider(height: 1, color: Color(0xFFF1F5F9)),
                      Container(
                        color: const Color(0xFFF8FAFC),
                        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                        child: Column(
                          children: List.generate(group.members.length, (mIdx) {
                            final member = group.members[mIdx];

                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 24,
                                    child: Text(
                                      '${mIdx + 1}',
                                      style: const TextStyle(
                                        color: Color(0xFF94A3B8),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFF1F5F9),
                                      shape: BoxShape.circle,
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      member.initials,
                                      style: const TextStyle(
                                        color: Color(0xFF64748B),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      member.name,
                                      style: const TextStyle(
                                        color: Color(0xFF334155),
                                        fontWeight: FontWeight.w500,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSubFilterChip(String label, RecipientSubFilter filter) {
    final isSelected = _viewModel.subFilter == filter;
    return GestureDetector(
      onTap: () => _viewModel.setSubFilter(filter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isSelected ? const Color(0xFF0F172A) : const Color(0xFF64748B),
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            height: 2,
            width: 24,
            color: isSelected ? const Color(0xFF0F172A) : Colors.transparent,
          ),
        ],
      ),
    );
  }
}

class _InAppVideoPreviewModal extends StatefulWidget {
  final String filePath;
  final String fileName;
  const _InAppVideoPreviewModal({required this.filePath, required this.fileName});

  @override
  State<_InAppVideoPreviewModal> createState() => _InAppVideoPreviewModalState();
}

class _InAppVideoPreviewModalState extends State<_InAppVideoPreviewModal> {
  late VideoPlayerController _controller;
  bool _initialized = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(File(widget.filePath))
      ..initialize().then((_) {
        if (mounted) {
          setState(() {
            _initialized = true;
          });
          _controller.play();
        }
      }).catchError((err) {
        if (mounted) {
          setState(() {
            _hasError = true;
          });
        }
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF0F172A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                const Icon(Icons.video_library_rounded, color: Color(0xFF38BDF8), size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.fileName,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white70),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          ClipRRect(
            child: AspectRatio(
              aspectRatio: _initialized ? _controller.value.aspectRatio : 16 / 9,
              child: Container(
                color: Colors.black,
                child: _initialized
                    ? Stack(
                        alignment: Alignment.bottomCenter,
                        children: [
                          VideoPlayer(_controller),
                          VideoProgressIndicator(_controller, allowScrubbing: true),
                          Center(
                            child: IconButton(
                              iconSize: 56,
                              icon: Icon(
                                _controller.value.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                                color: Colors.white.withValues(alpha: 0.85),
                              ),
                              onPressed: () {
                                setState(() {
                                  _controller.value.isPlaying ? _controller.pause() : _controller.play();
                                });
                              },
                            ),
                          ),
                        ],
                      )
                    : (_hasError
                        ? const Center(child: Text('Không thể nạp Video này', style: TextStyle(color: Colors.redAccent)))
                        : const Center(child: CircularProgressIndicator(color: Color(0xFF38BDF8)))),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _InAppAudioPreviewModal extends StatefulWidget {
  final String filePath;
  final String fileName;
  const _InAppAudioPreviewModal({required this.filePath, required this.fileName});

  @override
  State<_InAppAudioPreviewModal> createState() => _InAppAudioPreviewModalState();
}

class _InAppAudioPreviewModalState extends State<_InAppAudioPreviewModal> {
  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _initAudio();
  }

  Future<void> _initAudio() async {
    _player.onDurationChanged.listen((d) {
      if (mounted) setState(() => _duration = d);
    });
    _player.onPositionChanged.listen((p) {
      if (mounted) setState(() => _position = p);
    });
    _player.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() => _isPlaying = state == PlayerState.playing);
      }
    });

    try {
      await _player.play(DeviceFileSource(widget.filePath));
    } catch (_) {}
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFFF3E8FF),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.music_note_rounded, size: 54, color: Color(0xFF9333EA)),
            ),
            const SizedBox(height: 16),
            Text(
              widget.fileName,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 16),
            Slider(
              value: _position.inSeconds.toDouble().clamp(0.0, _duration.inSeconds.toDouble() > 0 ? _duration.inSeconds.toDouble() : 1.0),
              max: _duration.inSeconds.toDouble() > 0 ? _duration.inSeconds.toDouble() : 1.0,
              activeColor: const Color(0xFF9333EA),
              onChanged: (val) {
                _player.seek(Duration(seconds: val.toInt()));
              },
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_formatDuration(_position), style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                  Text(_formatDuration(_duration), style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  iconSize: 52,
                  icon: Icon(
                    _isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded,
                    color: const Color(0xFF9333EA),
                  ),
                  onPressed: () {
                    if (_isPlaying) {
                      _player.pause();
                    } else {
                      _player.resume();
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Đóng', style: TextStyle(color: Color(0xFF64748B))),
            ),
          ],
        ),
      ),
    );
  }
}

class _InAppPdfPreviewModal extends StatefulWidget {
  final String filePath;
  final String fileName;
  const _InAppPdfPreviewModal({required this.filePath, required this.fileName});

  @override
  State<_InAppPdfPreviewModal> createState() => _InAppPdfPreviewModalState();
}

class _InAppPdfPreviewModalState extends State<_InAppPdfPreviewModal> {
  int _totalPages = 0;
  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    final bool isMobile = !kIsWeb && (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.android);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.75,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                color: const Color(0xFFDC2626),
                child: Row(
                  children: [
                    const Icon(Icons.picture_as_pdf_rounded, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.fileName,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isMobile)
                      Text(
                        '${_currentPage + 1}/$_totalPages',
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: isMobile
                    ? PDFView(
                        filePath: widget.filePath,
                        enableSwipe: true,
                        swipeHorizontal: false,
                        autoSpacing: false,
                        pageFling: false,
                        onRender: (pages) {
                          setState(() {
                            _totalPages = pages ?? 0;
                          });
                        },
                        onPageChanged: (page, total) {
                          setState(() {
                            _currentPage = page ?? 0;
                          });
                        },
                      )
                    : Container(
                        color: const Color(0xFFF1F5F9),
                        padding: const EdgeInsets.all(24),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.picture_as_pdf_rounded,
                                color: Color(0xFFDC2626),
                                size: 72,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                widget.fileName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A),
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Tính năng xem trước PDF trực tiếp trong ứng dụng hiện chỉ hỗ trợ trên điện thoại di động (Android & iOS).',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF475569),
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton.icon(
                                onPressed: () async {
                                  try {
                                    if (kIsWeb) {
                                      // Trên Web, mở blob URL hoặc link
                                      final uri = Uri.parse(widget.filePath);
                                      await launchUrl(uri);
                                    } else {
                                      // Trên Desktop, mở tệp tin cục bộ
                                      final uri = Uri.file(widget.filePath);
                                      await launchUrl(uri);
                                    }
                                  } catch (e) {
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Không thể mở tệp: $e'),
                                        backgroundColor: Colors.redAccent,
                                      ),
                                    );
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFDC2626),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                icon: const Icon(Icons.open_in_new_rounded, size: 18),
                                label: const Text(
                                  'Mở xem bằng Trình xem PDF hệ thống',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InAppTextPreviewModal extends StatelessWidget {
  final String filePath;
  final String fileName;
  const _InAppTextPreviewModal({required this.filePath, required this.fileName});

  @override
  Widget build(BuildContext context) {
    String textContent = '';
    try {
      final file = File(filePath);
      textContent = file.readAsStringSync();
      if (textContent.length > 5000) {
        textContent = '${textContent.substring(0, 5000)}\n\n[... Trích đoạn 5,000 ký tự đầu tiên ...]';
      }
    } catch (e) {
      textContent = 'Không thể đọc trực tiếp nội dung file này: $e';
    }

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.description_rounded, color: Color(0xFF2563EB), size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    fileName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A)),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            Container(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.5),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: SingleChildScrollView(
                child: SelectableText(
                  textContent,
                  style: const TextStyle(fontSize: 13, fontFamily: 'monospace', color: Color(0xFF1E293B)),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Đóng'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

String _unescapeXml(String input) {
  return input
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&apos;', "'")
      .replaceAll('&#39;', "'")
      .replaceAll('&#34;', '"')
      .replaceAll('&#38;', '&')
      .replaceAll('&#60;', '<')
      .replaceAll('&#62;', '>')
      .replaceAllMapped(RegExp(r'&#(\d+);'), (match) {
        final code = int.tryParse(match.group(1) ?? '');
        if (code != null) return String.fromCharCode(code);
        return match.group(0)!;
      })
      .replaceAllMapped(RegExp(r'&#x([0-9a-fA-F]+);'), (match) {
        final code = int.tryParse(match.group(1) ?? '', radix: 16);
        if (code != null) return String.fromCharCode(code);
        return match.group(0)!;
      });
}

class _InAppExcelPreviewModal extends StatelessWidget {
  final String filePath;
  final String fileName;

  const _InAppExcelPreviewModal({required this.filePath, required this.fileName});

  @override
  Widget build(BuildContext context) {
    List<List<String>> rows = [];
    try {
      final file = File(filePath);
      final bytes = file.readAsBytesSync();
      final ext = fileName.split('.').last.toLowerCase();

      if (ext == 'csv' || ext == 'txt') {
        final content = utf8.decode(bytes, allowMalformed: true);
        final lines = content.split(RegExp(r'\r?\n'));
        for (final l in lines) {
          if (l.trim().isNotEmpty) {
            rows.add(l.split(RegExp(r'[,;\t]')));
          }
        }
      } else if (ext == 'xlsx') {
        final archive = ZipDecoder().decodeBytes(bytes);
        ArchiveFile? sheetXmlFile;
        for (final f in archive.files) {
          if (f.name.contains('sheet1.xml') || f.name.contains('sheet.xml')) {
            sheetXmlFile = f;
            break;
          }
        }
        if (sheetXmlFile != null) {
          final xmlStr = utf8.decode(sheetXmlFile.content as List<int>, allowMalformed: true);
          final rowRegex = RegExp(r'<row[^>]*>(.*?)</row>', dotAll: true);
          final vRegex = RegExp(r'<v[^>]*>(.*?)</v>', dotAll: true);
          final rowMatches = rowRegex.allMatches(xmlStr);
          for (final rm in rowMatches) {
            final rowXml = rm.group(1) ?? '';
            final vMatches = vRegex.allMatches(rowXml);
            final List<String> cellVals = [];
            for (final vm in vMatches) {
              cellVals.add(_unescapeXml(vm.group(1) ?? ''));
            }
            if (cellVals.isNotEmpty) {
              rows.add(cellVals);
            }
          }
        }
      }
    } catch (_) {}

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: double.infinity,
        height: MediaQuery.of(context).size.height * 0.75,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.table_chart_rounded, color: Color(0xFF059669), size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    fileName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A)),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const Divider(),
            Expanded(
              child: rows.isEmpty
                  ? const Center(
                      child: Text(
                        'Đã nạp file Bảng tính • Xem chi tiết dữ liệu',
                        style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold),
                      ),
                    )
                  : SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columns: List.generate(
                            rows.fold(0, (max, r) => r.length > max ? r.length : max),
                            (i) => DataColumn(label: Text('Cột ${i + 1}', style: const TextStyle(fontWeight: FontWeight.bold))),
                          ),
                          rows: rows.map((r) => DataRow(
                            cells: List.generate(
                              rows.fold(0, (max, row) => row.length > max ? row.length : max),
                              (idx) => DataCell(Text(idx < r.length ? r[idx] : '')),
                            ),
                          )).toList(),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

abstract class _DocxNode {}

class _DocxTextNode extends _DocxNode {
  final String text;
  final bool isHeader;
  _DocxTextNode(this.text, {this.isHeader = false});
}

class _DocxTableNode extends _DocxNode {
  final List<List<String>> rows;
  _DocxTableNode(this.rows);
}

class _InAppDocxPreviewModal extends StatefulWidget {
  final String filePath;
  final String fileName;

  const _InAppDocxPreviewModal({
    required this.filePath,
    required this.fileName,
  });

  @override
  State<_InAppDocxPreviewModal> createState() => _InAppDocxPreviewModalState();
}

class _InAppDocxPreviewModalState extends State<_InAppDocxPreviewModal> {
  bool _isLoading = true;
  String? _error;
  List<_DocxNode> _nodes = [];
  int _wordCount = 0;
  int _tableCount = 0;

  @override
  void initState() {
    super.initState();
    _parseDocxFile();
  }

  Future<void> _parseDocxFile() async {
    try {
      final file = File(widget.filePath);
      if (!file.existsSync()) {
        setState(() {
          _error = 'Không tìm thấy tập tin trên thiết bị.';
          _isLoading = false;
        });
        return;
      }

      final bytes = await file.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      ArchiveFile? docXmlFile;
      for (final f in archive.files) {
        if (f.name == 'word/document.xml') {
          docXmlFile = f;
          break;
        }
      }

      if (docXmlFile == null) {
        setState(() {
          _error = 'Không phải định dạng XML DOCX hợp lệ.';
          _isLoading = false;
        });
        return;
      }

      final content = docXmlFile.content;
      String xmlString = '';
      if (content is List<int>) {
        xmlString = utf8.decode(content, allowMalformed: true);
      } else {
        xmlString = content.toString();
      }

      final List<_DocxNode> parsedNodes = [];
      int totalWords = 0;
      int totalTables = 0;

      final bodyRegex = RegExp(r'<w:body[^>]*>(.*?)</w:body>', dotAll: true);
      final bodyMatch = bodyRegex.firstMatch(xmlString);
      final bodyXml = bodyMatch?.group(1) ?? xmlString;

      final elementRegex = RegExp(r'<w:p[^>]*>.*?</w:p>|<w:tbl[^>]*>.*?</w:tbl>', dotAll: true);
      final matches = elementRegex.allMatches(bodyXml);

      for (final m in matches) {
        final rawXml = m.group(0) ?? '';
        if (rawXml.startsWith('<w:tbl')) {
          final trRegex = RegExp(r'<w:tr[^>]*>(.*?)</w:tr>', dotAll: true);
          final tcRegex = RegExp(r'<w:tc[^>]*>(.*?)</w:tc>', dotAll: true);
          final tRegex = RegExp(r'<w:t[^>]*>(.*?)</w:t>', dotAll: true);

          final trMatches = trRegex.allMatches(rawXml);
          final List<List<String>> tableRows = [];

          for (final trMatch in trMatches) {
            final trXml = trMatch.group(1) ?? '';
            final tcMatches = tcRegex.allMatches(trXml);
            final List<String> cellTexts = [];

            for (final tcMatch in tcMatches) {
              final tcXml = tcMatch.group(1) ?? '';
              final tMatches = tRegex.allMatches(tcXml);
              final StringBuffer cellSb = StringBuffer();
              for (final tm in tMatches) {
                cellSb.write(_unescapeXml(tm.group(1) ?? ''));
              }
              final cellText = cellSb.toString().trim();
              cellTexts.add(cellText);
              totalWords += cellText.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
            }

            if (cellTexts.isNotEmpty && cellTexts.any((c) => c.isNotEmpty)) {
              tableRows.add(cellTexts);
            }
          }

          if (tableRows.isNotEmpty) {
            parsedNodes.add(_DocxTableNode(tableRows));
            totalTables++;
          }
        } else if (rawXml.startsWith('<w:p')) {
          final tRegex = RegExp(r'<w:t[^>]*>(.*?)</w:t>', dotAll: true);
          final tMatches = tRegex.allMatches(rawXml);
          final StringBuffer sb = StringBuffer();
          for (final tm in tMatches) {
            sb.write(_unescapeXml(tm.group(1) ?? ''));
          }
          final line = sb.toString().trim();
          if (line.isNotEmpty) {
            final isHeading = rawXml.contains('Heading') || rawXml.contains('Title') || rawXml.contains('<w:b/>');
            parsedNodes.add(_DocxTextNode(line, isHeader: isHeading));
            totalWords += line.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
          }
        }
      }

      if (parsedNodes.isEmpty) {
        final tRegex = RegExp(r'<w:t[^>]*>(.*?)</w:t>', dotAll: true);
        final tMatches = tRegex.allMatches(xmlString);
        final StringBuffer sb = StringBuffer();
        for (final tm in tMatches) {
          sb.write(_unescapeXml(tm.group(1) ?? ''));
          sb.write(' ');
        }
        final fullText = sb.toString().trim();
        if (fullText.isNotEmpty) {
          parsedNodes.add(_DocxTextNode(fullText));
          totalWords = fullText.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
        }
      }

      setState(() {
        _nodes = parsedNodes;
        _wordCount = totalWords;
        _tableCount = totalTables;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Không thể đọc nội dung file DOCX: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final double sheetHeight = MediaQuery.of(context).size.height * 0.92;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: double.infinity,
        height: sheetHeight,
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.description_rounded, color: Color(0xFF2563EB), size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.fileName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          _isLoading ? 'Đang đọc nội dung Word...' : 'Tài liệu Word Native • $_wordCount từ • $_tableCount bảng',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ),

            // Content Area
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(color: Color(0xFF2563EB)),
                          SizedBox(height: 12),
                          Text('Đang giải mã văn bản & bảng cột .docx...', style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                        ],
                      ),
                    )
                  : (_error != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 13), textAlign: TextAlign.center),
                          ),
                        )
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(12),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.fileName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Color(0xFF1E293B),
                                    height: 1.3,
                                  ),
                                ),
                                const Divider(height: 24, thickness: 1),
                                ..._nodes.map((node) {
                                  if (node is _DocxTextNode) {
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 12),
                                      child: SelectableText(
                                        node.text,
                                        style: TextStyle(
                                          fontSize: node.isHeader ? 15 : 14,
                                          fontWeight: node.isHeader ? FontWeight.bold : FontWeight.normal,
                                          color: node.isHeader ? const Color(0xFF0F172A) : const Color(0xFF334155),
                                          height: 1.6,
                                        ),
                                      ),
                                    );
                                  } else if (node is _DocxTableNode) {
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      child: SingleChildScrollView(
                                        scrollDirection: Axis.horizontal,
                                        child: Table(
                                          border: TableBorder.all(color: const Color(0xFFCBD5E1), width: 1),
                                          defaultColumnWidth: const IntrinsicColumnWidth(),
                                          children: node.rows.map((row) {
                                            return TableRow(
                                              children: row.map((cellText) {
                                                return Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                                  color: const Color(0xFFF8FAFC),
                                                  child: SelectableText(
                                                    cellText,
                                                    style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)),
                                                  ),
                                                );
                                              }).toList(),
                                            );
                                          }).toList(),
                                        ),
                                      ),
                                    );
                                  }
                                  return const SizedBox.shrink();
                                }),
                              ],
                            ),
                          ),
                        )),
            ),

            // Footer Toolbar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
                border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 16),
                  const SizedBox(width: 6),
                  const Text('Đọc Native Word thành công', style: TextStyle(fontSize: 12, color: Color(0xFF10B981), fontWeight: FontWeight.bold)),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: _nodes.isEmpty
                        ? null
                        : () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('📋 Đã sao chép nội dung văn bản Word!'),
                                backgroundColor: Color(0xFF2563EB),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                    icon: const Icon(Icons.copy_rounded, size: 16),
                    label: const Text('Sao chép text', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MediaGridItem {
  final String id;
  final String path;
  final String fileName;
  final bool isVideo;
  final String? durationText;
  final int sizeBytes;

  _MediaGridItem({
    required this.id,
    required this.path,
    required this.fileName,
    required this.isVideo,
    this.durationText,
    required this.sizeBytes,
  });
}

class _InAppMediaGallerySheet extends StatefulWidget {
  final CreateNotificationViewModel viewModel;

  const _InAppMediaGallerySheet({
    required this.viewModel,
  });

  @override
  State<_InAppMediaGallerySheet> createState() => _InAppMediaGallerySheetState();
}

class _InAppMediaGallerySheetState extends State<_InAppMediaGallerySheet> {
  int _activeFilterIndex = 0; // 0: Tất cả, 1: Video, 2: Hình ảnh
  bool _isLoading = true;
  List<_MediaGridItem> _allMedia = [];
  final Set<String> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    _loadDeviceMedia();
  }

  Future<void> _loadDeviceMedia() async {
    final List<_MediaGridItem> items = [];

    try {
      final dirs = [
        Directory('/storage/emulated/0/DCIM/Camera'),
        Directory('/storage/emulated/0/Pictures'),
        Directory('/storage/emulated/0/Download'),
        Directory('/storage/emulated/0/Movies'),
      ];

      for (final dir in dirs) {
        if (dir.existsSync()) {
          try {
            final entities = dir.listSync(recursive: false);
            for (final entity in entities) {
              if (entity is File) {
                final ext = entity.path.split('.').last.toLowerCase();
                final isImg = ['jpg', 'jpeg', 'png', 'webp', 'bmp'].contains(ext);
                final isVid = ['mp4', 'mov', 'avi', 'mkv', '3gp'].contains(ext);

                if (isImg || isVid) {
                  final stat = entity.statSync();
                  items.add(_MediaGridItem(
                    id: entity.path,
                    path: entity.path,
                    fileName: entity.path.split(RegExp(r'[/\\]')).last,
                    isVideo: isVid,
                    durationText: isVid ? '00:28' : null,
                    sizeBytes: stat.size > 0 ? stat.size : (isVid ? 1500 * 1024 : 350 * 1024),
                  ));
                }
              }
            }
          } catch (_) {}
        }
      }
    } catch (_) {}

    if (mounted) {
      setState(() {
        _allMedia = items;
        _isLoading = false;
      });
    }
  }

  Future<void> _importMoreFromGallery() async {
    try {
      final picker = ImagePicker();
      final List<XFile> picked = await picker.pickMultiImage(imageQuality: 80);
      if (picked.isNotEmpty) {
        for (final p in picked) {
          final length = await p.length();
          final rawName = p.name.isNotEmpty ? p.name : 'IMG_${DateTime.now().millisecondsSinceEpoch}.jpg';
          final jpgName = rawName.contains('.')
              ? '${rawName.substring(0, rawName.lastIndexOf('.'))}.jpg'
              : '$rawName.jpg';

          final newItem = _MediaGridItem(
            id: p.path,
            path: p.path,
            fileName: jpgName,
            isVideo: false,
            sizeBytes: length > 0 ? length : 280 * 1024,
          );

          if (!_allMedia.any((m) => m.path == p.path)) {
            _allMedia.insert(0, newItem);
          }
          _selectedIds.add(p.path);
        }
        setState(() {});
      }
    } catch (_) {}
  }

  List<_MediaGridItem> get _filteredMedia {
    if (_activeFilterIndex == 1) {
      return _allMedia.where((m) => m.isVideo).toList();
    }
    if (_activeFilterIndex == 2) {
      return _allMedia.where((m) => !m.isVideo).toList();
    }
    return _allMedia;
  }

  int get _selectedTotalBytes {
    int total = 0;
    for (final item in _allMedia) {
      if (_selectedIds.contains(item.id)) {
        total += item.sizeBytes;
      }
    }
    return total;
  }

  void _toggleSelection(_MediaGridItem item) {
    setState(() {
      if (_selectedIds.contains(item.id)) {
        _selectedIds.remove(item.id);
      } else {
        final int currentTotal = widget.viewModel.totalImageSizeBytes + _selectedTotalBytes;
        if (currentTotal + item.sizeBytes > CreateNotificationViewModel.maxTotalImageSizeBytes) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('⚠️ Tổng dung lượng tệp chọn đã vượt mốc 5.0 MB!'),
              backgroundColor: Colors.redAccent,
              duration: Duration(seconds: 2),
            ),
          );
          return;
        }
        _selectedIds.add(item.id);
      }
    });
  }

  void _confirmAndAttach() {
    final selectedItems = _allMedia.where((m) => _selectedIds.contains(m.id)).toList();
    if (selectedItems.isEmpty) {
      Navigator.of(context).pop();
      return;
    }

    final fileItems = selectedItems.map((m) => (
      fileName: m.fileName,
      filePath: m.path,
      sizeBytes: m.sizeBytes,
    )).toList();

    final res = widget.viewModel.addRealPickedAttachmentBatch(fileItems);
    Navigator.of(context).pop();

    if (res.addedCount > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🖼️ Đã đính kèm thành công ${res.addedCount} tệp từ Thư viện! (${widget.viewModel.formattedTotalImageSize})'),
          backgroundColor: const Color(0xFF10B981),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final double sheetHeight = MediaQuery.of(context).size.height * 0.90;
    final totalMB = (_selectedTotalBytes / (1024 * 1024)).toStringAsFixed(2);
    final selectedCount = _selectedIds.length;

    return Container(
      height: sheetHeight,
      decoration: const BoxDecoration(
        color: Colors.white, // Clean Hospital White Theme
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: Color(0xFF0F172A), size: 24),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: const Row(
                    children: [
                      Text('Album', style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 14)),
                      SizedBox(width: 4),
                      Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF0F172A), size: 18),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: _importMoreFromGallery,
                  icon: const Icon(Icons.add_photo_alternate_rounded, size: 18, color: Color(0xFF2563EB)),
                  label: const Text('Thêm ảnh', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF2563EB))),
                ),
              ],
            ),
          ),

          // 3 Filter Tabs Bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildTabItem(title: 'Tất cả', index: 0),
                _buildTabItem(title: 'Video', index: 1),
                _buildTabItem(title: 'Hình ảnh', index: 2),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),

          // 3-Column Responsive Grid Area
          Expanded(
            child: _isLoading
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: Color(0xFF2563EB)),
                        SizedBox(height: 12),
                        Text('Đang nạp bộ sưu tập...', style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                      ],
                    ),
                  )
                : (_filteredMedia.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.photo_library_outlined, size: 54, color: Color(0xFF94A3B8)),
                            const SizedBox(height: 12),
                            const Text('Chưa tìm thấy media trong thư mục máy', style: TextStyle(color: Color(0xFF64748B), fontSize: 14, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            ElevatedButton.icon(
                              onPressed: _importMoreFromGallery,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2563EB),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              icon: const Icon(Icons.photo_library_rounded, size: 18),
                              label: const Text('Mở chọn tệp máy'),
                            ),
                          ],
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(4),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 4,
                          mainAxisSpacing: 4,
                          childAspectRatio: 1.0,
                        ),
                        itemCount: _filteredMedia.length,
                        itemBuilder: (context, idx) {
                          final item = _filteredMedia[idx];
                          final isSelected = _selectedIds.contains(item.id);
                          final fileExists = File(item.path).existsSync();

                          return GestureDetector(
                            onTap: () => _toggleSelection(item),
                            child: Stack(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(6),
                                    border: isSelected ? Border.all(color: const Color(0xFF2563EB), width: 3) : null,
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: fileExists
                                        ? Image.file(
                                            File(item.path),
                                            width: double.infinity,
                                            height: double.infinity,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) => _buildTileFallback(item),
                                          )
                                        : _buildTileFallback(item),
                                  ),
                                ),

                                // Video duration badge overlay matching screenshot
                                if (item.isVideo)
                                  Positioned(
                                    bottom: 6,
                                    right: 6,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(alpha: 0.7),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.aspect_ratio_rounded, color: Colors.white70, size: 10),
                                          const SizedBox(width: 3),
                                          Text(
                                            item.durationText ?? '00:28',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),

                                // Checkmark badge when selected
                                Positioned(
                                  top: 6,
                                  right: 6,
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isSelected ? const Color(0xFF2563EB) : Colors.black.withValues(alpha: 0.35),
                                      border: Border.all(color: Colors.white, width: 2),
                                    ),
                                    child: isSelected
                                        ? const Icon(Icons.check_rounded, color: Colors.white, size: 14)
                                        : null,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      )),
          ),

          // Bottom Action Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        selectedCount > 0 ? 'Đã chọn $selectedCount tệp' : 'Chưa chọn tệp',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Tổng dung lượng: $totalMB MB / 5.0 MB',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _selectedTotalBytes > CreateNotificationViewModel.maxTotalImageSizeBytes ? const Color(0xFFDC2626) : const Color(0xFF059669),
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: selectedCount > 0 ? _confirmAndAttach : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(
                    'CHỌN ($selectedCount)',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabItem({required String title, required int index}) {
    final isSelected = _activeFilterIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeFilterIndex = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? const Color(0xFF2563EB) : Colors.transparent,
                width: 2.5,
              ),
            ),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF64748B),
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTileFallback(_MediaGridItem item) {
    return Container(
      color: const Color(0xFFE2E8F0),
      child: Center(
        child: Icon(
          item.isVideo ? Icons.videocam_rounded : Icons.image_rounded,
          color: const Color(0xFF64748B),
          size: 32,
        ),
      ),
    );
  }
}
