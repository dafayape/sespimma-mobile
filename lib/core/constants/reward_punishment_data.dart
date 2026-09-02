class RewardPunishmentItem {
  final String id;
  final String type;
  final String aspect;
  final String description;
  final double point;
  final String? note;

  const RewardPunishmentItem({
    required this.id,
    required this.type,
    required this.aspect,
    required this.description,
    required this.point,
    this.note,
  });
}

class RewardPunishmentData {
  static List<RewardPunishmentItem> rules = [];
  static bool _isLoaded = false;

  static const List<RewardPunishmentItem> _fallbackRules = [
    RewardPunishmentItem(
      id: 'R_M_01',
      type: 'REWARD',
      aspect: 'MORAL',
      description: 'Giat Keagamaan Mingguan',
      point: 0.25,
    ),
    RewardPunishmentItem(
      id: 'R_M_02',
      type: 'REWARD',
      aspect: 'MORAL',
      description: 'Memimpin Giat Keagamaan (Khutbah)',
      point: 0.50,
    ),
    RewardPunishmentItem(
      id: 'R_M_03',
      type: 'REWARD',
      aspect: 'MORAL',
      description: 'Bakti Lembaga',
      point: 0.25,
    ),
    RewardPunishmentItem(
      id: 'R_M_04',
      type: 'REWARD',
      aspect: 'MORAL',
      description: 'Memberikan Santunan (panti asuhan, warga dll)',
      point: 0.40,
      note: 'Maksimal 3x',
    ),
    RewardPunishmentItem(
      id: 'R_M_05',
      type: 'REWARD',
      aspect: 'MORAL',
      description: 'Memberikan Sumbangan Ke Masjid, Gereja, Pure',
      point: 0.38,
      note: 'Maksimal 3x',
    ),
    RewardPunishmentItem(
      id: 'R_M_06',
      type: 'REWARD',
      aspect: 'MORAL',
      description: 'Memberikan Sumbangan Buku Ke Perpustakaan',
      point: 0.30,
      note: 'Maksimal 3x',
    ),
    RewardPunishmentItem(
      id: 'R_M_07',
      type: 'REWARD',
      aspect: 'MORAL',
      description: 'Reward Pejabat Upacara',
      point: 0.30,
      note: 'Maksimal 3x',
    ),
    RewardPunishmentItem(
      id: 'R_M_08',
      type: 'REWARD',
      aspect: 'MORAL',
      description: 'Reward Pengucap Tribrata',
      point: 0.30,
    ),
    RewardPunishmentItem(
      id: 'R_M_09',
      type: 'REWARD',
      aspect: 'MORAL',
      description: 'Reward Pengucap Catur Prasetya',
      point: 0.30,
    ),
    RewardPunishmentItem(
      id: 'R_M_10',
      type: 'REWARD',
      aspect: 'MORAL',
      description: 'Reward Dirgen',
      point: 0.30,
    ),
    RewardPunishmentItem(
      id: 'R_M_11',
      type: 'REWARD',
      aspect: 'MORAL',
      description: 'Reward Pembaca Doa',
      point: 0.25,
    ),

    RewardPunishmentItem(
      id: 'R_D_01',
      type: 'REWARD',
      aspect: 'DISIPLIN',
      description: 'Selama Satu Bulan Tidak Ada Pelanggaran',
      point: 0.25,
    ),
    RewardPunishmentItem(
      id: 'R_D_02',
      type: 'REWARD',
      aspect: 'DISIPLIN',
      description: 'Danki Harian',
      point: 0.35,
    ),
    RewardPunishmentItem(
      id: 'R_D_03',
      type: 'REWARD',
      aspect: 'DISIPLIN',
      description: 'Pengibar Bendera',
      point: 0.25,
      note: 'NON SENAT',
    ),

    RewardPunishmentItem(
      id: 'R_K_01',
      type: 'REWARD',
      aspect: 'KEPEMIMPINAN',
      description:
          'Peserta Didik Yang Menjabat Sebagai Perangkat Senat Mendapatkan Reward Sesuai Keaktifan Dan Kontribusinya Setiap Dua Minggu Sekali Ditandai Dengan Rekomendasi Dari Patun',
      point: 0.25,
    ),
    RewardPunishmentItem(
      id: 'R_K_02',
      type: 'REWARD',
      aspect: 'KEPEMIMPINAN',
      description:
          'Mampu Menyelesaikan Tugas Dinas Sesuai Sprin Dengan Baik Dan Tuntas',
      point: 0.25,
    ),
    RewardPunishmentItem(
      id: 'R_K_03',
      type: 'REWARD',
      aspect: 'KEPEMIMPINAN',
      description: 'Menjadi Tim Perumus Seminar Sekolah',
      point: 0.25,
    ),
    RewardPunishmentItem(
      id: 'R_K_04',
      type: 'REWARD',
      aspect: 'KEPEMIMPINAN',
      description: 'Merumuskan Laporan Seminar Sekolah',
      point: 0.25,
    ),
    RewardPunishmentItem(
      id: 'R_K_05',
      type: 'REWARD',
      aspect: 'KEPEMIMPINAN',
      description: 'Kunjungan Perpustakaan',
      point: 0.15,
      note: '2X SEMINGGU',
    ),
    RewardPunishmentItem(
      id: 'R_K_06',
      type: 'REWARD',
      aspect: 'KEPEMIMPINAN',
      description:
          'Berani Tampil Menyelesaikan Permasalahan Yang Timbul Di Kalangan Teman-Temannya/Pokjarnya',
      point: 0.30,
    ),

    RewardPunishmentItem(
      id: 'R_PD_01',
      type: 'REWARD',
      aspect: 'PENGENDALIAN DIRI',
      description:
          'Loyal Untuk Mendukung Segala Bentuk Kegiatan Di Lingkungan Teman-Temannya/Pokjarnya',
      point: 0.30,
    ),

    RewardPunishmentItem(
      id: 'R_P_01',
      type: 'REWARD',
      aspect: 'PENAMPILAN',
      description: 'Peduli lingkungan / merawat lingkungan lembaga',
      point: 0.40,
    ),

    RewardPunishmentItem(
      id: 'P_M_01',
      type: 'PUNISHMENT',
      aspect: 'MORAL',
      description: 'Tidak Mau Mengakui Kesalahan / Kekurangan',
      point: -0.70,
    ),
    RewardPunishmentItem(
      id: 'P_M_02',
      type: 'PUNISHMENT',
      aspect: 'MORAL',
      description: 'Tidak Memberikan Keterangan Dengan Benar (Bohong)',
      point: -0.30,
    ),
    RewardPunishmentItem(
      id: 'P_M_03',
      type: 'PUNISHMENT',
      aspect: 'MORAL',
      description: 'Tidak Melaksanakan Giat Keagamaan Mingguan',
      point: -0.20,
    ),
    RewardPunishmentItem(
      id: 'P_M_04',
      type: 'PUNISHMENT',
      aspect: 'MORAL',
      description: 'Melanggar Norma Agama (Penistaan Agama)',
      point: -0.30,
    ),
    RewardPunishmentItem(
      id: 'P_M_05',
      type: 'PUNISHMENT',
      aspect: 'MORAL',
      description: 'Tidak Tertib Dalam Melaksanakan / Mengikuti Upacara',
      point: -0.50,
    ),
    RewardPunishmentItem(
      id: 'P_M_06',
      type: 'PUNISHMENT',
      aspect: 'MORAL',
      description: 'Tidak Melaksanakan Perintah Pimpinan',
      point: -0.50,
    ),
    RewardPunishmentItem(
      id: 'P_M_07',
      type: 'PUNISHMENT',
      aspect: 'MORAL',
      description: 'Menjadi Profokator / Memperkeruh Suasana Dalam Kelompok',
      point: -0.30,
    ),
    RewardPunishmentItem(
      id: 'P_M_08',
      type: 'PUNISHMENT',
      aspect: 'MORAL',
      description:
          'Melakukan Pembiaran Terhadap Perselisihan Yang Terjadi Dalam Kelompok',
      point: -0.30,
    ),

    RewardPunishmentItem(
      id: 'P_D_01',
      type: 'PUNISHMENT',
      aspect: 'DISIPLIN',
      description:
          'Tidak mengisi Daftar Hadir (face id) Setiap Kegiatan Tepat Pada Waktunya',
      point: -0.50,
    ),
    RewardPunishmentItem(
      id: 'P_D_02',
      type: 'PUNISHMENT',
      aspect: 'DISIPLIN',
      description:
          'Terlambat Mengikuti Kegiatan / Kuliah Tanpa Alasan Yang Bisa Dipertanggungjawabkan',
      point: -0.53,
    ),
    RewardPunishmentItem(
      id: 'P_D_03',
      type: 'PUNISHMENT',
      aspect: 'DISIPLIN',
      description:
          'Terlambat Kembali Pada Waktu Ijin / IBL Tanpa Alasan Yang Dapat Dipertanggungjawabkan (Pengembalian Kartu IBL)',
      point: -0.50,
    ),
    RewardPunishmentItem(
      id: 'P_D_04',
      type: 'PUNISHMENT',
      aspect: 'DISIPLIN',
      description: 'Terlambat Apel Pagi, Malam Dan Olga Pagi',
      point: -0.50,
    ),
    RewardPunishmentItem(
      id: 'P_D_05',
      type: 'PUNISHMENT',
      aspect: 'DISIPLIN',
      description:
          'Sengaja Tidak Mengikuti Kegiatan (Kuliah, Giat Pelatihan, Olah Raga, Giat Lain Yang Terjadwal) Tanpa Ijin / Bolos',
      point: -0.90,
    ),
    RewardPunishmentItem(
      id: 'P_D_06',
      type: 'PUNISHMENT',
      aspect: 'DISIPLIN',
      description: 'Sengaja Meninggalkan Kegiatan Sewaktu Kuliah Berlangsung',
      point: -0.30,
    ),
    RewardPunishmentItem(
      id: 'P_D_07',
      type: 'PUNISHMENT',
      aspect: 'DISIPLIN',
      description: 'Melanggar Ketentuan Menerima Tamu',
      point: -0.30,
    ),
    RewardPunishmentItem(
      id: 'P_D_08',
      type: 'PUNISHMENT',
      aspect: 'DISIPLIN',
      description: 'Melanggar Ketentuan Parkir Kendaraan',
      point: -0.30,
    ),
    RewardPunishmentItem(
      id: 'P_D_09',
      type: 'PUNISHMENT',
      aspect: 'DISIPLIN',
      description: 'Melanggar Ketentuan Ijin',
      point: -0.30,
    ),
    RewardPunishmentItem(
      id: 'P_D_10',
      type: 'PUNISHMENT',
      aspect: 'DISIPLIN',
      description: 'Melanggar Ketentuan Di Dormitori, Kamar, Ruang Makan',
      point: -0.30,
    ),
    RewardPunishmentItem(
      id: 'P_D_11',
      type: 'PUNISHMENT',
      aspect: 'DISIPLIN',
      description: 'Merokok Sambil Berjalan, Merokok Tidak Pada Tempatnya',
      point: -0.30,
    ),
    RewardPunishmentItem(
      id: 'P_D_12',
      type: 'PUNISHMENT',
      aspect: 'DISIPLIN',
      description: 'Tidak Mengikuti Kegiatan Pelatihan',
      point: -0.80,
    ),
    RewardPunishmentItem(
      id: 'P_D_13',
      type: 'PUNISHMENT',
      aspect: 'DISIPLIN',
      description: 'Berpakaian Tidak Sesuai Ketentuan',
      point: -0.50,
    ),
    RewardPunishmentItem(
      id: 'P_D_14',
      type: 'PUNISHMENT',
      aspect: 'DISIPLIN',
      description: 'Tidak Membuat/Mengumpulkan Resume Mata Pelajaran',
      point: -0.50,
    ),
    RewardPunishmentItem(
      id: 'P_D_15',
      type: 'PUNISHMENT',
      aspect: 'DISIPLIN',
      description:
          'Apabila Setelah Dilaksanakan Pengulangan/Pembuatan Ulang Resume (Remidial) Isi Resume Masih Kurang Tepat/Tidak Sesuai Dengan Materi Mata Pelajaran',
      point: -0.50,
    ),

    RewardPunishmentItem(
      id: 'P_K_01',
      type: 'PUNISHMENT',
      aspect: 'KEPEMIMPINAN',
      description: 'Membiarkan Kelompok Melakukan Pelanggaran',
      point: -0.50,
    ),
    RewardPunishmentItem(
      id: 'P_K_02',
      type: 'PUNISHMENT',
      aspect: 'KEPEMIMPINAN',
      description: 'Mengajak Kelompok Untuk Melakukan Pelanggaran',
      point: -0.50,
    ),
    RewardPunishmentItem(
      id: 'P_K_03',
      type: 'PUNISHMENT',
      aspect: 'KEPEMIMPINAN',
      description: 'Mengkritisi Tidak Proporsional (Asal Bunyi)',
      point: -1.00,
    ),
    RewardPunishmentItem(
      id: 'P_K_04',
      type: 'PUNISHMENT',
      aspect: 'KEPEMIMPINAN',
      description:
          'Menyuruh Orang Lain Untuk Mengerjakan Pekerjaan / Tugas Yang Dibebankan Kepadanya (Outsourching)',
      point: -0.50,
    ),
    RewardPunishmentItem(
      id: 'P_K_05',
      type: 'PUNISHMENT',
      aspect: 'KEPEMIMPINAN',
      description:
          'Waktu Jam Belajar Di Kelas Digunakan Untuk Kegiatan Lain Yang Tidak Bermanfaat',
      point: -0.40,
    ),
    RewardPunishmentItem(
      id: 'P_K_06',
      type: 'PUNISHMENT',
      aspect: 'KEPEMIMPINAN',
      description:
          'Mengganggu / Mencela Kegiatan Tentieur/Pencerahan Kepada Sesama Peserta Didik',
      point: -0.50,
    ),
    RewardPunishmentItem(
      id: 'P_K_07',
      type: 'PUNISHMENT',
      aspect: 'KEPEMIMPINAN',
      description:
          'Menggunakan Laptop Atau HP (Gadged) Yang Tidak Terkait Dengan Mata Pelajaran',
      point: -0.30,
    ),
    RewardPunishmentItem(
      id: 'P_K_08',
      type: 'PUNISHMENT',
      aspect: 'KEPEMIMPINAN',
      description:
          'Menulis Dan Atau Memviralkan Tulisan, Gambar Dan Video Yang Tidak Pantas Di Medsos',
      point: -0.50,
    ),
    RewardPunishmentItem(
      id: 'P_K_09',
      type: 'PUNISHMENT',
      aspect: 'KEPEMIMPINAN',
      description:
          'Acuh Tak Acuh / Masa Bodoh / Tidak Mau Bekerja Sama /Tidak Peduli Terhadap Kepentingan Organisasi',
      point: -0.31,
    ),
    RewardPunishmentItem(
      id: 'P_K_10',
      type: 'PUNISHMENT',
      aspect: 'KEPEMIMPINAN',
      description: 'Melempar Tanggung Jawab',
      point: -0.50,
    ),
    RewardPunishmentItem(
      id: 'P_K_11',
      type: 'PUNISHMENT',
      aspect: 'KEPEMIMPINAN',
      description:
          'Menyampaikan Informasi Yang Belum Pasti Kebenarannya atau Tidak Berdasarkan',
      point: -0.50,
    ),
    RewardPunishmentItem(
      id: 'P_K_12',
      type: 'PUNISHMENT',
      aspect: 'KEPEMIMPINAN',
      description: 'Tidak Mau Berpartisipasi Untuk Kepentingan Bersama',
      point: -0.50,
    ),
    RewardPunishmentItem(
      id: 'P_K_13',
      type: 'PUNISHMENT',
      aspect: 'KEPEMIMPINAN',
      description: 'Tidak Mau Diingatkan / Dimotivasi Untuk Patuh',
      point: -0.50,
    ),

    RewardPunishmentItem(
      id: 'P_PD_01',
      type: 'PUNISHMENT',
      aspect: 'PENGENDALIAN DIRI',
      description:
          'Tidak Mampu Mengendalikan Amarah, Mudah Tersinggung Dan Sulit Memaafkan',
      point: -0.90,
    ),
    RewardPunishmentItem(
      id: 'P_PD_02',
      type: 'PUNISHMENT',
      aspect: 'PENGENDALIAN DIRI',
      description:
          'Berbicara Tidak Sesuai Tugasnya / Porsi Yang Ada Padanya/Celometan',
      point: -0.53,
    ),
    RewardPunishmentItem(
      id: 'P_PD_03',
      type: 'PUNISHMENT',
      aspect: 'PENGENDALIAN DIRI',
      description:
          'Mengeluarkan Kata-Kata Kotor / Menyinggung Perasaan Orang Lain Dan Bersikap Arogan',
      point: -0.50,
    ),
    RewardPunishmentItem(
      id: 'P_PD_04',
      type: 'PUNISHMENT',
      aspect: 'PENGENDALIAN DIRI',
      description:
          'Sering Mengantuk/Tidur Pada Saat Mengikuti Kegiatan Kuliah/Ceramah',
      point: -0.60,
    ),
    RewardPunishmentItem(
      id: 'P_PD_05',
      type: 'PUNISHMENT',
      aspect: 'PENGENDALIAN DIRI',
      description:
          'Selalu Menolak Kritik / Saran / Pendapat Yang Baik Dan Proporsional',
      point: -0.30,
    ),
    RewardPunishmentItem(
      id: 'P_PD_06',
      type: 'PUNISHMENT',
      aspect: 'PENGENDALIAN DIRI',
      description: 'Pemborosan Terhadap Sarpras Dinas',
      point: -0.15,
    ),
    RewardPunishmentItem(
      id: 'P_PD_07',
      type: 'PUNISHMENT',
      aspect: 'PENGENDALIAN DIRI',
      description:
          'Tidak Membudayakan Diri Untuk Mandiri/Selalu Minta Dilayani (Membawa Ajudan / Staf Khusus)',
      point: -0.15,
    ),

    RewardPunishmentItem(
      id: 'P_P_01',
      type: 'PUNISHMENT',
      aspect: 'PENAMPILAN',
      description: 'Rambut, Kumis, Jambang, Dan Jenggot Tidak Rapi',
      point: -0.25,
    ),
    RewardPunishmentItem(
      id: 'P_P_02',
      type: 'PUNISHMENT',
      aspect: 'PENAMPILAN',
      description:
          'Pakaian, Sepatu, Atribut Tidak Bersih, Tidak Rapi Dan Berwarna Mencolok Serta Tidak Sesuai Dengan Ketentuan',
      point: -0.20,
    ),
    RewardPunishmentItem(
      id: 'P_P_03',
      type: 'PUNISHMENT',
      aspect: 'PENAMPILAN',
      description:
          'Tidak Melengkapi Identitas Diri (KTA, KTP Dan SIM) Dan Tidak Menggunakan Kelengkapan Atribut Gampol',
      point: -0.25,
    ),
    RewardPunishmentItem(
      id: 'P_P_04',
      type: 'PUNISHMENT',
      aspect: 'PENAMPILAN',
      description:
          'Memakai Accesoris Badan Berlebihan (Akar Bahar, Kalung, Cincin, Anting Dll) Yang Tidak Sesuai Dengan Ketentuan Gampol',
      point: -0.30,
    ),
    RewardPunishmentItem(
      id: 'P_P_05',
      type: 'PUNISHMENT',
      aspect: 'PENAMPILAN',
      description:
          'Lantai, Dinding, Kamar Mandi Dan Kelengkapan Kamar Lainnya Kotor, Tidak Rapih Dan Tidak Terawat Dengan Baik',
      point: -0.53,
    ),
    RewardPunishmentItem(
      id: 'P_P_06',
      type: 'PUNISHMENT',
      aspect: 'PENAMPILAN',
      description:
          'Memasang / Menempel Foto, Pamplet, Gambar Porno, Dll Pada Dinding Kamar Yang Tidak Sesuai Dengan Ketentuan',
      point: -0.30,
    ),
    RewardPunishmentItem(
      id: 'P_P_07',
      type: 'PUNISHMENT',
      aspect: 'PENAMPILAN',
      description: 'Menjemur Pakaian Tidak Pada Tempatnya',
      point: -0.25,
    ),
    RewardPunishmentItem(
      id: 'P_P_08',
      type: 'PUNISHMENT',
      aspect: 'PENAMPILAN',
      description:
          'Tidak Memelihara Dan Menjaga Kebersihan Ruang Kelas Dan Lembaga',
      point: -0.40,
    ),
  ];

