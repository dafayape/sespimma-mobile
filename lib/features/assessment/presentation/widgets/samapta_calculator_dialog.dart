import 'package:flutter/material.dart';
import 'package:sespimma/core/constants/app_dimensions.dart';
import 'package:sespimma/core/theme/app_colors.dart';
import 'package:sespimma/features/assessment/domain/services/samapta_scoring_service.dart';

class SamaptaCalculatorDialog extends StatefulWidget {
  final String exerciseName;
  final String birthDateStr;
  final String gender;
  final ValueChanged<double> onApply;

  const SamaptaCalculatorDialog({
    super.key,
    required this.exerciseName,
    required this.birthDateStr,
    required this.gender,
    required this.onApply,
  });

  @override
  State<SamaptaCalculatorDialog> createState() =>
      _SamaptaCalculatorDialogState();
}

class _SamaptaCalculatorDialogState extends State<SamaptaCalculatorDialog> {
  final TextEditingController _rawController = TextEditingController();
  double _calculatedScore = 0.0;

  late final Map<String, dynamic> _profile;
  late final int _age;
  late final String _golongan;
  late final String _golonganLabel;

  @override
  void initState() {
    super.initState();
    _profile = SamaptaScoringService.getAgeAndGolongan(widget.birthDateStr);
    _age = _profile['age'];
    _golongan = _profile['golongan'];
    _golonganLabel = _profile['label'];
  }

  @override
  void dispose() {
    _rawController.dispose();
    super.dispose();
  }

  void _recompute() {
    final double raw = double.tryParse(_rawController.text) ?? 0;
    setState(() {
      _calculatedScore = SamaptaScoringService.lookupScore(
        widget.exerciseName,
        _golongan,
        widget.gender,
        raw,
      );
    });
  }

  String _resolveInputLabel() {
    if (widget.exerciseName.contains('Lari')) {
      return 'Jarak Tempuh (Meter / HG)';
    }
    if (widget.exerciseName.contains('Shuttle')) {
      return 'Waktu Tempuh (Detik / HG)';
    }
    return 'Jumlah Gerakan (Repetisi / HG)';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusXxl),
      ),
      title: Row(
        children: [
          Icon(
            Icons.verified_user_rounded,
            color: Colors.teal.shade700,
            size: AppDimensions.iconDefault,
          ),
          const SizedBox(width: AppDimensions.md - 2),
          const Text(
            'Kalkulator IDMS',
            style: TextStyle(
              fontSize: AppDimensions.fontXl,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLockedBanner(),
            const SizedBox(height: AppDimensions.lg),
            _buildExerciseLabel(),
            const SizedBox(height: AppDimensions.md),
            _buildProfileField(
              '$_golonganLabel • $_age Thn',
              'Golongan Umur (Terhitung)',
            ),
            const SizedBox(height: AppDimensions.md),
            _buildProfileField(widget.gender, 'Jenis Kelamin'),
            const SizedBox(height: AppDimensions.lg),
            _buildInputField(),
            const SizedBox(height: AppDimensions.xl),
            _buildScoreResult(),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Batal', style: TextStyle(color: Colors.grey.shade600)),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onApply(_calculatedScore);
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryNavy,
            foregroundColor: AppColors.textOnPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
            ),
          ),
          child: const Text('Terapkan Nilai'),
        ),
      ],
    );
  }

  Widget _buildLockedBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.md - 2),
      decoration: BoxDecoration(
        color: Colors.teal.shade50,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: Colors.teal.shade200),
      ),
      child: Row(
        children: [
          Icon(
            Icons.lock_rounded,
            color: Colors.teal.shade700,
            size: AppDimensions.iconSm,
          ),
          const SizedBox(width: AppDimensions.sm),
          Expanded(
            child: Text(
              'Profil ini dikunci dan dihitung otomatis berdasarkan database kelahiran.',
              style: TextStyle(
                fontSize: AppDimensions.fontSm,
                fontWeight: FontWeight.w600,
                color: Colors.teal.shade900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseLabel() {
    return Text(
      'Konversi HG: ${widget.exerciseName}',
      style: const TextStyle(
        fontSize: AppDimensions.fontDefault,
        color: Colors.blueGrey,
        fontWeight: FontWeight.w800,
      ),
    );
  }

  Widget _buildProfileField(String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: AppDimensions.fontSm + 1,
            fontWeight: FontWeight.w700,
            color: Colors.blueGrey,
          ),
        ),
        const SizedBox(height: AppDimensions.xs + 2),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.md,
            vertical: AppDimensions.md,
          ),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: AppDimensions.fontDefault,
                  fontWeight: FontWeight.w700,
                  color: Colors.blueGrey.shade800,
                ),
              ),
              Icon(
                Icons.check_circle_rounded,
                color: Colors.teal.shade700,
                size: AppDimensions.iconSm,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInputField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _resolveInputLabel(),
          style: const TextStyle(
            fontSize: AppDimensions.fontMd,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryNavy,
          ),
        ),
        const SizedBox(height: AppDimensions.xs + 2),
        TextField(
          controller: _rawController,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(
            fontSize: AppDimensions.fontXl,
            fontWeight: FontWeight.w800,
            color: AppColors.primaryNavy,
          ),
          decoration: InputDecoration(
            hintText: 'Input Hasil Gerakan Fisik...',
            filled: true,
            fillColor: AppColors.surface,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.lg,
              vertical: AppDimensions.fontLg,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
              borderSide: const BorderSide(
                color: AppColors.primaryNavy,
                width: AppDimensions.borderWidthFocus,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
          ),
          onChanged: (_) => _recompute(),
        ),
      ],
    );
  }

  Widget _buildScoreResult() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blueGrey.shade900, AppColors.primaryNavy],
        ),
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryNavy.withValues(alpha: 0.15),
            blurRadius: AppDimensions.md - 2,
            offset: const Offset(0, AppDimensions.xs),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'SKOR HASIL KONVERSI',
            style: TextStyle(
              color: Colors.tealAccent,
              fontSize: AppDimensions.fontSm,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: AppDimensions.xs + 2),
          Text(
            _calculatedScore.toStringAsFixed(2),
            style: const TextStyle(
              color: AppColors.textOnPrimary,
              fontSize: AppDimensions.fontDisplayXl,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: AppDimensions.xs + 2),
          const Text(
            'Lookup Table Otomatis IDMS',
            style: TextStyle(
              color: Colors.white70,
              fontSize: AppDimensions.fontSm,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
