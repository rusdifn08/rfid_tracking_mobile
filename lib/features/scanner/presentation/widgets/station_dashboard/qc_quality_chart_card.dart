import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class QcQualityChartCard extends StatelessWidget {
  const QcQualityChartCard({
    super.key,
    required this.totalGood,
    required this.totalRepair,
    required this.totalReject,
  });

  final int totalGood;
  final int totalRepair;
  final int totalReject;

  @override
  Widget build(BuildContext context) {
    final total = totalGood + totalRepair + totalReject;
    double pct(int value) => total == 0 ? 0 : (value / total) * 100;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Komposisi Quality Control (%)',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 13),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 220,
            child: Row(
              children: [
                Expanded(
                  flex: 6,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      PieChart(
                        PieChartData(
                          sectionsSpace: 2,
                          centerSpaceRadius: 44,
                          startDegreeOffset: -90,
                          sections: [
                            PieChartSectionData(
                              color: const Color(0xFF16A34A),
                              value: totalGood.toDouble(),
                              title: total == 0 ? '0%' : '${pct(totalGood).toStringAsFixed(1)}%',
                              radius: 54,
                              titleStyle: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            PieChartSectionData(
                              color: const Color(0xFFF59E0B),
                              value: totalRepair.toDouble(),
                              title: total == 0 ? '0%' : '${pct(totalRepair).toStringAsFixed(1)}%',
                              radius: 54,
                              titleStyle: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            PieChartSectionData(
                              color: const Color(0xFFDC2626),
                              value: totalReject.toDouble(),
                              title: total == 0 ? '0%' : '${pct(totalReject).toStringAsFixed(1)}%',
                              radius: 54,
                              titleStyle: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Total',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                          Text(
                            '$total',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 4,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _LegendDot(
                        label: 'Good',
                        color: const Color(0xFF16A34A),
                        valueText:
                            '$totalGood (${pct(totalGood).toStringAsFixed(1)}%)',
                      ),
                      const SizedBox(height: 10),
                      _LegendDot(
                        label: 'Repair',
                        color: const Color(0xFFF59E0B),
                        valueText:
                            '$totalRepair (${pct(totalRepair).toStringAsFixed(1)}%)',
                      ),
                      const SizedBox(height: 10),
                      _LegendDot(
                        label: 'Reject',
                        color: const Color(0xFFDC2626),
                        valueText:
                            '$totalReject (${pct(totalReject).toStringAsFixed(1)}%)',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({
    required this.label,
    required this.color,
    required this.valueText,
  });

  final String label;
  final Color color;
  final String valueText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(label, style: GoogleFonts.poppins(fontSize: 11.5)),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          valueText,
          style: GoogleFonts.poppins(
            fontSize: 11,
            color: const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }
}
