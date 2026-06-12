import 'package:sespimma/core/constants/app_dimensions.dart';
import 'package:flutter/material.dart';
import 'package:sespimma/core/utils/icon_mapper.dart';

import 'package:sespimma/features/leadership_report/domain/services/score_calculator_service.dart';
import 'package:sespimma/features/leadership_report/data/models/final_recap_model.dart';
import 'package:sespimma/features/leadership_report/presentation/widgets/ai_recommendation_card.dart';
import 'package:sespimma/features/leadership_report/presentation/widgets/average_stats_card.dart';
import 'package:sespimma/features/leadership_report/presentation/widgets/report_card_item.dart';
import 'package:sespimma/features/leadership_report/presentation/widgets/summary_stats_cards.dart';
import 'package:sespimma/features/assessment/presentation/widgets/assessment_search_bar_widget.dart';
import 'package:sespimma/features/assessment/presentation/widgets/status_filter_button_widget.dart';
import 'package:sespimma/features/leadership_report/presentation/pages/pimpinan_generate_report_screen.dart';

class LeadershipReportScreen extends StatefulWidget {
  const LeadershipReportScreen({super.key});

  @override
  State<LeadershipReportScreen> createState() => _LeadershipReportScreenState();
}

class _LeadershipReportScreenState extends State<LeadershipReportScreen>
    with SingleTickerProviderStateMixin {
  AnimationController? _animController;
  String _searchQuery = '';
  String _selectedPokjar = 'Semua';
  String _selectedStatusFilter = 'Semua Status';
  bool _isSortDesc = true;

  static const Color _primaryNavy = Color(0xFF000B1D);
  static const Color _lightGrey = Color(0xFFF8F9FA);

  List<String> get _pokjars => [
    'Semua',
    'POKJAR I',
    'POKJAR II',
    'POKJAR III',
    'POKJAR IV',
    'POKJAR V',
  ];

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _animController?.forward();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animController?.dispose();
    super.dispose();
  }

  List<FinalRecapModel> get _allReports =>
      ScoreCalculatorService.generateRealReports();

  List<FinalRecapModel> get _filteredReports {
    final result = _allReports.where((report) {
      final String selectedP = _selectedPokjar.trim().toLowerCase();
      final bool matchesPokjar =
          selectedP == 'semua' ||
          report.pokjar.trim().toLowerCase() == selectedP;

      final bool matchesStatus =
          _selectedStatusFilter == 'Semua Status' ||
          (_selectedStatusFilter == 'Lulus' && report.average >= 70.0) ||
          (_selectedStatusFilter == 'Tidak Lulus' && report.average < 70.0);

      final String query = _searchQuery.trim().toLowerCase();
      final bool matchesSearch =
          query.isEmpty ||
          report.name.toLowerCase().contains(query) ||
          report.nrp.toLowerCase().contains(query);

      return matchesPokjar && matchesStatus && matchesSearch;
    }).toList();

    result.sort((a, b) {
      if (_isSortDesc) {
        return b.average.compareTo(a.average);
      } else {
        return a.average.compareTo(b.average);
      }
    });

    return result;
  }

  Widget _buildAnimatedSection({
    required Widget child,
    required double beginInterval,
    required double endInterval,
  }) {
    if (_animController == null) return child;
    return FadeTransition(
      opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _animController!,
          curve: Interval(beginInterval, endInterval, curve: Curves.easeOut),
        ),
      ),
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero)
            .animate(
              CurvedAnimation(
                parent: _animController!,
                curve: Interval(
                  beginInterval,
                  endInterval,
                  curve: Curves.easeOutQuart,
                ),
              ),
            ),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredReports;

    final int lulusCount = filtered.where((r) => r.average >= 70.0).length;
    final int peringatanCount = filtered.where((r) => r.average < 70.0).length;

    return Scaffold(
      backgroundColor: _lightGrey,
      appBar: AppBar(
        backgroundColor: _primaryNavy,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: const Text(
          'Laporan Nilai',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: AppDimensions.fontXxl,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(AppIcons.downloadSimple, color: Colors.white),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const PimpinanGenerateReportScreen(),
              ),
            ),
          ),
          const SizedBox(width: AppDimensions.sm),
        ],
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: _buildAnimatedSection(
              beginInterval: 0.0,
              endInterval: 0.4,
              child: Column(
                children: [
                  const SizedBox(height: AppDimensions.xl),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: SummaryStatsCards(
                      lulusCount: lulusCount,
                      peringatanCount: peringatanCount,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.xl),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: AverageStatsCard(data: _allReports),
                  ),
                  const SizedBox(height: AppDimensions.xl),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Builder(
                      builder: (context) {
                        double academicAvg = 0;
                        double mentalAvg = 0;
                        double physicalAvg = 0;

                        if (filtered.isNotEmpty) {
                          academicAvg =
                              filtered
                                  .map((e) => e.academicScore)
                                  .reduce((a, b) => a + b) /
                              filtered.length;
                          mentalAvg =
                              filtered
                                  .map((e) => e.mentalScore)
                                  .reduce((a, b) => a + b) /
                              filtered.length;
                          physicalAvg =
                              filtered
                                  .map((e) => e.physicalScore)
                                  .reduce((a, b) => a + b) /
                              filtered.length;
                        }

                        return AiRecommendationCard(
                          academicScore: academicAvg,
                          mentalScore: mentalAvg,
                          physicalScore: physicalAvg,
                          title: 'Rekomendasi $_selectedPokjar',
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: _buildAnimatedSection(
              beginInterval: 0.2,
              endInterval: 0.6,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppDimensions.lg),
                  _buildSectionTitle('DAFTAR REKAPITULASI NILAI'),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Expanded(
                          child: AssessmentSearchBarWidget(
                            controller: _searchController,
                            searchQuery: _searchQuery,
                            hintText: 'Cari Nama/NRP...',
                            onChanged: (val) =>
                                setState(() => _searchQuery = val),
                            onClear: () => setState(() {
                              _searchQuery = '';
                              _searchController.clear();
                            }),
                          ),
                        ),
                        const SizedBox(width: AppDimensions.sm),
                        StatusFilterButtonWidget(
                          selectedStatus: _selectedPokjar,
                          statuses: _pokjars,
                          onSelected: (val) =>
                              setState(() => _selectedPokjar = val),
                          defaultStatus: 'Semua',
                          icon: Icons.groups_rounded,
                          tooltip: 'Filter Pokjar',
                        ),
                        const SizedBox(width: AppDimensions.sm),
                        StatusFilterButtonWidget(
                          selectedStatus: _selectedStatusFilter,
                          statuses: const [
                            'Semua Status',
                            'Lulus',
                            'Tidak Lulus',
                          ],
                          onSelected: (val) =>
                              setState(() => _selectedStatusFilter = val),
                          defaultStatus: 'Semua Status',
                          icon: AppIcons.funnelFill,
                          tooltip: 'Filter Status',
                        ),
                        const SizedBox(width: AppDimensions.sm),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(
                              AppDimensions.radiusLg,
                            ),
                            border: Border.all(color: Colors.grey.shade200),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.02),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: IconButton(
                            icon: Icon(
                              _isSortDesc ? Icons.sort : Icons.sort_by_alpha,
                              color: _primaryNavy,
                              size: AppDimensions.iconSm,
                            ),
                            tooltip: 'Urutkan NAK',
                            onPressed: () {
                              setState(() {
                                _isSortDesc = !_isSortDesc;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: AppDimensions.xl)),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 60),
            sliver: filtered.isEmpty
                ? SliverToBoxAdapter(child: _buildEmptyState())
                : SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _buildAnimatedSection(
                        beginInterval: 0.4 + (index * 0.05).clamp(0.0, 0.4),
                        endInterval: 0.8 + (index * 0.05).clamp(0.0, 0.2),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: ReportCardItem(data: filtered[index]),
                        ),
                      ),
                      childCount: filtered.length,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: AppDimensions.fontSm + 1,
          fontWeight: FontWeight.w900,
          color: Colors.blueGrey.shade400,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: AppDimensions.avatarMd),
          Icon(
            AppIcons.magnifyingGlassFill,
            size: AppDimensions.iconDisplay,
            color: Colors.blueGrey.shade200,
          ),
          const SizedBox(height: AppDimensions.md),
          Text(
            'Data tidak ditemukan',
            style: TextStyle(
              fontSize: AppDimensions.fontXl,
              fontWeight: FontWeight.w600,
              color: Colors.blueGrey.shade400,
            ),
          ),
        ],
      ),
    );
  }
}
