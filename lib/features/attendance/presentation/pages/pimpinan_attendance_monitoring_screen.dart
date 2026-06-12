import 'package:flutter/material.dart';
import 'package:sespimma/core/constants/app_dimensions.dart';
import 'package:sespimma/features/attendance/presentation/widgets/patun_geofence_map_widget.dart';

class PimpinanAttendanceMonitoringScreen extends StatelessWidget {
  const PimpinanAttendanceMonitoringScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: false,
      appBar: AppBar(
        backgroundColor: const Color(0xFF000B1D),
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
      ),
      body: const PatunGeofenceMapWidget(pokjar: ''),
    );
  }
}
