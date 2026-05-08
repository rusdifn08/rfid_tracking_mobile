class HourlyScanPoint {
  const HourlyScanPoint({
    required this.hourLabel,
    required this.total,
    this.good = 0,
    this.repair = 0,
    this.reject = 0,
  });

  final String hourLabel;
  final int total;
  final int good;
  final int repair;
  final int reject;
}

class StationHistoryRow {
  const StationHistoryRow({
    required this.rfid,
    required this.workOrder,
    required this.qty,
  });

  final String rfid;
  final String workOrder;
  final int qty;
}

class QcHistoryRow {
  const QcHistoryRow({
    required this.rfidBundle,
    required this.qty,
    required this.good,
    required this.repair,
    required this.reject,
  });

  final String rfidBundle;
  final int qty;
  final int good;
  final int repair;
  final int reject;
}

class StationDashboardData {
  const StationDashboardData({
    required this.stationName,
    required this.totalScan,
    required this.peakHourLabel,
    required this.peakHourCount,
    required this.hourlySeries,
    required this.historyRows,
  });

  final String stationName;
  final int totalScan;
  final String peakHourLabel;
  final int peakHourCount;
  final List<HourlyScanPoint> hourlySeries;
  final List<StationHistoryRow> historyRows;
}

class QcDashboardData {
  const QcDashboardData({
    required this.totalScan,
    required this.totalGood,
    required this.totalRepair,
    required this.totalReject,
    required this.hourlySeries,
    required this.historyRows,
  });

  final int totalScan;
  final int totalGood;
  final int totalRepair;
  final int totalReject;
  final List<HourlyScanPoint> hourlySeries;
  final List<QcHistoryRow> historyRows;
}
