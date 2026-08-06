import 'package:sespimma/core/constants/app_dimensions.dart';
import 'package:flutter/material.dart';
import 'package:sespimma/core/utils/app_notifier.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sespimma/features/leadership_dashboard/data/datasources/pimpinan_mock_data.dart';
import 'package:sespimma/core/utils/avatar_helper.dart';

class LookupSelectionDialog extends StatefulWidget {
  const LookupSelectionDialog({super.key});

  @override
  State<LookupSelectionDialog> createState() => _LookupSelectionDialogState();
}

class _LookupSelectionDialogState extends State<LookupSelectionDialog>
    with SingleTickerProviderStateMixin {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _animController.forward();
  }

  static const Color _primaryNavy = Color(0xFF001C40);
  static const Color _lightGrey = Color(0xFFF8F9FA);
  static const Color _successGreen = Color(0xFF2E7D32);
  static const Color _dangerRed = Color(0xFFD32F2F);

  final List<Map<String, dynamic>> _mockRewards = [
    {
      'id': 'R1',
      'tipe': 'Moral',
      'deskripsi': 'Menjadi Imam Shalat',
      'poin': 0.50,
    },
    {
      'id': 'R2',
      'tipe': 'Moral',
      'deskripsi': 'Menjadi Khotib / Memimpin Kebaktian / Dharma Wacana',
      'poin': 0.40,
    },
    {
      'id': 'R3',
      'tipe': 'Moral',
      'deskripsi': 'Membaca Doa Apel / Mengumandangkan Adzan',
      'poin': 0.25,
    },
    {
      'id': 'R4',
      'tipe': 'Moral',
      'deskripsi': 'Bakti Lembaga',
      'poin': 0.25,
      'limit': 3,
      'usage': 3,
    },
    {
      'id': 'R5',
      'tipe': 'Moral',
      'deskripsi': 'Memberikan Santunan (Panti Asuhan/Warga)',
      'poin': 0.40,
      'limit': 3,
      'usage': 1,
    },
    {
      'id': 'R6',
      'tipe': 'Moral',
      'deskripsi': 'Sumbangan Ke Tempat Ibadah',
      'poin': 0.38,
      'limit': 3,
      'usage': 0,
    },
    {
      'id': 'R7',
      'tipe': 'Moral',
      'deskripsi': 'Menyumbang Buku ke Perpustakaan',
      'poin': 0.30,
      'limit': 3,
      'usage': 2,
    },
    {
      'id': 'R8',
      'tipe': 'Moral',
      'deskripsi': 'Menjadi Pejabat Upacara',
      'poin': 0.30,
    },
    {
      'id': 'R9',
      'tipe': 'Moral',
      'deskripsi': 'Pengucap Tri Brata / Catur Prasetya dengan Benar',
      'poin': 0.30,
    },
    {
      'id': 'R10',
      'tipe': 'Disiplin',
      'deskripsi': 'Satu Bulan Tanpa Pelanggaran',
      'poin': 0.25,
    },
    {
      'id': 'R11',
      'tipe': 'Disiplin',
      'deskripsi': 'Menjadi Danki Harian',
      'poin': 0.35,
    },
    {
      'id': 'R12',
      'tipe': 'Disiplin',
      'deskripsi': 'Menjadi Danton Harian',
      'poin': 0.30,
    },
    {
      'id': 'R13',
      'tipe': 'Disiplin',
      'deskripsi': 'Menjadi Pengibar Bendera',
      'poin': 0.25,
    },
    {
      'id': 'R14',
      'tipe': 'Kepemimpinan',
      'deskripsi': 'Menjabat Perangkat Senat',
      'poin': 0.25,
    },
    {
      'id': 'R15',
      'tipe': 'Kepemimpinan',
      'deskripsi': 'Menyelesaikan Tugas Dinas sesuai Sprin secara tuntas',
      'poin': 0.25,
    },
    {
      'id': 'R16',
      'tipe': 'Kepemimpinan',
      'deskripsi': 'Menjadi Tim Perumus / Pelapor Seminar Sekolah',
      'poin': 0.25,
    },
    {
      'id': 'R17',
      'tipe': 'Kepemimpinan',
      'deskripsi': 'Kunjungan Perpustakaan',
      'poin': 0.15,
      'limitWeek': 2,
      'usageWeek': 2,
    },
    {
      'id': 'R18',
      'tipe': 'Kepemimpinan',
      'deskripsi': 'Menyelesaikan Masalah di Kelompok/POKJAR',
      'poin': 0.30,
    },
    {
      'id': 'R19',
      'tipe': 'Pengendalian Diri',
      'deskripsi': 'Loyalitas Mendukung Kegiatan Kelompok/POKJAR',
      'poin': 0.30,
    },
    {
      'id': 'R20',
      'tipe': 'Penampilan',
      'deskripsi': 'Peduli dan Merawat Lingkungan Lembaga',
      'poin': 0.40,
    },
  ];

  final List<Map<String, dynamic>> _mockPunishments = [
    {
      'id': 'P1',
      'tipe': 'Moral',
      'deskripsi': 'Tidak Mau Mengakui Kesalahan / Kekurangan',
      'poin': -0.70,
    },
    {
      'id': 'P2',
      'tipe': 'Moral',
      'deskripsi': 'Berbohong / Tidak Memberikan Keterangan Benar',
      'poin': -0.30,
    },
    {
      'id': 'P3',
      'tipe': 'Moral',
      'deskripsi': 'Tidak Melaksanakan Giat Agama Mingguan',
      'poin': -0.20,
    },
    {
      'id': 'P4',
      'tipe': 'Moral',
      'deskripsi': 'Melanggar Norma Agama (Penistaan)',
      'poin': -0.30,
    },
    {
      'id': 'P5',
      'tipe': 'Moral',
      'deskripsi': 'Tidak Tertib / Tidak Mengikuti Upacara',
      'poin': -0.50,
    },
    {
      'id': 'P6',
      'tipe': 'Moral',
      'deskripsi': 'Tidak Melaksanakan Perintah Pimpinan',
      'poin': -0.50,
    },
    {
      'id': 'P7',
      'tipe': 'Moral',
      'deskripsi': 'Menjadi Provokator / Memperkeruh Suasana',
      'poin': -0.30,
    },
    {
      'id': 'P8',
      'tipe': 'Moral',
      'deskripsi': 'Pembiaran terhadap Perselisihan Kelompok',
      'poin': -0.30,
    },
    {
      'id': 'P9',
      'tipe': 'Disiplin',
      'deskripsi': 'Tidak Mengisi Absensi (Face ID) tepat waktu',
      'poin': -0.50,
    },
    {
      'id': 'P10',
      'tipe': 'Disiplin',
      'deskripsi': 'Terlambat Kuliah / Kegiatan (Tanpa Alasan)',
      'poin': -0.53,
    },
    {
      'id': 'P11',
      'tipe': 'Disiplin',
      'deskripsi': 'Terlambat Kembali Izin / IBL',
      'poin': -0.50,
    },
    {
      'id': 'P12',
      'tipe': 'Disiplin',
      'deskripsi': 'Terlambat Apel Pagi, Malam, atau Olahraga Pagi',
      'poin': -0.50,
    },
    {
      'id': 'P13',
      'tipe': 'Disiplin',
      'deskripsi': 'Sengaja Tidak Ikut Kegiatan / Bolos',
      'poin': -0.90,
    },
    {
      'id': 'P14',
      'tipe': 'Disiplin',
      'deskripsi': 'Meninggalkan Kuliah saat Berlangsung',
      'poin': -0.30,
    },
    {
      'id': 'P15',
      'tipe': 'Disiplin',
      'deskripsi': 'Melanggar Ketentuan Izin / Tamu / Parkir / Dormitori',
      'poin': -0.30,
    },
    {
      'id': 'P16',
      'tipe': 'Disiplin',
      'deskripsi': 'Merokok Sambil Berjalan / Tidak pada Tempatnya',
      'poin': -0.30,
    },
    {
      'id': 'P17',
      'tipe': 'Disiplin',
      'deskripsi': 'Tidak Mengikuti Kegiatan Pelatihan',
      'poin': -0.80,
    },
    {
      'id': 'P18',
      'tipe': 'Disiplin',
      'deskripsi': 'Pakaian / Gampol Tidak Sesuai Ketentuan',
      'poin': -0.50,
    },
    {
      'id': 'P19',
      'tipe': 'Disiplin',
      'deskripsi': 'Tidak Membuat/Mengumpulkan Resume Mata Pelajaran',
      'poin': -0.50,
    },
    {
      'id': 'P20',
      'tipe': 'Disiplin',
      'deskripsi': 'Gagal Perbaikan Resume (Remedial)',
      'poin': -0.50,
    },
    {
      'id': 'P21',
      'tipe': 'Kepemimpinan',
      'deskripsi': 'Membiarkan / Mengajak Kelompok Melanggar',
      'poin': -0.50,
    },
    {
      'id': 'P22',
      'tipe': 'Kepemimpinan',
      'deskripsi': 'Mengkritisi Tidak Proporsional (Asal Bunyi)',
      'poin': -1.00,
    },
    {
      'id': 'P23',
      'tipe': 'Kepemimpinan',
      'deskripsi': 'Menyuruh Orang Lain Mengerjakan Tugasnya',
      'poin': -0.50,
    },
    {
      'id': 'P24',
      'tipe': 'Kepemimpinan',
      'deskripsi': 'Jam Belajar Digunakan untuk Hal Tidak Bermanfaat',
      'poin': -0.40,
    },
    {
      'id': 'P25',
      'tipe': 'Kepemimpinan',
      'deskripsi': 'Menggunakan Gadget/Laptop tidak terkait Pelajaran',
      'poin': -0.30,
    },
    {
      'id': 'P26',
      'tipe': 'Kepemimpinan',
      'deskripsi': 'Posting Konten Tidak Pantas di Medsos',
      'poin': -0.50,
    },
    {
      'id': 'P27',
      'tipe': 'Kepemimpinan',
      'deskripsi': 'Acuh Tak Acuh / Tidak Mau Bekerja Sama',
      'poin': -0.31,
    },
    {
      'id': 'P28',
      'tipe': 'Kepemimpinan',
      'deskripsi': 'Melempar Tanggung Jawab',
      'poin': -0.50,
    },
    {
      'id': 'P29',
      'tipe': 'Pengendalian Diri',
      'deskripsi': 'Tidak Mampu Kendali Amarah / Mudah Tersinggung',
      'poin': -0.90,
    },
    {
      'id': 'P30',
      'tipe': 'Pengendalian Diri',
      'deskripsi': 'Berbicara Tidak Sopan / Celometan / Arogan',
      'poin': -0.53,
    },
    {
      'id': 'P31',
      'tipe': 'Pengendalian Diri',
      'deskripsi': 'Sering Mengantuk / Tidur saat Kuliah',
      'poin': -0.60,
    },
    {
      'id': 'P32',
      'tipe': 'Pengendalian Diri',
      'deskripsi': 'Membawa Kendaraan Pribadi',
      'poin': -0.50,
    },
    {
      'id': 'P33',
      'tipe': 'Pengendalian Diri',
      'deskripsi': 'Menolak Kritik / Saran yang Baik',
      'poin': -0.30,
    },
    {
      'id': 'P34',
      'tipe': 'Pengendalian Diri',
      'deskripsi': 'Boros Sarpras Dinas / Tidak Mandiri',
      'poin': -0.15,
    },
    {
      'id': 'P35',
      'tipe': 'Penampilan',
      'deskripsi': 'Rambut, Kumis, Jambang, Jenggot Tidak Rapi',
      'poin': -0.25,
    },
    {
      'id': 'P36',
      'tipe': 'Penampilan',
      'deskripsi': 'Atribut Kotor / Tidak Lengkap',
      'poin': -0.20,
    },
    {
      'id': 'P37',
      'tipe': 'Penampilan',
      'deskripsi': 'Memakai Aksesoris Berlebihan',
      'poin': -0.30,
    },
    {
      'id': 'P38',
      'tipe': 'Penampilan',
      'deskripsi': 'Kamar / Dormitori Kotor dan Tidak Terawat',
      'poin': -0.53,
    },
    {
      'id': 'P39',
      'tipe': 'Penampilan',
      'deskripsi': 'Menjemur Pakaian Tidak pada Tempatnya',
      'poin': -0.25,
    },
    {
      'id': 'P40',
      'tipe': 'Penampilan',
      'deskripsi': 'Buang Sampah / Puntung Rokok Sembarangan',
      'poin': -0.40,
    },
  ];

  @override
  void dispose() {
    _animController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _confirmSelection(
    BuildContext context,
    Map<String, dynamic> item,
    Map<String, dynamic> serdik,
    bool isReward,
  ) {
    showDialog(
      context: context,
      builder: (context) => _ConfirmSelectionDialog(
        item: item,
        serdik: serdik,
        isReward: isReward,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final bool isReward = args?['type'] == 'reward';
    final Map<String, dynamic> serdik =
        args?['serdik'] ?? {'name': 'Serdik', 'nrp': '-'};

    final List<Map<String, dynamic>> sourceList = isReward
        ? _mockRewards
        : _mockPunishments;
    final filteredList = sourceList.where((item) {
      final descLower = item['deskripsi'].toLowerCase();
      final typeLower = item['tipe'].toLowerCase();
      final queryLower = _searchQuery.toLowerCase();
      return descLower.contains(queryLower) || typeLower.contains(queryLower);
    }).toList();

    return Scaffold(
      backgroundColor: _lightGrey,
      appBar: AppBar(
        backgroundColor: _primaryNavy,
        elevation: 0,
        centerTitle: true,
        title: Text(
          isReward ? 'Indikator Pujian' : 'Indikator Teguran',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: AppDimensions.fontXl,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Container(
            color: _primaryNavy,
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      backgroundImage: AvatarHelper.getAvatar(
                        serdik['profile_photo'] ?? serdik['profilePhoto'],
                      ),
                    ),
                    const SizedBox(width: AppDimensions.md - 4),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Target Penilaian:',
                            style: TextStyle(
                              fontSize: AppDimensions.fontSm + 1,
                              color: Colors.blueGrey.shade200,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${serdik['name']} • ${serdik['nrp']}',
                            style: const TextStyle(
                              fontSize: AppDimensions.fontLg,
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: _buildSearchBar(),
          ),
          Divider(height: 1, color: Colors.grey.shade200, thickness: 1),
          Expanded(
            child: filteredList.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 20,
                    ),
                    itemCount: filteredList.length,
                    itemBuilder: (context, index) {
                      final animation = CurvedAnimation(
                        parent: _animController,
                        curve: Interval(
                          (index /
                                  (filteredList.isEmpty
                                      ? 1
                                      : filteredList.length))
                              .clamp(0.0, 1.0),
                          1.0,
                          curve: Curves.easeOutCubic,
                        ),
                      );
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.2),
                            end: Offset.zero,
                          ).animate(animation),
                          child: _buildLookupTile(
                            context,
                            filteredList[index],
                            serdik,
                            isReward,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: _lightGrey,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd + 2),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() => _searchQuery = value),
        style: const TextStyle(fontSize: AppDimensions.fontDefault),
        decoration: InputDecoration(
          hintText: 'Cari indikator perilaku...',
          hintStyle: TextStyle(
            color: Colors.blueGrey.shade300,
            fontSize: AppDimensions.fontDefault,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: Colors.blueGrey.shade400,
            size: AppDimensions.iconDefault,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.close_rounded,
                    color: Colors.blueGrey.shade400,
                    size: AppDimensions.iconSm,
                  ),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.find_in_page_rounded,
            size: AppDimensions.iconDisplay,
            color: Colors.blueGrey.shade200,
          ),
          const SizedBox(height: AppDimensions.md),
          Text(
            'Indikator tidak ditemukan',
            style: TextStyle(
              fontSize: AppDimensions.fontLg + 1,
              fontWeight: FontWeight.w700,
              color: Colors.blueGrey.shade400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLookupTile(
    BuildContext context,
    Map<String, dynamic> item,
    Map<String, dynamic> serdik,
    bool isReward,
  ) {
    final int? limit = item['limit'] as int?;
    final int? usage = item['usage'] as int?;
    final int? limitWeek = item['limitWeek'] as int?;
    final int? usageWeek = item['usageWeek'] as int?;

    bool isBlocked = false;
    String limitLabel = "";
    String usageLabel = "";

    if (limit != null && usage != null) {
      limitLabel = "Maksimal $limit Kali";
      usageLabel = "Digunakan: $usage/$limit";
      if (usage >= limit) {
        isBlocked = true;
      }
    } else if (limitWeek != null && usageWeek != null) {
      limitLabel = "$limitWeek Kali / Minggu";
      usageLabel = "Minggu Ini: $usageWeek/$limitWeek";
      if (usageWeek >= limitWeek) {
        isBlocked = true;
      }
    }

    final Color itemColor = isBlocked
        ? Colors.grey.shade400
        : (isReward ? _successGreen : _dangerRed);
    final IconData itemIcon = isReward
        ? Icons.stars_rounded
        : Icons.warning_rounded;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isBlocked ? Colors.grey.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(
          color: isBlocked ? Colors.grey.shade300 : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        child: Opacity(
          opacity: isBlocked ? 0.65 : 1.0,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
            onTap: isBlocked
                ? null
                : () => _confirmSelection(context, item, serdik, isReward),
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.md),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppDimensions.sm + 2),
                    decoration: BoxDecoration(
                      color: itemColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isBlocked ? Icons.lock_outline_rounded : itemIcon,
                      color: itemColor,
                      size: AppDimensions.iconLg,
                    ),
                  ),
                  const SizedBox(width: AppDimensions.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['deskripsi'],
                          style: TextStyle(
                            fontSize: AppDimensions.fontLg,
                            fontWeight: FontWeight.w700,
                            color: isBlocked
                                ? Colors.blueGrey.shade400
                                : _primaryNavy,
                            decoration: isBlocked
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                        const SizedBox(height: AppDimensions.radiusSm),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: isBlocked
                                    ? Colors.grey.shade200
                                    : Colors.blueGrey.shade50,
                                borderRadius: BorderRadius.circular(
                                  AppDimensions.radiusSm,
                                ),
                                border: Border.all(
                                  color: isBlocked
                                      ? Colors.grey.shade300
                                      : Colors.blueGrey.shade100,
                                ),
                              ),
                              child: Text(
                                item['tipe'].toUpperCase(),
                                style: TextStyle(
                                  fontSize: AppDimensions.fontSm,
                                  fontWeight: FontWeight.w800,
                                  color: isBlocked
                                      ? Colors.grey.shade600
                                      : Colors.blueGrey.shade600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            if (limitLabel.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: isBlocked
                                      ? Colors.red.shade50
                                      : Colors.amber.shade50,
                                  borderRadius: BorderRadius.circular(
                                    AppDimensions.radiusSm,
                                  ),
                                  border: Border.all(
                                    color: isBlocked
                                        ? Colors.red.shade100
                                        : Colors.amber.shade200,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isBlocked
                                          ? Icons.error_outline
                                          : Icons.info_outline,
                                      size: 10,
                                      color: isBlocked
                                          ? Colors.red.shade700
                                          : Colors.amber.shade800,
                                    ),
                                    const SizedBox(width: AppDimensions.xs),
                                    Flexible(
                                      child: Text(
                                        isBlocked
                                            ? "BATAS TERCAPAI ($usageLabel)"
                                            : usageLabel,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: AppDimensions.fontSm,
                                          fontWeight: FontWeight.w800,
                                          color: isBlocked
                                              ? Colors.red.shade700
                                              : Colors.amber.shade800,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppDimensions.md - 4),
                  Text(
                    isReward ? '+${item['poin']}' : '${item['poin']}',
                    style: TextStyle(
                      fontSize: AppDimensions.fontXl,
                      fontWeight: FontWeight.w800,
                      color: itemColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ConfirmSelectionDialog extends StatefulWidget {
  final Map<String, dynamic> item;
  final Map<String, dynamic> serdik;
  final bool isReward;

  const _ConfirmSelectionDialog({
    required this.item,
    required this.serdik,
    required this.isReward,
  });

  @override
  State<_ConfirmSelectionDialog> createState() =>
      _ConfirmSelectionDialogState();
}

class _ConfirmSelectionDialogState extends State<_ConfirmSelectionDialog> {
  String? _selectedImagePath;
  final TextEditingController _justifikasiController = TextEditingController();

  static const Color _primaryNavy = Color(0xFF001C40);
  static const Color _successGreen = Color(0xFF2E7D32);
  static const Color _dangerRed = Color(0xFFD32F2F);

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _justifikasiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isReward = widget.isReward;
    final Map<String, dynamic> item = widget.item;
    final Map<String, dynamic> serdik = widget.serdik;

    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
      ),
      title: Text(
        'Konfirmasi ${isReward ? 'Pujian' : 'Teguran'}',
        style: const TextStyle(
          fontSize: AppDimensions.fontXxl,
          fontWeight: FontWeight.w800,
          color: _primaryNavy,
        ),
      ),
      content: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Anda akan memberikan ${isReward ? 'pujian' : 'teguran'} kepada:',
              style: TextStyle(
                fontSize: AppDimensions.fontDefault,
                fontWeight: FontWeight.w500,
                color: Colors.blueGrey.shade600,
              ),
            ),
            const SizedBox(height: AppDimensions.sm),
            Text(
              '${serdik['name']} (${serdik['nrp']})',
              style: const TextStyle(
                fontSize: AppDimensions.fontLg,
                fontWeight: FontWeight.w800,
                color: _primaryNavy,
              ),
            ),
            const SizedBox(height: AppDimensions.md),
            Container(
              padding: const EdgeInsets.all(AppDimensions.md),
              decoration: BoxDecoration(
                color: isReward
                    ? _successGreen.withValues(alpha: 0.1)
                    : _dangerRed.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                border: Border.all(
                  color: isReward
                      ? _successGreen.withValues(alpha: 0.3)
                      : _dangerRed.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isReward ? Icons.stars_rounded : Icons.warning_rounded,
                    color: isReward ? _successGreen : _dangerRed,
                    size: AppDimensions.iconLg,
                  ),
                  const SizedBox(width: AppDimensions.md - 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['deskripsi'],
                          style: const TextStyle(
                            fontSize: AppDimensions.fontDefault,
                            fontWeight: FontWeight.w700,
                            color: _primaryNavy,
                          ),
                        ),
                        const SizedBox(height: AppDimensions.xs),
                        Text(
                          isReward
                              ? '+${item['poin']} Poin'
                              : '${item['poin']} Poin',
                          style: TextStyle(
                            fontSize: AppDimensions.fontLg,
                            fontWeight: FontWeight.w800,
                            color: isReward ? _successGreen : _dangerRed,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimensions.xl),
            Text(
              'Bukti Lampiran (Wajib)',
              style: TextStyle(
                fontSize: AppDimensions.fontDefault,
                fontWeight: FontWeight.w600,
                color: Colors.blueGrey.shade700,
              ),
            ),
            const SizedBox(height: AppDimensions.sm),
            InkWell(
              onTap: () async {
                try {
                  final picker = ImagePicker();
                  final pickedFile = await picker.pickImage(
                    source: ImageSource.camera,
                    maxWidth: 1024,
                    maxHeight: 1024,
                    imageQuality: 85,
                  );
                  if (pickedFile != null) {
                    setState(() {
                      _selectedImagePath = pickedFile.path;
                    });
                  }
                } catch (e) {
                  debugPrint('Image picker error: $e');
                }
              },
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: _selectedImagePath != null
                      ? _successGreen.withValues(alpha: 0.1)
                      : Colors.blueGrey.shade50,
                  border: Border.all(
                    color: _selectedImagePath != null
                        ? _successGreen
                        : Colors.blueGrey.shade200,
                  ),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                ),
                child: Row(
                  children: [
                    Icon(
                      _selectedImagePath != null
                          ? Icons.image_rounded
                          : Icons.camera_alt_rounded,
                      color: _selectedImagePath != null
                          ? _successGreen
                          : Colors.blueGrey.shade400,
                      size: AppDimensions.iconDefault,
                    ),
                    const SizedBox(width: AppDimensions.md - 4),
                    Expanded(
                      child: Text(
                        _selectedImagePath != null
                            ? 'Bukti berhasil dilampirkan'
                            : 'Ambil Foto Bukti...',
                        style: TextStyle(
                          fontSize: AppDimensions.fontDefault,
                          fontWeight: FontWeight.w600,
                          color: _selectedImagePath != null
                              ? _successGreen
                              : Colors.blueGrey.shade500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppDimensions.md),
            Text(
              'Keterangan Justifikasi',
              style: TextStyle(
                fontSize: AppDimensions.fontDefault,
                fontWeight: FontWeight.w600,
                color: Colors.blueGrey.shade700,
              ),
            ),
            const SizedBox(height: AppDimensions.sm),
            Container(
              decoration: BoxDecoration(
                color: Colors.blueGrey.shade50,
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                border: Border.all(color: Colors.blueGrey.shade200),
              ),
              child: TextField(
                controller: _justifikasiController,
                maxLines: 4,
                minLines: 3,
                textInputAction: TextInputAction.newline,
                style: const TextStyle(
                  fontSize: AppDimensions.fontDefault,
                  fontWeight: FontWeight.w500,
                  color: _primaryNavy,
                ),
                decoration: InputDecoration(
                  hintText:
                      'Deskripsikan kejadian, waktu, lokasi, atau kronologi singkat...',
                  hintStyle: TextStyle(
                    fontSize: AppDimensions.fontMd,
                    color: Colors.blueGrey.shade400,
                    fontWeight: FontWeight.w400,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(AppDimensions.md),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: Text(
            'BATAL',
            style: TextStyle(
              color: Colors.blueGrey.shade500,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: _selectedImagePath == null
              ? null
              : () {
                  final double pointChange = (item['poin'] as num).toDouble();
                  final index = PimpinanMockData.sharedReportData.indexWhere(
                    (r) => r.nrp == serdik['nrp'],
                  );
                  if (index != -1) {
                    final current = PimpinanMockData.sharedReportData[index];
                    final double newScore = (current.mentalScore + pointChange)
                        .clamp(0.0, 100.0);
                    PimpinanMockData.sharedReportData[index] = current.copyWith(
                      mentalScore: newScore,
                    );
                  }

                  final typeString = isReward ? 'reward' : 'punishment';
                  final titlePrefix = isReward ? 'Reward:' : 'Punishment:';
                  final pointStr = pointChange > 0
                      ? '+${pointChange.toStringAsFixed(2)}'
                      : pointChange.toStringAsFixed(2);
                  PimpinanMockData.customActivities.add({
                    'id': 'dyn_${DateTime.now().millisecondsSinceEpoch}',
                    'nrp': serdik['nrp'],
                    'title': '$titlePrefix ${item['tipe']}',
                    'subtitle': item['deskripsi'],
                    'timeRaw':
                        '${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}',
                    'dateTime': DateTime.now(),
                    'points': pointStr,
                    'type': typeString,
                    'note': _justifikasiController.text.trim(),
                  });

                  Navigator.pop(context);
                  Navigator.pop(context);
                  AppNotifier.showSuccess(
                    context,
                    'Tindakan beserta bukti berhasil dicatat. Nilai Mental diperbarui: ${pointChange > 0 ? '+' : ''}$pointChange',
                  );
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: _primaryNavy,
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.grey.shade300,
            disabledForegroundColor: Colors.grey.shade500,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd + 2),
            ),
          ),
          child: const Text(
            'KONFIRMASI',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}
