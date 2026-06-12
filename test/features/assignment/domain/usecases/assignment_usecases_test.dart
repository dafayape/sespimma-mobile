import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sespimma/core/usecases/usecase.dart';
import 'package:sespimma/features/assignment/domain/entities/assignment_entity.dart';
import 'package:sespimma/features/assignment/domain/repositories/assignment_repository.dart';
import 'package:sespimma/features/assignment/domain/usecases/get_assignments.dart';
import 'package:sespimma/features/assignment/domain/usecases/get_assignment_detail.dart';

class MockAssignmentRepository extends Mock implements AssignmentRepository {}

void main() {
  late MockAssignmentRepository mockRepository;

  setUp(() {
    mockRepository = MockAssignmentRepository();
  });

  group('GetAssignments', () {
    test('mengembalikan daftar assignment dari repository', () async {
      final expected = [
        const AssignmentEntity(
          id: '1',
          title: 'Naskah Akademik',
          description: 'Buat naskah akademik',
          status: 'aktif',
        ),
      ];
      when(
        () => mockRepository.getAssignments(),
      ).thenAnswer((_) async => expected);

      final usecase = GetAssignments(mockRepository);
      final result = await usecase(const NoParams());

      expect(result, expected);
      expect(result.length, 1);
      verify(() => mockRepository.getAssignments()).called(1);
    });
  });

  group('GetAssignmentDetail', () {
    test('mengembalikan assignment detail dari repository', () async {
      const expected = AssignmentEntity(
        id: '1',
        title: 'Naskah Akademik',
        description: 'Buat naskah akademik',
        status: 'aktif',
        score: 85.0,
      );
      when(
        () => mockRepository.getAssignmentDetail('1'),
      ).thenAnswer((_) async => expected);

      final usecase = GetAssignmentDetail(mockRepository);
      final result = await usecase('1');

      expect(result, expected);
      expect(result.title, 'Naskah Akademik');
      verify(() => mockRepository.getAssignmentDetail('1')).called(1);
    });
  });
}
