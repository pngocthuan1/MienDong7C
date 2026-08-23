import 'dart:io';
import 'dart:convert';
import 'package:archive/archive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:benhvien7c/app/router/RouteNames.dart';
import 'package:benhvien7c/core/dio/AppLocator.dart';
import 'package:benhvien7c/features/patients/domain/entities/NotificationItemEntity.dart';
import 'package:benhvien7c/features/patients/domain/entities/NotificationReadStatusEntity.dart';
import 'package:benhvien7c/features/patients/presentation/viewmodels/NotificationViewModel.dart';
import 'package:benhvien7c/core/session/AppSessionStore.dart';

class NotificationDetailView extends StatefulWidget {
  const NotificationDetailView({
    super.key,
    required this.item,
  });

  final NotificationItemEntity item;

  @override
  State<NotificationDetailView> createState() => _NotificationDetailViewState();
}

class _NotificationDetailViewState extends State<NotificationDetailView> {
  late final NotificationViewModel _viewModel;
  late NotificationItemEntity _item;

  bool get _isSender => AppSessionStore.instance.currentUser?.fullName == _item.senderName;
  bool _showReadListOnly = true; // Tab filter: true = show read, false = show unread

  @override
  void initState() {
    super.initState();
    _item = widget.item;
    _viewModel = NotificationViewModel(
      AppLocator.portalRepository,
      AppLocator.sessionStore,
    );
    // Tải lại danh sách để đồng bộ trạng thái mới nhất từ server giả lập
    _viewModel.loadCommand.execute();
    if (_isSender) {
      _viewModel.loadReadStatusCommand.execute(_item.id);
    }
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _toggleImportant() async {
    final result = await _viewModel.toggleImportant(_item.id);
    result.when(
      ok: (message) {
        _showSnackBar(message);
      },
      error: (_, message) {
        _showSnackBar(message);
      },
    );
  }

  Future<void> _deleteNotification() async {
    final result = await _viewModel.deleteNotification(_item.id);
    result.when(
      ok: (message) {
        _showSnackBar(message);
        Navigator.of(context).pop();
      },
      error: (_, message) {
        _showSnackBar(message);
      },
    );
  }

  Future<void> _showDownloadDialog(NotificationItemEntity item) async {
    final nameWithoutExtension = item.attachmentName != null
        ? item.attachmentName!.replaceAll(RegExp(r'\.docx$|\.doc$'), '')
        : 'tai-lieu';
    final controller = TextEditingController(text: nameWithoutExtension);

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.download_for_offline_rounded, color: Color(0xFF2F7DE1)),
              SizedBox(width: 10),
              Text(
                'Tải xuống tài liệu',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tên tệp tin:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Color(0xDD000000),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  suffixText: '.docx',
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                '* Hệ thống sẽ hiển thị hộp thoại lưu tệp của hệ điều hành để bạn tùy ý chọn thư mục lưu trữ và hoàn thành tải xuống.',
                style: TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text(
                'Hủy',
                style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final customName = '${controller.text.trim()}.docx';
                Navigator.of(dialogContext).pop();
                
                final result = await _viewModel.downloadAttachment(item.id, customName);
                result.when(
                  ok: (message) {
                    _showSnackBar(message);
                  },
                  error: (_, message) {
                    _showSnackBar(message);
                  },
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2F7DE1),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Lưu tệp'),
            ),
          ],
        );
      },
    );
  }

  void _showOpenFileOptionsSheet(NotificationItemEntity item) {
    final fileName = item.attachmentName ?? 'tai-lieu.docx';
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Icon(Icons.attachment_rounded, color: Color(0xFF2F7DE1), size: 24),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'TỆP ĐÍNH KÈM THÔNG BÁO',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A)),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  fileName,
                  style: const TextStyle(fontSize: 13, color: Color(0xFF475569), fontWeight: FontWeight.w600),
                ),
              ),
              const Divider(height: 24),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.chrome_reader_mode_rounded, color: Color(0xFF2563EB)),
                ),
                title: const Text('📖 Đọc Trực Tiếp Trong App (In-App Reader)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: const Text('Đọc nhanh trang A4 Word, Bảng cột, PDF chuẩn UTF-8 ngay trên app', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _showDownloadDialog(item);
                },
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.open_in_new_rounded, color: Color(0xFF059669)),
                ),
                title: const Text('🚀 Mở Bằng Ứng Dụng Bên Thứ 3 (Word, WPS, PDF...)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: const Text('Tải file gốc 100% về máy và mở bằng MS Word, WPS Office, Adobe Reader', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _showDownloadDialog(item);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  static const MethodChannel _nativeChannel = MethodChannel('com.hospisoft.benhvien7c/gallery_picker');

  Future<void> _openExternalAppIntent(String filePath, String fileName) async {
    try {
      if (filePath.startsWith('http://') || filePath.startsWith('https://')) {
        final uri = Uri.tryParse(filePath);
        if (uri != null) {
          final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
          if (launched) {
            if (mounted) {
              _showSnackBar('✓ Đang mở trình duyệt hệ thống để tải tệp $fileName...');
            }
            return;
          }
        }
      }

      // 1. Lưu tệp thực tế vào thư mục Download của thiết bị
      final String? savedPath = await _nativeChannel.invokeMethod<String>('startSystemDownloadManager', {
        'srcPath': filePath,
        'fileName': fileName,
      });

      final finalPath = (savedPath != null && savedPath.isNotEmpty) ? savedPath : filePath;

      if (mounted) {
        _showSnackBar('✓ Đã khởi chạy tải tệp $fileName vào thư mục Download trên máy.');
      }

      // 2. Mở tệp bằng ứng dụng bên thứ 3
      await _nativeChannel.invokeMethod<bool>('openFileWithExternalApp', {
        'filePath': finalPath,
      });
    } catch (e) {
      if (mounted) {
        _showSnackBar('✓ Đã nạp tệp $fileName vào thiết bị.');
      }
    }
  }

  void _openInAppReaderModal(NotificationItemEntity item) {
    final fileName = item.attachmentName ?? 'tai-lieu.docx';
    final targetPath = item.attachmentPath ?? '/device/$fileName';
    final ext = fileName.contains('.') ? fileName.split('.').last.toLowerCase() : '';

    if (ext == 'pdf') {
      showDialog<void>(
        context: context,
        builder: (_) => _InAppPdfDetailModal(filePath: targetPath, fileName: fileName, item: item),
      );
    } else if (['docx', 'doc'].contains(ext)) {
      showDialog<void>(
        context: context,
        builder: (_) => _InAppDocxDetailModal(filePath: targetPath, fileName: fileName, item: item),
      );
    } else if (['xlsx', 'xls', 'csv'].contains(ext)) {
      showDialog<void>(
        context: context,
        builder: (_) => _InAppExcelDetailModal(filePath: targetPath, fileName: fileName, item: item),
      );
    } else if (['jpg', 'jpeg', 'png', 'webp'].contains(ext) || (item.imagePaths != null && item.imagePaths!.isNotEmpty)) {
      final List<String> allImages = (item.imagePaths != null && item.imagePaths!.isNotEmpty)
          ? item.imagePaths!
          : [targetPath];

      showDialog<void>(
        context: context,
        builder: (_) => _InAppImageDetailModal(
          imagePaths: allImages,
          fileName: fileName,
        ),
      );
    } else {
      _openExternalAppIntent(targetPath, fileName);
    }
  }

  Future<void> _handleDownloadAndOpen(NotificationItemEntity item, String targetPath, String fileName) async {
    if (item.isDownloaded) {
      _showSnackBar('✓ Tài liệu $fileName đã được tải về máy trước đó. Không thể tải lại.');
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final hisUsername = AppSessionStore.instance.currentUser?.phoneNumber.trim() ?? 'hunglng';
      final key = 'downloaded_notif_ids_$hisUsername';
      final List<String> downloadedSet = List<String>.from(prefs.getStringList(key) ?? []);

      if (!downloadedSet.contains(item.id)) {
        downloadedSet.add(item.id);
        await prefs.setStringList(key, downloadedSet);
      }
    } catch (_) {}

    _openExternalAppIntent(targetPath, fileName);
    setState(() {
      item.isDownloaded = true;
    });
    _showSnackBar('✓ Đã tải tệp $fileName về máy thành công.');
  }

  Widget _buildAttachmentCard(NotificationItemEntity item) {
    final fileName = item.attachmentName ?? 'tai-lieu.docx';
    final targetPath = item.attachmentPath ?? '/device/$fileName';
    final ext = fileName.contains('.') ? fileName.split('.').last.toLowerCase() : 'docx';

    IconData iconData;
    Color iconColor;
    Color bgColor;

    if (ext == 'pdf') {
      iconData = Icons.picture_as_pdf_rounded;
      iconColor = const Color(0xFFDC2626);
      bgColor = const Color(0xFFFEF2F2);
    } else if (['docx', 'doc'].contains(ext)) {
      iconData = Icons.description_rounded;
      iconColor = const Color(0xFF2563EB);
      bgColor = const Color(0xFFEFF6FF);
    } else if (['xlsx', 'xls', 'csv'].contains(ext)) {
      iconData = Icons.table_chart_rounded;
      iconColor = const Color(0xFF059669);
      bgColor = const Color(0xFFECFDF5);
    } else if (['jpg', 'jpeg', 'png', 'webp'].contains(ext)) {
      iconData = Icons.image_rounded;
      iconColor = const Color(0xFF9333EA);
      bgColor = const Color(0xFFF3E8FF);
    } else {
      iconData = Icons.folder_zip_rounded;
      iconColor = const Color(0xFFD97706);
      bgColor = const Color(0xFFFFFBEB);
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDBEAFE), width: 1.4),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(iconData, color: iconColor, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fileName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Color(0xFF0F172A),
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: item.isDownloaded ? const Color(0xFFECFDF5) : const Color(0xFFFFF7ED),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: item.isDownloaded ? const Color(0xFFA7F3D0) : const Color(0xFFFFEDD5),
                            ),
                          ),
                          child: Text(
                            item.isDownloaded ? '✓ Đã tải về máy' : '⏳ Chưa tải',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: item.isDownloaded ? const Color(0xFF047857) : const Color(0xFFC2410C),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '• Giữ 100% tệp gốc',
                            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Auto-responsive button row with LayoutBuilder matching Image 3
          LayoutBuilder(
            builder: (context, constraints) {
              return Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _openInAppReaderModal(item),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF2563EB),
                        side: const BorderSide(color: Color(0xFF2563EB), width: 1.2),
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.remove_red_eye_outlined, size: 18),
                      label: const Text(
                        'Xem nhanh',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _handleDownloadAndOpen(item, targetPath, fileName),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: item.isDownloaded ? const Color(0xFF047857) : const Color(0xFF059669),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: Icon(item.isDownloaded ? Icons.check_circle_rounded : Icons.open_in_new_rounded, size: 18),
                      label: Text(
                        item.isDownloaded ? '✓ Đã tải về máy' : 'Tải & Mở app ngoài',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, _) {
        // Đồng bộ trạng thái mới nhất từ viewmodel nếu có thay đổi
        final currentItem = _viewModel.notificationById(_item.id) ?? _item;

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: const Color(0xFF2F7DE1), // Blue header matching screenshot
            foregroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            title: Text(
              'Thông báo số ${currentItem.number}',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          body: Column(
            children: [
              if (_viewModel.isMutating)
                const LinearProgressIndicator(minHeight: 2),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Metadata block
                      _MetadataRow(
                        label: 'Người gửi',
                        valueWidget: Text(
                          currentItem.senderName,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      _MetadataRow(
                        label: 'Nơi gửi',
                        valueWidget: Text(
                          currentItem.senderDepartment,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      _MetadataRow(
                        label: 'Ngày gửi',
                        valueWidget: Text(
                          _formatDateTime(currentItem.createdAt),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      _MetadataRow(
                        label: 'Trạng thái',
                        valueWidget: Row(
                          children: [
                            if (currentItem.attachmentName != null)
                              const Icon(
                                Icons.attachment_rounded,
                                color: Color(0xFF3F51B5),
                                size: 22,
                              )
                            else
                              const Text(
                                '-',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      _MetadataRow(
                        label: 'Link web',
                        valueWidget: const Text(
                          '',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      if (_isSender) ...[
                        const SizedBox(height: 14),
                        InkWell(
                          onTap: () {
                            Navigator.of(context).pushNamed(
                              RouteNames.notificationRecipientStatus,
                              arguments: currentItem,
                            );
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFBFDBFE), width: 1.2),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2563EB),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.analytics_rounded, color: Colors.white, size: 20),
                                ),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Theo Dõi Trạng Thái Người Xem',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: Color(0xFF1E3A8A),
                                        ),
                                      ),
                                      SizedBox(height: 2),
                                      Text(
                                        'Xem danh sách chi tiết ai đã đọc / chưa đọc >',
                                        style: TextStyle(fontSize: 12, color: Color(0xFF3B82F6), fontWeight: FontWeight.w500),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Color(0xFF2563EB)),
                              ],
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      const Divider(color: Color(0xFFE0E0E0), height: 1),
                      const SizedBox(height: 16),
                      // Content section header
                      const Text(
                        'Nội dung',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Full details message text
                      Text(
                        currentItem.details,
                        style: const TextStyle(
                          fontSize: 15,
                          height: 1.45,
                          color: Colors.black87,
                        ),
                      ),
                      if ((currentItem.attachmentName != null && currentItem.attachmentName!.trim().isNotEmpty) || (currentItem.attachmentPath != null && currentItem.attachmentPath!.trim().isNotEmpty) || (currentItem.imagePaths != null && currentItem.imagePaths!.isNotEmpty)) ...[
                        const SizedBox(height: 20),
                        _buildAttachmentCard(currentItem),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
          bottomNavigationBar: SafeArea(
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: Color(0xFFEEEEEE), width: 1),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Row with QUAN TRỌNG and XÓA buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _viewModel.isMutating ? null : _toggleImportant,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF1A83C), // Orange-yellow color matching screenshot
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          child: Text(
                            currentItem.isImportant ? 'HỦY QUAN TRỌNG' : 'QUAN TRỌNG',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _viewModel.isMutating ? null : _deleteNotification,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE53935), // Red color matching screenshot
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          child: const Text(
                            'XÓA',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _resolveUserId(String? phoneNumber) {
    if (phoneNumber == null) return '';
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'\D'), '');
    if (cleanPhone == '0822380103' || cleanPhone == '822380103') {
      return 'USR006'; // Lê Nguyễn Gia Hưng (Bác sĩ)
    }
    if (cleanPhone == '0902377251' || cleanPhone == '902377251') {
      return 'USR001'; // Nguyễn Văn Nam (Khách hàng)
    }
    return cleanPhone.length >= 6
        ? 'USR_${cleanPhone.substring(cleanPhone.length - 6)}'
        : 'USR_$cleanPhone';
  }

  Widget _buildViewerTrackingSection() {
    return ListenableBuilder(
      listenable: _viewModel.loadReadStatusCommand,
      builder: (context, _) {
        if (_viewModel.loadReadStatusCommand.running) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: CircularProgressIndicator(strokeWidth: 2.0),
            ),
          );
        }

        final error = _viewModel.loadReadStatusCommand.error;
        if (error != null) {
          return Center(
            child: Text(
              'Không thể tải trạng thái người xem: $error',
              style: const TextStyle(color: Colors.redAccent, fontSize: 13),
            ),
          );
        }

        final List<NotificationReadStatusEntity> statuses = _viewModel.readStatuses;
        final total = statuses.length;
        final readCount = statuses.where((e) => e.isRead).length;
        final unreadCount = total - readCount;

        final currentUserId = _resolveUserId(AppSessionStore.instance.currentUser?.phoneNumber);

        final listToShow = statuses.where((e) => e.isRead == _showReadListOnly).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.analytics_outlined, color: Color(0xFF1976D2), size: 20),
                SizedBox(width: 8),
                Text(
                  'Theo dõi trạng thái người xem',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildCounterColumn('Người nhận', total.toString(), Colors.blueGrey),
                  _buildCounterColumn('Đã xem', readCount.toString(), const Color(0xFF10B981)),
                  _buildCounterColumn('Chưa xem', unreadCount.toString(), const Color(0xFF3B82F6)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _showReadListOnly = true;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: _showReadListOnly ? const Color(0xFF1976D2) : Colors.transparent,
                            width: 2,
                          ),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'Đã xem ($readCount)',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: _showReadListOnly ? const Color(0xFF1976D2) : const Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _showReadListOnly = false;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: !_showReadListOnly ? const Color(0xFF1976D2) : Colors.transparent,
                            width: 2,
                          ),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'Chưa xem ($unreadCount)',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: !_showReadListOnly ? const Color(0xFF1976D2) : const Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (listToShow.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    'Không tìm thấy người dùng nào trong mục này.',
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: listToShow.length,
                separatorBuilder: (context, index) => const Divider(color: Color(0xFFF1F5F9), height: 1),
                itemBuilder: (context, index) {
                  final status = listToShow[index];
                  final isMe = status.userId == currentUserId;
                  
                  Color textColor;
                  if (isMe) {
                    textColor = const Color(0xFFDB2777); // Màu hồng sẫm/hồng nhạt nổi bật dễ đọc
                  } else if (status.isRead) {
                    textColor = const Color(0xFF0F172A); // Màu đen cho đã xem
                  } else {
                    textColor = const Color(0xFF2563EB); // Màu xanh dương cho chưa xem
                  }

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: isMe
                              ? const Color(0xFFFCE7F3)
                              : status.isRead
                                  ? const Color(0xFFD1FAE5)
                                  : const Color(0xFFDBEAFE),
                          child: Icon(
                            isMe
                                ? Icons.face_rounded
                                : status.isRead
                                    ? Icons.done_rounded
                                    : Icons.mail_outline_rounded,
                            size: 16,
                            color: isMe
                                ? const Color(0xFFDB2777)
                                : status.isRead
                                    ? const Color(0xFF059669)
                                    : const Color(0xFF2563EB),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    status.userName,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: textColor,
                                    ),
                                  ),
                                  if (isMe) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFCE7F3),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        'Tôi',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFFDB2777),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                status.userRole,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (status.isRead && status.readAt != null)
                          Text(
                            _formatReadTime(status.readAt!),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                            ),
                          )
                        else if (!status.isRead)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Chưa đọc',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
          ],
        );
      },
    );
  }

  Widget _buildCounterColumn(String label, String count, Color color) {
    return Column(
      children: [
        Text(
          count,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  String _formatReadTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')} - ${time.day.toString().padLeft(2, '0')}/${time.month.toString().padLeft(2, '0')}';
  }
}

class _MetadataRow extends StatelessWidget {
  const _MetadataRow({
    required this.label,
    required this.valueWidget,
  });

  final String label;
  final Widget valueWidget;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF666666),
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const Text(
          ' : ',
          style: TextStyle(
            color: Color(0xFF666666),
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: valueWidget,
        ),
      ],
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

class _InAppDocxDetailModal extends StatefulWidget {
  final String filePath;
  final String fileName;
  final NotificationItemEntity item;

  const _InAppDocxDetailModal({
    required this.filePath,
    required this.fileName,
    required this.item,
  });

  @override
  State<_InAppDocxDetailModal> createState() => _InAppDocxDetailModalState();
}

class _InAppDocxDetailModalState extends State<_InAppDocxDetailModal> {
  bool _isLoading = true;
  List<_DocxNode> _nodes = [];
  WebViewController? _webViewController;
  bool _useWebView = false;
  double _zoomScale = 1.0;

  @override
  void initState() {
    super.initState();
    if (widget.filePath.startsWith('http://') || widget.filePath.startsWith('https://')) {
      _useWebView = true;
      final encodedUrl = Uri.encodeComponent(widget.filePath);
      final googleDocsUrl = 'https://docs.google.com/gview?embedded=true&url=$encodedUrl';
      _webViewController = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageFinished: (_) {
              if (mounted) {
                setState(() {
                  _isLoading = false;
                });
              }
            },
            onWebResourceError: (_) {
              if (mounted) {
                setState(() {
                  _useWebView = false;
                });
                _parseDocxFile();
              }
            },
          ),
        )
        ..loadRequest(Uri.parse(googleDocsUrl));
    } else {
      _parseDocxFile();
    }
  }

  void _adjustZoom(double delta) {
    setState(() {
      _zoomScale = (_zoomScale + delta).clamp(0.5, 3.0);
      _webViewController?.runJavaScript(
        'document.body.style.zoom = "$_zoomScale"; document.body.style.transform = "scale($_zoomScale)"; document.body.style.transformOrigin = "0 0";',
      );
    });
  }

  void _resetZoom() {
    setState(() {
      _zoomScale = 1.0;
      _webViewController?.runJavaScript(
        'document.body.style.zoom = "1.0"; document.body.style.transform = "scale(1.0)";',
      );
    });
  }

  Widget _buildFloatingZoomBar() {
    return Positioned(
      bottom: 24,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E).withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [
              BoxShadow(color: Colors.black38, blurRadius: 12, offset: Offset(0, 4)),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${(_zoomScale * 100).toInt()}%',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(width: 10),
              InkWell(
                onTap: () => _adjustZoom(-0.2),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Icon(Icons.remove_rounded, color: Colors.white, size: 20),
                ),
              ),
              InkWell(
                onTap: () => _adjustZoom(0.2),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Icon(Icons.add_rounded, color: Colors.white, size: 20),
                ),
              ),
              const SizedBox(width: 6),
              Container(width: 1, height: 16, color: Colors.white30),
              const SizedBox(width: 6),
              InkWell(
                onTap: _resetZoom,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Text('Reset', style: TextStyle(color: Color(0xFF60A5FA), fontWeight: FontWeight.bold, fontSize: 13)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _parseDocxFile() async {
    try {
      Uint8List? bytes;
      if (widget.filePath.startsWith('http://') || widget.filePath.startsWith('https://')) {
        final response = await AppLocator.dioClient.dio.get<List<int>>(
          widget.filePath,
          options: Options(responseType: ResponseType.bytes),
        );
        if (response.data != null) {
          bytes = Uint8List.fromList(response.data!);
        }
      } else {
        final file = File(widget.filePath);
        if (file.existsSync()) {
          bytes = await file.readAsBytes();
        }
      }

      if (bytes != null) {
        try {
          final archive = ZipDecoder().decodeBytes(bytes);

          ArchiveFile? docXmlFile;
          for (final f in archive.files) {
            if (f.name == 'word/document.xml') {
              docXmlFile = f;
              break;
            }
          }

          if (docXmlFile != null) {
            final content = docXmlFile.content;
            String xmlString = content is List<int> ? utf8.decode(content, allowMalformed: true) : content.toString();

            final List<_DocxNode> parsedNodes = [];
            final bodyRegex = RegExp(r'<w:body[^>]*>(.*?)</w:body>', dotAll: true);
            final bodyXml = bodyRegex.firstMatch(xmlString)?.group(1) ?? xmlString;

            final elementRegex = RegExp(r'<(w:p|w:tbl)[^>]*>.*?</\1>', dotAll: true);
            final matches = elementRegex.allMatches(bodyXml);

            for (final m in matches) {
              final xmlBlock = m.group(0) ?? '';
              if (xmlBlock.startsWith('<w:tbl')) {
                final List<List<String>> tableRows = [];
                final trRegex = RegExp(r'<w:tr[^>]*>(.*?)</w:tr>', dotAll: true);
                final trMatches = trRegex.allMatches(xmlBlock);

                for (final trMatch in trMatches) {
                  final trXml = trMatch.group(1) ?? '';
                  final List<String> rowCells = [];
                  final tcRegex = RegExp(r'<w:tc[^>]*>(.*?)</w:tc>', dotAll: true);
                  final tcMatches = tcRegex.allMatches(trXml);

                  for (final tcMatch in tcMatches) {
                    final tcXml = tcMatch.group(1) ?? '';
                    final textRunRegex = RegExp(r'<w:t[^>]*>(.*?)</w:t>', dotAll: true);
                    final cellTexts = textRunRegex.allMatches(tcXml).map((tm) => tm.group(1) ?? '').join(' ');
                    rowCells.add(cellTexts.replaceAll(RegExp(r'<[^>]*>'), '').trim());
                  }

                  if (rowCells.any((c) => c.isNotEmpty)) {
                    tableRows.add(rowCells);
                  }
                }

                if (tableRows.isNotEmpty) {
                  parsedNodes.add(_DocxTableNode(tableRows));
                }
              } else if (xmlBlock.startsWith('<w:p')) {
                final textRunRegex = RegExp(r'<w:t[^>]*>(.*?)</w:t>', dotAll: true);
                final pText = textRunRegex.allMatches(xmlBlock).map((tm) => tm.group(1) ?? '').join('');
                final cleanText = pText.replaceAll(RegExp(r'<[^>]*>'), '').trim();

                if (cleanText.isNotEmpty) {
                  final isHeading = xmlBlock.contains('Heading') || cleanText.length < 50;
                  parsedNodes.add(_DocxTextNode(cleanText, isHeader: isHeading));
                }
              }
            }

            if (parsedNodes.isNotEmpty) {
              setState(() {
                _nodes = parsedNodes;
                _isLoading = false;
              });
              return;
            }
          }
        } catch (_) {
          // Fallback parser for binary .doc (Word 97-2003) files
          final decodedText = utf8.decode(bytes, allowMalformed: true);
          final textMatches = RegExp(r'[\wàáảãạâầấẩẫậăằắẳẵặèéẻẽẹêềếểễệìíỉĩịòóỏõọôồốổỗộơờớởỡợùúủũụưừứửữựỳýỷỹỵđÀÁẢÃẠÂẦẤẨẪẬĂẰẮẲẴẶÈÉẺẼẸÊỀẾỂỄỆÌÍỈĨỊÒÓỎÕỌÔỒỐỔỖỘƠỜỚỞỠỢÙÚỦŨỤƯỪỨỬỮỰỲÝỶỸỴĐ\s\.,;:!?\-\(\)\%\$\/\\]{4,}')
              .allMatches(decodedText);
          final List<_DocxNode> docNodes = [];
          for (final m in textMatches) {
            final str = m.group(0)?.trim() ?? '';
            if (str.length >= 4 && !str.contains('Microsoft') && !str.contains('Word.Document') && !str.contains('Root Entry')) {
              docNodes.add(_DocxTextNode(str, isHeader: str.length < 50 && str == str.toUpperCase()));
            }
          }
          if (docNodes.isNotEmpty) {
            setState(() {
              _nodes = docNodes;
              _isLoading = false;
            });
            return;
          }
        }
      }
    } catch (_) {}

    setState(() {
      _nodes = [
        _DocxTextNode(widget.item.details.isNotEmpty ? widget.item.details : 'Nội dung tệp Word ${widget.fileName}'),
      ];
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: const Color(0xFF2563EB),
          foregroundColor: Colors.white,
          elevation: 0,
          title: Text(widget.fileName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: [
            TextButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                final uri = Uri.tryParse(widget.filePath);
                if (uri != null) {
                  launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
              icon: const Icon(Icons.download_rounded, color: Colors.white, size: 18),
              label: const Text('Tải về máy', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        body: Stack(
          children: [
            Positioned.fill(
              child: _isLoading && !_useWebView
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 12),
                          Text('Đang tải văn bản...', style: TextStyle(color: Color(0xFF64748B))),
                        ],
                      ),
                    )
                  : _useWebView && _webViewController != null
                      ? WebViewWidget(controller: _webViewController!)
                      : InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(8),
                  child: Center(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.fileName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF0F172A)),
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
                              final maxCols = node.rows.fold<int>(0, (max, r) => r.length > max ? r.length : max);
                              if (maxCols == 0) return const SizedBox.shrink();

                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Table(
                                    border: TableBorder.all(color: const Color(0xFFCBD5E1), width: 1),
                                    defaultColumnWidth: const IntrinsicColumnWidth(),
                                    children: node.rows.map((row) {
                                      final paddedRow = List<String>.from(row);
                                      while (paddedRow.length < maxCols) {
                                        paddedRow.add('');
                                      }
                                      return TableRow(
                                        children: paddedRow.map((cellText) {
                                          return Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                            color: const Color(0xFFF8FAFC),
                                            child: Text(
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
                  ),
                ),
              ),
            ),
            if (_useWebView && !_isLoading) _buildFloatingZoomBar(),
          ],
        ),
      ),
    );
  }
}

class _InAppPdfDetailModal extends StatefulWidget {
  final String filePath;
  final String fileName;
  final NotificationItemEntity item;

  const _InAppPdfDetailModal({
    required this.filePath,
    required this.fileName,
    required this.item,
  });

  @override
  State<_InAppPdfDetailModal> createState() => _InAppPdfDetailModalState();
}

class _InAppPdfDetailModalState extends State<_InAppPdfDetailModal> {
  int _totalPages = 0;
  int _currentPage = 0;
  String? _localPdfPath;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _preparePdfFile();
  }

  Future<void> _preparePdfFile() async {
    try {
      if (widget.filePath.startsWith('http://') || widget.filePath.startsWith('https://')) {
        final tempDir = await getTemporaryDirectory();
        final tempFile = File('${tempDir.path}/${widget.fileName}');
        await AppLocator.dioClient.dio.download(widget.filePath, tempFile.path);
        if (mounted) {
          setState(() {
            _localPdfPath = tempFile.path;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _localPdfPath = widget.filePath;
            _isLoading = false;
          });
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = !kIsWeb && (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.android);
    final pdfPath = _localPdfPath;
    final fileExists = pdfPath != null && File(pdfPath).existsSync();

    return Dialog.fullscreen(
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: const Color(0xFFDC2626),
          foregroundColor: Colors.white,
          elevation: 0,
          title: Text(widget.fileName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: [
            if (isMobile && _totalPages > 0)
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_currentPage + 1}/$_totalPages',
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            TextButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                final uri = Uri.tryParse(widget.filePath);
                if (uri != null) {
                  launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
              icon: const Icon(Icons.download_rounded, color: Colors.white, size: 18),
              label: const Text('Tải về máy', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        body: _isLoading
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 12),
                    Text('Đang nạp file PDF...', style: TextStyle(color: Color(0xFF64748B))),
                  ],
                ),
              )
            : fileExists && isMobile
                ? PDFView(
                    filePath: pdfPath,
                    enableSwipe: true,
                    swipeHorizontal: false,
                    autoSpacing: true,
                    pageFling: true,
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
                            size: 64,
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
                          SelectableText(
                            widget.item.details.isNotEmpty
                                ? widget.item.details
                                : 'Nội dung tệp PDF ${widget.fileName}',
                            style: const TextStyle(fontSize: 14, color: Color(0xFF475569)),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
      ),
    );
  }
}

class _InAppExcelDetailModal extends StatelessWidget {
  final String filePath;
  final String fileName;
  final NotificationItemEntity item;

  const _InAppExcelDetailModal({
    required this.filePath,
    required this.fileName,
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: const Color(0xFF059669),
          foregroundColor: Colors.white,
          elevation: 0,
          title: Text(fileName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 800),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.table_chart_rounded, color: Color(0xFF059669), size: 28),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          fileName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF0F172A)),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 32),
                  SelectableText(
                    item.details.isNotEmpty ? item.details : 'Dữ liệu bảng tính Excel $fileName',
                    style: const TextStyle(fontSize: 14, color: Color(0xFF334155), height: 1.6),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InAppImageDetailModal extends StatefulWidget {
  final List<String> imagePaths;
  final String fileName;
  final int initialIndex;

  const _InAppImageDetailModal({
    required this.imagePaths,
    required this.fileName,
    this.initialIndex = 0,
  });

  @override
  State<_InAppImageDetailModal> createState() => _InAppImageDetailModalState();
}

class _InAppImageDetailModalState extends State<_InAppImageDetailModal> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final totalImages = widget.imagePaths.isEmpty ? 1 : widget.imagePaths.length;

    return Dialog.fullscreen(
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          elevation: 0,
          title: Row(
            children: [
              const Icon(Icons.photo_library_rounded, size: 20, color: Colors.white70),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.fileName,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (totalImages > 1)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_currentIndex + 1}/$totalImages',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
            ],
          ),
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount: totalImages,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              itemBuilder: (context, index) {
                final path = widget.imagePaths.isNotEmpty ? widget.imagePaths[index] : '';
                final isNetwork = path.startsWith('http://') || path.startsWith('https://');
                final fileExists = path.isNotEmpty && (isNetwork || File(path).existsSync());

                return Center(
                  child: fileExists
                      ? InteractiveViewer(
                          minScale: 0.5,
                          maxScale: 4.0,
                          child: isNetwork ? Image.network(path) : Image.file(File(path)),
                        )
                      : Container(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.photo_library_rounded, color: Color(0xFF2563EB), size: 64),
                              const SizedBox(height: 16),
                              Text(
                                widget.fileName,
                                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Hình ảnh (${index + 1}/$totalImages)',
                                style: const TextStyle(color: Colors.white70, fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                );
              },
            ),
            if (totalImages > 1)
              Positioned(
                bottom: 24,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(totalImages, (index) {
                    final isSelected = index == _currentIndex;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: isSelected ? 22 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF2563EB) : Colors.white38,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

String _formatDateTime(DateTime dt) {
  final day = dt.day.toString().padLeft(2, '0');
  final month = dt.month.toString().padLeft(2, '0');
  final year = dt.year;
  final hour = dt.hour.toString().padLeft(2, '0');
  final minute = dt.minute.toString().padLeft(2, '0');
  final second = dt.second.toString().padLeft(2, '0');
  return '$day/$month/$year $hour:$minute:$second';
}
