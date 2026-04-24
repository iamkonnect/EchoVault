import 'package:flutter/material.dart';

/// Utility class for handling track images and cover arts
class ImageUtils {
  /// Returns the main app logo with a confirmed fallback
  static ImageProvider getAppLogo() {
    // Verify if you are using '0' (zero) or 'o' (letter) in your actual filename
    // Using Echo-Vault-Icon.png as the primary logo as per user request.
    return const AssetImage('assets/Echo-Vault-Icon.png');
    // Note: If the above fails, the Image widget's errorBuilder should 
    // handle the UI fallback.
  }

  /// Returns ImageProvider for track cover images
  /// Handles asset paths, network URLs, and fallbacks
  static ImageProvider getTrackImage(String? cover) {
    if (cover == null || cover.isEmpty) {
      // AssetImage cannot load SVG files directly (need flutter_svg for that).
      // Using one of your confirmed images as a safe fallback to prevent 404/500 errors.
      return const AssetImage('assets/Echo-Vault-Icon.png');
    }

    // Check if it's a network URL
    if (cover.startsWith('http://') || cover.startsWith('https://')) {
      return NetworkImage(cover);
    }

    // Handle asset paths (WhatsApp images, samples, etc.)
    if (cover.startsWith('assets/')) {
      return AssetImage(cover); 
    }

    // Fallback for any other paths
    return const AssetImage('assets/Echo-Vault-Icon.png'); 
  }

  /// Returns the file path for cover images (used in MediaItem artUri)
  static String getImagePath(String? cover) {
    final effectiveCover = cover ?? '';
    if (effectiveCover.startsWith('http://') || effectiveCover.startsWith('https://')) {
      return effectiveCover;
    }

    // For assets, return the path as-is for artUri encoding
    if (effectiveCover.startsWith('assets/')) {
      return effectiveCover;
    }

    // Default fallback
    return 'assets/Echo-Vault-Icon.png';
  }
}
