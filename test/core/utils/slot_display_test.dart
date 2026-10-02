import 'package:flutter_test/flutter_test.dart';
import 'package:benhvien7c/core/utils/DateTimeConverter.dart';
import 'package:benhvien7c/features/patients/data/models/DatLichKhamDtos.dart';

void main() {
  group('Kiểm tra định dạng hiển thị khung giờ khám (HH:mm - HH:mm)', () {
    const allSampleSlots = [
      '06:00-06:30',
      '06:30-07:00',
      '07:00-07:30',
      '07:30-08:00',
      '08:00-08:30',
      '08:30-09:00',
      '09:00-09:30',
      '09:30-10:00',
      '10:00-10:30',
      '10:30-11:00',
      '11:00-11:30',
      '11:30-12:00',
      '13:00-13:30',
      '13:30-14:00',
      '14:00-14:30',
      '14:30-15:00',
      '15:00-15:30',
      '15:30-16:00',
      '16:00-16:30',
      '16:30-17:00',
      '17:00-17:30',
      '17:30-18:00',
      '18:00-18:30',
      '18:30-19:00',
      '19:00-19:30',
    ];

    test('Chạy qua toàn bộ 25 khung giờ mẫu: tất cả phải hiển thị đúng "HH:mm - HH:mm"', () {
      for (final slotId in allSampleSlots) {
        final formatted = DateTimeConverter.formatGioKhamForDisplay(slotId);
        final parts = slotId.split('-');
        final expected = '${parts[0]} - ${parts[1]}';

        expect(formatted, equals(expected),
            reason: 'Khung giờ $slotId phải format thành $expected nhưng lại ra $formatted');
      }
    });

    test('Đặc biệt kiểm tra trường hợp 10:00-10:30 không bị lỗi "10g: 10:30"', () {
      final formatted = DateTimeConverter.formatGioKhamForDisplay('10:00-10:30');
      expect(formatted, equals('10:00 - 10:30'));
      expect(formatted.contains('g'), isFalse);
    });

    test('DkkListMasterDto.getSlotsForDate luôn trả về Id sạch kể cả khi server gửi Display có chữ "g"', () {
      final master = DkkListMasterDto(
        listPhongKham: [],
        listTinh: [],
        dicPhuong: {},
        listNgayKham: [],
        listGioKham: [
          DkkGioKhamSlotDto(
            id: '10:00-10:30',
            tuGio: 10,
            tuPhut: 0,
            denGio: 10,
            denPhut: 30,
            display: '10g - 10:30', // Chuỗi Display bị lỗi từ backend cũ
          ),
          DkkGioKhamSlotDto(
            id: '07:30-08:00',
            tuGio: 7,
            tuPhut: 30,
            denGio: 8,
            denPhut: 0,
            display: '7g30 - 8g',
          ),
        ],
        dicNgayGioKham: {
          '2026-10-02T00:00:00': ['10g - 10:30', '07:30-08:00'],
        },
      );

      final slots = master.getSlotsForDate('2026-10-02T00:00:00');

      // Cả 2 slot phải được quy đổi về Id sạch dạng "HH:mm-HH:mm"
      expect(slots, equals(['10:00-10:30', '07:30-08:00']));

      // Khi format hiển thị trên UI:
      final displaySlots = slots.map(DateTimeConverter.formatGioKhamForDisplay).toList();
      expect(displaySlots, equals(['10:00 - 10:30', '07:30 - 08:00']));
      expect(displaySlots.any((s) => s.contains('g')), isFalse);
    });
  });
}
