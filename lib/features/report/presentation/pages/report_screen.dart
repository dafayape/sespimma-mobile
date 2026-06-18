import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sespimma/core/constants/app_dimensions.dart';
import 'package:sespimma/core/theme/app_colors.dart';
import 'package:sespimma/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:sespimma/features/auth/presentation/bloc/auth_state.dart';
import 'package:sespimma/features/report/presentation/widgets/report_content_body.dart';
import 'package:sespimma/features/report/presentation/widgets/report_error_state.dart';
import 'package:sespimma/features/report/data/datasources/report_remote_data_source.dart';
import 'package:sespimma/injection_container.dart';

import 'package:sespimma/features/auth/domain/entities/user_entity.dart';

class ReportScreen extends StatefulWidget {
  final UserEntity? targetUser;
  const ReportScreen({super.key, this.targetUser});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  String _selectedCategory = 'Mental Kepribadian';
  Map<String, dynamic>? _reportData;
  bool _isLoadingReport = false;
  String? _reportError;

  @override
  void initState() {
    super.initState();
    if (widget.targetUser != null) {
      final serdikId = widget.targetUser!.serdikId ?? widget.targetUser!.noSerdik;
      _fetchReportData(serdikId);
    } else {
      final authState = context.read<AuthBloc>().state;
      if (authState is AuthSuccess) {
        final serdikId = authState.user.serdikId;
        if (serdikId != null && serdikId.isNotEmpty) {
          _fetchReportData(serdikId);
        }
      }
    }
  }

  Future<void> _fetchReportData(String serdikId) async {
    setState(() {
      _isLoadingReport = true;
      _reportError = null;
    });
    try {
      final data = await sl<ReportRemoteDataSource>().getLaporanPerkembangan(serdikId);
      if (mounted) {
        setState(() {
          _reportData = data;
          _isLoadingReport = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _reportError = e.toString().replaceAll('Exception: ', '');
          _isLoadingReport = false;
        });
      }
    }
  }

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
        title: Text(
          widget.targetUser != null ? 'Rapor ${widget.targetUser!.name}' : 'Laporan Nilai',
          style: const TextStyle(
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
            if (_isLoadingReport && _reportData == null) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primaryNavy),
              );
            } else if (_reportError != null && _reportData == null) {
              return ReportErrorState(message: _reportError!);
            }

            final displayUser = widget.targetUser ?? state.user;

            return ReportContentBody(
              user: displayUser,
              selectedCategory: _selectedCategory,
              onCategoryChanged: _updateCategory,
              reportData: _reportData ?? {},
              onRefresh: () => _fetchReportData(displayUser.serdikId ?? displayUser.noSerdik),
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
