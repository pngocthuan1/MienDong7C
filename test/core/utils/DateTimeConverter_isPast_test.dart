import 'package:flutter_test/flutter_test.dart';
import 'package:benhvien7c/core/utils/DateTimeConverter.dart';
import 'package:benhvien7c/features/patients/domain/entities/MedicalTicketEntity.dart';

void main() {
  group('DateTimeConverter.extractTicketEndTime', () {
    test('trích xuất giờ kết thúc từ khoảng giờ HH:mm - HH:mm', () {
      final res = DateTimeConverter.extractTicketEndTime(selectedTime: '14:30 - 15:00');
      expect(res, isNotNull);
      expect(res!.hour, 15);
      expect(res.minute, 0);
    });

    test('trích xuất giờ kết thúc từ định dạng có chữ g (ví dụ 14g30 - 15g00)', () {
      final res = DateTimeConverter.extractTicketEndTime(selectedTime: '14g30 - 15g00');
      expect(res, isNotNull);
      expect(res!.hour, 15);
      expect(res.minute, 0);
    });

    test('trích xuất giờ kết thúc từ scheduleText có bullet point', () {
      final res = DateTimeConverter.extractTicketEndTime(
        scheduleText: '05/10/2026 • 14:30 - 15:00',
      );
      expect(res, isNotNull);
      expect(res!.hour, 15);
      expect(res.minute, 0);
    });

    test('fallback cộng 30 phút khi chỉ có giờ bắt đầu (14:30)', () {
      final res = DateTimeConverter.extractTicketEndTime(selectedTime: '14:30');
      expect(res, isNotNull);
      expect(res!.hour, 15);
      expect(res.minute, 0);
    });
  });

  group('DateTimeConverter.isTicketPast & MedicalTicketEntity.isPast', () {
    final ticketDate = DateTime(2026, 10, 5);

    test('Lúc 14:42 trong ca khám 14:30 - 15:00 thì CHƯA ĐƯỢC COI LÀ ĐÃ QUA (isPast = false)', () {
      final duringSlot = DateTime(2026, 10, 5, 14, 42);
      final isPast = DateTimeConverter.isTicketPast(
        ticketDate: ticketDate,
        selectedTime: '14:30 - 15:00',
        now: duringSlot,
      );
      expect(isPast, isFalse, reason: 'Ca khám 14:30 - 15:00 lúc 14:42 vẫn đang diễn ra, phải là false');
    });

    test('Lúc 15:01 sau khi kết thúc ca khám 14:30 - 15:00 thì ĐÃ QUA (isPast = true)', () {
      final afterSlot = DateTime(2026, 10, 5, 15, 1);
      final isPast = DateTimeConverter.isTicketPast(
        ticketDate: ticketDate,
        selectedTime: '14:30 - 15:00',
        now: afterSlot,
      );
      expect(isPast, isTrue, reason: 'Sau 15:00 thì ca khám đã kết thúc, phải là true');
    });

    test('MedicalTicketEntity getter isPast hoạt động đồng bộ với logic trên', () {
      final ticket = MedicalTicketEntity(
        hospitalName: 'BV',
        hospitalAddress: 'ĐC',
        ticketTitle: 'Phiếu',
        roomName: 'P1',
        serviceName: 'Khám',
        queueNumber: '001',
        scheduleText: '05/10/2026 • 14:30 - 15:00',
        selectedDate: '2026-10-05T00:00:00',
        selectedTime: '14:30 - 15:00',
        patientName: 'Nguyễn Văn A',
        gender: 'Nam',
        birthYear: '1990',
        address: 'HCM',
        insuranceText: 'Tự túc',
        patientCode: 'BN001',
        createdAtText: '05/10/2026',
        note: 'Ghi chú',
      );

      // Verify date parsing
      expect(ticket.parsedTicketDate, isNotNull);
      expect(ticket.parsedTicketDate!.day, 5);
      expect(ticket.parsedTicketDate!.month, 10);
      expect(ticket.parsedTicketDate!.year, 2026);
    });
  });
}
