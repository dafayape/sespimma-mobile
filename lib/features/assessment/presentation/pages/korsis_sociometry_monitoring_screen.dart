import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sespimma/core/constants/app_dimensions.dart';
import 'package:sespimma/core/utils/icon_mapper.dart';
import 'package:sespimma/features/auth/data/datasources/serdik_real_data.dart';
import 'package:sespimma/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:sespimma/features/auth/presentation/bloc/auth_state.dart';
import 'patun_sociometry_detail_screen.dart';
import '../../data/models/sociometry_period_config.dart';
import 'package:sespimma/core/utils/app_notifier.dart';
import 'package:sespimma/core/utils/avatar_helper.dart';

class KorsisSociometryMonitoringScreen extends StatefulWidget {
  const KorsisSociometryMonitoringScreen({super.key});

  @override
  State<KorsisSociometryMonitoringScreen> createState() =>
      _KorsisSociometryMonitoringScreenState();
}

class _KorsisSociometryMonitoringScreenState
    extends State<KorsisSociometryMonitoringScreen> {
  static const Color _primaryNavy = Color(0xFF000B1D);
  static const Color _primaryIndigo = Color(0xFF4F46E5);
  static const Color _lightGrey = Color(0xFFF8F9FA);

  bool _isPhaseAwal = true;
  String _selectedPokjar = 'Semua Pokjar';
  final List<String> _pokjarOptions = [
    'Semua Pokjar',
    'POKJAR I',
    'POKJAR II',
    'POKJAR III',
    'POKJAR IV',
    'POKJAR V',
  ];

  String _selectedStatus = 'Semua Status';
  final List<String> _statusOptions = [
    'Semua Status',
    'Tuntas',
    'Proses',
    'Belum',
  ];

  bool get _isCurrentPhaseActive => _isPhaseAwal
      ? SociometryPeriodConfig.isAwalActive()
      : SociometryPeriodConfig.isAkhirActive();

  bool get _isCurrentPhaseClosed => _isPhaseAwal
      ? SociometryPeriodConfig.isAwalClosed()
      : SociometryPeriodConfig.isAkhirClosed();

  @override
  void initState() {
    super.initState();
    _isPhaseAwal = !SociometryPeriodConfig.isAkhirActive();
  }

  int _getFilledEvaluations(String nrp, int totalSerdik) {
    if (!_isCurrentPhaseActive && !_isCurrentPhaseClosed) return 0;

    if (nrp == '77110075') {
      final peers = _isPhaseAwal
          ? SociometryPeriodConfig.peersAwal
          : SociometryPeriodConfig.peersAkhir;
      final evaluated = peers.where((p) => p.isEvaluated).length;
      final totalPeers = peers.length;

      if (totalPeers == 0) return 0;

      return ((evaluated / totalPeers) * totalSerdik).round();
    }

    int hash = nrp.hashCode;
    if (!_isPhaseAwal) hash += 1000;

    if (hash % 10 > 3) return totalSerdik;
    return hash % (totalSerdik + 1);
  }

  int _getPokjarSize(String pokjar, List<Map<String, dynamic>> allSerdik) {
    return allSerdik.where((s) => s['kelompok_kelas'] == pokjar).length;
  }

  String _getSerdikStatus(
    Map<String, dynamic> serdik,
    List<Map<String, dynamic>> allSerdik,
  ) {
    final int total = _getPokjarSize(serdik['kelompok_kelas'], allSerdik);
    final int filled = _getFilledEvaluations(serdik['nrp'], total);

    if (filled == total) return 'Tuntas';
    if (filled == 0) return 'Belum';
    return 'Proses';
  }

  String _getRealPokjar(String romanPokjar) {
    switch (romanPokjar) {
      case 'POKJAR I':
        return 'POKJAR I';
      case 'POKJAR II':
        return 'POKJAR II';
      case 'POKJAR III':
        return 'POKJAR III';
      case 'POKJAR IV':
        return 'POKJAR IV';
      case 'POKJAR V':
        return 'POKJAR V';
      default:
        return romanPokjar;
    }
  }

  String _formatPokjarName(String realPokjar) {
    switch (realPokjar.toUpperCase()) {
      case 'POKJAR I':
        return 'POKJAR I';
      case 'POKJAR II':
        return 'POKJAR II';
      case 'POKJAR III':
        return 'POKJAR III';
      case 'POKJAR IV':
        return 'POKJAR IV';
      case 'POKJAR V':
        return 'POKJAR V';
      default:
        return realPokjar;
    }
  }

  String _formatIndoDate(DateTime date) {
    final List<String> months = [
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
    return "${date.day} ${months[date.month - 1]} ${date.year}";
  }

  String _getDynamicPeriodRange(bool isAwal) {
    final start = isAwal
        ? SociometryPeriodConfig.awalStartDate
        : SociometryPeriodConfig.akhirStartDate;
    final end = isAwal
        ? SociometryPeriodConfig.awalEndDate
        : SociometryPeriodConfig.akhirEndDate;
    return "${_formatIndoDate(start)} - ${_formatIndoDate(end)}";
  }

  void _toggleLock() {
    setState(() {
      if (_isPhaseAwal) {
        final currentlyActive = SociometryPeriodConfig.isAwalActive();
        SociometryPeriodConfig.isAwalUnlockedForce = !currentlyActive;
      } else {
        final currentlyActive = SociometryPeriodConfig.isAkhirActive();
        SociometryPeriodConfig.isAkhirUnlockedForce = !currentlyActive;
      }
    });

    if (_isCurrentPhaseActive) {
      AppNotifier.showSuccess(context, 'Sosiometri Dibuka');
    } else {
      AppNotifier.showError(context, 'Sosiometri Ditutup');
    }
  }

  void _showSettingsSheet() {
    bool isAwalLocal = _isPhaseAwal;
    DateTime startLocal = isAwalLocal
        ? SociometryPeriodConfig.awalStartDate
        : SociometryPeriodConfig.akhirStartDate;
    DateTime endLocal = isAwalLocal
        ? SociometryPeriodConfig.awalEndDate
        : SociometryPeriodConfig.akhirEndDate;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppDimensions.xl),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: _primaryNavy.withValues(alpha: 0.05),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.settings_suggest_rounded,
                              color: _primaryNavy,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: AppDimensions.md),
                          const Text(
                            'Pengaturan Sosiometri',
                            style: TextStyle(
                              fontSize: AppDimensions.fontXl,
                              fontWeight: FontWeight.w800,
                              color: _primaryNavy,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(
                              Icons.close_rounded,
                              color: Colors.grey,
                            ),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppDimensions.xl),
                      Container(
                        padding: const EdgeInsets.all(AppDimensions.lg),
                        decoration: BoxDecoration(
                          color: _lightGrey,
                          borderRadius: BorderRadius.circular(
                            AppDimensions.radiusLg,
                          ),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.school_rounded,
                                  size: 20,
                                  color: _primaryNavy,
                                ),
                                const SizedBox(width: AppDimensions.sm),
                                Text(
                                  'Fase Pendidikan',
                                  style: TextStyle(
                                    fontSize: AppDimensions.fontSm + 1,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.blueGrey.shade700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppDimensions.sm),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.02),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<bool>(
                                  value: isAwalLocal,
                                  isExpanded: true,
                                  icon: const Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    color: _primaryNavy,
                                  ),
                                  items: const [
                                    DropdownMenuItem(
                                      value: true,
                                      child: Text(
                                        'Awal Pendidikan',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: _primaryNavy,
                                        ),
                                      ),
                                    ),
                                    DropdownMenuItem(
                                      value: false,
                                      child: Text(
                                        'Akhir Pendidikan',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: _primaryNavy,
                                        ),
                                      ),
                                    ),
                                  ],
                                  onChanged: (val) {
                                    if (val != null) {
                                      setSheetState(() {
                                        isAwalLocal = val;
                                        startLocal = isAwalLocal
                                            ? SociometryPeriodConfig
                                                  .awalStartDate
                                            : SociometryPeriodConfig
                                                  .akhirStartDate;
                                        endLocal = isAwalLocal
                                            ? SociometryPeriodConfig.awalEndDate
                                            : SociometryPeriodConfig
                                                  .akhirEndDate;
                                      });
                                    }
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppDimensions.lg),
                      Row(
                        children: [
                          Expanded(
                            child: _buildDatePickerCard(
                              context: context,
                              label: 'Tanggal Mulai',
                              date: startLocal,
                              icon: Icons.event_available_rounded,
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: startLocal,
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime(2100),
                                  builder: (context, child) {
                                    return Theme(
                                      data: Theme.of(context).copyWith(
                                        colorScheme: const ColorScheme.light(
                                          primary: _primaryNavy,
                                          onPrimary: Colors.white,
                                          onSurface: _primaryNavy,
                                        ),
                                      ),
                                      child: child!,
                                    );
                                  },
                                );
                                if (picked != null) {
                                  setSheetState(() => startLocal = picked);
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: AppDimensions.md),
                          Expanded(
                            child: _buildDatePickerCard(
                              context: context,
                              label: 'Tanggal Selesai',
                              date: endLocal,
                              icon: Icons.event_busy_rounded,
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: endLocal,
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime(2100),
                                  builder: (context, child) {
                                    return Theme(
                                      data: Theme.of(context).copyWith(
                                        colorScheme: const ColorScheme.light(
                                          primary: _primaryNavy,
                                          onPrimary: Colors.white,
                                          onSurface: _primaryNavy,
                                        ),
                                      ),
                                      child: child!,
                                    );
                                  },
                                );
                                if (picked != null) {
                                  setSheetState(() => endLocal = picked);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppDimensions.xxl),
                      ElevatedButton(
                        onPressed: () {
                          if (isAwalLocal) {
                            SociometryPeriodConfig.setAwalPeriod(
                              startLocal,
                              endLocal,
                            );
                            SociometryPeriodConfig.isAwalUnlockedForce = null;
                          } else {
                            SociometryPeriodConfig.setAkhirPeriod(
                              startLocal,
                              endLocal,
                            );
                            SociometryPeriodConfig.isAkhirUnlockedForce = null;
                          }

                          setState(() {
                            _isPhaseAwal = isAwalLocal;
                          });

                          Navigator.pop(context);
                          AppNotifier.showSuccess(
                            context,
                            'Pengaturan berhasil disimpan',
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryNavy,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'SIMPAN PENGATURAN',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _lightGrey,
      appBar: AppBar(
        backgroundColor: _primaryNavy,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Monitoring Sosiometri',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: AppDimensions.fontXxl,
          ),
        ),
        centerTitle: true,
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: 'settings_fab',
            onPressed: _showSettingsSheet,
            backgroundColor: Colors.white,
            elevation: 4,
            child: const Icon(Icons.edit_calendar_rounded, color: _primaryNavy),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            heroTag: 'lock_fab',
            onPressed: _toggleLock,
            backgroundColor: _isCurrentPhaseActive ? Colors.red : Colors.green,
            elevation: 4,
            child: Icon(
              _isCurrentPhaseActive
                  ? Icons.lock_outline_rounded
                  : Icons.lock_open_rounded,
              color: Colors.white,
            ),
          ),
        ],
      ),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is AuthSuccess) {
            List<Map<String, dynamic>> allSerdik = SerdikRealData.records;
            List<Map<String, dynamic>> serdikList = allSerdik;

            if (_selectedPokjar != 'Semua Pokjar') {
              final realPokjar = _getRealPokjar(_selectedPokjar);
              serdikList = serdikList
                  .where((s) => s['kelompok_kelas'] == realPokjar)
                  .toList();
            }

            if (_selectedStatus != 'Semua Status') {
              serdikList = serdikList
                  .where(
                    (s) => _getSerdikStatus(s, allSerdik) == _selectedStatus,
                  )
                  .toList();
            }

            int totalCompleted = 0;
            for (var s in serdikList) {
              final int totalInPokjar = _getPokjarSize(
                s['kelompok_kelas'],
                allSerdik,
              );
              if (_getFilledEvaluations(s['nrp'], totalInPokjar) ==
                  totalInPokjar) {
                totalCompleted++;
              }
            }

            final double progressPercent = serdikList.isNotEmpty
                ? totalCompleted / serdikList.length
                : 0;

            return Column(
              children: [
                _buildPhaseSelector(),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      setState(() {});
                      await Future.delayed(const Duration(milliseconds: 500));
                    },
                    color: _primaryNavy,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildProgressBanner(
                            progressPercent,
                            totalCompleted,
                            serdikList.length,
                          ),
                          const SizedBox(height: AppDimensions.lg),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Text(
                                    'DAFTAR SERDIK',
                                    style: TextStyle(
                                      fontSize: AppDimensions.fontLg,
                                      fontWeight: FontWeight.w800,
                                      color: _primaryNavy,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  if (_selectedPokjar != 'Semua Pokjar') ...[
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _primaryNavy,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        _selectedPokjar,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                          fontSize: AppDimensions.fontXs,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                  ],
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _primaryNavy,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          AppIcons.usersFill,
                                          size: 12,
                                          color: Colors.white,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${serdikList.length} Serdik',
                                          style: const TextStyle(
                                            fontSize: AppDimensions.fontXs,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  _buildFilterDropdown(
                                    icon: AppIcons.usersFill,
                                    value: _selectedPokjar,
                                    options: _pokjarOptions,
                                    onChanged: (val) {
                                      setState(() => _selectedPokjar = val);
                                    },
                                  ),
                                  const SizedBox(width: 8),
                                  _buildFilterDropdown(
                                    icon: AppIcons.funnelFill,
                                    value: _selectedStatus,
                                    options: _statusOptions,
                                    iconColor: _selectedStatus == 'Tuntas'
                                        ? Colors.green
                                        : (_selectedStatus == 'Belum'
                                              ? Colors.red
                                              : _primaryNavy),
                                    onChanged: (val) {
                                      setState(() => _selectedStatus = val);
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: AppDimensions.md),
                          if (serdikList.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: AppDimensions.xxxl,
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(
                                        AppDimensions.xl,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.blueGrey.shade50,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        AppIcons.usersFill,
                                        size: 48,
                                        color: Colors.blueGrey.shade300,
                                      ),
                                    ),
                                    const SizedBox(height: AppDimensions.lg),
                                    Text(
                                      'Tidak ada data sosiometri',
                                      style: TextStyle(
                                        fontSize: AppDimensions.fontLg,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.blueGrey.shade400,
                                      ),
                                    ),
                                    const SizedBox(height: AppDimensions.sm),
                                    Text(
                                      'Coba ubah filter pokjar atau status',
                                      style: TextStyle(
                                        fontSize: AppDimensions.fontSm,
                                        color: Colors.blueGrey.shade300,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: serdikList.length,
                              separatorBuilder: (context, index) =>
                                  const SizedBox(height: AppDimensions.md),
                              itemBuilder: (context, index) {
                                return _buildPeerTile(
                                  context,
                                  index,
                                  serdikList,
                                  allSerdik,
                                );
                              },
                            ),
                          const SizedBox(height: AppDimensions.xl),
                        ],
                      ),
                    ),
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

  Widget _buildPhaseSelector() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.xs),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        ),
        child: Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _isPhaseAwal = true);
                },
                borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: _isPhaseAwal ? _primaryNavy : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                    boxShadow: _isPhaseAwal
                        ? [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    'Awal Pendidikan',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: AppDimensions.fontDefault,
                      fontWeight: FontWeight.w800,
                      color: _isPhaseAwal
                          ? Colors.white
                          : Colors.blueGrey.shade400,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: InkWell(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _isPhaseAwal = false);
                },
                borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: !_isPhaseAwal ? _primaryNavy : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                    boxShadow: !_isPhaseAwal
                        ? [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    'Akhir Pendidikan',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: AppDimensions.fontDefault,
                      fontWeight: FontWeight.w800,
                      color: !_isPhaseAwal
                          ? Colors.white
                          : Colors.blueGrey.shade400,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBanner(
    double percentage,
    int totalCompleted,
    int totalSerdik,
  ) {
    final periodLabel = _getDynamicPeriodRange(_isPhaseAwal);
    return Container(
      padding: const EdgeInsets.all(AppDimensions.lg),
      decoration: BoxDecoration(
        color: _primaryNavy,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXxl),
        boxShadow: [
          BoxShadow(
            color: _primaryIndigo.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'TAHAP AKTIF',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: AppDimensions.fontSm + 1,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.xs),
                  Text(
                    _isPhaseAwal ? 'SOSIOMETRI AWAL' : 'SOSIOMETRI AKHIR',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: AppDimensions.fontXxl,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(AppDimensions.sm + 2),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  AppIcons.chartBarFill,
                  color: Colors.white,
                  size: AppDimensions.iconLg,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.md),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.calendar_month_rounded,
                  color: Colors.white,
                  size: AppDimensions.fontLg,
                ),
                const SizedBox(width: AppDimensions.sm),
                Text(
                  'Periode: $periodLabel',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: AppDimensions.fontSm + 1,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tuntas: $totalCompleted dari $totalSerdik Serdik',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: AppDimensions.fontDefault,
                ),
              ),
              Text(
                '${(percentage * 100).toInt()}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: AppDimensions.fontLg,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
            child: LinearProgressIndicator(
              value: percentage,
              backgroundColor: Colors.white.withValues(alpha: 0.15),
              color: Colors.white,
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeerTile(
    BuildContext context,
    int index,
    List<Map<String, dynamic>> serdikList,
    List<Map<String, dynamic>> allSerdik,
  ) {
    final serdik = serdikList[index];
    final int total = _getPokjarSize(serdik['kelompok_kelas'], allSerdik);
    final int filled = _getFilledEvaluations(serdik['nrp'], total);
    final bool isComplete = filled == total;
    final bool isBelum = filled == 0;

    Color badgeFg;
    Color badgeBg;
    IconData badgeIcon;
    String badgeText;

    if (!_isCurrentPhaseActive) {
      badgeFg = Colors.grey.shade500;
      badgeBg = Colors.grey.shade100;
      badgeIcon = AppIcons.lockFill;
      badgeText = _isCurrentPhaseClosed ? 'Ditutup' : 'Belum Dibuka';
    } else if (isComplete) {
      badgeFg = const Color(0xFF047857);
      badgeBg = const Color(0xFFECFDF5);
      badgeIcon = Icons.check_circle_rounded;
      badgeText = 'Tuntas';
    } else if (isBelum) {
      badgeFg = const Color(0xFFD32F2F);
      badgeBg = const Color(0xFFFFEBEE);
      badgeIcon = Icons.cancel_rounded;
      badgeText = 'Belum';
    } else {
      badgeFg = Colors.orange.shade800;
      badgeBg = Colors.orange.shade50;
      badgeIcon = Icons.pending_actions_rounded;
      badgeText = 'Proses';
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.01),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
          onTap: !_isCurrentPhaseActive
              ? null
              : () {
                  HapticFeedback.mediumImpact();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PatunSociometryDetailScreen(
                        serdikData: serdik,
                        isPhaseAwal: _isPhaseAwal,
                        totalSerdik: total,
                      ),
                    ),
                  );
                },
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.md),
            child: Row(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: _lightGrey,
                      backgroundImage: AvatarHelper.getAvatar(
                        serdik['foto']?.toString(),
                      ),
                    ),
                    if (isComplete)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(AppDimensions.xs / 2),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            AppIcons.checkCircleFill,
                            color: Color(0xFF059669),
                            size: AppDimensions.iconMd,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: AppDimensions.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${serdik['nama_lengkap']}',
                        style: const TextStyle(
                          fontSize: AppDimensions.fontLg,
                          fontWeight: FontWeight.w800,
                          color: _primaryNavy,
                        ),
                      ),
                      const SizedBox(height: AppDimensions.xs),
                      Text(
                        '${serdik['pangkat']} • ${serdik['no_serdik']}',
                        style: TextStyle(
                          fontSize: AppDimensions.fontSm + 1,
                          fontWeight: FontWeight.w600,
                          color: Colors.blueGrey.shade400,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: AppDimensions.xs),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blueGrey.shade50,
                          borderRadius: BorderRadius.circular(
                            AppDimensions.radiusSm,
                          ),
                        ),
                        child: Text(
                          _formatPokjarName(
                            serdik['kelompok_kelas']?.toString() ?? '-',
                          ),
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: Colors.blueGrey.shade600,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppDimensions.sm),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(badgeIcon, size: 12, color: badgeFg),
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: badgeBg,
                              borderRadius: BorderRadius.circular(
                                AppDimensions.radiusMd,
                              ),
                            ),
                            child: Text(
                              badgeText,
                              style: TextStyle(
                                fontSize: AppDimensions.fontXs,
                                fontWeight: FontWeight.w800,
                                color: badgeFg,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
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
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                    border: Border.all(color: badgeFg.withValues(alpha: 0.25)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'SUBMIT',
                        style: TextStyle(
                          fontSize: AppDimensions.fontXs,
                          fontWeight: FontWeight.w800,
                          color: badgeFg,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _isCurrentPhaseActive ? '$filled / $total' : '- / -',
                        style: TextStyle(
                          fontSize: AppDimensions.fontXl,
                          fontWeight: FontWeight.w900,
                          color: badgeFg,
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

  Widget _buildFilterDropdown({
    required IconData icon,
    required String value,
    required List<String> options,
    required Function(String) onChanged,
    Color? iconColor,
  }) {
    return PopupMenuButton<String>(
      onSelected: onChanged,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.sm),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: iconColor ?? _primaryNavy),
            const SizedBox(width: 4),
            Icon(Icons.arrow_drop_down, size: 16, color: Colors.grey.shade600),
          ],
        ),
      ),
      itemBuilder: (BuildContext context) {
        return options.map((String choice) {
          return PopupMenuItem<String>(
            value: choice,
            child: Row(
              children: [
                Icon(
                  value == choice
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  color: value == choice ? _primaryNavy : Colors.grey,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  choice,
                  style: TextStyle(
                    fontWeight: value == choice
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: value == choice ? _primaryNavy : Colors.black87,
                  ),
                ),
              ],
            ),
          );
        }).toList();
      },
    );
  }

  Widget _buildDatePickerCard({
    required BuildContext context,
    required String label,
    required DateTime date,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.md),
      decoration: BoxDecoration(
        color: _lightGrey,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: _primaryNavy),
              const SizedBox(width: AppDimensions.sm),
              Text(
                label,
                style: TextStyle(
                  fontSize: AppDimensions.fontSm + 1,
                  fontWeight: FontWeight.w700,
                  color: Colors.blueGrey.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.sm),
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      _formatIndoDate(date),
                      style: const TextStyle(
                        fontSize: AppDimensions.fontSm + 1,
                        fontWeight: FontWeight.w700,
                        color: _primaryNavy,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(
                    Icons.edit_calendar_rounded,
                    size: 18,
                    color: Colors.blueGrey,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
