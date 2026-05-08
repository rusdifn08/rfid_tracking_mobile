String formatScanHistoryDate(DateTime date) {
  final hh = date.hour.toString().padLeft(2, '0');
  final mm = date.minute.toString().padLeft(2, '0');
  final dd = date.day.toString().padLeft(2, '0');
  final mo = date.month.toString().padLeft(2, '0');
  final yy = date.year.toString();
  return '$dd/$mo/$yy $hh:$mm';
}
