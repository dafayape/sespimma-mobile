import 'package:flutter/material.dart';

abstract final class AssessmentSubCategories {
  static List<Map<String, dynamic>> getAkademik() => [
    {
      'index': 0,
      'name': 'Ujian MP (30% - Pelajaran)',
      'icon': Icons.menu_book_rounded,
      'tahap': 'Pelajaran',
    },
    {
      'index': 1,
      'name': 'NKKP (5% - Pelajaran)',
      'icon': Icons.menu_book_rounded,
      'tahap': 'Pelajaran',
    },
    {
      'index': 2,
      'name': 'NPKP (5% - Pelajaran)',
      'icon': Icons.menu_book_rounded,
      'tahap': 'Pelajaran',
    },
    {
      'index': 3,
      'name': 'NKP (60% - Pelajaran)',
      'icon': Icons.menu_book_rounded,
      'tahap': 'Pelajaran',
    },
    {
      'index': 4,
      'name': 'Keaktifan (60% - Simulasi)',
      'icon': Icons.lightbulb_rounded,
      'tahap': 'Simulasi',
    },
    {
      'index': 5,
      'name': 'Produk (20% - Simulasi)',
      'icon': Icons.lightbulb_rounded,
      'tahap': 'Simulasi',
    },
    {
      'index': 6,
      'name': 'Tata Ruang (20% - Simulasi)',
      'icon': Icons.lightbulb_rounded,
      'tahap': 'Simulasi',
    },
    {
      'index': 7,
      'name': 'Materi (40% - Taskap)',
      'icon': Icons.assignment_rounded,
      'tahap': 'Taskap',
    },
    {
      'index': 8,
      'name': 'Menulis (30% - Taskap)',
      'icon': Icons.assignment_rounded,
      'tahap': 'Taskap',
    },
    {
      'index': 9,
      'name': 'Paparan (30% - Taskap)',
      'icon': Icons.assignment_rounded,
      'tahap': 'Taskap',
    },
  ];

  static List<Map<String, dynamic>> getMentalKepribadian() => [
    {
      'index': 0,
      'name': 'Moral (20%)',
      'icon': Icons.psychology_alt_rounded,
      'tahap': 'Observasi Harian',
    },
    {
      'index': 1,
      'name': 'Disiplin (15%)',
      'icon': Icons.access_time_filled_rounded,
      'tahap': 'Observasi Harian',
    },
    {
      'index': 2,
      'name': 'Kepemimpinan (20%)',
      'icon': Icons.flag_circle_rounded,
      'tahap': 'Observasi Harian',
    },
    {
      'index': 3,
      'name': 'Pengendalian Diri (15%)',
      'icon': Icons.self_improvement_rounded,
      'tahap': 'Observasi Harian',
    },
    {
      'index': 4,
      'name': 'Penampilan (15%)',
      'icon': Icons.checkroom_rounded,
      'tahap': 'Observasi Harian',
    },
    {
      'index': 5,
      'name': 'Sosiometri Awal (Bobot 30%)',
      'icon': Icons.groups_rounded,
      'tahap': 'Sosiometri Awal',
    },
    {
      'index': 6,
      'name': 'Sosiometri Akhir (Bobot 30%)',
      'icon': Icons.groups_rounded,
      'tahap': 'Sosiometri Akhir',
    },
  ];

  static List<Map<String, dynamic>> getJasmani({
    required bool isWanita,
    required String currentRole,
  }) {
    List<Map<String, dynamic>> items = [
      {
        'index': 0,
        'name': 'Tes Kesehatan Awal',
        'icon': Icons.medical_services_rounded,
        'tahap': 'Tes Awal',
      },
      {
        'index': 1,
        'name': 'Tes Kesehatan Akhir',
        'icon': Icons.medical_services_rounded,
        'tahap': 'Tes Akhir',
      },
      {
        'index': 2,
        'name': 'Status Kesehatan',
        'icon': Icons.medical_services_rounded,
        'tahap': 'Harian',
      },
      {
        'index': 3,
        'name': 'Samapta A (Lari 12 Menit)',
        'icon': Icons.directions_run_rounded,
        'tahap': 'Samapta',
      },
      {
        'index': 4,
        'name': isWanita
            ? 'Samapta B (Chinning / Pull-up)'
            : 'Samapta B (Pull-up)',
        'icon': Icons.fitness_center_rounded,
        'tahap': 'Samapta',
      },
      {
        'index': 5,
        'name': 'Samapta B (Sit-up)',
        'icon': Icons.fitness_center_rounded,
        'tahap': 'Samapta',
      },
      {
        'index': 6,
        'name': 'Samapta B (Push-up)',
        'icon': Icons.fitness_center_rounded,
        'tahap': 'Samapta',
      },
      {
        'index': 7,
        'name': 'Samapta B (Shuttle Run)',
        'icon': Icons.fitness_center_rounded,
        'tahap': 'Samapta',
      },
    ];

    if (currentRole == 'Tim Medis') {
      items = items
          .where(
            (s) =>
                s['tahap'] == 'Tes Awal' ||
                s['tahap'] == 'Tes Akhir' ||
                s['tahap'] == 'Harian',
          )
          .toList();
    } else if (currentRole == 'Korsis' || currentRole == 'Gadik') {
      items = items.where((s) => s['tahap'] == 'Samapta').toList();
    }

    return items;
  }

  static List<String> getTahapOptions(String category, String currentRole) {
    if (category == 'Akademik') {
      return ['Semua', 'Pelajaran', 'Simulasi', 'Taskap'];
    }
    if (category == 'Mental Kepribadian') {
      return [
        'Semua',
        'Observasi Harian',
        'Sosiometri Awal',
        'Sosiometri Akhir',
      ];
    }
    if (currentRole == 'Tim Medis') {
      return ['Semua', 'Tes Awal', 'Tes Akhir', 'Harian'];
    }
    if (currentRole == 'Korsis') {
      return ['Semua', 'Samapta'];
    }
    return ['Semua', 'Tes Awal', 'Tes Akhir', 'Harian', 'Samapta'];
  }
}
