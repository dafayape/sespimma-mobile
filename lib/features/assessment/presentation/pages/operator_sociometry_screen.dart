import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sespimma/core/constants/app_dimensions.dart';
import 'package:sespimma/core/utils/app_notifier.dart';
import 'package:sespimma/core/utils/avatar_helper.dart';
import 'package:sespimma/features/assessment/data/datasources/assessment_remote_data_source.dart';
import 'package:sespimma/features/assessment/presentation/widgets/assessment_search_bar_widget.dart';
import 'package:sespimma/features/assessment/presentation/widgets/status_filter_button_widget.dart';
import 'package:sespimma/injection_container.dart';

class OperatorSociometryScreen extends StatefulWidget {
  const OperatorSociometryScreen({super.key});

  @override
  State<OperatorSociometryScreen> createState() => _OperatorSociometryScreenState();
}

class _OperatorSociometryScreenState extends State<OperatorSociometryScreen> {
  static const Color _primaryNavy = Color(0xFF000B1D);
  static const Color _lightGrey = Color(0xFFF8F9FA);

  List<Map<String, dynamic>> _students = [];
  bool _isLoading = true;

  String _searchQuery = '';
  String _selectedFilter = 'Semua';
  final TextEditingController _searchController = TextEditingController();

  final List<String> _filterOptions = [
    'Semua',
    'POKJAR I',
    'POKJAR II',
    'POKJAR III',
    'POKJAR IV',
    'POKJAR V',
  ];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final dataSource = sl<AssessmentRemoteDataSource>();
      final list = await dataSource.getAllMentalScores();
      if (mounted) {
        setState(() {
          _students = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        AppNotifier.showError(context, 'Gagal memuat data sosiometri: $e');
      }
    }
  }

  Color _getScoreColor(double score) {
    if (score == 0) return _primaryNavy;
    if (score >= 85.01) return Colors.green.shade700;
    if (score >= 80.01) return Colors.lightGreen.shade700;
    if (score >= 75.01) return Colors.orange.shade700;
    if (score >= 70.00) return Colors.amber.shade700;
    return Colors.red.shade700;
  }

  String _getScoreCategory(double score) {
    if (score == 0) return '-';
    if (score >= 85.01) return 'Sangat Memuaskan (SM)';
    if (score >= 80.01) return 'Memuaskan (M)';
    if (score >= 75.01) return 'Baik (B)';
    if (score >= 70.00) return 'Cukup (C)';
    return 'Kurang (K)';
  }

