import 'package:flutter_test/flutter_test.dart';
import 'package:benhvien7c/features/patients/domain/entities/MedicalTicketEntity.dart';

void main() {
  group('MedicalTicketEntity.isToday Tests', () {
    final now = DateTime.now();
    final todayStr = '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
    final yesterday = now.subtract(const Duration(days: 1));
    final yesterdayStr = '${yesterday.day.toString().padLeft(2, '0')}/${yesterday.month.toString().padLeft(2, '0')}/${yesterday.year}';
    final tomorrow = now.add(const Duration(days: 1));
    final tomorrowStr = '${tomorrow.day.toString().padLeft(2, '0')}/${tomorrow.month.toString().padLeft(2, '0')}/${tomorrow.year}';

    test('Ticket with today scheduleText returns isToday == true', () {
      final ticket = MedicalTicketEntity(
        hospitalName: 'BV',
        hospitalAddress: 'DC',
        ticketTitle: 'Phieu',
        roomName: 'P1',
        serviceName: 'Kham Mat',
        queueNumber: '001',
        scheduleText: '$todayStr 08:30',
        patientName: 'Nguyen Van A',
        gender: 'Nam',
        birthYear: '1990',
        address: 'HCM',
        insuranceText: 'Tu tuc',
        patientCode: '24001234',
        createdAtText: '01/01/2026',
        note: '',
      );

      expect(ticket.isToday, isTrue);
    });

    test('Ticket with yesterday scheduleText returns isToday == false', () {
      final ticket = MedicalTicketEntity(
        hospitalName: 'BV',
        hospitalAddress: 'DC',
        ticketTitle: 'Phieu',
        roomName: 'P1',
        serviceName: 'Kham Mat',
        queueNumber: '001',
        scheduleText: '$yesterdayStr 08:30',
        patientName: 'Nguyen Van A',
        gender: 'Nam',
        birthYear: '1990',
        address: 'HCM',
        insuranceText: 'Tu tuc',
        patientCode: '24001234',
        createdAtText: '01/01/2026',
        note: '',
      );

      expect(ticket.isToday, isFalse);
    });

    test('Ticket with tomorrow scheduleText returns isToday == false', () {
      final ticket = MedicalTicketEntity(
        hospitalName: 'BV',
        hospitalAddress: 'DC',
        ticketTitle: 'Phieu',
        roomName: 'P1',
        serviceName: 'Kham Mat',
        queueNumber: '001',
        scheduleText: '$tomorrowStr 08:30',
        patientName: 'Nguyen Van A',
        gender: 'Nam',
        birthYear: '1990',
        address: 'HCM',
        insuranceText: 'Tu tuc',
        patientCode: '24001234',
        createdAtText: '01/01/2026',
        note: '',
      );

      expect(ticket.isToday, isFalse);
    });
  });

  group('Smart Ticket Scan Decision Logic Tests', () {
    final now = DateTime.now();
    final todayStr = '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
    final yesterday = now.subtract(const Duration(days: 1));
    final yesterdayStr = '${yesterday.day.toString().padLeft(2, '0')}/${yesterday.month.toString().padLeft(2, '0')}/${yesterday.year}';

    final t1Today = MedicalTicketEntity(
      id: '101',
      hospitalName: 'BV',
      hospitalAddress: 'DC',
      ticketTitle: 'Phieu 1',
      roomName: 'P1',
      serviceName: 'Kham Mat',
      queueNumber: '001',
      scheduleText: '$todayStr 08:30',
      patientName: 'Nguyen Van A',
      gender: 'Nam',
      birthYear: '1990',
      address: 'HCM',
      insuranceText: 'Tu tuc',
      patientCode: '24001234',
      createdAtText: todayStr,
      note: '',
    );

    final t2Today = MedicalTicketEntity(
      id: '102',
      hospitalName: 'BV',
      hospitalAddress: 'DC',
      ticketTitle: 'Phieu 2',
      roomName: 'P2',
      serviceName: 'Kham Noi',
      queueNumber: '002',
      scheduleText: '$todayStr 10:00',
      patientName: 'Nguyen Van A',
      gender: 'Nam',
      birthYear: '1990',
      address: 'HCM',
      insuranceText: 'Tu tuc',
      patientCode: '24001234',
      createdAtText: todayStr,
      note: '',
    );

    final t3Yesterday = MedicalTicketEntity(
      id: '103',
      hospitalName: 'BV',
      hospitalAddress: 'DC',
      ticketTitle: 'Phieu 3',
      roomName: 'P3',
      serviceName: 'Kham Rang',
      queueNumber: '003',
      scheduleText: '$yesterdayStr 09:00',
      patientName: 'Nguyen Van A',
      gender: 'Nam',
      birthYear: '1990',
      address: 'HCM',
      insuranceText: 'Tu tuc',
      patientCode: '24001234',
      createdAtText: yesterdayStr,
      note: '',
    );

    final t4OtherPatient = MedicalTicketEntity(
      id: '104',
      hospitalName: 'BV',
      hospitalAddress: 'DC',
      ticketTitle: 'Phieu 4',
      roomName: 'P1',
      serviceName: 'Kham Da Lieu',
      queueNumber: '004',
      scheduleText: '$todayStr 09:00',
      patientName: 'Tran Thi B',
      gender: 'Nu',
      birthYear: '1995',
      address: 'HCM',
      insuranceText: 'Tu tuc',
      patientCode: '24009999',
      createdAtText: todayStr,
      note: '',
    );

    final allTickets = [t1Today, t2Today, t3Yesterday, t4OtherPatient];

    test('Exact ID match takes highest priority and returns single ticket directly', () {
      const scannedCode = '103';
      final directId = allTickets.where((t) => !t.isDeleted && t.id == scannedCode).toList();
      expect(directId.length, equals(1));
      expect(directId.first.serviceName, equals('Kham Rang'));
    });

    test('Single ticket matching patientCode opens directly without prompt', () {
      const scannedCode = '24009999';
      final matching = allTickets.where((t) => !t.isDeleted && t.patientCode == scannedCode).toList();
      expect(matching.length, equals(1));
      expect(matching.first.patientName, equals('Tran Thi B'));
    });

    test('Multiple tickets with exactly 1 ticket today auto-opens today ticket', () {
      // Giả sử chỉ có t1Today và t3Yesterday của bệnh nhân A
      final patientTickets = [t1Today, t3Yesterday];
      expect(patientTickets.length, equals(2));

      final todayTickets = patientTickets.where((t) => t.isToday).toList();
      expect(todayTickets.length, equals(1));
      expect(todayTickets.first.id, equals('101'));
      expect(todayTickets.first.serviceName, equals('Kham Mat'));
    });

    test('Multiple tickets with 2 tickets today triggers bottom sheet', () {
      final patientTickets = [t1Today, t2Today, t3Yesterday];
      expect(patientTickets.length, equals(3));

      final todayTickets = patientTickets.where((t) => t.isToday).toList();
      expect(todayTickets.length, equals(2)); // Cần mở bottom sheet để người dùng chọn
      expect(todayTickets.map((t) => t.serviceName).toList(), containsAll(['Kham Mat', 'Kham Noi']));
    });

    test('Multiple tickets with 0 tickets today triggers bottom sheet showing all sorted by date', () {
      final patientOldTickets = [t3Yesterday];
      // Thêm 1 phiếu cũ hơn
      final t5Older = t3Yesterday.copyWith(
        id: '105',
        scheduleText: '01/01/2025 08:00',
      );
      final list = [t5Older, t3Yesterday];

      final todayTickets = list.where((t) => t.isToday).toList();
      expect(todayTickets.length, equals(0)); // 0 phiếu hôm nay

      // Sắp xếp ngày giảm dần
      list.sort((a, b) {
        final dateA = a.parsedTicketDate ?? DateTime(1970);
        final dateB = b.parsedTicketDate ?? DateTime(1970);
        return dateB.compareTo(dateA);
      });

      expect(list.first.id, equals('103')); // t3Yesterday mới hơn t5Older
    });
  });
}
