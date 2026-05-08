import 'station_dashboard_models.dart';

class StationDashboardMockData {
  static StationDashboardData bundle() {
    const series = <HourlyScanPoint>[
      HourlyScanPoint(hourLabel: '08', total: 22),
      HourlyScanPoint(hourLabel: '09', total: 29),
      HourlyScanPoint(hourLabel: '10', total: 34),
      HourlyScanPoint(hourLabel: '11', total: 27),
      HourlyScanPoint(hourLabel: '12', total: 20),
      HourlyScanPoint(hourLabel: '13', total: 31),
      HourlyScanPoint(hourLabel: '14', total: 38),
      HourlyScanPoint(hourLabel: '15', total: 35),
    ];

    const rows = <StationHistoryRow>[
      StationHistoryRow(rfid: '123456', workOrder: '187249', qty: 1),
      StationHistoryRow(rfid: '999', workOrder: '187249', qty: 1),
      StationHistoryRow(rfid: '222', workOrder: '187249', qty: 1),
      StationHistoryRow(rfid: '456', workOrder: '187249', qty: 1),
      StationHistoryRow(rfid: '123', workOrder: '187249', qty: 1),
      StationHistoryRow(rfid: '123123', workOrder: '186762', qty: 10),
      StationHistoryRow(rfid: '0042613531', workOrder: '185035', qty: 1),
      StationHistoryRow(rfid: '0006063838', workOrder: '186762', qty: 25),
      StationHistoryRow(rfid: '2013562388', workOrder: '186752', qty: 25),
    ];

    return const StationDashboardData(
      stationName: 'Bundle',
      totalScan: 236,
      peakHourLabel: '14:00',
      peakHourCount: 38,
      hourlySeries: series,
      historyRows: rows,
    );
  }

  static StationDashboardData supermarket() {
    const series = <HourlyScanPoint>[
      HourlyScanPoint(hourLabel: '08', total: 14),
      HourlyScanPoint(hourLabel: '09', total: 18),
      HourlyScanPoint(hourLabel: '10', total: 26),
      HourlyScanPoint(hourLabel: '11', total: 22),
      HourlyScanPoint(hourLabel: '12', total: 16),
      HourlyScanPoint(hourLabel: '13', total: 28),
      HourlyScanPoint(hourLabel: '14', total: 30),
      HourlyScanPoint(hourLabel: '15', total: 24),
    ];

    const rows = <StationHistoryRow>[
      StationHistoryRow(rfid: 'SPM-483920', workOrder: 'SM240511', qty: 3),
      StationHistoryRow(rfid: 'SPM-483921', workOrder: 'SM240511', qty: 2),
      StationHistoryRow(rfid: 'SPM-483922', workOrder: 'SM240511', qty: 1),
      StationHistoryRow(rfid: 'SPM-483930', workOrder: 'SM240534', qty: 4),
      StationHistoryRow(rfid: 'SPM-483936', workOrder: 'SM240534', qty: 3),
      StationHistoryRow(rfid: 'SPM-484001', workOrder: 'SM240612', qty: 5),
      StationHistoryRow(rfid: 'SPM-484010', workOrder: 'SM240612', qty: 2),
      StationHistoryRow(rfid: 'SPM-484055', workOrder: 'SM240619', qty: 4),
    ];

    return const StationDashboardData(
      stationName: 'Supermarket',
      totalScan: 178,
      peakHourLabel: '14:00',
      peakHourCount: 30,
      hourlySeries: series,
      historyRows: rows,
    );
  }

  static StationDashboardData supplySewing() {
    const series = <HourlyScanPoint>[
      HourlyScanPoint(hourLabel: '08', total: 16),
      HourlyScanPoint(hourLabel: '09', total: 21),
      HourlyScanPoint(hourLabel: '10', total: 24),
      HourlyScanPoint(hourLabel: '11', total: 23),
      HourlyScanPoint(hourLabel: '12', total: 17),
      HourlyScanPoint(hourLabel: '13', total: 25),
      HourlyScanPoint(hourLabel: '14', total: 27),
      HourlyScanPoint(hourLabel: '15', total: 26),
    ];

    const rows = <StationHistoryRow>[
      StationHistoryRow(rfid: 'SUP-938201', workOrder: 'SW240410', qty: 2),
      StationHistoryRow(rfid: 'SUP-938233', workOrder: 'SW240410', qty: 1),
      StationHistoryRow(rfid: 'SUP-938291', workOrder: 'SW240411', qty: 3),
      StationHistoryRow(rfid: 'SUP-938311', workOrder: 'SW240411', qty: 2),
      StationHistoryRow(rfid: 'SUP-938350', workOrder: 'SW240428', qty: 4),
      StationHistoryRow(rfid: 'SUP-938380', workOrder: 'SW240428', qty: 5),
      StationHistoryRow(rfid: 'SUP-938433', workOrder: 'SW240501', qty: 2),
      StationHistoryRow(rfid: 'SUP-938444', workOrder: 'SW240501', qty: 3),
    ];

    return const StationDashboardData(
      stationName: 'Supply Sewing',
      totalScan: 179,
      peakHourLabel: '14:00',
      peakHourCount: 27,
      hourlySeries: series,
      historyRows: rows,
    );
  }

  static QcDashboardData qualityControl() {
    const series = <HourlyScanPoint>[
      HourlyScanPoint(hourLabel: '08', total: 20, good: 17, repair: 2, reject: 1),
      HourlyScanPoint(hourLabel: '09', total: 24, good: 20, repair: 2, reject: 2),
      HourlyScanPoint(hourLabel: '10', total: 26, good: 22, repair: 3, reject: 1),
      HourlyScanPoint(hourLabel: '11', total: 22, good: 17, repair: 3, reject: 2),
      HourlyScanPoint(hourLabel: '12', total: 16, good: 12, repair: 2, reject: 2),
      HourlyScanPoint(hourLabel: '13', total: 27, good: 22, repair: 3, reject: 2),
      HourlyScanPoint(hourLabel: '14', total: 29, good: 24, repair: 3, reject: 2),
      HourlyScanPoint(hourLabel: '15', total: 25, good: 20, repair: 3, reject: 2),
    ];

    const rows = <QcHistoryRow>[
      QcHistoryRow(rfidBundle: 'QC-240511-001', qty: 12, good: 10, repair: 1, reject: 1),
      QcHistoryRow(rfidBundle: 'QC-240511-007', qty: 10, good: 8, repair: 2, reject: 0),
      QcHistoryRow(rfidBundle: 'QC-240511-010', qty: 16, good: 12, repair: 3, reject: 1),
      QcHistoryRow(rfidBundle: 'QC-240511-015', qty: 8, good: 6, repair: 1, reject: 1),
      QcHistoryRow(rfidBundle: 'QC-240511-018', qty: 20, good: 17, repair: 2, reject: 1),
      QcHistoryRow(rfidBundle: 'QC-240511-021', qty: 14, good: 11, repair: 2, reject: 1),
      QcHistoryRow(rfidBundle: 'QC-240511-025', qty: 18, good: 15, repair: 2, reject: 1),
      QcHistoryRow(rfidBundle: 'QC-240511-032', qty: 13, good: 9, repair: 2, reject: 2),
    ];

    return const QcDashboardData(
      totalScan: 189,
      totalGood: 154,
      totalRepair: 18,
      totalReject: 12,
      hourlySeries: series,
      historyRows: rows,
    );
  }
}
