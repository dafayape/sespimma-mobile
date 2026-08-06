import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sespimma/core/utils/app_notifier.dart';
import 'package:sespimma/core/constants/app_dimensions.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sespimma/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:sespimma/features/auth/presentation/bloc/auth_state.dart';
import 'package:sespimma/core/utils/avatar_helper.dart';
import 'package:sespimma/features/assessment/data/datasources/assessment_remote_data_source.dart';
import 'package:sespimma/injection_container.dart';

class MedisHealthRecordScreen extends StatefulWidget {
  final Map<String, dynamic> serdik;
  final Map<String, dynamic> initialHealth;
  final VoidCallback onRecordAdded;

  const MedisHealthRecordScreen({
    super.key,
    required this.serdik,
    required this.initialHealth,
    required this.onRecordAdded,
  });

  @override
  State<MedisHealthRecordScreen> createState() =>
      _MedisHealthRecordScreenState();
}

class _MedisHealthRecordScreenState extends State<MedisHealthRecordScreen> {
  static const Color _primaryNavy = Color(0xFF000B1D);
  static const Color _lightGrey = Color(0xFFF8F9FA);

  late Map<String, dynamic> _health;
  bool _isLoading = false;

  String? _selectedType;
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _daysController = TextEditingController();
  String? _photoPath;

  @override
  void initState() {
    super.initState();
    _health = widget.initialHealth;
  }

