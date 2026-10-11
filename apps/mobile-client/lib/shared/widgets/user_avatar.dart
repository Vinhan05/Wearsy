import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../features/auth/providers/auth_provider.dart';

/// Reusable user avatar widget that dynamically synchronizes with AuthProvider state.
class UserAvatar extends StatelessWidget {
  final double radius;
  final String? avatarUrl;
  final VoidCallback? onTap;
  final bool showBorder;
  final Color? borderColor;
  final double borderWidth;
  final String fallbackAsset;

  const UserAvatar({
    super.key,
    this.radius = 20,
    this.avatarUrl,
    this.onTap,
    this.showBorder = false,
    this.borderColor,
    this.borderWidth = 1.5,
    this.fallbackAsset = 'assets/images/profile_avatar.jpg',
  });

  ImageProvider _getImageProvider(String url) {
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return NetworkImage(url);
    } else if (url.startsWith('assets/')) {
      return AssetImage(url);
    } else {
      final file = File(url);
      if (file.existsSync()) {
        return FileImage(file);
      }
    }
    return AssetImage(fallbackAsset);
  }

  @override
  Widget build(BuildContext context) {
    final authUser = Provider.of<AuthProvider>(context).user;
    final effectiveUrl = avatarUrl ?? authUser?.avatarUrl;

    Widget avatarContent;

    if (effectiveUrl != null && effectiveUrl.isNotEmpty) {
      avatarContent = CircleAvatar(
        radius: radius,
        backgroundColor: const Color(0xFFF3F4F6),
        backgroundImage: _getImageProvider(effectiveUrl),
        onBackgroundImageError: (exception, stackTrace) {
          debugPrint('UserAvatar error loading image ($effectiveUrl): $exception');
        },
      );
    } else {
      avatarContent = CircleAvatar(
        radius: radius,
        backgroundColor: const Color(0xFFF3F4F6),
        backgroundImage: AssetImage(fallbackAsset),
      );
    }

    if (showBorder) {
      avatarContent = Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: borderColor ?? const Color(0xFFE5E7EB),
            width: borderWidth,
          ),
        ),
        child: avatarContent,
      );
    }

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: avatarContent,
      );
    }

    return avatarContent;
  }
}
