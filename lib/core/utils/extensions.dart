import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

// ─── String Extensions ────────────────────────────────────────────────────

extension StringExtensions on String {
  String get toTitleCase {
    if (isEmpty) return this;
    return split(' ')
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
        .join(' ');
  }

  String get truncate80 => length > 80 ? '${substring(0, 80)}…' : this;
}

// ─── Number Extensions ────────────────────────────────────────────────────

extension IntExtensions on int {
  String get withCommas {
    return toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
  }

  String get zennyFormat => '${withCommas}z';
}

// ─── Color Helpers ────────────────────────────────────────────────────────

Color elementColor(String element) {
  switch (element.toLowerCase()) {
    case 'fire': return AppColors.elementFire;
    case 'water': return AppColors.elementWater;
    case 'thunder': return AppColors.elementThunder;
    case 'ice': return AppColors.elementIce;
    case 'dragon': return AppColors.elementDragon;
    case 'poison': return AppColors.elementPoison;
    case 'blast': return AppColors.elementBlast;
    default: return AppColors.onSurfaceMuted;
  }
}

Color rankColor(String rank) {
  switch (rank) {
    case 'G Rank': return AppColors.primary;
    case 'High Rank': return const Color(0xFF42A5F5);
    default: return AppColors.onSurfaceMuted;
  }
}

// ─── Debouncer ────────────────────────────────────────────────────────────

class Debouncer {
  final Duration delay;
  DateTime? _lastCall;

  Debouncer({this.delay = const Duration(milliseconds: 300)});

  void call(VoidCallback action) {
    final now = DateTime.now();
    _lastCall = now;
    Future.delayed(delay, () {
      if (_lastCall == now) action();
    });
  }
}
