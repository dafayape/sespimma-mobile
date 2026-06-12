import 'package:flutter_test/flutter_test.dart';
import 'package:sespimma/core/errors/failures.dart';

void main() {
  group('Failures', () {
    test('ServerFailure menyimpan pesan yang benar', () {
      const failure = ServerFailure('Server error 500');
      expect(failure.message, 'Server error 500');
      expect(failure.toString(), 'Server error 500');
    });

    test('CacheFailure menyimpan pesan yang benar', () {
      const failure = CacheFailure('Cache tidak ditemukan');
      expect(failure.message, 'Cache tidak ditemukan');
    });

    test('NetworkFailure menyimpan pesan yang benar', () {
      const failure = NetworkFailure('Tidak ada koneksi internet');
      expect(failure.message, 'Tidak ada koneksi internet');
    });

    test('ValidationFailure menyimpan pesan yang benar', () {
      const failure = ValidationFailure('Input tidak valid');
      expect(failure.message, 'Input tidak valid');
    });

    test('UnknownFailure menyimpan pesan yang benar', () {
      const failure = UnknownFailure('Error tidak diketahui');
      expect(failure.message, 'Error tidak diketahui');
    });

    test('Failure subclasses bersifat final', () {
      const Failure serverFailure = ServerFailure('test');
      const Failure cacheFailure = CacheFailure('test');
      const Failure networkFailure = NetworkFailure('test');

      expect(serverFailure, isA<ServerFailure>());
      expect(cacheFailure, isA<CacheFailure>());
      expect(networkFailure, isA<NetworkFailure>());
    });
  });
}
