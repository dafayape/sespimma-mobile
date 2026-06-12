import 'dart:io';
import 'package:flutter/material.dart';

class AvatarHelper {
  static ImageProvider getAvatar(String? photoUrl) {
    if (photoUrl != null && photoUrl.isNotEmpty) {
      if (photoUrl.startsWith('http')) {
        return NetworkImage(photoUrl);
      } else if (photoUrl.startsWith('assets/')) {
        return AssetImage(photoUrl);
      } else {
        return FileImage(File(photoUrl));
      }
    }
    return const AssetImage('assets/images/default_avatar.png');
  }
}
