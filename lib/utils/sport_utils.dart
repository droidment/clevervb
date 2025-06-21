import 'package:flutter/material.dart';

/// Utility helpers for sport-specific UI theming.
class SportUtils {
  /// Returns a primary Material [Color] representing the given [sport].
  ///
  /// The mapping is kept central so different screens (discovery cards,
  /// game details, etc.) use a consistent palette.
  static Color color(String sport) {
    switch (sport.toLowerCase()) {
      case 'volleyball':
        return Colors.brown; // 🏐
      case 'pickleball':
        return Colors.green; // 🏓
      case 'basketball':
        return Colors.deepOrange; // 🏀
      case 'tennis':
        return Colors.blue; // 🎾
      case 'badminton':
        return Colors.purple; // 🏸
      case 'soccer':
        return Colors.teal; // ⚽
      case 'cricket':
        return Colors.lightGreen; // 🏏
      default:
        return Colors.grey;
    }
  }
}
