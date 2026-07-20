import 'package:flutter/material.dart';

abstract final class AppColors {
  static const Color primary = Color(0xFF2563EB);
  static const Color secondary = Color(0xFF475569);

  static const Color lightSurface = Color(0xFFF8FAFC);
  static const Color darkSurface = Color(0xFF0F172A);

  static const Color info = Color(0xFF2563EB);
  static const Color success = Color(0xFF059669);
  static const Color warning = Color(0xFFD97706);
  static const Color danger = Color(0xFFDC2626);
  static const Color neutral = Color(0xFF64748B);
  static const Color purple = Color(0xFF7C3AED);

  static Color ticketStatus(String value) {
    final normalized = value.trim().toLowerCase().replaceAll(
      RegExp(r'[\s_-]+'),
      '',
    );
    return switch (normalized) {
      'submitted' || 'open' => info,
      'assigned' => purple,
      'processing' || 'inprogress' || 'pending' => warning,
      'resolved' => success,
      'closed' => neutral,
      'cancelled' || 'canceled' => danger,
      _ => neutral,
    };
  }

  static Color priority(String value) {
    final normalized = value.trim().toLowerCase();
    return switch (normalized) {
      'critical' || 'urgent' => const Color(0xFFB91C1C),
      'high' => danger,
      'medium' || 'normal' => warning,
      'low' => success,
      _ => neutral,
    };
  }
}
