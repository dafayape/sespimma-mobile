import 'dart:io';
import 'package:flutter/material.dart';
import 'package:sespimma/features/assessment/data/models/serdik_physical_scores.dart';
import 'package:sespimma/core/constants/app_dimensions.dart';

import 'package:sespimma/core/utils/icon_mapper.dart';
import 'package:sespimma/features/assessment/presentation/pages/patun_physical_medical_history_screen.dart';
import 'package:sespimma/features/assessment/data/models/health_monitoring_data.dart';
import 'package:sespimma/core/utils/avatar_helper.dart';

class PatunPhysicalDetailScreen extends StatefulWidget {
  final Map<String, dynamic> serdik;

  const PatunPhysicalDetailScreen({super.key, required this.serdik});

  @override
  State<PatunPhysicalDetailScreen> createState() =>
      _PatunPhysicalDetailScreenState();
}

class _PatunPhysicalDetailScreenState extends State<PatunPhysicalDetailScreen>
    with SingleTickerProviderStateMixin {
  static const Color _primaryNavy = Color(0xFF000B1D);
  static const Color _lightGrey = Color(0xFFF8F9FA);

  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Color _getScoreColor(double s) {
    if (s == 0) return Colors.blueGrey.shade800;
    if (s > 85.00) return const Color(0xFF1B5E20);
    if (s > 80.00) return const Color(0xFF2E7D32);
    if (s > 75.00) return const Color(0xFF827717);
    if (s > 70.00) return const Color(0xFFF9A825);
    return const Color(0xFFB71C1C);
  }

  String _formatDate(DateTime dt) {
    final indonesianMonths = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    final month = indonesianMonths[dt.month - 1];
    return '${dt.day.toString().padLeft(2, '0')} $month ${dt.year}, ${dt.hour.toString().padLeft(2, '0')}.${dt.minute.toString().padLeft(2, '0')}';
  }

  List<Map<String, dynamic>> _getDynamicMedicalRecords(String noSerdik) {
    final data = HealthMonitoringData.getHealthData(noSerdik);
    final List<Map<String, dynamic>> list = [];

    for (var r in data.records) {
      String title = r.type;
      if (title == 'Rawat Inap Tempat Perawatan Sementara') {
        title = 'Rawat Inap TPS';
      } else if (title == 'Rawat Inap Rumah Sakit') {
        title = 'Rawat Inap RS';
      } else if (title.contains('Kunjungan Poliklinik')) {
        title = 'Kunjungan Poliklinik';
      }

      list.add({
        'title': title,
        'desc': r.description,
        'sender': r.medisName,
        'time': _formatDate(r.timestamp),
        'category': title.contains('Rawat Inap') ? 'Rawat Inap' : 'Poliklinik',
        'date': r.timestamp,
        'photoPath': r.photoPath,
      });
    }

    if (data.nilaiA != null) {
      final dt = DateTime.now().subtract(const Duration(days: 20));
      list.add({
        'title': 'Tes Kesehatan Awal Selesai',
        'desc': data.catatanDokterA ?? '',
        'sender': 'Tim Medis Sespimma',
        'time': _formatDate(dt),
        'category': 'Tes Medis',
        'date': dt,
      });
    }

    if (data.nilaiB != null) {
      final dt = DateTime.now().subtract(const Duration(days: 2));
      list.add({
        'title': 'Tes Kesehatan Akhir Selesai',
        'desc': data.catatanDokterB ?? '',
        'sender': 'Tim Medis Sespimma',
        'time': _formatDate(dt),
        'category': 'Tes Medis',
        'date': dt,
      });
    }

    list.sort(
      (a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime),
    );
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.serdik['nama_lengkap'] ?? '-';
    final noSerdik = widget.serdik['no_serdik'] ?? '-';
    final pangkat = widget.serdik['pangkat'] ?? '-';

    final physicalScores = SerdikPhysicalScores.getScores(noSerdik);
    final double score = (physicalScores['nKj'] as num?)?.toDouble() ?? 0.0;

    final String status = score >= 70 ? 'LULUS' : 'TIDAK LULUS';
    final String? profilePhoto =
        widget.serdik['profile_photo'] ?? widget.serdik['profilePhoto'];

    return Scaffold(
      backgroundColor: _lightGrey,
      appBar: AppBar(
        backgroundColor: _primaryNavy,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Keterangan Jasmani',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: AppDimensions.fontXxl,
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildProfileHeader(
                    name,
                    pangkat,
                    noSerdik,
                    status,
                    score,
                    profilePhoto,
                  ),
                  _buildHealthScoresSection(noSerdik),
                  _buildMedicalHistorySection(noSerdik),
                  _buildPhysicalScoresSection(noSerdik),
                  _buildRecommendationSection(),
                  const SizedBox(height: AppDimensions.xxxl),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(
    String name,
    String pangkat,
    String noSerdik,
    String status,
    double score,
    String? profilePhoto,
  ) {
    Color statusColor;
    if (status == 'Aman') {
      statusColor = Colors.green.shade600;
    } else if (status == 'Warning') {
      statusColor = Colors.orange.shade600;
    } else {
      statusColor = Colors.red.shade600;
    }

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.xl,
        vertical: AppDimensions.xl,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: _lightGrey,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.shade200, width: 2),
              image: DecorationImage(
                image: (profilePhoto != null && profilePhoto.isNotEmpty)
                    ? FileImage(File(profilePhoto)) as ImageProvider
                    : AvatarHelper.getAvatar(null),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: AppDimensions.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: AppDimensions.fontXl,
                    fontWeight: FontWeight.w800,
                    color: _primaryNavy,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppDimensions.xs),
                Text(
                  '$pangkat • No. Serdik: $noSerdik',
                  style: TextStyle(
                    fontSize: AppDimensions.fontMd,
                    fontWeight: FontWeight.w600,
                    color: Colors.blueGrey.shade500,
                  ),
                ),
                const SizedBox(height: AppDimensions.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      fontSize: AppDimensions.fontXs,
                      fontWeight: FontWeight.w800,
                      color: statusColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppDimensions.md),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
              border: Border.all(color: statusColor.withValues(alpha: 0.3)),
            ),
            child: Text(
              score > 0 ? score.toStringAsFixed(2) : '-',
              style: TextStyle(
                fontSize: AppDimensions.fontXxl,
                fontWeight: FontWeight.w900,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, [String? weight]) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: _primaryNavy,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: AppDimensions.sm),
        if (weight != null && weight.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: _primaryNavy.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
            ),
            child: Text(
              weight,
              style: const TextStyle(
                fontSize: AppDimensions.fontXs,
                fontWeight: FontWeight.w800,
                color: _primaryNavy,
                letterSpacing: 0.3,
              ),
            ),
          ),
          const SizedBox(width: AppDimensions.sm),
        ],
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: AppDimensions.fontLg,
              fontWeight: FontWeight.w800,
              color: _primaryNavy,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHealthScoresSection(String noSerdik) {
    final physicalScores = SerdikPhysicalScores.getScores(noSerdik);
    final double scoreA =
        (physicalScores['tes_awal'] as num?)?.toDouble() ?? 0.0;
    final double scoreB =
        (physicalScores['tes_akhir'] as num?)?.toDouble() ?? 0.0;
    final double scoreC =
        (physicalScores['status_kesehatan'] as num?)?.toDouble() ?? 0.0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.lg,
        AppDimensions.xl,
        AppDimensions.lg,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: AppDimensions.md),
            child: _buildSectionTitle('SELURUH NILAI KESEHATAN', '40%'),
          ),
          _buildScoreGroup('Tes Kesehatan Awal', '', scoreA, []),
          const SizedBox(height: AppDimensions.sm),
          _buildScoreGroup('Tes Kesehatan Akhir', '', scoreB, []),
          const SizedBox(height: AppDimensions.sm),
          _buildScoreGroup(
            'Status Kesehatan Selama Pendidikan',
            '',
            scoreC,
            [],
          ),
          const SizedBox(height: AppDimensions.lg),
        ],
      ),
    );
  }

  Widget _buildMedicalHistorySection(String noSerdik) {
    final dynamicRecords = _getDynamicMedicalRecords(noSerdik);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.xl,
        AppDimensions.md,
        AppDimensions.xl,
        AppDimensions.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: _buildSectionTitle('RIWAYAT CATATAN MEDIS')),
              if (dynamicRecords.isNotEmpty)
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PatunPhysicalMedicalHistoryScreen(
                          initialRecords: dynamicRecords,
                        ),
                      ),
                    );
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.blueGrey.shade600,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.sm,
                      vertical: AppDimensions.xs,
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Lihat Semua',
                        style: TextStyle(
                          fontSize: AppDimensions.fontMd,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.chevron_right_rounded, size: 20),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppDimensions.lg),
          if (dynamicRecords.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(AppDimensions.xl),
                child: Text(
                  'Belum ada catatan riwayat kesehatan',
                  style: TextStyle(color: Colors.blueGrey.shade400),
                ),
              ),
            )
          else
            ...dynamicRecords
                .take(2)
                .map((item) => _buildMedicalRecordCard(item)),
        ],
      ),
    );
  }

  Color _categoryColor(String? category) {
    switch (category) {
      case 'Rawat Inap':
        return const Color(0xFFD32F2F);
      case 'Tes Medis':
        return const Color(0xFF1565C0);
      default:
        return const Color(0xFFF57C00);
    }
  }

  IconData _categoryIcon(String? category) {
    switch (category) {
      case 'Rawat Inap':
        return Icons.local_hospital_rounded;
      case 'Tes Medis':
        return Icons.verified_rounded;
      default:
        return Icons.medical_services_rounded;
    }
  }

  Widget _buildMedicalRecordCard(Map<String, dynamic> item) {
    final String? category = item['category'] as String?;
    final Color color = _categoryColor(category);
    final Color bgColor = color.withValues(alpha: 0.1);
    final IconData icon = _categoryIcon(category);
    final String desc = (item['desc'] as String?) ?? '';

    return FadeTransition(
      opacity: _animController,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.2),
          end: Offset.zero,
        ).animate(_animController),
        child: Container(
          margin: const EdgeInsets.only(bottom: AppDimensions.md),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.lg),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppDimensions.sm + 2),
                  decoration: BoxDecoration(
                    color: bgColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: AppDimensions.iconLg),
                ),
                const SizedBox(width: AppDimensions.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              (item['title'] as String?) ?? '-',
                              style: const TextStyle(
                                fontSize: AppDimensions.fontLg,
                                fontWeight: FontWeight.w800,
                                color: _primaryNavy,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: bgColor,
                              borderRadius: BorderRadius.circular(
                                AppDimensions.radiusFull,
                              ),
                            ),
                            child: Text(
                              category ?? '-',
                              style: TextStyle(
                                fontSize: AppDimensions.fontSm,
                                fontWeight: FontWeight.w700,
                                color: color,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (desc.isNotEmpty) ...[
                        const SizedBox(height: AppDimensions.xs),
                        Text(
                          desc,
                          style: TextStyle(
                            fontSize: AppDimensions.fontSm,
                            fontWeight: FontWeight.w600,
                            color: Colors.blueGrey.shade700,
                          ),
                        ),
                      ],
                      const SizedBox(height: AppDimensions.sm),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: 14,
                            color: Colors.blueGrey.shade400,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            (item['time'] as String?) ?? '-',
                            style: TextStyle(
                              fontSize: AppDimensions.fontSm,
                              fontWeight: FontWeight.w500,
                              color: Colors.blueGrey.shade400,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            Icons.person,
                            size: 14,
                            color: Colors.blueGrey.shade400,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              (item['sender'] as String?) ?? '-',
                              style: TextStyle(
                                fontSize: AppDimensions.fontSm,
                                fontWeight: FontWeight.w500,
                                color: Colors.blueGrey.shade400,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhysicalScoresSection(String noSerdik) {
    final physicalScores = SerdikPhysicalScores.getScores(noSerdik);
    final double scoreA = (physicalScores['nga'] as num?)?.toDouble() ?? 0.0;
    final double scoreB = (physicalScores['ngb'] as num?)?.toDouble() ?? 0.0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.lg,
        AppDimensions.xl,
        AppDimensions.lg,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: AppDimensions.md),
            child: _buildSectionTitle('SELURUH NILAI JASMANI', '60%'),
          ),
          _buildScoreGroup('Samapta A', '', scoreA, [
            _buildSubScoreItem('Lari / Jalan 12 Menit', scoreA),
          ]),
          const SizedBox(height: AppDimensions.sm),
          _buildScoreGroup('Samapta B', '', scoreB, [
            _buildSubScoreItem('Pull Up (1 menit)', scoreB),
            _buildSubScoreItem('Sit Up (1 menit)', scoreB),
            _buildSubScoreItem('Push Up (1 menit)', scoreB),
            _buildSubScoreItem('Shuttle Run 6x10m', scoreB),
          ]),
          const SizedBox(height: AppDimensions.lg),
        ],
      ),
    );
  }

  Widget _buildScoreGroup(
    String title,
    String weight,
    double score,
    List<Widget> children,
  ) {
    final scoreColor = _getScoreColor(score);
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.lg,
              vertical: AppDimensions.md,
            ),
            decoration: BoxDecoration(
              color: _primaryNavy.withValues(alpha: 0.03),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppDimensions.radiusLg),
              ),
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade100, width: 1.5),
              ),
            ),
            child: Row(
              children: [
                if (weight.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: _primaryNavy.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusSm,
                      ),
                    ),
                    child: Text(
                      weight,
                      style: const TextStyle(
                        fontSize: AppDimensions.fontXs,
                        fontWeight: FontWeight.w800,
                        color: _primaryNavy,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppDimensions.sm),
                ],
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: AppDimensions.fontMd,
                      fontWeight: FontWeight.w800,
                      color: _primaryNavy,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: AppDimensions.sm),
                Container(
                  constraints: const BoxConstraints(minWidth: 52),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: scoreColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                  ),
                  child: Text(
                    score > 0 ? score.toStringAsFixed(2) : '-',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: AppDimensions.fontMd,
                      fontWeight: FontWeight.w900,
                      color: scoreColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (children.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppDimensions.md,
                AppDimensions.sm,
                AppDimensions.md,
                AppDimensions.sm,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: children,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSubScoreItem(String title, double score) {
    final scoreColor = _getScoreColor(score);
    return Padding(
      padding: const EdgeInsets.only(
        bottom: AppDimensions.xs,
        left: AppDimensions.xs,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.circle, size: 5, color: Colors.blueGrey.shade400),
          const SizedBox(width: AppDimensions.sm),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: AppDimensions.fontSm,
                fontWeight: FontWeight.w600,
                color: Colors.blueGrey.shade700,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: AppDimensions.xs),
          Container(
            constraints: const BoxConstraints(minWidth: 44),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: scoreColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              score > 0 ? score.toStringAsFixed(2) : '-',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: AppDimensions.fontXs + 1,
                fontWeight: FontWeight.w800,
                color: scoreColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationSection() {
    final String status = widget.serdik['_mock_status'] ?? 'Aman';
    final bool isWarning = status == 'Warning' || status == 'Kritis';
    final String insight = isWarning
        ? 'Perlu perhatian khusus. Evaluasi catatan medis menunjukkan adanya potensi penurunan jasmani (Samapta A) akibat seringnya kunjungan poli (Status C). Disarankan pantauan ketat dan program pemulihan terstruktur.'
        : 'Serdik menunjukkan performa jasmani (Samapta A) yang memuaskan. Namun, frekuensi kunjungan medis (Status C) perlu diperhatikan agar tidak berdampak pada akumulasi nilai kesehatan. Disarankan untuk memantau waktu istirahat dan suplemen harian Serdik.';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.lg),
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.lg),
        decoration: BoxDecoration(
          color: isWarning ? Colors.red.shade50 : Colors.blue.shade50,
          borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
          border: Border.all(
            color: isWarning ? Colors.red.shade100 : Colors.blue.shade100,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(AppDimensions.sm),
              decoration: BoxDecoration(
                color: isWarning ? Colors.red.shade100 : Colors.blue.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                AppIcons.sparkleFill,
                color: isWarning ? Colors.red.shade700 : Colors.blue.shade700,
                size: AppDimensions.iconSm,
              ),
            ),
            const SizedBox(width: AppDimensions.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Rekomendasi Evaluasi Jasmani',
                    style: TextStyle(
                      color: isWarning
                          ? Colors.red.shade900
                          : Colors.blue.shade900,
                      fontSize: AppDimensions.fontSm,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.xs),
                  Text(
                    insight,
                    style: TextStyle(
                      color: Colors.blueGrey.shade700,
                      fontSize: AppDimensions.fontXs + 2,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
