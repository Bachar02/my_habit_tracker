
// lib/utils/colors.dart
import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF4285f4);
  static const Color secondary = Color(0xFF34a853);
  static const Color accent = Color(0xFFfbbc05);
  static const Color error = Color(0xFFea4335);

  // Heatmap colors (GitHub style)
  static const Color heatmapEmpty = Color(0xFFf0f0f0);
  static const Color heatmapLight = Color(0xFFc6e48b);
  static const Color heatmapMedium = Color(0xFF7bc96f);
  static const Color heatmapDark = Color(0xFF239a3b);
  static const Color heatmapIntense = Color(0xFF196127);

  // UI colors
  static const Color backgroundLight = Color(0xFFfafafa);
  static const Color cardBackground = Colors.white;
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);

  // Habit preset colors
  static const List<String> habitColors = [
    '#4285f4', // Blue
    '#34a853', // Green
    '#fbbc05', // Yellow
    '#ea4335', // Red
    '#9c27b0', // Purple
    '#ff9800', // Orange
    '#795548', // Brown
    '#607d8b', // Blue Grey
  ];
}
