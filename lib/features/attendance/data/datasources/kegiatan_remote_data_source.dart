import 'package:dio/dio.dart';
import '../../domain/models/map_tile_mode.dart';
import 'package:latlong2/latlong.dart';

class KegiatanRemoteDataSource {
  final Dio dio;

  KegiatanRemoteDataSource({required this.dio});

  /// Fetches active kegiatan for today from the backend API
  /// and converts them into [AttendanceZone] objects for the map.
  Future<List<AttendanceZone>> fetchActiveZones() async {
    try {
      final response = await dio.get('/mobile/kegiatan-aktif');

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        final List items = data['data'] ?? [];

        return items.map<AttendanceZone>((json) {
          // Parse polygon points if available
          List<LatLng>? polygonPoints;
          if (json['polygon_points'] != null && json['polygon_points'] is List) {
            final polyList = json['polygon_points'] as List;
            if (polyList.isNotEmpty) {
              polygonPoints = polyList
                  .map<LatLng>((p) => LatLng(
                        (p['latitude'] as num).toDouble(),
                        (p['longitude'] as num).toDouble(),
                      ))
                  .toList();
            }
          }

          // Parse times
          final startTimeFull = DateTime.tryParse(json['start_time_full'] ?? '') ?? DateTime.now();
          final endTimeFull = DateTime.tryParse(json['end_time_full'] ?? '') ?? DateTime.now();
          final deadline = DateTime.tryParse(json['deadline'] ?? '') ?? endTimeFull;
          final cutoffTime = DateTime.tryParse(json['cutoff_time'] ?? '') ?? endTimeFull;
          final createdAt = DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now();

          // Parse routine dates
          DateTime? routineStartDate;
          DateTime? routineEndDate;
          if (json['routine_start_date'] != null) {
            routineStartDate = DateTime.tryParse(json['routine_start_date']);
          }
          if (json['routine_end_date'] != null) {
            routineEndDate = DateTime.tryParse(json['routine_end_date']);
          }

          return AttendanceZone(
            id: json['id']?.toString() ?? '',
            name: json['name']?.toString() ?? json['activity_name']?.toString() ?? '',
            latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
            longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
            radiusMeters: (json['radius_meters'] as num?)?.toDouble() ?? 50.0,
            polygonPoints: polygonPoints,
            activityName: json['activity_name']?.toString() ?? '',
            creator: json['creator_name']?.toString() ?? 'Admin',
            startTime: startTimeFull,
            endTime: endTimeFull,
            deadline: deadline,
            cutoffTime: cutoffTime,
            createdAt: createdAt,
            isRoutine: json['is_routine'] == true,
            isTraining: json['is_training'] == true,
            routineStartDate: routineStartDate,
            routineEndDate: routineEndDate,
          );
        }).toList();
      }

      return [];
    } catch (e) {
      // print('ERROR in fetchActiveZones: $e');
      // print(stack);
      // Return empty list on error - the UI will show "no zones" state
      return [];
    }
  }
}
