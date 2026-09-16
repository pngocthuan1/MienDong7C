import 'package:flutter/material.dart';
import 'package:benhvien7c/features/patients/domain/entities/MedicalTicketEntity.dart';

class TicketPickerBottomSheet extends StatefulWidget {
  const TicketPickerBottomSheet({
    required this.patientCode,
    required this.allTickets,
    required this.todayTickets,
    super.key,
  });

  final String patientCode;
  final List<MedicalTicketEntity> allTickets;
  final List<MedicalTicketEntity> todayTickets;

  static Future<MedicalTicketEntity?> show({
    required BuildContext context,
    required String patientCode,
    required List<MedicalTicketEntity> allTickets,
    required List<MedicalTicketEntity> todayTickets,
  }) {
    return showModalBottomSheet<MedicalTicketEntity>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => TicketPickerBottomSheet(
        patientCode: patientCode,
        allTickets: allTickets,
        todayTickets: todayTickets,
      ),
    );
  }

  @override
  State<TicketPickerBottomSheet> createState() => _TicketPickerBottomSheetState();
}

class _TicketPickerBottomSheetState extends State<TicketPickerBottomSheet> {
  bool _showAll = false;

  @override
  void initState() {
    super.initState();
    // Nếu không có phiếu nào hôm nay, mặc định mở toàn bộ phiếu
    _showAll = widget.todayTickets.isEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final patientName = widget.allTickets.isNotEmpty
        ? widget.allTickets.first.patientName
        : '';
    final displayedTickets = (_showAll || widget.todayTickets.isEmpty)
        ? widget.allTickets
        : widget.todayTickets;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 14),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.receipt_long_rounded,
                      color: Color(0xFF0D6EFD),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Chọn phiếu khám',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$patientName • Mã BN: ${widget.patientCode}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Color(0xFF94A3B8)),
                    onPressed: () => Navigator.of(context).pop(null),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),
            const Divider(height: 1, color: Color(0xFFF1F5F9)),

            // Filter indicator (nếu có phiếu hôm nay và còn phiếu ngày khác)
            if (widget.todayTickets.isNotEmpty && widget.todayTickets.length < widget.allTickets.length)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 4),
                child: Row(
                  children: [
                    Text(
                      _showAll
                          ? 'Tất cả phiếu (${widget.allTickets.length})'
                          : 'Các phiếu khám hôm nay (${widget.todayTickets.length})',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF475569),
                      ),
                    ),
                    const Spacer(),
                    InkWell(
                      onTap: () {
                        setState(() {
                          _showAll = !_showAll;
                        });
                      },
                      borderRadius: BorderRadius.circular(6),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        child: Text(
                          _showAll ? 'Chỉ xem hôm nay' : 'Xem tất cả phiếu',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0D6EFD),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // List of tickets
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                itemCount: displayedTickets.length,
                separatorBuilder: (context, index) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final ticket = displayedTickets[index];
                  final isToday = ticket.isToday;

                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => Navigator.of(context).pop(ticket),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isToday ? const Color(0xFFF0FDF4) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isToday ? const Color(0xFF86EFAC) : const Color(0xFFE2E8F0),
                            width: isToday ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            // Số thứ tự (STT) Box
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: isToday ? const Color(0xFF16A34A) : const Color(0xFF4F46E5),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    'STT',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white70,
                                    ),
                                  ),
                                  Text(
                                    ticket.queueNumber,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Thông tin phiếu
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      if (isToday)
                                        Container(
                                          margin: const EdgeInsets.only(right: 6),
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFDCFCE7),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: const Text(
                                            'HÔM NAY',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF15803D),
                                            ),
                                          ),
                                        ),
                                      Expanded(
                                        child: Text(
                                          ticket.serviceName.isNotEmpty ? ticket.serviceName : 'Khám bệnh',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF1E293B),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.calendar_today_rounded,
                                        size: 13,
                                        color: Color(0xFF64748B),
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          ticket.scheduleText,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF64748B),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (ticket.roomName.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.meeting_room_outlined,
                                          size: 13,
                                          color: Color(0xFF64748B),
                                        ),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            ticket.roomName,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF64748B),
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),

                            // Mũi tên chọn
                            const Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 14,
                              color: Color(0xFF94A3B8),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
