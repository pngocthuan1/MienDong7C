import 'package:flutter/material.dart';
import 'package:benhvien7c/core/widgets/AppResponsiveContainer.dart';
import 'package:benhvien7c/app/router/RouteNames.dart';
import 'package:benhvien7c/core/navigation/AppNavigator.dart';
import 'package:benhvien7c/features/auth/presentation/views/AuthFlowArguments.dart';
import 'package:benhvien7c/features/patients/presentation/viewmodels/MedicalTicketViewModel.dart';
import 'package:benhvien7c/features/patients/presentation/widgets/MedicalTicketBarcode.dart';

class MedicalTicketView extends StatefulWidget {
  const MedicalTicketView({required this.args, super.key});

  final MedicalTicketViewArgs args;

  @override
  State<MedicalTicketView> createState() => _MedicalTicketViewState();
}

class _MedicalTicketViewState extends State<MedicalTicketView> {
  late final MedicalTicketViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = MedicalTicketViewModel(widget.args.ticket);
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ticket = _viewModel.ticket;

    return AppResponsiveContainer(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D6EFD),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Phiếu khám bệnh',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => AppNavigator.safePop(context),
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        children: [
          // Stack to draw the ticket with left/right circular punches
          Stack(
            clipBehavior: Clip.none,
            children: [
              // Ticket Body Container
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      ticket.hospitalName,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ticket.hospitalAddress,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'PHIẾU KHÁM BỆNH',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A), letterSpacing: 0.8),
                    ),
                    const SizedBox(height: 8),
                    
                    // Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: ticket.isPast ? Colors.grey[200] : const Color(0xFFEBF3FF),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        ticket.isPast ? 'ĐÃ QUA' : 'SẮP TỚI',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: ticket.isPast ? Colors.grey[600] : const Color(0xFF0D6EFD),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          ticket.roomName,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                        ),
                        Text(
                          ticket.serviceName,
                          style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    // Big Sequence Number
                    const Text(
                      'SỐ THỨ TỰ',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ticket.queueNumber,
                      style: const TextStyle(
                        fontSize: 64,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0D6EFD),
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Custom Dashed Divider (Tear line)
                    CustomPaint(
                      painter: _DashedLinePainter(),
                      child: const SizedBox(height: 1, width: double.infinity),
                    ),
                    const SizedBox(height: 20),

                    // Patient Details Block
                    _TicketRow(label: 'Ngày khám', value: ticket.scheduleText),
                    _TicketRow(label: 'Họ tên', value: ticket.patientName),
                    _TicketRow(label: 'Giới tính', value: ticket.gender),
                    _TicketRow(label: 'Năm sinh', value: ticket.birthYear),
                    _TicketRow(label: 'SĐT', value: ticket.phoneNumber ?? ''),
                    _TicketRow(label: 'Mã BN', value: ticket.patientCode),
                    
                    const SizedBox(height: 16),
                    CustomPaint(
                      painter: _DashedLinePainter(),
                      child: const SizedBox(height: 1, width: double.infinity),
                    ),
                    const SizedBox(height: 18),

                    // Real scannable barcode
                    Text(
                      'Mã BN: ${ticket.patientCode}',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: MedicalTicketBarcode(seed: ticket.patientCode),
                    ),
                  ],
                ),
              ),

              // Left Punch Hole Overlay
              Positioned(
                left: -10,
                top: 220,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF8FAFC),
                    shape: BoxShape.circle,
                  ),
                ),
              ),

              // Right Punch Hole Overlay
              Positioned(
                right: -10,
                top: 220,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF8FAFC),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),

          // "Rebook this profile" button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                AppNavigator.pushNamed(
                  context,
                  RouteNames.patientProfileCreate,
                  arguments: ticket, // Pre-fills all patient details
                );
              },
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Chọn lại hồ sơ này để đăng ký lại'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF0D6EFD),
                side: const BorderSide(color: Color(0xFF0D6EFD)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Dashed Line Painter
class _DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    double dashWidth = 5, dashSpace = 4, startX = 0;
    final paint = Paint()
      ..color = Colors.grey[300]!
      ..strokeWidth = 1;
    while (startX < size.width) {
      canvas.drawLine(Offset(startX, 0), Offset(startX + dashWidth, 0), paint);
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class _TicketRow extends StatelessWidget {
  const _TicketRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF334155),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