  static Future<void> loadFromApi(dynamic dataSource) async {
    if (_isLoaded && rules.isNotEmpty) return;
    try {
      final prestasis = await dataSource.getPoints('prestasi');
      final pelanggarans = await dataSource.getPoints('pelanggaran');

      List<RewardPunishmentItem> newRules = [];

      String mapAspect(int? mentalComponentId) {
        switch (mentalComponentId) {
          case 1:
            return 'MORAL';
          case 2:
            return 'DISIPLIN';
          case 3:
            return 'KEPEMIMPINAN';
          case 4:
            return 'PENGENDALIAN DIRI';
          case 5:
            return 'PENAMPILAN';
          default:
            return 'UMUM';
        }
      }

      for (var p in prestasis) {
        String? ket = p['keterangan'] ?? p['note'] ?? p['specialRule'];
        if (ket == null || ket == '-') {
          final maxCount = p['maxCount'];
          if (maxCount != null && maxCount is int && maxCount > 0) {
            ket = 'Maksimal ${maxCount}x';
          }
        }
        final aspectName = (p['aspek'] != null && (p['aspek'] as String).isNotEmpty)
            ? (p['aspek'] as String)
            : mapAspect(p['mentalComponentId']);

        newRules.add(RewardPunishmentItem(
          id: p['id'].toString(),
          type: 'REWARD',
          aspect: aspectName,
          description: p['name'] ?? p['description'] ?? p['kegiatan'] ?? '',
          point: (p['points'] as num).toDouble(),
          note: ket != null && ket != '-' ? ket : null,
        ));
      }

      for (var p in pelanggarans) {
        String? ket = p['keterangan'] ?? p['note'] ?? p['specialRule'];
        if (ket == null || ket == '-') {
          final maxCount = p['maxCount'];
          if (maxCount != null && maxCount is int && maxCount > 0) {
            ket = 'Maksimal ${maxCount}x';
          }
        }
        final aspectName = (p['aspek'] != null && (p['aspek'] as String).isNotEmpty)
            ? (p['aspek'] as String)
            : mapAspect(p['mentalComponentId']);

        newRules.add(RewardPunishmentItem(
          id: p['id'].toString(),
          type: 'PUNISHMENT',
          aspect: aspectName,
          description: p['name'] ?? p['description'] ?? p['activity'] ?? '',
          point: (p['points'] as num).toDouble(),
          note: ket != null && ket != '-' ? ket : null,
        ));
      }

      if (newRules.isNotEmpty) {
        rules = newRules;
      } else {
        rules = List.from(_fallbackRules);
      }
      _isLoaded = true;
    } catch (e) {
      // print('Failed to load points from API: $e');
      if (rules.isEmpty) {
        rules = List.from(_fallbackRules);
      }
      _isLoaded = true;
    }
  }

  static List<RewardPunishmentItem> get rewards =>
      rules.where((r) => r.type == 'REWARD').toList();

  static List<RewardPunishmentItem> get punishments =>
      rules.where((r) => r.type == 'PUNISHMENT').toList();

  static List<RewardPunishmentItem> getByAspect(String aspect) =>
      rules.where((r) => r.aspect == aspect).toList();
}
