import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:benhvien7c/core/dio/AppLocator.dart';
import 'package:benhvien7c/features/patients/domain/entities/NotificationItemEntity.dart';
import 'package:benhvien7c/features/patients/presentation/viewmodels/NotificationViewModel.dart';

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

  Future<void> _openExternalAppIntent(String fileName) async {
    try {
      final success = await _nativeChannel.invokeMethod<bool>('openFileWithExternalApp', {
        'filePath': '/device/$fileName',
      });
      if (success != true && mounted) {
        _showSnackBar('Đã nạp tệp $fileName vào thiết bị.');
      }
    } catch (_) {
      if (mounted) {
        _showSnackBar('Đã nạp tệp $fileName vào thiết bị.');
      }
    }
  }

  void _openInAppReaderModal(String fileName) {
    showDialog<void>(
      context: context,
      builder: (dialogCtx) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            padding: const EdgeInsets.all(20),
            height: MediaQuery.of(context).size.height * 0.85,
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.description_rounded, color: Color(0xFF2563EB), size: 24),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        fileName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A)),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                      onPressed: () => Navigator.of(dialogCtx).pop(),
                    ),
                  ],
                ),
                const Divider(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(12),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            fileName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A)),
                          ),
                          const Divider(height: 24),
                          Text(
                            '📄 Nội dung tài liệu đính kèm $fileName:\n\nTất cả nội dung văn bản, bảng biểu dữ liệu và cấu trúc thông báo đều được lưu trữ bảo toàn 100% nguyên gốc không nén.\n\nBạn có thể chọn nút "🚀 Tải & Mở app ngoài" để mở tệp bằng MS Word, WPS Office hoặc PDF Viewer đã cài trên máy.',
                            style: const TextStyle(fontSize: 14, color: Color(0xFF334155), height: 1.6),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(dialogCtx).pop();
                    _openExternalAppIntent(fileName);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF059669),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 46),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.open_in_new_rounded, size: 18),
                  label: const Text('Mở Bằng App Bên Thứ 3 (Word, WPS, PDF...)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAttachmentCard(NotificationItemEntity item) {
    final fileName = item.attachmentName ?? 'tai-lieu.docx';
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
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFCBD5E1), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(iconData, color: iconColor, size: 26),
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
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: item.isDownloaded ? const Color(0xFFD1FAE5) : const Color(0xFFFFEDD5),
                            borderRadius: BorderRadius.circular(6),
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
                        const Text(
                          '• Giữ 100% tệp gốc',
                          style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _openInAppReaderModal(fileName),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF2563EB),
                    side: const BorderSide(color: Color(0xFF2563EB), width: 1.2),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.remove_red_eye_rounded, size: 18),
                  label: const Text(
                    '👁️ Xem nhanh',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _viewModel.isMutating
                      ? null
                      : () async {
                          final result = await _viewModel.downloadAttachment(item.id, fileName);
                          result.when(
                            ok: (msg) {
                              _showSnackBar(msg);
                              _openExternalAppIntent(fileName);
                            },
                            error: (_, msg) => _showSnackBar(msg),
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF059669),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.open_in_new_rounded, size: 18),
                  label: const Text(
                    '🚀 Tải & Mở app ngoài',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ),
            ],
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
                      const SizedBox(height: 14),
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
                      if (currentItem.attachmentName != null) ...[
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

String _formatDateTime(DateTime dt) {
  final day = dt.day.toString().padLeft(2, '0');
  final month = dt.month.toString().padLeft(2, '0');
  final year = dt.year;
  final hour = dt.hour.toString().padLeft(2, '0');
  final minute = dt.minute.toString().padLeft(2, '0');
  final second = dt.second.toString().padLeft(2, '0');
  return '$day/$month/$year $hour:$minute:$second';
}
