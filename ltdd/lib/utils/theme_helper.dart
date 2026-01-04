// File: lib/utils/theme_helper.dart
// Helper để lấy màu sắc phù hợp với theme

import 'package:flutter/material.dart';

extension ThemeHelper on BuildContext {
  /// Lấy màu nền cho card/container
  Color get cardBackgroundColor {
    final brightness = Theme.of(this).brightness;
    return brightness == Brightness.dark 
        ? const Color(0xFF1A1A1A) 
        : Colors.white;
  }

  /// Lấy màu border cho card/container
  Color get cardBorderColor {
    final brightness = Theme.of(this).brightness;
    return brightness == Brightness.dark 
        ? const Color(0xFF2A2A2A) 
        : const Color(0xFFE0E0E0);
  }

  /// Lấy màu text chính
  Color get primaryTextColor {
    final brightness = Theme.of(this).brightness;
    return brightness == Brightness.dark 
        ? Colors.white 
        : const Color(0xFF212121);
  }

  /// Lấy màu text phụ
  Color get secondaryTextColor {
    final brightness = Theme.of(this).brightness;
    return brightness == Brightness.dark 
        ? Colors.grey[400]! 
        : const Color(0xFF757575);
  }

  /// Lấy màu text label
  Color get labelTextColor {
    final brightness = Theme.of(this).brightness;
    return brightness == Brightness.dark 
        ? Colors.grey[600]! 
        : const Color(0xFF9E9E9E);
  }

  /// Lấy màu divider
  Color get dividerColor {
    final brightness = Theme.of(this).brightness;
    return brightness == Brightness.dark 
        ? const Color(0xFF2A2A2A) 
        : const Color(0xFFE0E0E0);
  }

  /// Lấy màu nền cho icon container
  Color get iconContainerColor {
    final brightness = Theme.of(this).brightness;
    return brightness == Brightness.dark 
        ? const Color(0xFF2A2A2A) 
        : const Color(0xFFF5F5F5);
  }

  /// Lấy màu nền cho avatar
  Color get avatarBackgroundColor {
    final brightness = Theme.of(this).brightness;
    return brightness == Brightness.dark 
        ? const Color(0xFF2A2A2A) 
        : const Color(0xFFF5F5F5);
  }
}

