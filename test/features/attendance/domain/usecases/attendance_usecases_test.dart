import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sespimma/core/usecases/usecase.dart';
import 'package:sespimma/features/attendance/domain/entities/attendance_entity.dart';
import 'package:sespimma/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:sespimma/features/attendance/domain/usecases/get_attendances.dart';
import 'package:sespimma/features/attendance/domain/usecases/submit_attendance.dart';

class MockAttendanceRepository extends Mock implements AttendanceRepository {}

void main() {
  late MockAttendanceRepository mockRepository;

  setUp(() {
    mockRepository = MockAttendanceRepository();
  });

  group('GetAttendances', () {
    test('mengembalikan daftar attendance dari repository', () async {
      final expected = [
        AttendanceEntity(id: '1', date: DateTime(2026, 5, 21), status: 'hadir'),
      ];
      when(
        () => mockRepository.getAttendances(),
      ).thenAnswer((_) async => expected);

      final usecase = GetAttendances(mockRepository);
      final result = await usecase(const NoParams());

      expect(result, expected);
      verify(() => mockRepository.getAttendances()).called(1);
    });

    test('mengembalikan daftar kosong jika tidak ada data', () async {
      when(() => mockRepository.getAttendances()).thenAnswer((_) async => []);

      final usecase = GetAttendances(mockRepository);
      final result = await usecase(const NoParams());

      expect(result, isEmpty);
    });
  });

  group('SubmitAttendance', () {
    test('memanggil repository submitAttendance', () async {
      final entity = AttendanceEntity(
        id: '1',
        date: DateTime(2026, 5, 21),
        status: 'hadir',
        location: 'Kampus SESPIMMA',
      );
      when(
        () => mockRepository.submitAttendance(entity),
      ).thenAnswer((_) async {});

      final usecase = SubmitAttendance(mockRepository);
      await usecase(entity);

      verify(() => mockRepository.submitAttendance(entity)).called(1);
    });
  });
}