  Future<void> _fetchHealthData() async {
    final String noSerdik = widget.serdik['no_serdik'].toString();
    try {
      final dataSource = sl<AssessmentRemoteDataSource>();
      final updatedHealth = await dataSource.getHealth(noSerdik);
      if (mounted) {
        setState(() {
          _health = updatedHealth;
        });
      }
    } catch (e) {
      debugPrint('Error fetching updated health data: $e');
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (pickedFile != null) {
      setState(() {
        _photoPath = pickedFile.path;
      });
    }
  }

  final List<String> _types = [
    'Kunjungan Poliklinik',
    'Rawat Inap Tempat Perawatan Sementara',
    'Rawat Inap Rumah Sakit',
  ];

  int _calculateMinusPoints(String type) {
    if (type.contains('Poliklinik')) {
      final List<dynamic> recordsList = _health['records'] ?? [];
      final totalPoli = recordsList
          .where((r) => (r['type'] ?? '').toString().contains('Poliklinik'))
          .length;
      final newTotal = totalPoli + 1;

      if (newTotal % 5 == 1) {
        return 1;
      }
      return 0;
    } else {
      final days = int.tryParse(_daysController.text.trim()) ?? 1;
      if (type.contains('Sementara')) {
        return (days / 2).ceil();
      } else if (type.contains('Rumah Sakit')) {
        return days * 2;
      }
    }
    return 0;
  }

  Future<void> _saveRecord(String medisName) async {
    if (_selectedType == null || _descController.text.trim().isEmpty) {
      AppNotifier.showError(
        context,
        'Pilih jenis rawat dan isi keterangan medis',
      );
      return;
    }

    if ((_selectedType!.contains('Rawat Inap')) &&
        _daysController.text.trim().isEmpty) {
      AppNotifier.showError(context, 'Isi durasi hari rawat inap');
      return;
    }

    final noSerdik = widget.serdik['no_serdik'].toString();
    final minus = _calculateMinusPoints(_selectedType!);

    setState(() => _isLoading = true);

    try {
      final dataSource = sl<AssessmentRemoteDataSource>();
      final Map<String, dynamic> body = {
        'type': _selectedType,
        'description': _descController.text.trim(),
        'medis_name': medisName,
        'minus_points': minus,
        'photo_path': _photoPath,
      };

      await dataSource.createHealthRecord(noSerdik, body);
      await _fetchHealthData();

      widget.onRecordAdded();

      if (mounted) {
        setState(() {
          _selectedType = null;
          _descController.clear();
          _daysController.clear();
          _photoPath = null;
          _isLoading = false;
        });
        AppNotifier.showSuccess(context, 'Catatan kesehatan berhasil disimpan');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        AppNotifier.showError(context, 'Gagal menyimpan catatan kesehatan: $e');
      }
    }
  }

  @override
  void dispose() {
    _descController.dispose();
    _daysController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final noSerdik = widget.serdik['no_serdik'].toString();
    final name = widget.serdik['nama_lengkap'].toString();

    final List<dynamic> recordsList = _health['records'] ?? [];

    return Scaffold(
      backgroundColor: _lightGrey,
      appBar: AppBar(
        backgroundColor: _primaryNavy,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Catatan Status Kesehatan',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: AppDimensions.fontXl,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          String medisName = 'Tenaga Medis';
          if (state is AuthSuccess) {
            medisName = state.user.name;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppDimensions.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeaderInfo(name, noSerdik, _health),
                const SizedBox(height: AppDimensions.xl),
                _buildForm(medisName),
                const SizedBox(height: AppDimensions.xxl),
                Row(
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
                      'CATATAN RIWAYAT KESEHATAN',
                      style: TextStyle(
                        fontSize: AppDimensions.fontLg,
                        fontWeight: FontWeight.w800,
                        color: _primaryNavy,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.md),
                _buildRecordList(recordsList),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeaderInfo(String name, String noSerdik, Map<String, dynamic> healthData) {
    final pangkat = (widget.serdik['pangkat'] ?? '-').toString();
    final String rawPokjar = (widget.serdik['kelompok_kelas'] ?? '-')
        .toString()
        .toUpperCase();
    final Map<String, String> pokjarMap = {
      'POKJAR I': 'POKJAR I',
      'POKJAR II': 'POKJAR II',
      'POKJAR III': 'POKJAR III',
      'POKJAR IV': 'POKJAR IV',
      'POKJAR V': 'POKJAR V',
    };
    final String displayPokjar = pokjarMap[rawPokjar] ?? rawPokjar;

    final currentNilaiC = (healthData['current_nilai_c'] as num?)?.toDouble() ?? 80.0;

    int currentDeduction = 0;
    if (_selectedType != null) {
      currentDeduction = _calculateMinusPoints(_selectedType!);
    }

    final score = currentNilaiC - currentDeduction;
    Color statusColor = Colors.green;
    if (score < 70) {
      statusColor = Colors.red;
    } else if (score < 80) {
      statusColor = Colors.orange;
    }

    return Container(
      padding: const EdgeInsets.all(AppDimensions.lg),
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
      child: Row(
        children: [
          _buildAvatar(widget.serdik),
          const SizedBox(width: AppDimensions.md),
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
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$pangkat • $noSerdik',
                  style: TextStyle(
                    fontSize: AppDimensions.fontSm,
                    fontWeight: FontWeight.w500,
                    color: Colors.blueGrey.shade400,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              border: Border.all(color: statusColor.withValues(alpha: 0.5)),
            ),
            child: Column(
              children: [
                Text(
                  'NILAI',
                  style: TextStyle(
                    fontSize: AppDimensions.fontSm,
                    fontWeight: FontWeight.w800,
                    color: statusColor,
                  ),
                ),
                Text(
                  score.toStringAsFixed(2),
                  style: TextStyle(
                    fontSize: AppDimensions.fontXxl,
                    fontWeight: FontWeight.w900,
                    color: statusColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(Map<String, dynamic> serdik) {
    final String? profilePhoto =
        serdik['profile_photo'] ?? serdik['profilePhoto'];

    return Container(
      width: 48,
      height: 48,
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

  Widget _buildForm(String medisName) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.lg),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Tambah Catatan Baru',
            style: TextStyle(
              fontSize: AppDimensions.fontLg,
              fontWeight: FontWeight.w800,
              color: _primaryNavy,
            ),
          ),
          const SizedBox(height: AppDimensions.lg),
          InputDecorator(
            decoration: InputDecoration(
              filled: true,
              fillColor: _lightGrey,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 4,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                borderSide: BorderSide.none,
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedType,
                isExpanded: true,
                hint: const Text('Pilih Jenis Perawatan'),
                items: _types.map((t) {
                  return DropdownMenuItem(value: t, child: Text(t));
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedType = val;
                  });
                },
              ),
            ),
          ),
          if (_selectedType != null &&
              _selectedType!.contains('Rawat Inap')) ...[
            const SizedBox(height: AppDimensions.md),
            TextField(
              controller: _daysController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'Durasi Hari',
                filled: true,
                fillColor: _lightGrey,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (val) {
                setState(() {});
              },
            ),
          ],
          const SizedBox(height: AppDimensions.md),
          TextField(
            controller: _descController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Keterangan Medis',
              filled: true,
              fillColor: _lightGrey,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: AppDimensions.md),
          if (_photoPath != null) ...[
            Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                border: Border.all(color: Colors.grey.shade300),
                image: DecorationImage(
                  image: FileImage(File(_photoPath!)),
                  fit: BoxFit.cover,
                ),
              ),
              child: Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: const Icon(Icons.cancel, color: Colors.white),
                  onPressed: () => setState(() => _photoPath = null),
                ),
              ),
            ),
          ] else ...[
            OutlinedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.camera_alt, color: _primaryNavy),
              label: const Text('Upload Bukti Foto'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                foregroundColor: _primaryNavy,
                side: const BorderSide(color: _primaryNavy),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                ),
              ),
            ),
          ],
          if (_selectedType != null) ...[
            const SizedBox(height: AppDimensions.lg),
            Container(
              padding: const EdgeInsets.all(AppDimensions.md),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                border: Border.all(color: Colors.red.withValues(alpha: 0.5)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.red, size: 20),
                  const SizedBox(width: AppDimensions.md),
                  Expanded(
                    child: Text(
                      'Potongan Nilai: -${_calculateMinusPoints(_selectedType!)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: Colors.red,
                        fontSize: AppDimensions.fontMd,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppDimensions.xl),
          ElevatedButton(
            onPressed: _isLoading ? null : () => _saveRecord(medisName),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: _primaryNavy,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'SIMPAN',
                    style: TextStyle(
                      fontSize: AppDimensions.fontMd,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordList(List<dynamic> records) {
    if (records.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppDimensions.xl),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        ),
        child: const Center(
          child: Text(
            'Belum ada catatan riwayat kesehatan',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: records.length,
      separatorBuilder: (context, index) =>
          const SizedBox(height: AppDimensions.md),
      itemBuilder: (context, index) {
        final record = records[index] as Map<String, dynamic>;
        final String recordType = record['type'] ?? '';
        final String recordDesc = record['description'] ?? '';
        final String recordMedis = record['medis_name'] ?? '';
        final int recordMinus = (record['minus_points'] as num?)?.toInt() ?? 0;

        final DateTime timestamp = record['timestamp'] != null
            ? DateTime.parse(record['timestamp'].toString())
            : DateTime.now();

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
        final month = indonesianMonths[timestamp.month - 1];
        final timeStr =
            '${timestamp.day.toString().padLeft(2, '0')} $month ${timestamp.year} ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';

        return Container(
          padding: const EdgeInsets.all(AppDimensions.md),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.medical_services,
                  color: Colors.red.shade400,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppDimensions.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recordType,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: _primaryNavy,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      recordDesc,
                      style: TextStyle(color: Colors.blueGrey.shade700),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 12,
                          color: Colors.blueGrey.shade400,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          timeStr,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blueGrey.shade400,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.person,
                          size: 12,
                          color: Colors.blueGrey.shade400,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            recordMedis,
                            style: TextStyle(
                              fontSize: 12,
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
              const SizedBox(width: AppDimensions.sm),
              Container(
                margin: const EdgeInsets.only(left: 4),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                ),
                child: Text(
                  '-$recordMinus',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: AppDimensions.fontLg,
                    color: Colors.red.shade700,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
