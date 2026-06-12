import 'package:sespimma/core/constants/app_dimensions.dart';
import 'package:flutter/material.dart';
import 'package:sespimma/core/utils/app_notifier.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:sespimma/core/utils/icon_mapper.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sespimma/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:sespimma/features/auth/presentation/bloc/auth_state.dart';

class HelpFaqScreen extends StatefulWidget {
  const HelpFaqScreen({super.key});

  @override
  State<HelpFaqScreen> createState() => _HelpFaqScreenState();
}

class _HelpFaqScreenState extends State<HelpFaqScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final TextEditingController _searchController = TextEditingController();

  static const Color _primaryNavy = Color(0xFF000B1D);
  static const Color _lightGrey = Color(0xFFF8F9FA);
  static const Color _waColor = Color(0xFF25D366);

  List<Map<String, String>> get _faqs {
    if (!mounted) return [];
    final authState = context.read<AuthBloc>().state;
    String role = 'siswa';
    if (authState is AuthSuccess) {
      role = authState.user.roleId;
    }

    if (role == 'pimpinan') {
      return [
        {
          'q': 'Bagaimana cara memantau peringatan dini (EWS)?',
          'a':
              'Buka menu "Monitoring". Anda dapat melihat daftar Serdik berdasarkan tingkat risikonya. Klik pada Serdik untuk melihat rincian kompetensi dan "Log Pelanggaran" secara dinamis.',
        },
        {
          'q': 'Bagaimana cara mengunduh laporan nilai akhir?',
          'a':
              'Di menu "Laporan", Anda akan melihat rekapitulasi nilai Serdik. Klik ikon unduh (PDF) di pojok kanan atas, sesuaikan nama dan pangkat penandatangan, lalu klik "Generate Laporan".',
        },
        {
          'q': 'Apa indikator Serdik berstatus Risiko Tinggi?',
          'a':
              'Status "Tinggi" pada Early Warning System muncul jika nilai rata-rata Serdik di bawah standar (Cukup/Kurang), atau Serdik memiliki banyak riwayat pelanggaran (Punishment).',
        },
        {
          'q': 'Bagaimana sistem penilaian terintegrasi bekerja?',
          'a':
              'Sistem (IDMS) akan mengakumulasi nilai dari Patun, Gadik, dan Korsis secara otomatis. Bobot penilaian terdiri dari Akademik (70%), Mental Kepribadian (20%), dan Jasmani (10%).',
        },
      ];
    } else if (role == 'operator') {
      return [
        {
          'q': 'Bagaimana cara membuat zona kegiatan?',
          'a':
              'Gunakan menu "Zona". Anda dapat menandai koordinat lokasi dan menentukan batas radiusnya, lalu sistem akan memantau kehadiran Serdik secara otomatis.',
        },
        {
          'q': 'Bagaimana cara menginput nilai jasmani?',
          'a':
              'Gunakan menu "Jasmani" untuk mencari Serdik dan memasukkan nilai ujian kesamaptaan jasmani secara real-time.',
        },
      ];
    } else if (role == 'korsis') {
      return [
        {
          'q': 'Bagaimana memantau pencatatan inbox?',
          'a':
              'Gunakan menu "Inbox" untuk memantau pencatatan Serdik. Anda dapat memfilter berdasarkan Pokjar (I-V) atau status pencatatan.',
        },
        {
          'q': 'Bagaimana cara mengisi form mental kepribadian?',
          'a':
              'Pilih menu "Mental" di navigasi bawah, lalu gunakan form penilaian mental kepribadian untuk merekam perkembangan atau pelanggaran Serdik secara dinamis.',
        },
        {
          'q': 'Bagaimana memantau pengisian sosiometri?',
          'a':
              'Buka menu "Sosiometri". Anda dapat memonitor progres pengisian (prosentase tuntas) oleh Serdik secara real-time untuk fase Awal maupun Akhir.',
        },
        {
          'q': 'Bagaimana cara membuat zona absensi?',
          'a':
              'Masuk ke menu "Zona" dan klik tombol tambah. Anda bebas membuat zona Lingkaran (radius) maupun zona Poligon (bentuk khusus).',
        },
      ];
    } else if (role == 'medis') {
      return [
        {
          'q': 'Bagaimana cara memantau status kesehatan serdik?',
          'a':
              'Gunakan menu "Kesehatan" pada bilah bawah. Anda dapat mencari nama atau nomor Serdik spesifik, atau menggunakan filter berdasarkan kelompok POKJAR I hingga V.',
        },
        {
          'q': 'Bagaimana sistem perhitungan nilai kesehatan?',
          'a':
              'Sistem secara dinamis menghitung N.KES = (A + B + C) / 3. Nilai C akan otomatis berkurang secara progresif bila Serdik tercatat berkunjung ke Poliklinik atau menjalani Rawat Inap (TPS/RS).',
        },
        {
          'q': 'Bagaimana cara merekam rawat inap atau berobat?',
          'a':
              'Dari layar monitoring, pilih Serdik, ketuk form "Status Kesehatan Pendidikan", lengkapi informasi jenis rawat dan durasi harinya, lalu ambil bukti foto langsung menggunakan kamera sebelum menekan SIMPAN.',
        },
      ];
    } else if (role == 'gadik') {
      return [
        {
          'q': 'Bagaimana cara menggunakan fitur Monitoring Tugas?',
          'a':
              'Pilih menu "Tugas" di navigasi bawah untuk melihat daftar penugasan. Anda dapat memantau status pengumpulan tugas dari setiap Serdik dan memberikan nilai secara langsung.',
        },
        {
          'q': 'Bagaimana cara memberikan Reward atau Punishment?',
          'a':
              'Gunakan menu "Penilaian" di navigasi bawah untuk mencari Serdik dan menginput Reward atau Punishment. Sistem akan otomatis menghitung poin dan memvalidasi batas maksimal pemberian sesuai aturan.',
        },
      ];
    } else if (role == 'patun') {
      return [
        {
          'q': 'Bagaimana cara memantau akademik pokjar saya?',
          'a':
              'Buka menu "Akademik". Anda dapat melihat rangkuman nilai dari setiap penugasan, hasil ujian, dan performa Serdik di Pokjar Anda secara real-time.',
        },
        {
          'q': 'Bagaimana cara merekam penilaian mental kepribadian?',
          'a':
              'Masuk ke menu "Mental". Anda dapat menambahkan catatan pelanggaran atau penghargaan secara spesifik beserta bukti foto untuk Serdik di bawah asuhan Anda.',
        },
        {
          'q': 'Dimana saya dapat melihat nilai kesamaptaan jasmani?',
          'a':
              'Di menu "Jasmani", Anda akan melihat ringkasan skor Lari, Pull Up, Sit Up, dan lari Shuttle Run (NGB) beserta rincian kesehatan terkini tiap Serdik.',
        },
        {
          'q': 'Bagaimana cara memonitor absensi harian serdik?',
          'a':
              'Buka menu "Absen". Layar monitoring akan mendeteksi koordinat Serdik secara live di dalam Geofencing. Anda juga dapat mengunduh laporan PDF absensi di tombol "Laporan".',
        },
        {
          'q': 'Bagaimana cara mengontrol progres sosiometri?',
          'a':
              'Di menu "Sosiometri", Anda dapat melihat persentase tuntas penilaian antar-rekan. Klik profil Serdik untuk melihat detail penilaian yang sudah ia kerjakan.',
        },
      ];
    }

    return [
      {
        'q': 'Bagaimana cara absensi geofencing?',
        'a':
            'Gunakan menu "Apel" di navigasi bawah. Pastikan fitur GPS aktif dan Anda berada di dalam radius Geofencing.',
      },
      {
        'q': 'Bagaimana sistem perhitungan bobot nilai?',
        'a':
            'Sistem penilaian menerapkan pembobotan transparan: 70% Akademik, 20% Mental & Kepribadian, dan 10% Jasmani.',
      },
      {
        'q': 'Bagaimana cara mengumpulkan tugas harian?',
        'a':
            'Masuk ke menu "Tugas", pilih Tugas aktif, lalu klik "Unggah Bukti" sebelum batas waktu berakhir.',
      },
      {
        'q': 'Apa yang harus dilakukan jika GPS tidak akurat?',
        'a':
            'Pastikan izin lokasi disetel ke "Selalu Izinkan" dengan opsi Akurasi Tinggi. Jika bermasalah, hubungi Admin IT.',
      },
    ];
  }

  List<Map<String, String>> _filteredFaqs = [];
  bool _isInit = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInit) {
      _filteredFaqs = List.from(_faqs);
      _isInit = true;
    }
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0.0, 0.05), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutQuart,
          ),
        );

    _animationController.forward();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      if (query.isEmpty) {
        _filteredFaqs = List.from(_faqs);
      } else {
        _filteredFaqs = _faqs.where((faq) {
          final question = faq['q']!.toLowerCase();
          final answer = faq['a']!.toLowerCase();
          return question.contains(query) || answer.contains(query);
        }).toList();
      }
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _contactAdminWA(BuildContext context) async {
    HapticFeedback.mediumImpact();
    final Uri url = Uri.parse(
      'https://wa.me/6285862393696?text=Halo%20Admin%20Makerindo%2C%20saya%20Serdik%20SESPIMMA%20membutuhkan%20bantuan%20terkait%20aplikasi.',
    );

    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (context.mounted) {
        AppNotifier.showError(
          context,
          'Gagal membuka WhatsApp. Pastikan aplikasi terinstal.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _lightGrey,
      appBar: AppBar(
        backgroundColor: _lightGrey,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(AppIcons.caretLeft, size: AppDimensions.iconXl),
          onPressed: () => Navigator.pop(context),
          color: _primaryNavy,
        ),
        title: const Text(
          'Bantuan',
          style: TextStyle(
            color: _primaryNavy,
            fontWeight: FontWeight.w800,
            fontSize: AppDimensions.fontXxl,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: AppDimensions.sm),
                      const Text(
                        'Pusat Panduan Digital',
                        style: TextStyle(
                          fontSize: AppDimensions.fontDisplay,
                          fontWeight: FontWeight.w800,
                          color: _primaryNavy,
                        ),
                      ),
                      const SizedBox(height: AppDimensions.sm),
                      Text(
                        'Temukan jawaban atas pertanyaan umum terkait fitur dan operasional pendidikan di sistem SESPIMMA.',
                        style: TextStyle(
                          fontSize: AppDimensions.fontLg,
                          fontWeight: FontWeight.w500,
                          color: Colors.blueGrey.shade600,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: AppDimensions.md),
                      _buildSearchBar(),
                      const SizedBox(height: AppDimensions.xl),
                      if (_filteredFaqs.isEmpty)
                        _buildEmptyState()
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _filteredFaqs.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: AppDimensions.md),
                          itemBuilder: (context, index) {
                            final faq = _filteredFaqs[index];
                            return _buildFaqItem(faq['q']!, faq['a']!);
                          },
                        ),
                      const SizedBox(height: AppDimensions.avatarMd),
                      _buildContactAdminCard(context),
                      const SizedBox(height: AppDimensions.xl),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFaqItem(String question, String answer) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        clipBehavior: Clip.antiAlias,
        child: Theme(
          data: ThemeData().copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            onExpansionChanged: (_) => HapticFeedback.selectionClick(),
            collapsedIconColor: _primaryNavy,
            iconColor: _primaryNavy,
            tilePadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 4,
            ),
            title: Text(
              question,
              style: const TextStyle(
                fontSize: AppDimensions.fontLg,
                fontWeight: FontWeight.w700,
                color: _primaryNavy,
              ),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
                child: Text(
                  answer,
                  style: TextStyle(
                    fontSize: AppDimensions.fontDefault,
                    fontWeight: FontWeight.w500,
                    color: Colors.blueGrey.shade600,
                    height: 1.6,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactAdminCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.lg),
      decoration: BoxDecoration(
        color: _primaryNavy,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
        boxShadow: [
          BoxShadow(
            color: _primaryNavy.withValues(alpha: 0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppDimensions.md),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  AppIcons.headsetFill,
                  color: Colors.white,
                  size: AppDimensions.iconXl,
                ),
              ),
              const SizedBox(width: AppDimensions.md),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Butuh Bantuan Lain?',
                      style: TextStyle(
                        fontSize: AppDimensions.fontXl,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: AppDimensions.xs),
                    Text(
                      'Hubungi Admin (PT. Makerindo Prima Solusi)',
                      style: TextStyle(
                        fontSize: AppDimensions.fontMd,
                        fontWeight: FontWeight.w500,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.lg),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _contactAdminWA(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: _waColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                ),
                elevation: 4,
                shadowColor: _waColor.withValues(alpha: 0.4),
              ),
              icon: Icon(
                AppIcons.whatsappLogoFill,
                size: AppDimensions.iconDefault + 2,
              ),
              label: const Text(
                'Hubungi WhatsApp',
                style: TextStyle(
                  fontSize: AppDimensions.fontLg,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(
          fontSize: AppDimensions.fontLg,
          fontWeight: FontWeight.w600,
          color: _primaryNavy,
        ),
        decoration: InputDecoration(
          hintText: 'Cari pertanyaan bantuan...',
          hintStyle: TextStyle(
            color: Colors.blueGrey.shade300,
            fontSize: AppDimensions.fontLg,
          ),
          prefixIcon: Icon(
            AppIcons.magnifyingGlass,
            color: Colors.blueGrey.shade400,
            size: AppDimensions.iconDefault,
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: AppDimensions.iconMd),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    _searchController.clear();
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 16,
            horizontal: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Icon(
              AppIcons.magnifyingGlassFill,
              size: AppDimensions.iconHuge,
              color: Colors.blueGrey.shade100,
            ),
            const SizedBox(height: AppDimensions.md),
            Text(
              'Pertanyaan Tidak Ditemukan',
              style: TextStyle(
                fontSize: AppDimensions.fontXl,
                fontWeight: FontWeight.w700,
                color: Colors.blueGrey.shade700,
              ),
            ),
            const SizedBox(height: AppDimensions.sm),
            Text(
              'Coba gunakan kata kunci lain atau hubungi admin.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: AppDimensions.fontDefault,
                fontWeight: FontWeight.w500,
                color: Colors.blueGrey.shade400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
