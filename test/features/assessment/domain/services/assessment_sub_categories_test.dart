import 'package:flutter_test/flutter_test.dart';
import 'package:sespimma/features/assessment/domain/services/assessment_sub_categories.dart';

void main() {
  group('AssessmentSubCategories', () {
    group('getAkademik', () {
      test('mengembalikan 10 sub-kategori', () {
        final items = AssessmentSubCategories.getAkademik();
        expect(items.length, 10);
      });

      test('mencakup tahap Pelajaran, Simulasi, dan Taskap', () {
        final items = AssessmentSubCategories.getAkademik();
        final tahaps = items.map((e) => e['tahap'] as String).toSet();

        expect(tahaps, containsAll(['Pelajaran', 'Simulasi', 'Taskap']));
      });
    });

    group('getMentalKepribadian', () {
      test('mengembalikan 6 sub-kategori', () {
        final items = AssessmentSubCategories.getMentalKepribadian();
        expect(items.length, 6);
      });

      test('mencakup Sosiometri', () {
        final items = AssessmentSubCategories.getMentalKepribadian();
        final tahaps = items.map((e) => e['tahap'] as String).toSet();

        expect(
          tahaps,
          containsAll([
            'Observasi Harian',
            'Sosiometri',
          ]),
        );
      });
    });

    group('getJasmani', () {
      test('mengembalikan 8 sub-kategori untuk Admin', () {
        final items = AssessmentSubCategories.getJasmani(
          isWanita: false,
          currentRole: 'Admin',
        );
        expect(items.length, 8);
      });

      test('hanya mengembalikan tes kesehatan untuk Tim Medis', () {
        final items = AssessmentSubCategories.getJasmani(
          isWanita: false,
          currentRole: 'Tim Medis',
        );

        for (final item in items) {
          expect(['Tes Awal', 'Tes Akhir', 'Harian'], contains(item['tahap']));
        }
      });

      test('hanya mengembalikan samapta untuk Korsis', () {
        final items = AssessmentSubCategories.getJasmani(
          isWanita: false,
          currentRole: 'Korsis',
        );

        for (final item in items) {
          expect(item['tahap'], 'Samapta');
        }
      });

      test('menampilkan Chinning untuk wanita', () {
        final items = AssessmentSubCategories.getJasmani(
          isWanita: true,
          currentRole: 'Admin',
        );

        final pullUpItem = items.firstWhere(
          (item) => (item['name'] as String).contains('Pull-up'),
        );
        expect(pullUpItem['name'] as String, contains('Chinning'));
      });
    });

    group('getTahapOptions', () {
      test('mengembalikan opsi yang benar untuk Akademik', () {
        final options = AssessmentSubCategories.getTahapOptions(
          'Akademik',
          'Gadik',
        );

        expect(options, ['Semua', 'Pelajaran', 'Simulasi', 'Taskap']);
      });

      test('mengembalikan opsi yang benar untuk Korsis', () {
        final options = AssessmentSubCategories.getTahapOptions(
          'Jasmani',
          'Korsis',
        );

        expect(options, ['Semua', 'Samapta']);
      });
    });
  });
}
