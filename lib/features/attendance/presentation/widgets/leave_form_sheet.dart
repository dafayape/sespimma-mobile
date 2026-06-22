import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:sespimma/core/constants/app_dimensions.dart';
import 'package:sespimma/core/theme/app_colors.dart';
import 'package:sespimma/core/utils/icon_mapper.dart';
import 'package:sespimma/core/utils/app_notifier.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sespimma/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:sespimma/features/auth/presentation/bloc/auth_state.dart';
import 'package:sespimma/features/attendance/data/datasources/absensi_remote_data_source.dart';
import 'package:sespimma/injection_container.dart';

class LeaveFormSheet extends StatefulWidget {
  final String kegiatanId;
  final VoidCallback onSuccess;

  const LeaveFormSheet({
    super.key,
    required this.kegiatanId,
    required this.onSuccess,
  });

  @override
  State<LeaveFormSheet> createState() => _LeaveFormSheetState();
}

class _LeaveFormSheetState extends State<LeaveFormSheet> {
  String? attachedFileName;
  String? attachedFilePath;
  bool isAttaching = false;
  bool _isLoading = false;
  String _izinType = 'izin';
  late final TextEditingController reasonCtrl;
  final formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    reasonCtrl = TextEditingController();
  }

  @override
  void dispose() {
    reasonCtrl.dispose();
    super.dispose();
  }

  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  Future<void> _selectTime(String type) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (ctx, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primaryNavy),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (type == 'start') {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  Widget _buildTimePicker({required String type}) {
    final time = type == 'start' ? _startTime : _endTime;
    final label = type == 'start' ? 'Mulai' : 'Berakhir';
    return InkWell(
      onTap: () => _selectTime(type),
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
          time?.format(context) ?? '--:--',
          style: TextStyle(
            fontWeight: time != null ? FontWeight.bold : FontWeight.normal,
            color: time != null ? Colors.black87 : Colors.grey,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isReady =
        attachedFileName != null &&
        attachedFilePath != null &&
        _startTime != null &&
        _endTime != null &&
        reasonCtrl.text.trim().isNotEmpty &&
        !_isLoading;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + AppDimensions.xxxl,
        top: AppDimensions.xl,
        left: AppDimensions.xxl,
        right: AppDimensions.xxl,
      ),
      child: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusXs),
                ),
              ),
            ),
            const SizedBox(height: AppDimensions.xxl),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Pengajuan Izin',
                  style: TextStyle(
                    fontSize: AppDimensions.fontLg,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryNavy,
                  ),
                ),
                DropdownButton<String>(
                  value: _izinType,
                  icon: const Icon(Icons.arrow_drop_down, color: AppColors.primaryNavy),
                  elevation: 16,
                  style: const TextStyle(
                    color: AppColors.primaryNavy,
                    fontWeight: FontWeight.w600,
                  ),
                  underline: Container(
                    height: 2,
                    color: AppColors.primaryNavy,
                  ),
                  onChanged: (String? value) {
                    setState(() {
                      _izinType = value!;
                    });
                  },
                  items: const [
                    DropdownMenuItem(
                      value: 'izin',
                      child: Text('Izin Khusus'),
                    ),
                    DropdownMenuItem(
                      value: 'sakit',
                      child: Text('Sakit'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.xs + 2),
            Text(
              _izinType == 'sakit'
                  ? 'Silakan lampirkan alasan beserta Surat Keterangan Dokter.'
                  : 'Silakan lampirkan alasan tertulis beserta dokumen bukti.',
              style: TextStyle(
                fontSize: AppDimensions.fontXs + 1,
                color: Colors.blueGrey.shade500,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: AppDimensions.xl),
            TextFormField(
              controller: reasonCtrl,
              maxLines: 3,
              onChanged: (_) => setState(() {}),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Alasan wajib diisi' : null,
              decoration: InputDecoration(
                hintText: 'Ketik alasan pengajuan izin...',
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
              ),
            ),
            const SizedBox(height: AppDimensions.xl),
            Row(
              children: [
                Expanded(child: _buildTimePicker(type: 'start')),
                const SizedBox(width: AppDimensions.md),
                Expanded(child: _buildTimePicker(type: 'end')),
              ],
            ),
            const SizedBox(height: AppDimensions.xl),
            InkWell(
              onTap: isAttaching || _isLoading
                  ? null
                  : () async {
                      setState(() => isAttaching = true);
                      try {
                        final result = await FilePicker.pickFiles(
                          type: FileType.custom,
                          allowedExtensions: [
                            'pdf',
                            'doc',
                            'docx',
                            'jpg',
                            'png',
                          ],
                        );
                        if (result != null) {
                          setState(() {
                            attachedFileName = result.files.single.name;
                            attachedFilePath = result.files.single.path;
                          });
                        }
                      } catch (_) {}
                      setState(() => isAttaching = false);
                    },
              borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
              child: Container(
                padding: const EdgeInsets.all(AppDimensions.lg),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                  border: Border.all(
                    color: attachedFileName != null
                        ? AppColors.successGreen
                        : Colors.grey.shade300,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      attachedFileName != null
                          ? AppIcons.filePdfFill
                          : AppIcons.paperclip,
                      color: attachedFileName != null
                          ? AppColors.successGreen
                          : Colors.blueGrey,
                    ),
                    const SizedBox(width: AppDimensions.lg),
                    Expanded(
                      child: Text(
                        attachedFileName ?? 'Lampirkan Dokumen Bukti',
                        style: TextStyle(
                          fontSize: AppDimensions.fontSm,
                          fontWeight: attachedFileName != null
                              ? FontWeight.w700
                              : FontWeight.w600,
                          color: attachedFileName != null
                              ? AppColors.successGreen
                              : Colors.blueGrey,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppDimensions.xxl),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: !isReady || _isLoading
                    ? null
                    : () async {
                        if (_startTime == null || _endTime == null) {
                          AppNotifier.showError(
                            context,
                            'Harap isi waktu mulai dan berakhir izin!',
                          );
                          return;
                        }
                        if (attachedFilePath == null) {
                          AppNotifier.showError(
                            context,
                            'Harap lampirkan dokumen bukti izin',
                          );
                          return;
                        }
                        if (formKey.currentState!.validate()) {
                          HapticFeedback.heavyImpact();

                          final now = DateTime.now();
                          final startDt = DateTime(
                            now.year,
                            now.month,
                            now.day,
                            _startTime!.hour,
                            _startTime!.minute,
                          );
                          final endDt = DateTime(
                            now.year,
                            now.month,
                            now.day,
                            _endTime!.hour,
                            _endTime!.minute,
                          );

                          String sSerdikId = '';
                          final authState = context.read<AuthBloc>().state;
                          if (authState is AuthSuccess) {
                            sSerdikId = authState.user.serdikId ?? '';
                          }

                          setState(() => _isLoading = true);

                          try {
                            final absensiSource = sl<AbsensiRemoteDataSource>();
                            await absensiSource.submitIzin(
                              kegiatanId: widget.kegiatanId,
                              serdikId: sSerdikId,
                              startTime: startDt,
                              endTime: endDt,
                              description: reasonCtrl.text.trim(),
                              filePath: attachedFilePath!,
                              izinType: _izinType,
                            );

                            if (context.mounted) {
                              Navigator.pop(context);
                              widget.onSuccess();
                            }
                          } catch (e) {
                            if (context.mounted) {
                              String errorMsg = e.toString().replaceAll('Exception: ', '');
                              AppNotifier.showError(
                                context,
                                errorMsg,
                              );
                            }
                          } finally {
                            if (mounted) {
                              setState(() => _isLoading = false);
                            }
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isReady
                      ? AppColors.primaryNavy
                      : Colors.grey.shade400,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    vertical: AppDimensions.lg,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'KIRIM PERMOHONAN',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
