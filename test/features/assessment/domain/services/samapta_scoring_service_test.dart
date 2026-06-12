import 'package:flutter_test/flutter_test.dart';
import 'package:sespimma/features/assessment/domain/services/samapta_scoring_service.dart';

void main() {
  group('SamaptaScoringService', () {
    group('getAgeAndGolongan', () {
      test('mengembalikan default Golongan I jika birthDateStr null', () {
        final result = SamaptaScoringService.getAgeAndGolongan(null);

        expect(result['age'], 25);
        expect(result['golongan'], 'Golongan I');
      });

      test('mengembalikan Golongan II untuk usia 31-40', () {
        final birthDate = DateTime.now()
            .subtract(const Duration(days: 365 * 35))
            .toIso8601String()
            .split('T')
            .first;

        final result = SamaptaScoringService.getAgeAndGolongan(birthDate);

        expect(result['golongan'], 'Golongan II');
      });

      test('mengembalikan Golongan III untuk usia >50', () {
        final birthDate = DateTime.now()
            .subtract(const Duration(days: 365 * 55))
            .toIso8601String()
            .split('T')
            .first;

        final result = SamaptaScoringService.getAgeAndGolongan(birthDate);

        expect(result['golongan'], 'Golongan III');
      });

      test('mengembalikan default jika format tanggal tidak valid', () {
        final result = SamaptaScoringService.getAgeAndGolongan('invalid-date');

        expect(result['age'], 25);
        expect(result['golongan'], 'Golongan I');
      });
    });

    group('lookupScore', () {
      test('mengembalikan 0.0 jika rawValue <= 0', () {
        final score = SamaptaScoringService.lookupScore(
          'Lari 12 Menit',
          'Golongan I',
          'Laki-laki',
          0,
        );

        expect(score, 0.0);
      });

      test('mengembalikan 100.0 jika rawValue Lari >= nilai tertinggi', () {
        final score = SamaptaScoringService.lookupScore(
          'Lari 12 Menit',
          'Golongan I',
          'Laki-laki',
          3500,
        );

        expect(score, 100.0);
      });

      test('mengembalikan skor interpolasi untuk Lari pria Golongan I', () {
        final score = SamaptaScoringService.lookupScore(
          'Lari 12 Menit',
          'Golongan I',
          'Laki-laki',
          3300,
        );

        expect(score, greaterThan(90));
        expect(score, lessThan(100));
      });

      test('mengembalikan skor untuk Shuttle Run (lower is better)', () {
        final score = SamaptaScoringService.lookupScore(
          'Shuttle Run',
          'Golongan I',
          'Laki-laki',
          16.2,
        );

        expect(score, 100.0);
      });

      test('mengembalikan skor rendah untuk Shuttle Run lambat', () {
        final score = SamaptaScoringService.lookupScore(
          'Shuttle Run',
          'Golongan I',
          'Laki-laki',
          19.0,
        );

        expect(score, greaterThan(40));
        expect(score, lessThan(65));
      });

      test('mengembalikan skor untuk Pull-up pria Golongan I', () {
        final score = SamaptaScoringService.lookupScore(
          'Pull-up',
          'Golongan I',
          'Laki-laki',
          17,
        );

        expect(score, 100.0);
      });

      test('mengembalikan skor untuk Pull-up wanita (Chinning)', () {
        final score = SamaptaScoringService.lookupScore(
          'Pull-up',
          'Golongan I',
          'Perempuan',
          72,
        );

        expect(score, 100.0);
      });
    });

    group('calculateAkademikScore', () {
      test('menghitung rata-rata akademik dengan bobot yang benar', () {
        double getVal(int idx) => switch (idx) {
          0 => 80.0,
          1 => 85.0,
          2 => 90.0,
          3 => 75.0,
          4 => 88.0,
          5 => 82.0,
          6 => 78.0,
          7 => 85.0,
          8 => 80.0,
          9 => 90.0,
          _ => 0.0,
        };

        final score = SamaptaScoringService.calculateAkademikScore(getVal);

        expect(score, greaterThan(0));
        expect(score, lessThanOrEqualTo(100));
      });
    });

    group('calculateMentalScore', () {
      test('menghitung rata-rata mental dengan lookup points', () {
        double getVal(int idx) => 80.0;

        final score = SamaptaScoringService.calculateMentalScore(getVal, 0.50);

        expect(score, greaterThan(0));
      });
    });

    group('calculateJasmaniScore', () {
      test('mengembalikan nKes untuk Tim Medis', () {
        double getVal(int idx) => switch (idx) {
          0 => 85.0,
          1 => 90.0,
          2 => 80.0,
          _ => 70.0,
        };

        final score = SamaptaScoringService.calculateJasmaniScore(
          getVal,
          'Tim Medis',
        );

        expect(score, closeTo(85.0, 0.1));
      });

      test('mengembalikan nJas untuk Korsis', () {
        double getVal(int idx) => 80.0;

        final score = SamaptaScoringService.calculateJasmaniScore(
          getVal,
          'Korsis',
        );

        expect(score, greaterThan(0));
      });
    });

    group('getScorePredicate', () {
      test('mengembalikan SM untuk skor > 85', () {
        expect(
          SamaptaScoringService.getScorePredicate(90.0),
          'Sangat Memuaskan (SM)',
        );
      });

      test('mengembalikan M untuk skor 80-85', () {
        expect(SamaptaScoringService.getScorePredicate(82.5), 'Memuaskan (M)');
      });

      test('mengembalikan Tidak Lulus untuk skor <= 70', () {
        expect(
          SamaptaScoringService.getScorePredicate(65.0),
          'Tidak Lulus (K)',
        );
      });

      test('mengembalikan - untuk skor 0', () {
        expect(SamaptaScoringService.getScorePredicate(0), '-');
      });
    });
  });
}
