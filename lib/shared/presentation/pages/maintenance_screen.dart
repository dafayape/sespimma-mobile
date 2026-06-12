import 'package:flutter/material.dart';
import 'package:sespimma/core/constants/app_dimensions.dart';

class MaintenanceScreen extends StatelessWidget {
  final String title;

  const MaintenanceScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          title,
          style: const TextStyle(
            color: Color(0xFF000B1D),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.xxl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(AppDimensions.xxl),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.construction_rounded,
                  size: 80,
                  color: Colors.blue.shade300,
                ),
              ),
              const SizedBox(height: AppDimensions.xxl),
              const Text(
                'Fitur Dalam Pengembangan',
                style: TextStyle(
                  fontSize: AppDimensions.fontXxl,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF000B1D),
                  letterSpacing: -0.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppDimensions.md),
              Text(
                'Halaman $title sedang dibangun dan akan segera tersedia pada versi mendatang.',
                style: TextStyle(
                  fontSize: AppDimensions.fontLg,
                  color: Colors.blueGrey.shade400,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
