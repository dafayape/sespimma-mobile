import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AvatarHelper {
  /// Returns an ImageProvider if photoUrl points to a valid file, remote URL, or asset.
  /// Returns null if no photo is set.
  static ImageProvider? getImageProvider(String? photoUrl) {
    if (photoUrl != null && photoUrl.isNotEmpty) {
      if (photoUrl.startsWith('http')) {
        return NetworkImage(photoUrl);
      }

      final file = File(photoUrl);
      if (file.existsSync()) {
        return FileImage(file);
      }

      if (photoUrl.startsWith('/')) {
        final baseUrl = dotenv.env['API_BASE_URL'] ?? '';
        final cleanBase = baseUrl.endsWith('/api/v1')
            ? baseUrl.substring(0, baseUrl.length - 7)
            : (baseUrl.endsWith('/api/v1/')
                ? baseUrl.substring(0, baseUrl.length - 8)
                : (baseUrl.endsWith('/')
                    ? baseUrl.substring(0, baseUrl.length - 1)
                    : baseUrl));
        final fullUrl = '$cleanBase$photoUrl';
        return NetworkImage(fullUrl);
      } else if (photoUrl.startsWith('assets/')) {
        return AssetImage(photoUrl);
      }
    }
    return null;
  }

  /// Legacy helper for fallback image.
  static ImageProvider getAvatar(String? photoUrl) {
    return getImageProvider(photoUrl) ?? const AssetImage('assets/images/default_avatar.png');
  }

  /// Extracts 1 or 2 uppercase initials from a person's name (matching web frontend).
  static String getInitials(String? name) {
    if (name == null || name.trim().isEmpty) return '??';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '??';
    if (parts.length == 1) {
      final str = parts[0];
      return str.substring(0, str.length >= 2 ? 2 : 1).toUpperCase();
    }
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  /// Generates a deterministic background color based on name hash (matching web frontend).
  static Color getAvatarColor(String? name) {
    if (name == null || name.trim().isEmpty) return const Color(0xFF64748B);
    const colors = [
      Color(0xFF3B82F6), // Blue 500
      Color(0xFF8B5CF6), // Purple 500
      Color(0xFFEC4899), // Pink 500
      Color(0xFF10B981), // Green 500
      Color(0xFF6366F1), // Indigo 500
    ];
    final charCode = name.runes.fold<int>(0, (sum, char) => sum + char);
    return colors[charCode % colors.length];
  }
}