  void _showGradingDialog(Map<String, dynamic> student) {
    final noSerdik = (student['no_serdik'] ?? student['nip'] ?? student['nrp'] ?? '').toString();
    final name = (student['nama_lengkap'] ?? student['name'] ?? '-').toString();
    final double currentVal = (student['sosiometri'] as num?)?.toDouble() ?? 0.0;

    final TextEditingController controller = TextEditingController(
      text: currentVal > 0 ? currentVal.toStringAsFixed(2) : '',
    );

    bool dialogSaving = false;

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (dialogCtx2, setStateDialog) {
            final double currentScore = double.tryParse(controller.text) ?? 0.0;
            final Color scoreColor = _getScoreColor(currentScore);
            final String scoreCategory = _getScoreCategory(currentScore);

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
              ),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Input Sosiometri',
                    style: TextStyle(
                      color: _primaryNavy,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    name,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: AppDimensions.fontSm,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: controller,
                    enabled: !dialogSaving,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                    ],
                    decoration: InputDecoration(
                      hintText: 'Masukkan nilai sosiometri (0-100)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                        borderSide: const BorderSide(
                          color: _primaryNavy,
                          width: 2,
                        ),
                      ),
                    ),
                    onChanged: (val) {
                      final parsed = double.tryParse(val) ?? 0.0;
                      if (parsed > 100) {
                        controller.text = '100.00';
                        controller.selection = TextSelection.fromPosition(
                          const TextPosition(offset: 6),
                        );
                      }
                      setStateDialog(() {});
                    },
                  ),
                  const SizedBox(height: AppDimensions.lg),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      color: currentScore > 0
                          ? scoreColor.withValues(alpha: 0.1)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                      border: Border.all(
                        color: currentScore > 0
                            ? scoreColor.withValues(alpha: 0.5)
                            : Colors.grey.shade300,
                      ),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'PREDIKAT',
                          style: TextStyle(
                            fontSize: AppDimensions.fontXs,
                            fontWeight: FontWeight.w800,
                            color: Colors.blueGrey,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          scoreCategory,
                          style: TextStyle(
                            fontSize: AppDimensions.fontMd,
                            fontWeight: FontWeight.w800,
                            color: currentScore > 0 ? scoreColor : Colors.grey.shade500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: dialogSaving ? null : () => Navigator.pop(dialogCtx2),
                  child: const Text(
                    'Batal',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryNavy,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                    ),
                  ),
                  onPressed: dialogSaving
                      ? null
                      : () async {
                          final val = double.tryParse(controller.text);
                          if (val != null) {
                            setStateDialog(() {
                              dialogSaving = true;
                            });
                            try {
                              final dataSource = sl<AssessmentRemoteDataSource>();
                              await dataSource.updateMental(noSerdik, {'sosiometri': val});
                              _fetchData();
                              if (dialogCtx2.mounted) {
                                Navigator.pop(dialogCtx2);
                                AppNotifier.showSuccess(
                                  dialogCtx2,
                                  'Nilai Sosiometri berhasil disimpan',
                                );
                              }
                            } catch (e) {
                              setStateDialog(() {
                                dialogSaving = false;
                              });
                              if (dialogCtx2.mounted) {
                                AppNotifier.showError(
                                  dialogCtx2,
                                  'Gagal menyimpan nilai: $e',
                                );
                              }
                            }
                          }
                        },
                  child: dialogSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Simpan'),
                ),
              ],
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
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: const Text(
          'Monitoring Sosiometri',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: AppDimensions.fontXxl,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: _primaryNavy),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeaderBlock(),
                Divider(
                  height: AppDimensions.dividerHeight,
                  color: Colors.grey.shade200,
                  thickness: AppDimensions.dividerHeight,
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _fetchData,
                    color: _primaryNavy,
                    child: _buildFilteredList(),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildHeaderBlock() {
    var filteredList = _students.where((serdik) {
      final name = (serdik['name'] ?? serdik['nama_lengkap'] ?? '').toString().toLowerCase();
      final noSerdik = (serdik['nip'] ?? serdik['nrp'] ?? serdik['no_serdik'] ?? '').toString().toLowerCase();
      final query = _searchQuery.toLowerCase();
      return name.contains(query) || noSerdik.contains(query);
    }).toList();

    if (_selectedFilter != 'Semua') {
      final targetPokjar = _selectedFilter;
      filteredList = filteredList.where((serdik) {
        final pokjar = (serdik['group_name'] ?? serdik['kelompok_kelas'] ?? '').toString().toUpperCase();
        return pokjar == targetPokjar;
      }).toList();
    }

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
              const Expanded(
                child: Text(
                  'DAFTAR SERDIK',
                  style: TextStyle(
                    color: _primaryNavy,
                    fontWeight: FontWeight.w800,
                    fontSize: AppDimensions.fontLg,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: AppDimensions.md),
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
                      '${filteredList.length} Serdik',
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

  Widget _buildFilteredList() {
    var filteredList = _students.where((serdik) {
      final name = (serdik['name'] ?? serdik['nama_lengkap'] ?? '').toString().toLowerCase();
      final noSerdik = (serdik['nip'] ?? serdik['nrp'] ?? serdik['no_serdik'] ?? '').toString().toLowerCase();
      final query = _searchQuery.toLowerCase();
      return name.contains(query) || noSerdik.contains(query);
    }).toList();

    if (_selectedFilter != 'Semua') {
      final targetPokjar = _selectedFilter;
      filteredList = filteredList.where((serdik) {
        final pokjar = (serdik['group_name'] ?? serdik['kelompok_kelas'] ?? '').toString().toUpperCase();
        return pokjar == targetPokjar;
      }).toList();
    }

    if (filteredList.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppDimensions.xl),
      itemCount: filteredList.length,
      separatorBuilder: (context, index) => const SizedBox(height: AppDimensions.md),
      itemBuilder: (context, index) {
        final student = filteredList[index];
        return _buildSerdikCard(student);
      },
    );
  }

  Widget _buildSerdikCard(Map<String, dynamic> student) {
    final noSerdik = (student['nip'] ?? student['nrp'] ?? student['no_serdik'] ?? '').toString();
    final name = (student['name'] ?? student['nama_lengkap'] ?? '-').toString();
    final pangkat = (student['pangkat'] ?? '-').toString();
    final double sosiometri = (student['sosiometri'] as num?)?.toDouble() ?? 0.0;

    final String rawPokjar = (student['group_name'] ?? student['kelompok_kelas'] ?? '-').toString().toUpperCase();
    final Map<String, String> pokjarMap = {
      'POKJAR I': 'POKJAR I',
      'POKJAR II': 'POKJAR II',
      'POKJAR III': 'POKJAR III',
      'POKJAR IV': 'POKJAR IV',
      'POKJAR V': 'POKJAR V',
    };
    final String displayPokjar = pokjarMap[rawPokjar] ?? rawPokjar;

    final bool isGraded = sosiometri > 0;
    final Color scoreColor = isGraded ? _getScoreColor(sosiometri) : Colors.grey;

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
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.lg),
        child: Row(
          children: [
            _buildAvatar(student),
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
                  ),
                  const SizedBox(height: AppDimensions.xs),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.xs,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blueGrey.shade50,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                    ),
                    child: Text(
                      displayPokjar,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: Colors.blueGrey.shade600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppDimensions.md),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isGraded ? scoreColor.withValues(alpha: 0.1) : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                  ),
                  child: Column(
                    children: [
                      Text(
                        isGraded ? 'SOSIOMETRI' : 'BELUM DINILAI',
                        style: TextStyle(
                          fontSize: AppDimensions.fontXs - 1,
                          fontWeight: FontWeight.w800,
                          color: isGraded ? scoreColor : Colors.grey.shade500,
                        ),
                      ),
                      Text(
                        isGraded ? sosiometri.toStringAsFixed(2) : '-',
                        style: TextStyle(
                          fontSize: AppDimensions.fontXl,
                          fontWeight: FontWeight.w900,
                          color: isGraded ? scoreColor : Colors.grey.shade400,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    _showGradingDialog(student);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryNavy,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    minimumSize: const Size(0, 36),
                  ),
                  child: const Text(
                    'Nilai',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: AppDimensions.fontSm,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(Map<String, dynamic> serdik) {
    final String? profilePhoto = serdik['profile_photo'] ?? serdik['profilePhoto'];
    return Container(
      width: 56,
      height: 56,
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
                isSearching ? Icons.search_off_rounded : Icons.person_search_rounded,
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
                  : 'Belum ada data Serdik.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: AppDimensions.fontLg,
                color: Colors.grey.shade400,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
