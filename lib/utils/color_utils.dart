import 'package:flutter/material.dart';

class ColorUtils {
  static Color getColorForIndex(int index) {
    final colors = [
      Color(0xFF6366F1),
      Color(0xFF10B981),
      Color(0xFFF59E0B),
      Color(0xFFEF4444),
      Color(0xFF8B5CF6),
      Color(0xFF06B6D4),
    ];
    return colors[index % colors.length];
  }

  static Color get primaryColor => Color(0xFF4F46E5);

  static Color getHariColor(String hari) {
    final Map<String, Color> hariColorMap = {
      'Senin': Color(0xFF6366F1),
      'Selasa': Color(0xFF10B981),
      'Rabu': Color(0xFFF59E0B),
      'Kamis': Color(0xFFEF4444),
      'Jumat': Color(0xFF8B5CF6),
      'Sabtu': Color(0xFF06B6D4),
    };
    return hariColorMap[hari] ?? Color(0xFF6B7280);
  }
}