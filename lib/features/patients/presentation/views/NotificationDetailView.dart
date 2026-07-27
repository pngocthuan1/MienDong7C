import 'package:flutter/material.dart';
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
                  // If has attachment, render full-width download button below
                  if (currentItem.attachmentName != null) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: (currentItem.isDownloaded || _viewModel.isMutating)
                            ? null
                            : () => _showDownloadDialog(currentItem),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2F7DE1), // Blue color matching screenshot
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: const Color(0xFFCCCCCC), // Grey when disabled
                          disabledForegroundColor: const Color(0xFF888888),
                          elevation: 0,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        child: Text(
                          currentItem.isDownloaded
                              ? 'ĐÃ TẢI TỆP ${currentItem.attachmentName!.toUpperCase()}'
                              : 'MỞ TỆP ${currentItem.attachmentName!.toUpperCase()}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ],
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
