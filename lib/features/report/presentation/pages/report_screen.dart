import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sespimma/core/constants/app_dimensions.dart';
import 'package:sespimma/core/theme/app_colors.dart';
import 'package:sespimma/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:sespimma/features/auth/presentation/bloc/auth_state.dart';
import 'package:sespimma/features/report/presentation/widgets/report_content_body.dart';
import 'package:sespimma/features/report/presentation/widgets/report_error_state.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  String _selectedCategory = 'Mental Kepribadian';

  void _updateCategory(String cat) {
    HapticFeedback.selectionClick();
    setState(() => _selectedCategory = cat);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primaryNavy,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Laporan Nilai',
          style: TextStyle(
            color: AppColors.textOnPrimary,
            fontWeight: FontWeight.w700,
            fontSize: AppDimensions.fontXxl,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.textOnPrimary),
      ),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is AuthLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primaryNavy),
            );
          } else if (state is AuthFailure) {
            return ReportErrorState(message: state.message);
          } else if (state is AuthSuccess) {
            return ReportContentBody(
              user: state.user,
              selectedCategory: _selectedCategory,
              onCategoryChanged: _updateCategory,
            );
          }
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primaryNavy),
          );
        },
      ),
    );
  }
}
