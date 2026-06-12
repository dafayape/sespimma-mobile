import 'package:flutter/material.dart';
import 'package:sespimma/core/constants/app_dimensions.dart';
import 'package:sespimma/core/theme/app_colors.dart';

class AssignmentInstructionSection extends StatelessWidget {
  final String? deskripsi;

  const AssignmentInstructionSection({super.key, required this.deskripsi});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Instruksi Tugas',
          style: TextStyle(
            fontSize: AppDimensions.fontXl,
            fontWeight: FontWeight.w800,
            color: AppColors.primaryNavy,
          ),
        ),
        const SizedBox(height: AppDimensions.md),
        Text(
          deskripsi?.isNotEmpty == true
              ? deskripsi!
              : 'Silahkan selesaikan naskah sesuai dengan '
                    'pedoman yang telah dibagikan. Pastikan format '
                    'penulisan mematuhi standar SESPIMMA. Unggah '
                    'dokumen dalam format PDF atau foto bukti '
                    'kegiatan yang relevan sebelum batas waktu '
                    'berakhir.',
          style: TextStyle(
            fontSize: AppDimensions.fontLg,
            fontWeight: FontWeight.w500,
            color: Colors.blueGrey.shade600,
            height: 1.6,
          ),
        ),
      ],
    );
  }
}
