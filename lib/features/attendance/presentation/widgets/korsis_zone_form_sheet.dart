import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';
import 'package:sespimma/core/constants/app_dimensions.dart';
import 'package:sespimma/core/theme/app_colors.dart';
import 'package:sespimma/core/utils/icon_mapper.dart';
import 'package:sespimma/features/attendance/domain/models/map_tile_mode.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:sespimma/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:sespimma/features/auth/presentation/bloc/auth_state.dart';
import 'package:sespimma/injection_container.dart';

class KorsisZoneFormSheet extends StatefulWidget {
  final LatLng? centerPoint;
  final double? radius;
  final List<LatLng>? polygonPoints;
  final AttendanceZone? existingZone;

  const KorsisZoneFormSheet({
    super.key,
    this.centerPoint,
    this.radius,
    this.polygonPoints,
    this.existingZone,
  }) : assert(
         existingZone != null ||
             centerPoint != null ||
             (polygonPoints != null && polygonPoints.length >= 3),
         'Either existingZone, centerPoint, or polygonPoints (≥3) must be provided',
       );

  @override
  State<KorsisZoneFormSheet> createState() => _KorsisZoneFormSheetState();
}

class _KorsisZoneFormSheetState extends State<KorsisZoneFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _activityController = TextEditingController();
  final _locationController = TextEditingController();

  TimeOfDay _startTime = const TimeOfDay(hour: 7, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 16, minute: 0);
  TimeOfDay _cutoffTime = const TimeOfDay(hour: 8, minute: 0);
  bool _isRoutine = false;
  bool _isTraining = false;
  bool _generateQr = true;
  DateTime _routineStartDate = DateTime.now();
  DateTime _routineEndDate = DateTime.now().add(const Duration(days: 5));

  @override
  void initState() {
    super.initState();
    if (widget.existingZone != null) {
      final z = widget.existingZone!;
      _locationController.text = z.name;
      _activityController.text = z.activityName;
      _startTime = TimeOfDay(
        hour: z.startTime.hour,
        minute: z.startTime.minute,
      );
      _endTime = TimeOfDay(hour: z.endTime.hour, minute: z.endTime.minute);
      _cutoffTime = TimeOfDay(
        hour: z.cutoffTime.hour,
        minute: z.cutoffTime.minute,
      );
      _isRoutine = z.isRoutine;
      _isTraining = z.isTraining;
      _routineStartDate = z.routineStartDate ?? DateTime.now();
      _routineEndDate =
          z.routineEndDate ?? DateTime.now().add(const Duration(days: 5));
    }
  }

  bool _isSubmitting = false;

  @override
  void dispose() {
    _activityController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _selectTime(BuildContext context, String type) async {
    final initialTime = type == 'start'
        ? _startTime
        : (type == 'end' ? _endTime : _cutoffTime);

    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (ctx, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primaryNavy),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() {
      if (type == 'start') {
        _startTime = picked;
      } else if (type == 'end') {
        _endTime = picked;
      } else {
        _cutoffTime = picked;
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    HapticFeedback.mediumImpact();
    setState(() => _isSubmitting = true);

    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;

    final now = DateTime.now();
    DateTime baseDate = _isRoutine ? _routineStartDate : now;

    final startDt = DateTime(
      baseDate.year,
      baseDate.month,
      baseDate.day,
      _startTime.hour,
      _startTime.minute,
    );
    final endDt = DateTime(
      baseDate.year,
      baseDate.month,
      baseDate.day,
      _endTime.hour,
      _endTime.minute,
    );
    final cutoffDt = DateTime(
      baseDate.year,
      baseDate.month,
      baseDate.day,
      _cutoffTime.hour,
      _cutoffTime.minute,
    );

    double centerLat = widget.existingZone?.latitude ?? 0.0;
    double centerLng = widget.existingZone?.longitude ?? 0.0;
    if (widget.centerPoint != null) {
      centerLat = widget.centerPoint!.latitude;
      centerLng = widget.centerPoint!.longitude;
    } else if (widget.polygonPoints != null &&
        widget.polygonPoints!.isNotEmpty) {
      for (final p in widget.polygonPoints!) {
        centerLat += p.latitude;
        centerLng += p.longitude;
      }
      centerLat /= widget.polygonPoints!.length;
      centerLng /= widget.polygonPoints!.length;
    }

    String creatorName = widget.existingZone?.creator ?? 'Korsis';
    if (widget.existingZone == null) {
      final authState = context.read<AuthBloc>().state;
      if (authState is AuthSuccess) {
        creatorName = authState.user.name;
      }
    }

    final zone = AttendanceZone(
      id: widget.existingZone?.id ?? 'zone_${now.millisecondsSinceEpoch}',
      name: _locationController.text.trim(),
      latitude: centerLat,
      longitude: centerLng,
      radiusMeters: widget.radius ?? widget.existingZone?.radiusMeters ?? 0.0,
      polygonPoints: widget.polygonPoints ?? widget.existingZone?.polygonPoints,
      activityName: _activityController.text.trim(),
      creator: creatorName,
      startTime: startDt,
      endTime: endDt,
      deadline: cutoffDt,
      cutoffTime: cutoffDt,
      createdAt: widget.existingZone?.createdAt ?? now,
      isRoutine: _isRoutine,
      isTraining: _isTraining,
      routineStartDate: _isRoutine ? _routineStartDate : null,
      routineEndDate: _isRoutine ? _routineEndDate : null,
    );

    final Map<String, dynamic> requestData = {
      'id': zone.id,
      'name': zone.name,
      'latitude': zone.latitude,
      'longitude': zone.longitude,
      'radius_meters': zone.radiusMeters,
      'polygon_points': zone.polygonPoints?.map((p) => {
        'latitude': p.latitude,
        'longitude': p.longitude,
      }).toList(),
      'activity_name': zone.activityName,
      'start_time': zone.startTime.toUtc().toIso8601String(),
      'end_time': zone.endTime.toUtc().toIso8601String(),
      'deadline': zone.deadline.toUtc().toIso8601String(),
      'cutoff_time': zone.cutoffTime.toUtc().toIso8601String(),
      'is_routine': zone.isRoutine,
      'is_training': zone.isTraining,
      'routine_start_date': zone.routineStartDate?.toIso8601String().split('T')[0],
      'routine_end_date': zone.routineEndDate?.toIso8601String().split('T')[0],
    };

    try {
      final dio = sl<Dio>();
      if (widget.existingZone != null) {
        await dio.put('/attendance/zones/${zone.id}', data: requestData);
        AttendanceZones.updateZone(zone);
      } else {
        await dio.post('/attendance/zones', data: requestData);
        AttendanceZones.addZone(zone);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan zona: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isPolygon =
        (widget.polygonPoints != null && widget.polygonPoints!.isNotEmpty) ||
        (widget.existingZone?.polygonPoints != null &&
            widget.existingZone!.polygonPoints!.isNotEmpty);
    final int pointsLength =
        widget.polygonPoints?.length ??
        widget.existingZone?.polygonPoints?.length ??
        0;
    final int displayRadius =
        (widget.radius ?? widget.existingZone?.radiusMeters ?? 0).toInt();

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + AppDimensions.xxl,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusXxl),
        ),
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppDimensions.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppDimensions.lg),
              Center(
                child: Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                  ),
                ),
              ),
              const SizedBox(height: AppDimensions.xl),
              const Text(
                'Detail Zona',
                style: TextStyle(
                  fontSize: AppDimensions.fontXxl,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primaryNavy,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppDimensions.md),

              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.lg,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryNavy.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
                    border: Border.all(
                      color: AppColors.primaryNavy.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        AppIcons.mapPinLine,
                        color: AppColors.primaryNavy,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isPolygon
                            ? 'Polygon · $pointsLength Titik'
                            : 'Radius · $displayRadius meter',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryNavy,
                          fontSize: AppDimensions.fontSm,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppDimensions.xxl),

              TextFormField(
                controller: _activityController,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: 'Nama Kegiatan',
                  hintText: 'Contoh: Apel Pagi, Kuliah Umum',
                  prefixIcon: const Icon(AppIcons.clipboardText),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                  ),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Nama kegiatan wajib diisi'
                    : null,
              ),
              const SizedBox(height: AppDimensions.lg),

              TextFormField(
                controller: _locationController,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  labelText: 'Nama Lokasi',
                  hintText: 'Contoh: Lapangan Sespimma',
                  prefixIcon: const Icon(AppIcons.buildings),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                  ),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Nama lokasi wajib diisi'
                    : null,
              ),
              const SizedBox(height: AppDimensions.lg),

              if (_isRoutine) ...[
                Row(
                  children: [
                    Expanded(
                      child: _buildDatePicker(context, 'Dari Tanggal', true),
                    ),
                    const SizedBox(width: AppDimensions.md),
                    Expanded(
                      child: _buildDatePicker(context, 'Sampai Tanggal', false),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.lg),
              ],

              Row(
                children: [
                  Expanded(child: _buildTimePicker(context, type: 'start')),
                  const SizedBox(width: AppDimensions.md),
                  Expanded(child: _buildTimePicker(context, type: 'end')),
                ],
              ),
              const SizedBox(height: AppDimensions.md),
              _buildTimePicker(context, type: 'cutoff'),
              const SizedBox(height: AppDimensions.xl),

              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    _buildToggleRow(
                      icon: AppIcons.arrowsClockwiseBold,
                      title: 'Kegiatan Rutin',
                      subtitle:
                          'Zona berulang harian, QR Code diperbarui otomatis setiap hari',
                      value: _isRoutine,
                      onChanged: (val) => setState(() {
                        _isRoutine = val;
                        if (val) _isTraining = false;
                      }),
                    ),
                    Divider(height: 1, color: Colors.grey.shade200),
                    _buildToggleRow(
                      icon: AppIcons.usersFill,
                      title: 'Kegiatan Pelatihan',
                      subtitle:
                          'Zona ini khusus dibuat ketika ada kegiatan pelatihan khusus',
                      value: _isTraining,
                      onChanged: (val) => setState(() {
                        _isTraining = val;
                        if (val) _isRoutine = false;
                      }),
                    ),
                    Divider(height: 1, color: Colors.grey.shade200),
                    _buildToggleRow(
                      icon: AppIcons.qrCode,
                      title: 'Buat QR Code',
                      subtitle:
                          'QR Code berfungsi apabila fitur geofencing bermasalah',
                      value: _generateQr,
                      onChanged: (val) => setState(() => _generateQr = val),
                    ),
                  ],
                ),
              ),

              if (_isRoutine && _generateQr)
                Padding(
                  padding: const EdgeInsets.only(top: AppDimensions.md),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1565C0).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusMd,
                      ),
                      border: Border.all(
                        color: const Color(0xFF1565C0).withValues(alpha: 0.2),
                      ),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          size: 16,
                          color: Color(0xFF1565C0),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'QR Code akan diperbarui otomatis setiap hari pukul 00:00. Kegiatan tetap sama.',
                            style: TextStyle(
                              fontSize: AppDimensions.fontXs,
                              color: Color(0xFF1565C0),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: AppDimensions.xxl),

              ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryNavy,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppColors.primaryNavy.withValues(
                    alpha: 0.4,
                  ),
                  padding: const EdgeInsets.symmetric(
                    vertical: AppDimensions.xl,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                  ),
                  elevation: 0,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Text(
                        'SIMPAN ZONA',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.0,
                          fontSize: AppDimensions.fontLg,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final initialDate = isStart ? _routineStartDate : _routineEndDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (ctx, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primaryNavy),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _routineStartDate = picked;
          if (_routineEndDate.isBefore(picked)) {
            _routineEndDate = picked;
          }
        } else {
          _routineEndDate = picked;
          if (_routineStartDate.isAfter(picked)) {
            _routineStartDate = picked;
          }
        }
      });
    }
  }

  Widget _buildDatePicker(BuildContext context, String label, bool isStart) {
    final date = isStart ? _routineStartDate : _routineEndDate;
    final dateStr = DateFormat('dd MMM yyyy').format(date);
    return InkWell(
      onTap: () => _selectDate(context, isStart),
      borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(AppIcons.calendarBlank),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          ),
        ),
        child: Text(
          dateStr,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildTimePicker(BuildContext context, {required String type}) {
    final time = type == 'start'
        ? _startTime
        : (type == 'end' ? _endTime : _cutoffTime);

    final label = type == 'start'
        ? 'Waktu Mulai'
        : (type == 'end' ? 'Waktu Selesai' : 'Batas Waktu Absen');

    return InkWell(
      onTap: () => _selectTime(context, type),
      borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(AppIcons.clock),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          ),
        ),
        child: Text(
          time.format(context),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildToggleRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onChanged(!value);
      },
      borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.lg,
          vertical: AppDimensions.md,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: value
                    ? AppColors.primaryNavy.withValues(alpha: 0.1)
                    : Colors.grey.shade200,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 18,
                color: value ? AppColors.primaryNavy : Colors.grey,
              ),
            ),
            const SizedBox(width: AppDimensions.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: AppDimensions.fontDefault,
                      color: value ? AppColors.primaryNavy : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: AppDimensions.fontXs,
                      color: Colors.blueGrey.shade500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppDimensions.md),
            Switch(
              value: value,
              onChanged: (val) {
                HapticFeedback.selectionClick();
                onChanged(val);
              },
              activeThumbColor: AppColors.primaryNavy,
              activeTrackColor: AppColors.primaryNavy.withValues(alpha: 0.35),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ],
        ),
      ),
    );
  }
}
