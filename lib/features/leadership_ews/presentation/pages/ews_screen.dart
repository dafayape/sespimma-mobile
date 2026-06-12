import 'dart:math';

import 'package:sespimma/core/constants/app_dimensions.dart';
import 'package:flutter/material.dart';
import 'package:sespimma/core/utils/icon_mapper.dart';
import 'package:sespimma/features/assessment/presentation/widgets/assessment_search_bar_widget.dart';
import 'package:sespimma/features/assessment/presentation/widgets/status_filter_button_widget.dart';

import 'package:sespimma/features/auth/data/datasources/serdik_real_data.dart';
import 'package:sespimma/features/auth/data/datasources/patun_real_data.dart';
import 'package:sespimma/core/constants/reward_punishment_data.dart';
import 'package:intl/intl.dart';
import 'package:sespimma/core/utils/avatar_helper.dart';

class EwsScreen extends StatefulWidget {
  const EwsScreen({super.key});

  @override
  State<EwsScreen> createState() => _EwsScreenState();
}

class _EwsScreenState extends State<EwsScreen>
    with SingleTickerProviderStateMixin {
  AnimationController? _animController;
  String _searchQuery = '';
  String _selectedPokjar = 'Semua';
  String _selectedStatus = 'Semua Status';

  static const Color _primaryNavy = Color(0xFF000B1D);
  static const Color _lightGrey = Color(0xFFF8F9FA);
  static const Color _successGreen = Color(0xFF2E7D32);
  static const Color _warningOrange = Color(0xFFF57C00);
  static const Color _dangerRed = Color(0xFFD32F2F);

  List<String> get _pokjarOptions => [
    'Semua',
    'POKJAR I',
    'POKJAR II',
    'POKJAR III',
    'POKJAR IV',
    'POKJAR V',
  ];

  List<String> get _statusOptions => [
    'Semua Status',
    'Tinggi',
    'Sedang',
    'Aman',
  ];

  final TextEditingController _searchController = TextEditingController();

  Map<String, _EwsSerdikData>? _ewsDataMapCache;
  Map<String, _EwsSerdikData> get _ewsDataMap {
    _ewsDataMapCache ??= _generateEwsData();
    return _ewsDataMapCache!;
  }

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animController?.forward();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animController?.dispose();
    super.dispose();
  }

  Map<String, _EwsSerdikData> _generateEwsData() {
    final map = <String, _EwsSerdikData>{};
    final records = SerdikRealData.records;
    final random = Random(42);

    for (final serdik in records) {
      final noSerdik = (serdik['no_serdik'] ?? '').toString();

      final nak = 65.0 + random.nextDouble() * 30.0;

      final violations = random.nextInt(9);

      map[noSerdik] = _EwsSerdikData(
        nakScore: double.parse(nak.toStringAsFixed(2)),
        violationCount: violations,
      );
    }
    return map;
  }

  String _getRiskLevel(_EwsSerdikData data) {
    if (data.nakScore <= 70.0 || data.violationCount >= 5) {
      return 'Tinggi';
    }
    if (data.nakScore > 70.0 &&
        data.nakScore <= 75.0 &&
        data.violationCount < 5) {
      return 'Sedang';
    }
    return 'Aman';
  }

  Color _getRiskColor(String risk) {
    switch (risk) {
      case 'Tinggi':
        return _dangerRed;
      case 'Sedang':
        return _warningOrange;
      default:
        return _successGreen;
    }
  }

  IconData _getRiskIcon(String risk) {
    switch (risk) {
      case 'Tinggi':
        return AppIcons.warningCircleFill;
      case 'Sedang':
        return AppIcons.warningFill;
      default:
        return AppIcons.checkCircleFill;
    }
  }

  String _getDynamicAnalysis(String risk, _EwsSerdikData data) {
    if (risk == 'Tinggi') {
      if (data.nakScore <= 70.0 && data.violationCount >= 5) {
        return 'NAK di bawah passing grade DAN jumlah pelanggaran mencapai ambang kritis. Perlu penanganan segera dari Patun.';
      } else if (data.nakScore <= 70.0) {
        return 'NAK di bawah passing grade (${data.nakScore.toStringAsFixed(2)}). Perlu peningkatan intensif pada bidang akademik, mental, atau jasmani.';
      } else {
        return 'Jumlah pelanggaran tinggi (${data.violationCount} kali). Perlu pembinaan disiplin lebih lanjut dari Patun.';
      }
    } else if (risk == 'Sedang') {
      return 'NAK mendekati batas bawah (${data.nakScore.toStringAsFixed(2)}). Memerlukan bimbingan preventif dari Patun agar tidak turun ke zona risiko tinggi.';
    } else {
      return 'Capaian NAK di atas standar (${data.nakScore.toStringAsFixed(2)}) dan riwayat disiplin terpantau baik (${data.violationCount} pelanggaran).';
    }
  }

  String _formatPokjar(String pokjar) {
    String p = pokjar.toUpperCase().trim();
    if (p.endsWith(' 1')) return 'POKJAR I';
    if (p.endsWith(' 2')) return 'POKJAR II';
    if (p.endsWith(' 3')) return 'POKJAR III';
    if (p.endsWith(' 4')) return 'POKJAR IV';
    if (p.endsWith(' 5')) return 'POKJAR V';
    return p;
  }

  List<Map<String, dynamic>> get _filteredList {
    final records = SerdikRealData.records;

    return records.where((serdik) {
      final name = (serdik['nama_lengkap'] ?? '').toString().toLowerCase();
      final noSerdik = (serdik['no_serdik'] ?? '').toString().toLowerCase();
      final query = _searchQuery.toLowerCase();

      if (query.isNotEmpty &&
          !name.contains(query) &&
          !noSerdik.contains(query)) {
        return false;
      }

      if (_selectedPokjar != 'Semua') {
        final pokjar = _formatPokjar(
          (serdik['kelompok_kelas'] ?? '').toString(),
        );
        if (pokjar != _selectedPokjar) return false;
      }

      if (_selectedStatus != 'Semua Status') {
        final ewsData = _ewsDataMap[(serdik['no_serdik'] ?? '').toString()];
        if (ewsData == null) return false;
        final risk = _getRiskLevel(ewsData);
        if (risk != _selectedStatus) return false;
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredList = _filteredList;

    int highRisk = 0;
    int medRisk = 0;
    int safe = 0;
    for (final serdik in filteredList) {
      final noSerdik = (serdik['no_serdik'] ?? '').toString();
      final ewsData = _ewsDataMap[noSerdik];
      if (ewsData == null) continue;
      final risk = _getRiskLevel(ewsData);
      if (risk == 'Tinggi') {
        highRisk++;
      } else if (risk == 'Sedang') {
        medRisk++;
      } else {
        safe++;
      }
    }

    return Scaffold(
      backgroundColor: _lightGrey,
      appBar: AppBar(
        backgroundColor: _primaryNavy,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: const Text(
          'Early Warning System',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: AppDimensions.fontXxl,
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeaderBlock(filteredList.length, highRisk, medRisk, safe),

          _buildRingkasanStatus(highRisk, medRisk, safe),
          Divider(
            height: AppDimensions.dividerHeight,
            color: Colors.grey.shade200,
            thickness: AppDimensions.dividerHeight,
          ),
          Expanded(
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                if (_selectedPokjar != 'Semua')
                  SliverToBoxAdapter(child: _buildPatunSection()),
                if (filteredList.isEmpty)
                  SliverFillRemaining(child: _buildEmptyState())
                else
                  _buildSerdikList(filteredList),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderBlock(int totalFiltered, int high, int med, int safe) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.xl,
        vertical: AppDimensions.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: AssessmentSearchBarWidget(
                  controller: _searchController,
                  searchQuery: _searchQuery,
                  hintText: 'Cari nama atau No. Serdik...',
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                  onClear: () {
                    setState(() {
                      _searchQuery = '';
                      _searchController.clear();
                    });
                  },
                ),
              ),
              const SizedBox(width: AppDimensions.sm),
              StatusFilterButtonWidget(
                selectedStatus: _selectedPokjar,
                statuses: _pokjarOptions,
                onSelected: (value) {
                  setState(() {
                    _selectedPokjar = value;
                  });
                },
                defaultStatus: 'Semua',
                icon: Icons.groups_rounded,
                tooltip: 'Filter Pokjar',
              ),
              const SizedBox(width: AppDimensions.sm),
              StatusFilterButtonWidget(
                selectedStatus: _selectedStatus,
                statuses: _statusOptions,
                onSelected: (value) {
                  setState(() {
                    _selectedStatus = value;
                  });
                },
                defaultStatus: 'Semua Status',
                icon: AppIcons.funnelFill,
                tooltip: 'Filter Status Risiko',
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.lg),

          Row(
            children: [
              Expanded(
                child: Text(
                  _selectedPokjar != 'Semua'
                      ? 'DAFTAR SERDIK ${_selectedPokjar.toUpperCase()}'
                      : 'PENCARIAN SELURUH SERDIK',
                  style: const TextStyle(
                    color: _primaryNavy,
                    fontWeight: FontWeight.w800,
                    fontSize: AppDimensions.fontLg,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: AppDimensions.sm),
              _buildMiniCounter('$high', _dangerRed),
              const SizedBox(width: 4),
              _buildMiniCounter('$med', _warningOrange),
              const SizedBox(width: 4),
              _buildMiniCounter('$safe', _successGreen),
              const SizedBox(width: AppDimensions.sm),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _primaryNavy,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.people_alt, color: Colors.white, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      '$totalFiltered Serdik',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: AppDimensions.fontSm,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniCounter(String count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        count,
        style: TextStyle(
          fontSize: AppDimensions.fontSm,
          fontWeight: FontWeight.w900,
          color: color,
        ),
      ),
    );
  }

  Widget _buildRingkasanStatus(int high, int med, int safe) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryCard(
              'Tinggi',
              '$high',
              _dangerRed,
              AppIcons.warningCircleFill,
            ),
          ),
          const SizedBox(width: AppDimensions.md - 4),
          Expanded(
            child: _buildSummaryCard(
              'Sedang',
              '$med',
              _warningOrange,
              AppIcons.warningFill,
            ),
          ),
          const SizedBox(width: AppDimensions.md - 4),
          Expanded(
            child: _buildSummaryCard(
              'Aman',
              '$safe',
              _successGreen,
              AppIcons.checkCircleFill,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    String title,
    String count,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppDimensions.sm),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: AppDimensions.iconDefault),
          ),
          const SizedBox(height: AppDimensions.sm),
          Text(
            count,
            style: TextStyle(
              fontSize: AppDimensions.fontHuge,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: AppDimensions.fontSm,
              fontWeight: FontWeight.w700,
              color: Colors.blueGrey.shade400,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatunSection() {
    final patuns = PatunRealData.records
        .where(
          (p) =>
              _formatPokjar((p['pokjar'] ?? '').toString()) == _selectedPokjar,
        )
        .toList();

    if (patuns.isEmpty) return const SizedBox.shrink();

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: AppDimensions.sm),
            child: Text(
              'PATUN $_selectedPokjar',
              style: TextStyle(
                fontSize: AppDimensions.fontSm + 1,
                fontWeight: FontWeight.w900,
                color: Colors.blueGrey.shade400,
                letterSpacing: 1.0,
              ),
            ),
          ),
          ...patuns.map((patun) => _buildPatunCard(patun)),
        ],
      ),
    );
  }

  Widget _buildPatunCard(Map<String, dynamic> patun) {
    final name = (patun['nama'] ?? '-').toString();
    final pangkat = (patun['pangkat'] ?? '-').toString();
    final nrpNip = (patun['nrp_nip'] ?? '-').toString();
    final peran = (patun['peran_pengasuhan'] ?? '-').toString();

    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.sm),
      padding: const EdgeInsets.all(AppDimensions.md),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFBFC),
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              image: DecorationImage(
                image: AvatarHelper.getAvatar(null),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: AppDimensions.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: AppDimensions.fontDefault,
                    fontWeight: FontWeight.w800,
                    color: _primaryNavy,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '$pangkat · $nrpNip',
                  style: TextStyle(
                    fontSize: AppDimensions.fontSm,
                    fontWeight: FontWeight.w500,
                    color: Colors.blueGrey.shade400,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppDimensions.sm),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF8E44AD).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              peran,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: Color(0xFF8E44AD),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSerdikList(List<Map<String, dynamic>> serdikList) {
    return SliverPadding(
      padding: const EdgeInsets.all(AppDimensions.xl),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: index < serdikList.length - 1 ? AppDimensions.md : 0,
            ),
            child: _buildSerdikCard(context, serdikList[index]),
          );
        }, childCount: serdikList.length),
      ),
    );
  }

  Widget _buildSerdikCard(BuildContext context, Map<String, dynamic> serdik) {
    final name = (serdik['nama_lengkap'] ?? '-').toString();
    final noSerdik = (serdik['no_serdik'] ?? '-').toString();
    final pangkat = (serdik['pangkat'] ?? '-').toString();
    final pokjar = _formatPokjar((serdik['kelompok_kelas'] ?? '-').toString());

    final ewsData = _ewsDataMap[noSerdik];
    final risk = ewsData != null ? _getRiskLevel(ewsData) : 'Aman';
    final riskColor = _getRiskColor(risk);
    final riskIcon = _getRiskIcon(risk);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
        clipBehavior: Clip.antiAlias,
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            leading: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
                image: DecorationImage(
                  image: AvatarHelper.getAvatar(null),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            title: Text(
              name,
              style: const TextStyle(
                fontSize: AppDimensions.fontLg,
                fontWeight: FontWeight.w800,
                color: _primaryNavy,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 2),
                Text(
                  '$pangkat · $noSerdik',
                  style: TextStyle(
                    fontSize: AppDimensions.fontSm,
                    fontWeight: FontWeight.w500,
                    color: Colors.blueGrey.shade400,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blueGrey.shade50,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        pokjar,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Colors.blueGrey.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: riskColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                border: Border.all(color: riskColor.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(riskIcon, size: 14, color: riskColor),
                  const SizedBox(width: 4),
                  Text(
                    risk.toUpperCase(),
                    style: TextStyle(
                      fontSize: AppDimensions.fontSm,
                      fontWeight: FontWeight.w900,
                      color: riskColor,
                    ),
                  ),
                ],
              ),
            ),
            children: [_buildDetailContent(context, serdik, ewsData, risk)],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailContent(
    BuildContext context,
    Map<String, dynamic> serdik,
    _EwsSerdikData? ewsData,
    String risk,
  ) {
    final riskColor = _getRiskColor(risk);
    final nak = ewsData?.nakScore ?? 0.0;
    final violations = ewsData?.violationCount ?? 0;
    final analysisText = ewsData != null
        ? _getDynamicAnalysis(risk, ewsData)
        : 'Data belum tersedia.';

    return Container(
      padding: const EdgeInsets.all(AppDimensions.md),
      decoration: BoxDecoration(
        color: _lightGrey.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildMetricItem(
                  'NAK',
                  nak.toStringAsFixed(2),
                  riskColor,
                ),
              ),
              Container(width: 1, height: 30, color: Colors.grey.shade200),
              Expanded(
                child: _buildMetricItem(
                  'Pelanggaran',
                  '$violations',
                  riskColor,
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1),
          ),
          Text(
            'ANALISIS SISTEM',
            style: TextStyle(
              fontSize: AppDimensions.fontSm,
              fontWeight: FontWeight.w900,
              color: Colors.blueGrey.shade400,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: AppDimensions.radiusSm),
          Text(
            analysisText,
            style: TextStyle(
              fontSize: AppDimensions.fontMd,
              fontWeight: FontWeight.w600,
              color: Colors.blueGrey.shade700,
              height: 1.5,
            ),
          ),
          if (risk != 'Aman') ...[
            const SizedBox(height: AppDimensions.md),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => _showViolationLog(context, serdik, ewsData),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.grey.shade200),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      AppIcons.receiptFill,
                      size: AppDimensions.iconSm,
                      color: _primaryNavy,
                    ),
                    SizedBox(width: AppDimensions.sm),
                    Text(
                      'Log Pelanggaran',
                      style: TextStyle(
                        fontSize: AppDimensions.fontMd,
                        fontWeight: FontWeight.w800,
                        color: _primaryNavy,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetricItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: AppDimensions.fontXxl,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
        const SizedBox(height: AppDimensions.xs / 2),
        Text(
          label,
          style: TextStyle(
            fontSize: AppDimensions.fontSm + 1,
            fontWeight: FontWeight.w700,
            color: Colors.blueGrey.shade400,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    final isSearching = _searchQuery.isNotEmpty;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.xxxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isSearching
                    ? Icons.search_off_rounded
                    : Icons.person_search_rounded,
                size: AppDimensions.iconDisplay,
                color: Colors.grey.shade300,
              ),
            ),
            const SizedBox(height: AppDimensions.xl),
            Text(
              isSearching ? 'Tidak Ditemukan' : 'Tidak Ada Data',
              style: TextStyle(
                fontSize: AppDimensions.fontXxl,
                fontWeight: FontWeight.w800,
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: AppDimensions.sm),
            Text(
              isSearching
                  ? 'Tidak ada Serdik yang cocok dengan pencarian "$_searchQuery".'
                  : 'Belum ada data Serdik.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: AppDimensions.fontLg,
                color: Colors.grey.shade400,
                height: 1.5,
              ),
            ),
            if (isSearching) ...[
              const SizedBox(height: AppDimensions.xl),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _searchQuery = '';
                    _searchController.clear();
                    _selectedPokjar = 'Semua';
                    _selectedStatus = 'Semua Status';
                  });
                },
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Reset Filter'),
                style: TextButton.styleFrom(
                  foregroundColor: _primaryNavy,
                  textStyle: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showViolationLog(
    BuildContext context,
    Map<String, dynamic> serdik,
    _EwsSerdikData? ewsData,
  ) {
    final name = (serdik['nama_lengkap'] ?? '-').toString();
    final nrp = (serdik['nrp'] ?? '').toString();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusXxl),
        ),
        titlePadding: EdgeInsets.zero,
        title: Container(
          padding: const EdgeInsets.all(AppDimensions.xl),
          decoration: const BoxDecoration(
            color: _dangerRed,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(AppDimensions.radiusXxl),
              topRight: Radius.circular(AppDimensions.radiusXxl),
            ),
          ),
          child: Row(
            children: [
              const Icon(
                AppIcons.warningCircleFill,
                color: Colors.white,
                size: AppDimensions.iconXl,
              ),
              const SizedBox(width: AppDimensions.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Log Pelanggaran',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: AppDimensions.fontXl,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.xs / 2),
                    Text(
                      name,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: AppDimensions.fontMd,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Builder(
            builder: (context) {
              final count = ewsData?.violationCount ?? 0;
              if (count == 0) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppDimensions.xl),
                  child: Center(
                    child: Text(
                      'Belum ada pelanggaran tercatat.',
                      style: TextStyle(
                        color: Colors.blueGrey,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                );
              }

              final random = Random(nrp.hashCode);
              final allPunishments = RewardPunishmentData.punishments;
              final allPatuns = PatunRealData.records;

              final logs = List.generate(count, (index) {
                final p = allPunishments[random.nextInt(allPunishments.length)];
                final patun =
                    allPatuns[random.nextInt(allPatuns.length)]['nama']
                        .toString();

                final daysAgo = random.nextInt(30);
                final hoursAgo = random.nextInt(24);
                final minsAgo = random.nextInt(60);
                final date = DateTime.now().subtract(
                  Duration(days: daysAgo, hours: hoursAgo, minutes: minsAgo),
                );

                return {
                  'description': p.description,
                  'point': p.point,
                  'patun': patun,
                  'date': date,
                };
              });

              logs.sort(
                (a, b) =>
                    (b['date'] as DateTime).compareTo(a['date'] as DateTime),
              );

              return ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.6,
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: logs.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: AppDimensions.md),
                  itemBuilder: (context, index) {
                    final log = logs[index];
                    return _buildLogItem(log);
                  },
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: _primaryNavy,
              textStyle: const TextStyle(fontWeight: FontWeight.w800),
            ),
            child: const Text('TUTUP'),
          ),
        ],
      ),
    );
  }

  Widget _buildLogItem(Map<String, dynamic> log) {
    final DateTime date = log['date'] as DateTime;
    final String formattedDay = DateFormat(
      'EEEE, dd MMM yyyy',
      'id_ID',
    ).format(date);
    final String formattedTime = DateFormat('HH:mm').format(date);
    final double point = log['point'] as double;

    return Container(
      padding: const EdgeInsets.all(AppDimensions.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppDimensions.sm),
            decoration: BoxDecoration(
              color: _dangerRed.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              AppIcons.warningCircleFill,
              color: _dangerRed,
              size: AppDimensions.iconMd,
            ),
          ),
          const SizedBox(width: AppDimensions.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  log['description'].toString(),
                  style: const TextStyle(
                    fontSize: AppDimensions.fontDefault,
                    fontWeight: FontWeight.w800,
                    color: _primaryNavy,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: AppDimensions.sm),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      size: 12,
                      color: Colors.blueGrey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$formattedDay  •  $formattedTime',
                      style: const TextStyle(
                        fontSize: AppDimensions.fontSm,
                        fontWeight: FontWeight.w600,
                        color: Colors.blueGrey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.person, size: 12, color: Colors.blueGrey),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${log['patun']}',
                        style: const TextStyle(
                          fontSize: AppDimensions.fontSm,
                          fontWeight: FontWeight.w600,
                          color: Colors.blueGrey,
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
          const SizedBox(width: AppDimensions.sm),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _dangerRed.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '${point.toStringAsFixed(2)} Poin',
              style: const TextStyle(
                fontSize: AppDimensions.fontSm,
                fontWeight: FontWeight.w800,
                color: _dangerRed,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EwsSerdikData {
  final double nakScore;
  final int violationCount;

  const _EwsSerdikData({required this.nakScore, required this.violationCount});
}
