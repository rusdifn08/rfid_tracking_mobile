import 'package:flutter/material.dart';

class RfidCheckingFormat {
  static String dateTime(DateTime dt) {
    const months = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Ags',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    final day = dt.day.toString().padLeft(2, '0');
    final mon = months[(dt.month - 1).clamp(0, 11)];
    final year = dt.year;
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    final ss = dt.second.toString().padLeft(2, '0');
    return '$day $mon $year, $hh.$mm.$ss';
  }

  /// Format badge "Last Scanned: 2026-05-11 16:07:18"
  static String lastScannedBadge(DateTime dt) {
    final y = dt.year;
    final mo = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    final ss = dt.second.toString().padLeft(2, '0');
    return '$y-$mo-$d $hh:$mm:$ss';
  }

  static String timeOnly(DateTime dt) {
    final h = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    final m = dt.minute.toString().padLeft(2, '0');
    final s = dt.second.toString().padLeft(2, '0');
    return '$h:$m:$s $ampm';
  }

  static String statusLabel(String raw) {
    final s = raw.trim().toUpperCase();
    switch (s) {
      case 'IN_SMARKET':
        return 'In Supermarket';
      case 'OUT_SMARKET':
        return 'Out Supermarket';
      case 'SUPPLY_URGENT':
        return 'Supply Urgent';
      case 'GOOD':
        return 'Good';
      case 'REPAIR':
        return 'Repair';
      case 'REJECT':
        return 'Reject';
      default:
        if (s.isEmpty) {
          return '-';
        }
        return s.replaceAll('_', ' ');
    }
  }

  static StatusStyle statusStyle(String raw) {
    final s = raw.trim().toUpperCase();
    switch (s) {
      case 'OUT_SMARKET':
        return const StatusStyle(
          background: Color(0xFFFFF7ED),
          foreground: Color(0xFFEA580C),
        );
      case 'IN_SMARKET':
        return const StatusStyle(
          background: Color(0xFFFFF7ED),
          foreground: Color(0xFFD97706),
        );
      case 'GOOD':
        return const StatusStyle(
          background: Color(0xFFECFDF5),
          foreground: Color(0xFF059669),
        );
      case 'REPAIR':
        return const StatusStyle(
          background: Color(0xFFFFFBEB),
          foreground: Color(0xFFD97706),
        );
      case 'REJECT':
        return const StatusStyle(
          background: Color(0xFFFFF1F2),
          foreground: Color(0xFFE11D48),
        );
      default:
        return const StatusStyle(
          background: Color(0xFFF1F5F9),
          foreground: Color(0xFF475467),
        );
    }
  }
}

class StatusStyle {
  const StatusStyle({required this.background, required this.foreground});

  final Color background;
  final Color foreground;
}
