import 'package:flutter/material.dart';
import 'package:sespimma/core/constants/app_dimensions.dart';

class AssessmentEmptyStateWidget extends StatelessWidget {
  const AssessmentEmptyStateWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_search_rounded,
            size: AppDimensions.iconDisplay,
            color: Colors.blueGrey.shade200,
          ),
          const SizedBox(height: AppDimensions.lg),
          Text(
            'Serdik tidak ditemukan',
            style: TextStyle(
              fontSize: AppDimensions.fontXl,
              fontWeight: FontWeight.w700,
              color: Colors.blueGrey.shade400,
            ),
          ),
        ],
      ),
    );
  }
}
