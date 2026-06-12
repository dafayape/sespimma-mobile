import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sespimma/core/usecases/usecase.dart';
import 'package:sespimma/features/dashboard/domain/entities/dashboard_summary_entity.dart';
import 'package:sespimma/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:sespimma/features/dashboard/domain/usecases/get_dashboard_summary.dart';

class MockDashboardRepository extends Mock implements DashboardRepository {}

void main() {
  late MockDashboardRepository mockRepository;

  setUp(() {
    mockRepository = MockDashboardRepository();
  });

  group('GetDashboardSummary', () {
    test('mengembalikan dashboard summary dari repository', () async {
      const expected = DashboardSummaryEntity(
        totalSerdik: 120,
        hadir: 100,
        izin: 15,
        absen: 5,
        attendancePercentage: 83.3,
        averageAcademic: 82.5,
        averageMental: 78.0,
        averagePhysical: 85.2,
        announcements: ['Jadwal ujian dipercepat'],
      );

      when(
        () => mockRepository.getDashboardSummary(),
      ).thenAnswer((_) async => expected);

      final usecase = GetDashboardSummary(mockRepository);
      final result = await usecase(const NoParams());

      expect(result, expected);
      expect(result.totalSerdik, 120);
      expect(result.announcements.length, 1);
      verify(() => mockRepository.getDashboardSummary()).called(1);
    });
  });
}
