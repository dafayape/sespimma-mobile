import 'dart:io';
import 'package:flutter/material.dart';
import 'package:sespimma/features/assessment/data/models/serdik_academic_scores.dart';
import 'package:sespimma/core/constants/app_dimensions.dart';
import 'package:sespimma/core/utils/icon_mapper.dart';
import 'package:sespimma/core/utils/avatar_helper.dart';

class PatunAcademicDetailScreen extends StatelessWidget {
  final Map<String, dynamic> serdik;

  const PatunAcademicDetailScreen({super.key, required this.serdik});

  static const Color _primaryNavy = Color(0xFF000B1D);
  static const Color _lightGrey = Color(0xFFF8F9FA);

  @override
  Widget build(BuildContext context) {
    final name = serdik['nama_lengkap'] ?? '-';
    final noSerdik = serdik['no_serdik'] ?? '-';
    final pangkat = serdik['pangkat'] ?? '-';

    final academicScores = SerdikAcademicScores.getScores(noSerdik);
    final double score = (academicScores['na'] as num?)?.toDouble() ?? 0.0;

    String status;
    if (score >= 75) {
      status = 'Aman';
    } else if (score >= 70) {
      status = 'Warning';
    } else {
      status = 'Kritis';
    }
    final String? profilePhoto =
        serdik['profile_photo'] ?? serdik['profilePhoto'];

    return Scaffold(
      backgroundColor: _lightGrey,
      appBar: AppBar(
        backgroundColor: _primaryNavy,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Keterangan Akademik',
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
          onPressed: () {
            Navigator.pop(context);
          },
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
                  _buildAcademicScores(noSerdik),
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
                  '$pangkat • $noSerdik',
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

  Widget _buildAcademicScores(String noSerdik) {
    final scores = SerdikAcademicScores.getScores(noSerdik);

    double nump = (scores['nump'] as num?)?.toDouble() ?? 0.0;
    double nkkp = (scores['nkkp'] as num?)?.toDouble() ?? 0.0;
    double npkp = (scores['npkp'] as num?)?.toDouble() ?? 0.0;
    double nkp = (scores['nkp'] as num?)?.toDouble() ?? 0.0;
    double np = (scores['np'] as num?)?.toDouble() ?? 0.0;

    double nskAktif = (scores['nsk_keaktifan'] as num?)?.toDouble() ?? 0.0;
    double nskProduk = (scores['nsk_produk'] as num?)?.toDouble() ?? 0.0;
    double nskRuang = (scores['nsk_tata_ruang'] as num?)?.toDouble() ?? 0.0;
    double nsk = (scores['nsk'] as num?)?.toDouble() ?? 0.0;

    double ntMateri = (scores['nt_materi'] as num?)?.toDouble() ?? 0.0;
    double ntPenulisan = (scores['nt_penulisan'] as num?)?.toDouble() ?? 0.0;
    double ntPaparan = (scores['nt_paparan'] as num?)?.toDouble() ?? 0.0;
    double nt = (scores['nt'] as num?)?.toDouble() ?? 0.0;
    double na = (scores['na'] as num?)?.toDouble() ?? 0.0;

    double ujianMp = nump;
    double nkkpMateri = nkkp;
    double nkkpPaparan = nkkp;
    double nkkpKeaktifan = nkkp;
    double npkpMateri = npkp;
    double npkpPaparan = npkp;
    double npkpKeaktifan = npkp;
    double nkpMateri = nkp;
    double nkpPaparan = nkp;

    double baseScore = na;
    String status;
    if (na >= 75) {
      status = 'Aman';
    } else if (na >= 70) {
      status = 'Warning';
    } else {
      status = 'Kritis';
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.lg,
        0,
        AppDimensions.lg,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(
              bottom: AppDimensions.xxl,
              top: AppDimensions.xl,
            ),
            child: Row(
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
                const Text(
                  'SELURUH NILAI AKADEMIK',
                  style: TextStyle(
                    fontSize: AppDimensions.fontLg,
                    fontWeight: FontWeight.w800,
                    color: _primaryNavy,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          _buildScoreGroup('Nilai Pelajaran', '60%', np, [
            _buildScoreItem('Ujian Mata Pelajaran atau Esai', '30%', ujianMp),
            _buildScoreGroup2('Naskah Kuliah Kerja Profesi', '5%', nkkp, [
              _buildSubScoreItem('Materi & Penulisan', '35%', nkkpMateri),
              _buildSubScoreItem('Paparan', '35%', nkkpPaparan),
              _buildSubScoreItem('Keaktifan', '30%', nkkpKeaktifan),
            ]),
            _buildScoreGroup2('Naskah Praktek Kerja Profesi', '5%', npkp, [
              _buildSubScoreItem('Materi & Penulisan', '35%', npkpMateri),
              _buildSubScoreItem('Paparan', '35%', npkpPaparan),
              _buildSubScoreItem('Keaktifan', '30%', npkpKeaktifan),
            ]),
            _buildScoreGroup2('Naskah Karya Perseorangan', '60%', nkp, [
              _buildSubScoreItem('Materi & Penulisan', '50%', nkpMateri),
              _buildSubScoreItem('Paparan', '50%', nkpPaparan),
            ]),
          ]),
          const SizedBox(height: AppDimensions.md),
          _buildScoreGroup('Simulasi Kepemimpinan Kontemporer', '10%', nsk, [
            _buildSubScoreItem('Keaktifan Perseorangan', '60%', nskAktif),
            _buildSubScoreItem('Produk Perseorangan', '20%', nskProduk),
            _buildSubScoreItem('Tata Ruang Kelompok', '20%', nskRuang),
          ]),
          const SizedBox(height: AppDimensions.md),
          _buildScoreGroup('Naskah Program Transformasi Teknis', '30%', nt, [
            _buildSubScoreItem('Materi', '40%', ntMateri),
            _buildSubScoreItem('Penulisan Efektif', '30%', ntPenulisan),
            _buildSubScoreItem('Paparan & Diskusi', '30%', ntPaparan),
          ]),
          const SizedBox(height: AppDimensions.lg),
          _buildRecommendationCard(baseScore, status),
          const SizedBox(height: AppDimensions.xxl),
        ],
      ),
    );
  }

  Widget _buildRecommendationCard(double score, String status) {
    bool isWarning = status == 'Warning';
    bool isKritis = status == 'Kritis';
    bool isExcellent = score >= 85.0;

    String insight;
    if (isKritis) {
      insight =
          'Berdasarkan analisis tren Akademik, Serdik mengalami penurunan performa secara drastis. Disarankan bagi Patun untuk memberikan sesi bimbingan intensif dan evaluasi menyeluruh segera.';
    } else if (isWarning) {
      insight =
          'Berdasarkan analisis tren Akademik, Serdik mengalami penurunan performa secara spesifik pada pemahaman NPTT / Taskap. Disarankan bagi Patun untuk memberikan sesi bimbingan dan pendalaman materi ekstra.';
    } else if (isExcellent) {
      insight =
          'Performa Akademik Serdik sangat luar biasa dengan pemahaman konseptual yang tajam. Patun dapat mempertahankan ritme belajar Serdik untuk diarahkan menjadi Lulusan Terbaik.';
    } else {
      insight =
          'Nilai Akademik Serdik berada pada kondisi stabil dan baik. Patun disarankan untuk tetap memonitor fokus belajar Serdik, terutama pada simulasi kepemimpinan kontemporer untuk mendongkrak nilai ke tingkat maksimal.';
    }

    Color bgColor = isKritis
        ? Colors.red.shade50
        : isWarning
        ? Colors.orange.shade50
        : Colors.green.shade50;
    Color borderColor = isKritis
        ? Colors.red.shade100
        : isWarning
        ? Colors.orange.shade100
        : Colors.green.shade100;
    Color iconBgColor = isKritis
        ? Colors.red.shade100
        : isWarning
        ? Colors.orange.shade100
        : Colors.green.shade100;
    Color iconColor = isKritis
        ? Colors.red.shade700
        : isWarning
        ? Colors.orange.shade700
        : Colors.green.shade700;
    Color titleColor = isKritis
        ? Colors.red.shade900
        : isWarning
        ? Colors.orange.shade900
        : Colors.green.shade900;

    return Container(
      padding: const EdgeInsets.all(AppDimensions.xl - 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXl - 4),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppDimensions.sm),
            decoration: BoxDecoration(
              color: iconBgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              AppIcons.sparkleFill,
              color: iconColor,
              size: AppDimensions.iconSm,
            ),
          ),
          const SizedBox(width: AppDimensions.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rekomendasi Tindakan Patun',
                  style: TextStyle(
                    color: titleColor,
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
    );
  }

  Color _getScoreColor(double s) {
    if (s == 0) return Colors.blueGrey.shade800;
    if (s > 85.00) return Colors.green.shade800;
    if (s > 80.00) return Colors.green.shade500;
    if (s > 75.00) return Colors.lime.shade700;
    if (s > 70.00) return Colors.amber.shade500;
    return Colors.red.shade700;
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
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
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

  Widget _buildScoreGroup2(
    String title,
    String weight,
    double score,
    List<Widget> children,
  ) {
    final scoreColor = _getScoreColor(score);
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.sm),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.sm,
              vertical: AppDimensions.sm,
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.arrow_right_rounded,
                  size: 20,
                  color: _primaryNavy,
                ),
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blueGrey.shade50,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    weight,
                    style: TextStyle(
                      fontSize: AppDimensions.fontXs,
                      fontWeight: FontWeight.w800,
                      color: Colors.blueGrey.shade600,
                    ),
                  ),
                ),
                const SizedBox(width: AppDimensions.xs),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: AppDimensions.fontMd,
                      fontWeight: FontWeight.w700,
                      color: _primaryNavy,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: AppDimensions.xs),
                Container(
                  constraints: const BoxConstraints(minWidth: 52),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: scoreColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                  ),
                  child: Text(
                    score > 0 ? score.toStringAsFixed(2) : '-',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: AppDimensions.fontSm,
                      fontWeight: FontWeight.w800,
                      color: scoreColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppDimensions.sm,
              0,
              AppDimensions.sm,
              AppDimensions.xs,
            ),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreItem(String title, String weight, double score) {
    final scoreColor = _getScoreColor(score);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(Icons.arrow_right_rounded, size: 20, color: _primaryNavy),
          const SizedBox(width: AppDimensions.xs),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.blueGrey.shade50,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              weight,
              style: TextStyle(
                fontSize: AppDimensions.fontXs,
                fontWeight: FontWeight.w800,
                color: Colors.blueGrey.shade600,
              ),
            ),
          ),
          const SizedBox(width: AppDimensions.xs),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: AppDimensions.fontMd,
                fontWeight: FontWeight.w700,
                color: _primaryNavy,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: AppDimensions.xs),
          Container(
            constraints: const BoxConstraints(minWidth: 52),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: scoreColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
            ),
            child: Text(
              score > 0 ? score.toStringAsFixed(2) : '-',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: AppDimensions.fontSm,
                fontWeight: FontWeight.w800,
                color: scoreColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubScoreItem(String title, String weight, double score) {
    final scoreColor = _getScoreColor(score);
    return Padding(
      padding: const EdgeInsets.only(
        bottom: AppDimensions.xs,
        left: AppDimensions.md,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.circle, size: 5, color: Colors.blueGrey.shade400),
          const SizedBox(width: AppDimensions.sm),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF001C40).withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              weight,
              style: const TextStyle(
                fontSize: AppDimensions.fontXs - 1,
                fontWeight: FontWeight.w800,
                color: Color(0xFF001C40),
              ),
            ),
          ),
          const SizedBox(width: AppDimensions.xs),
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
}
