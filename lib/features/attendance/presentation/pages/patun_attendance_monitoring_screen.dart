import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sespimma/core/constants/app_dimensions.dart';
import 'package:sespimma/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:sespimma/features/auth/presentation/bloc/auth_state.dart';
import 'package:sespimma/features/attendance/presentation/widgets/patun_geofence_map_widget.dart';
import 'package:sespimma/features/attendance/presentation/pages/patun_attendance_report_screen.dart';

class PatunAttendanceMonitoringScreen extends StatefulWidget {
  const PatunAttendanceMonitoringScreen({super.key});

  @override
  State<PatunAttendanceMonitoringScreen> createState() =>
      _PatunAttendanceMonitoringScreenState();
}

class _PatunAttendanceMonitoringScreenState
    extends State<PatunAttendanceMonitoringScreen> {
  static const Color _primaryNavy = Color(0xFF000B1D);

  void _goToLaporan(BuildContext context, String pokjar) {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PatunAttendanceReportScreen(pokjar: pokjar),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        String userPokjar = '';
        if (state is AuthSuccess) {
          userPokjar = state.user.pokjar;
        }

        return Scaffold(
          extendBodyBehindAppBar: false,
          appBar: AppBar(
            backgroundColor: _primaryNavy,
            elevation: 0,
            centerTitle: true,
            automaticallyImplyLeading: false,
            title: const Text(
              'Monitoring Absen',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: AppDimensions.fontXxl,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(
                  Icons.description_rounded,
                  color: Colors.white,
                ),
                tooltip: 'Laporan Absen',
                onPressed: () => _goToLaporan(context, userPokjar),
              ),
            ],
          ),
          body: PatunGeofenceMapWidget(pokjar: userPokjar),
        );
      },
    );
  }
}
