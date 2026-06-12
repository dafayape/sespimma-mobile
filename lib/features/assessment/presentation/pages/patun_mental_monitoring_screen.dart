import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sespimma/core/constants/app_dimensions.dart';

import 'package:sespimma/features/leadership_report/domain/services/score_calculator_service.dart';
import 'package:sespimma/features/assessment/presentation/widgets/assessment_search_bar_widget.dart';
import 'package:sespimma/features/assessment/presentation/widgets/status_filter_button_widget.dart';
import 'package:sespimma/features/auth/data/datasources/serdik_real_data.dart';
import 'package:sespimma/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:sespimma/features/auth/presentation/bloc/auth_state.dart';
import 'package:sespimma/features/assessment/presentation/pages/patun_mental_form_screen.dart';

import 'package:sespimma/core/utils/avatar_helper.dart';

class PatunMentalMonitoringScreen extends StatefulWidget {
  const PatunMentalMonitoringScreen({super.key});

  @override
  State<PatunMentalMonitoringScreen> createState() =>
      _PatunMentalMonitoringScreenState();
}

class _PatunMentalMonitoringScreenState
    extends State<PatunMentalMonitoringScreen> {
  static const Color _primaryNavy = Color(0xFF000B1D);
  static const Color _lightGrey = Color(0xFFF8F9FA);

  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  String _selectedFilter = 'Semua';
  final List<String> _filterOptions = ['Semua', 'Aman', 'Warning', 'Kritis'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showInputBottomSheet(BuildContext context) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _InputTypeSheet(
        onReward: () async {
          Navigator.pop(context);
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const PatunMentalFormScreen(isReward: true),
            ),
          );
          if (mounted) setState(() {});
        },
        onPunishment: () async {
          Navigator.pop(context);
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const PatunMentalFormScreen(isReward: false),
            ),
          );
          if (mounted) setState(() {});
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _lightGrey,
      appBar: AppBar(
        backgroundColor: _primaryNavy,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: const Text(
          'Monitoring Mental',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: AppDimensions.fontXxl,
          ),
        ),
        actions: [const SizedBox(width: AppDimensions.sm)],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: 'input_nilai_fab',
            onPressed: () => _showInputBottomSheet(context),
            backgroundColor: _primaryNavy,
            elevation: 6,
            icon: const Icon(Icons.add_rounded, color: Colors.white, size: 22),
            label: const Text(
              'Input Nilai',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: AppDimensions.fontMd,
              ),
            ),
          ),
        ],
      ),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is AuthSuccess) {
            final user = state.user;
            final userPokjar = user.pokjar;

            final baseList = SerdikRealData.records
                .where((r) => r['kelompok_kelas'] == userPokjar)
                .toList();

            final listWithScores = baseList.map((entry) {
              final serdik = Map<String, dynamic>.from(entry);
              final noSerdik = serdik['no_serdik'] as String? ?? '';

              final allRecaps = ScoreCalculatorService.generateRealReports();
              final finalRecap = allRecaps.firstWhere(
                (r) => r.id == noSerdik,
                orElse: () => allRecaps.first,
              );
              final score = finalRecap.mentalScore;

              final String status;
              if (score >= 80.0) {
                status = 'Aman';
              } else if (score >= 70.0) {
                status = 'Warning';
              } else {
                status = 'Kritis';
              }

              serdik['_mock_score'] = score;
              serdik['_mock_status'] = status;
              serdik['_senat_role'] = serdik['jabatan_senat'];
              return serdik;
            }).toList();

            var filteredList = listWithScores.where((serdik) {
              final name = (serdik['nama_lengkap'] ?? '')
                  .toString()
                  .toLowerCase();
              final noSerdik = (serdik['no_serdik'] ?? '')
                  .toString()
                  .toLowerCase();
              final status = (serdik['_mock_status'] as String?) ?? 'Aman';
              final query = _searchQuery.toLowerCase();

              final matchesSearch =
                  name.contains(query) || noSerdik.contains(query);
              final matchesFilter =
                  _selectedFilter == 'Semua' || status == _selectedFilter;

              return matchesSearch && matchesFilter;
            }).toList();

            filteredList.sort((a, b) {
              final scoreA = (a['_mock_score'] as num?)?.toDouble() ?? 100.0;
              final scoreB = (b['_mock_score'] as num?)?.toDouble() ?? 100.0;
              return scoreA.compareTo(scoreB);
            });

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeaderBlock(userPokjar, baseList.length),
                Divider(
                  height: AppDimensions.dividerHeight,
                  color: Colors.grey.shade200,
                  thickness: AppDimensions.dividerHeight,
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      setState(() {});
                      await Future.delayed(const Duration(milliseconds: 500));
                    },
                    color: _primaryNavy,
                    child: filteredList.isEmpty
                        ? CustomScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            slivers: [
                              SliverFillRemaining(child: _buildEmptyState()),
                            ],
                          )
                        : _buildSerdikList(filteredList),
                  ),
                ),
              ],
            );
          }
          return const Center(
            child: CircularProgressIndicator(color: _primaryNavy),
          );
        },
      ),
    );
  }

  Widget _buildHeaderBlock(String pokjar, int totalSerdik) {
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
                  hintText: 'Cari nama atau nomor serdik...',
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
              const SizedBox(width: AppDimensions.md),
              StatusFilterButtonWidget(
                selectedStatus: _selectedFilter,
                statuses: _filterOptions,
                onSelected: (value) {
                  setState(() {
                    _selectedFilter = value;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.lg),
          Row(
            children: [
              const Text(
                'DAFTAR SERDIK',
                style: TextStyle(
                  color: _primaryNavy,
                  fontWeight: FontWeight.w800,
                  fontSize: AppDimensions.fontLg,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(width: AppDimensions.sm),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _primaryNavy,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
                ),
                child: Text(
                  pokjar.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: AppDimensions.fontSm,
                  ),
                ),
              ),
              const Spacer(),
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
                    const Icon(
                      Icons.people_alt_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$totalSerdik Serdik',
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

  Widget _buildEmptyState() {
    final isFiltered = _selectedFilter != 'Semua';
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
              isSearching ? 'Tidak Ditemukan' : 'Tidak Ada Serdik',
              style: TextStyle(
                fontSize: AppDimensions.fontXxl,
                fontWeight: FontWeight.w800,
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: AppDimensions.sm),
            Text(
              isSearching
                  ? 'Tidak ada Serdik yang cocok dengan kata kunci "$_searchQuery".'
                  : isFiltered
                  ? 'Tidak ada Serdik dengan status "$_selectedFilter" di Pokjar Anda.'
                  : 'Belum ada data Serdik untuk Pokjar Anda.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: AppDimensions.fontLg,
                color: Colors.grey.shade400,
                height: 1.5,
              ),
            ),
            if (isSearching || isFiltered) ...[
              const SizedBox(height: AppDimensions.xl),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _searchQuery = '';
                    _searchController.clear();
                    _selectedFilter = 'Semua';
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

  Widget _buildSerdikList(List<Map<String, dynamic>> serdikList) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            AppDimensions.xl,
            AppDimensions.xl,
            AppDimensions.xl,
            AppDimensions.huge + AppDimensions.xxxl,
          ),
          itemCount: serdikList.length,
          separatorBuilder: (context, index) =>
              const SizedBox(height: AppDimensions.md),
          itemBuilder: (context, index) {
            final serdik = serdikList[index];
            final name = (serdik['nama_lengkap'] ?? '-').toString();
            final noSerdik = (serdik['no_serdik'] ?? '-').toString();
            final pangkat = (serdik['pangkat'] ?? '-').toString();
            final double score =
                (serdik['_mock_score'] as num?)?.toDouble() ?? 0.0;
            final String status = (serdik['_mock_status'] as String?) ?? 'Aman';

            return _buildSerdikCard(
              serdik,
              name,
              noSerdik,
              pangkat,
              score,
              status,
            );
          },
        ),
      ),
    );
  }

  Widget _buildSerdikCard(
    Map<String, dynamic> serdik,
    String name,
    String noSerdik,
    String pangkat,
    double score,
    String status,
  ) {
    final Color statusColor;
    final IconData statusIcon;
    final String? senatRole = serdik['_senat_role'] as String?;
    if (status == 'Aman') {
      statusColor = const Color(0xFF2E7D32);
      statusIcon = Icons.check_circle_rounded;
    } else if (status == 'Warning') {
      statusColor = const Color(0xFFF57C00);
      statusIcon = Icons.warning_rounded;
    } else {
      statusColor = const Color(0xFFD32F2F);
      statusIcon = Icons.error_rounded;
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
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
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
          onTap: () {
            HapticFeedback.selectionClick();
          },
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.lg),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildAvatar(serdik),
                const SizedBox(width: AppDimensions.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: AppDimensions.fontLg,
                          fontWeight: FontWeight.w800,
                          color: _primaryNavy,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppDimensions.xs),
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
                      const SizedBox(height: AppDimensions.sm),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, size: 12, color: statusColor),
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(
                                AppDimensions.radiusMd,
                              ),
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
                          if (senatRole != null) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF1A237E,
                                ).withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(
                                  AppDimensions.radiusMd,
                                ),
                                border: Border.all(
                                  color: const Color(
                                    0xFF1A237E,
                                  ).withValues(alpha: 0.2),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.star_rounded,
                                    size: 10,
                                    color: Color(0xFF1A237E),
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    senatRole,
                                    style: const TextStyle(
                                      fontSize: AppDimensions.fontXs,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF1A237E),
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppDimensions.md),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                    border: Border.all(
                      color: statusColor.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'NILAI',
                        style: TextStyle(
                          fontSize: AppDimensions.fontXs,
                          fontWeight: FontWeight.w800,
                          color: statusColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        score.toStringAsFixed(2),
                        style: TextStyle(
                          fontSize: AppDimensions.fontXl,
                          fontWeight: FontWeight.w900,
                          color: statusColor,
                        ),
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

  Widget _buildAvatar(Map<String, dynamic> serdik) {
    final String? profilePhoto =
        serdik['profile_photo'] ?? serdik['profilePhoto'];

    return Container(
      width: AppDimensions.avatarLg,
      height: AppDimensions.avatarLg,
      decoration: BoxDecoration(
        color: _lightGrey,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.grey.shade200, width: 1.5),
        image: DecorationImage(
          image: (profilePhoto != null && profilePhoto.isNotEmpty)
              ? FileImage(File(profilePhoto)) as ImageProvider
              : AvatarHelper.getAvatar(null),
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

class _InputTypeSheet extends StatelessWidget {
  final VoidCallback onReward;
  final VoidCallback onPunishment;

  const _InputTypeSheet({required this.onReward, required this.onPunishment});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppDimensions.xl,
            AppDimensions.lg,
            AppDimensions.xl,
            AppDimensions.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: AppDimensions.handleWidth,
                  height: AppDimensions.bottomSheetHandle,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(
                      AppDimensions.radiusFull,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppDimensions.xl),
              const Text(
                'Input Nilai Mental',
                style: TextStyle(
                  fontSize: AppDimensions.fontXxl,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF000B1D),
                ),
              ),
              const SizedBox(height: AppDimensions.xs),
              Text(
                'Pilih jenis penilaian yang akan diinput',
                style: TextStyle(
                  fontSize: AppDimensions.fontLg,
                  color: Colors.blueGrey.shade400,
                ),
              ),
              const SizedBox(height: AppDimensions.xxl),
              Row(
                children: [
                  Expanded(
                    child: _SheetOptionCard(
                      title: 'Reward',
                      subtitle: 'Penilaian Positif',
                      icon: Icons.thumb_up_rounded,
                      color: const Color(0xFF1B5E20),
                      bgColor: const Color(0xFFE8F5E9),
                      onTap: onReward,
                    ),
                  ),
                  const SizedBox(width: AppDimensions.lg),
                  Expanded(
                    child: _SheetOptionCard(
                      title: 'Punishment',
                      subtitle: 'Penilaian Negatif',
                      icon: Icons.thumb_down_rounded,
                      color: const Color(0xFFB71C1C),
                      bgColor: const Color(0xFFFFEBEE),
                      onTap: onPunishment,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.lg),
            ],
          ),
        ),
      ),
    );
  }
}

class _SheetOptionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Color bgColor;
  final VoidCallback onTap;

  const _SheetOptionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: AppDimensions.xl,
            horizontal: AppDimensions.lg,
          ),
          child: Column(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: color.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: Icon(icon, color: color, size: AppDimensions.iconXl),
              ),
              const SizedBox(height: AppDimensions.md),
              Text(
                title,
                style: TextStyle(
                  fontSize: AppDimensions.fontXl,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
              const SizedBox(height: AppDimensions.xs),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: AppDimensions.fontSm,
                  fontWeight: FontWeight.w500,
                  color: color.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
