import 'dart:io';
import 'package:flutter/material.dart';
import 'package:sespimma/core/utils/avatar_helper.dart';

class UserAvatar extends StatelessWidget {
  final String? name;
  final String? photoUrl;
  final File? localFile;
  final double size;
  final double? fontSize;
  final BorderRadius? borderRadius;
  final List<BoxShadow>? boxShadow;
  final Border? border;

  const UserAvatar({
    super.key,
    this.name,
    this.photoUrl,
    this.localFile,
    this.size = 48,
    this.fontSize,
    this.borderRadius,
    this.boxShadow,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final ImageProvider? provider = localFile != null && localFile!.existsSync()
        ? FileImage(localFile!)
        : AvatarHelper.getImageProvider(photoUrl);

    final effectiveRadius = borderRadius ?? BorderRadius.circular(size * 0.3);

    if (provider != null) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: effectiveRadius,
          border: border,
          boxShadow: boxShadow,
          image: DecorationImage(
            image: provider,
            fit: BoxFit.cover,
          ),
        ),
      );
    }

    final initials = AvatarHelper.getInitials(name);
    final bgColor = AvatarHelper.getAvatarColor(name);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: effectiveRadius,
        border: border,
        boxShadow: boxShadow,
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: fontSize ?? (size * 0.38),
          ),
        ),
      ),
    );
  }
}
