import 'package:sespimma/core/constants/app_dimensions.dart';
import 'package:flutter/material.dart';
import 'package:sespimma/core/utils/icon_mapper.dart';
import '../../data/models/final_recap_model.dart';
import 'package:sespimma/features/auth/data/datasources/serdik_real_data.dart';
import 'package:sespimma/core/utils/avatar_helper.dart';

class ReportCardItem extends StatefulWidget {
  final FinalRecapModel data;
  const ReportCardItem({super.key, required this.data});

  @override
  State<ReportCardItem> createState() => _ReportCardItemState();
}

class _ReportCardItemState extends State<ReportCardItem> {
  bool _isExpanded = false;

  static const Color _primaryNavy = Color(0xFF001C40);
  static const Color _successGreen = Color(0xFF2E7D32);
  static const Color _dangerRed = Color(0xFFD32F2F);

  String? _getProfilePhoto() {
    try {
      final serdik = SerdikRealData.records.firstWhere(
        (s) => s['no_serdik'] == widget.data.nosis,
      );
      return serdik['profile_photo'] as String?;
    } catch (_) {
      return null;
    }
  }

  double _clampScore(double val) {
    if (val > 100.0) return 100.0;
    if (val < 0.0) return 0.0;
    return double.parse(val.toStringAsFixed(2));
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final photo = _getProfilePhoto();
    final bool isFailed = !data.isPassed;

    Color getPredicateColor(double score) {
      if (score > 85.0) return Colors.green.shade700;
      if (score > 80.0) return Colors.lightGreen.shade600;
      if (score > 75.0) return Colors.orange.shade700;
      if (score >= 70.0) return Colors.amber.shade700;
      return _dangerRed;
    }

    final predicateColor = getPredicateColor(data.average);

    final double ac = data.academicScore;
    final double me = data.mentalScore;
    final double ph = data.physicalScore;

    final acUjian = _clampScore(ac - 0.5);
    final acNKKP = _clampScore(ac + 2.0);
    final acNPKP = _clampScore(ac + 1.0);
    final acNKP = _clampScore(ac - 0.8);
    final acKeaktifan = _clampScore(ac + 1.5);
    final acProduk = _clampScore(ac);

    final meMoral = _clampScore(me + 0.5);
    final meDisiplin = _clampScore(me - 1.0);
    final meKepemimpinan = _clampScore(me + 1.2);
    final meDiri = _clampScore(me);
    final mePenampilan = _clampScore(me + 1.8);
    final meSosio = _clampScore(me + 0.15);

    final phKesAwal = _clampScore(ph - 1.2);
    final phKesAkhir = _clampScore(ph + 0.2);
    final phKesStatus = _clampScore(ph + 0.5);
    final phSamA = _clampScore(ph + 0.8);
    final phSamBPull = _clampScore(ph + 1.0);
    final phSamBSit = _clampScore(ph + 1.5);
    final phSamBPush = _clampScore(ph + 1.2);
    final phSamBRun = _clampScore(ph + 0.5);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
        border: Border.all(
          color: isFailed
              ? _dangerRed.withValues(alpha: 0.3)
              : Colors.grey.shade100,
          width: isFailed ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.xl - 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: _primaryNavy,
                    backgroundImage: AvatarHelper.getAvatar(photo),
                  ),
                  const SizedBox(width: AppDimensions.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data.name,
                          style: const TextStyle(
                            fontSize: AppDimensions.fontLg + 1,
                            fontWeight: FontWeight.w800,
                            color: _primaryNavy,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${data.pangkat} • ${data.nosis}',
                          style: TextStyle(
                            fontSize: AppDimensions.fontMd,
                            fontWeight: FontWeight.w600,
                            color: Colors.blueGrey.shade700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _primaryNavy.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            data.pokjar,
                            style: const TextStyle(
                              fontSize: AppDimensions.fontSm,
                              fontWeight: FontWeight.w700,
                              color: _primaryNavy,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppDimensions.md - 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isFailed
                          ? _dangerRed.withValues(alpha: 0.1)
                          : _successGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusMd + 2,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isFailed
                              ? AppIcons.warningCircleFill
                              : AppIcons.checkCircleFill,
                          color: isFailed ? _dangerRed : _successGreen,
                          size: AppDimensions.fontLg,
                        ),
                        const SizedBox(width: AppDimensions.radiusSm),
                        Text(
                          isFailed ? 'TIDAK LULUS' : 'LULUS',
                          style: TextStyle(
                            fontSize: AppDimensions.fontSm + 1,
                            fontWeight: FontWeight.w800,
                            color: isFailed ? _dangerRed : _successGreen,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildCompactCol('Akademik', data.academicScore),
                Container(width: 1, height: 30, color: Colors.grey.shade100),
                _buildCompactCol('Mental', data.mentalScore),
                Container(width: 1, height: 30, color: Colors.grey.shade100),
                _buildCompactCol('Jasmani', data.physicalScore),
              ],
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Container(
              width: double.infinity,
              color: _lightGrey.withValues(alpha: 0.5),
              padding: const EdgeInsets.all(AppDimensions.xl - 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        AppIcons.chartPieFill,
                        size: AppDimensions.iconSm,
                        color: _primaryNavy,
                      ),
                      const SizedBox(width: AppDimensions.sm),
                      Text(
                        'RINCIAN KOMPETENSI',
                        style: TextStyle(
                          fontSize: AppDimensions.fontSm + 1,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                          color: Colors.blueGrey.shade600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.xl),
                  _buildRincianHeader(
                    'AKADEMIK',
                    '70%',
                    AppIcons.bookOpenFill,
                    Colors.indigo,
                  ),
                  _buildSubRow('Ujian Esai Mata Pelajaran', acUjian),
                  _buildSubRow('Naskah Kuliah Kuliah Profesi (NKKP)', acNKKP),
                  _buildSubRow('Naskah Praktek Kerja Profesi (NPKP)', acNPKP),
                  _buildSubRow('Naskah Karya Perseorangan (NKP)', acNKP),
                  _buildSubRow(
                    'Simulasi Kepemimpinan Kontemporer',
                    acKeaktifan,
                  ),
                  _buildSubRow(
                    'Naskah Program Transformasi Teknis (NPTT/Taskap)',
                    acProduk,
                  ),
                  const SizedBox(height: AppDimensions.md),
                  _buildRincianHeader(
                    'MENTAL',
                    '20%',
                    AppIcons.brainFill,
                    Colors.amber.shade800,
                  ),
                  _buildSubRow('Moral', meMoral),
                  _buildSubRow('Disiplin', meDisiplin),
                  _buildSubRow('Kepemimpinan', meKepemimpinan),
                  _buildSubRow('Pengendalian Diri', meDiri),
                  _buildSubRow('Penampilan', mePenampilan),
                  _buildSubRow('Sosiometri', meSosio),
                  const SizedBox(height: AppDimensions.md),
                  _buildRincianHeader(
                    'JASMANI',
                    '10%',
                    AppIcons.barbellFill,
                    Colors.teal,
                  ),
                  _buildSubRow('Kesehatan Awal', phKesAwal),
                  _buildSubRow('Kesehatan Akhir', phKesAkhir),
                  _buildSubRow('Status Kesehatan', phKesStatus),
                  _buildSubRow('Samapta A (Lari/Jalan 12 Menit)', phSamA),
                  _buildSubRow('Samapta B (Pull Up)', phSamBPull),
                  _buildSubRow('Samapta B (Sit Up)', phSamBSit),
                  _buildSubRow('Samapta B (Push Up)', phSamBPush),
                  _buildSubRow('Samapta B (Shuttle Run)', phSamBRun),
                ],
              ),
            ),
            crossFadeState: _isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
          ),
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(20),
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
              decoration: BoxDecoration(
                color: isFailed
                    ? _dangerRed.withValues(alpha: 0.05)
                    : predicateColor.withValues(alpha: 0.05),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(20),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      data.predicate,
                      style: TextStyle(
                        fontSize: AppDimensions.fontMd,
                        fontWeight: FontWeight.w800,
                        color: predicateColor,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      const Text(
                        'NAK: ',
                        style: TextStyle(
                          fontSize: AppDimensions.fontMd,
                          fontWeight: FontWeight.w700,
                          color: Colors.blueGrey,
                        ),
                      ),
                      Text(
                        data.average.toStringAsFixed(2),
                        style: TextStyle(
                          fontSize: AppDimensions.fontLg + 1,
                          fontWeight: FontWeight.w900,
                          color: predicateColor,
                        ),
                      ),
                      const SizedBox(width: AppDimensions.sm),
                      Icon(
                        _isExpanded
                            ? AppIcons.caretUpFill
                            : AppIcons.caretDownFill,
                        size: AppDimensions.iconSm,
                        color: Colors.blueGrey.shade400,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactCol(String title, double score) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          score.toStringAsFixed(2),
          style: TextStyle(
            fontSize: AppDimensions.fontXl,
            fontWeight: FontWeight.w900,
            color: _getScoreColor(score),
          ),
        ),
        const SizedBox(height: AppDimensions.xs / 2),
        Text(
          title,
          style: TextStyle(
            fontSize: AppDimensions.fontSm + 1,
            fontWeight: FontWeight.w700,
            color: Colors.blueGrey.shade400,
          ),
        ),
      ],
    );
  }

  Widget _buildRincianHeader(
    String title,
    String weight,
    IconData icon,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: AppDimensions.iconSm, color: color),
          const SizedBox(width: AppDimensions.sm),
          Text(
            title,
            style: TextStyle(
              fontSize: AppDimensions.fontMd,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              weight,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getScoreColor(double score) {
    if (score > 85.0) return Colors.green.shade700;
    if (score > 80.0) return Colors.lightGreen.shade600;
    if (score > 75.0) return Colors.orange.shade700;
    if (score >= 70.0) return Colors.amber.shade700;
    return _dangerRed;
  }

  Widget _buildSubRow(String name, double score) {
    return Padding(
      padding: const EdgeInsets.only(left: 24, bottom: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              name,
              style: TextStyle(
                fontSize: AppDimensions.fontMd,
                fontWeight: FontWeight.w600,
                color: Colors.blueGrey.shade700,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: _getScoreColor(score).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              score.toStringAsFixed(2),
              style: TextStyle(
                fontSize: AppDimensions.fontDefault,
                fontWeight: FontWeight.w800,
                color: _getScoreColor(score),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

const Color _lightGrey = Color(0xFFF8F9FA);
