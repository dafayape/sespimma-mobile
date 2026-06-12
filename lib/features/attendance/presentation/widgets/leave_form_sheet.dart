import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:sespimma/core/constants/app_dimensions.dart';
import 'package:sespimma/core/theme/app_colors.dart';
import 'package:sespimma/core/utils/icon_mapper.dart';
import 'package:sespimma/core/utils/app_notifier.dart';
import 'package:sespimma/features/assessment/data/models/korsis_inbox_mock_data.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sespimma/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:sespimma/features/auth/presentation/bloc/auth_state.dart';

class LeaveFormSheet extends StatefulWidget {
  final VoidCallback onSuccess;

  const LeaveFormSheet({super.key, required this.onSuccess});

  @override
  State<LeaveFormSheet> createState() => _LeaveFormSheetState();
}

class _LeaveFormSheetState extends State<LeaveFormSheet> {
  String? attachedFileName;
  bool isAttaching = false;
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
        _startTime != null &&
        _endTime != null &&
        reasonCtrl.text.trim().isNotEmpty;

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
            const Text(
              'Pengajuan Izin Khusus',
              style: TextStyle(
                fontSize: AppDimensions.fontLg,
                fontWeight: FontWeight.w800,
                color: AppColors.primaryNavy,
              ),
            ),
            const SizedBox(height: AppDimensions.xs + 2),
            Text(
              'Silakan lampirkan alasan tertulis beserta dokumen bukti.',
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
              onTap: isAttaching
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
                onPressed: () {
                  if (_startTime == null || _endTime == null) {
                    AppNotifier.showError(
                      context,
                      'Harap isi waktu mulai dan berakhir izin!',
                    );
                    return;
                  }
                  if (attachedFileName == null) {
                    AppNotifier.showError(
                      context,
                      'Harap lampirkan dokumen bukti izin',
                    );
                    return;
                  }
                  if (formKey.currentState!.validate()) {
                    Navigator.pop(context);
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

                    String sName = 'Dummy User';
                    String sPangkat = 'AKP';
                    String sNosis = '000000';
                    String sPokjar = 'POKJAR I';

                    final authState = context.read<AuthBloc>().state;
                    if (authState is AuthSuccess) {
                      sName = authState.user.name;
                      sPangkat = authState.user.pangkat;
                      sNosis = authState.user.noSerdik.isNotEmpty
                          ? authState.user.noSerdik
                          : authState.user.nrp;
                      sPokjar = authState.user.pokjar.isNotEmpty
                          ? authState.user.pokjar
                          : 'POKJAR I';
                    }

                    KorsisInboxMockData.addRecord(
                      InboxItem(
                        id: 'izin_${now.millisecondsSinceEpoch}',
                        serdikName: sName,
                        pangkat: sPangkat,
                        nosis: sNosis,
                        pokjar: sPokjar,
                        isReward: false,
                        senderName: sName,
                        timestamp: now,
                        points: 0,
                        description: reasonCtrl.text.trim(),
                        rewardPunishmentName: 'Pengajuan Izin Khusus',
                        isIzin: true,
                        izinStartTime: startDt,
                        izinEndTime: endDt,
                        attachmentPath: attachedFileName,
                      ),
                    );

                    widget.onSuccess();
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
                child: const Text(
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
