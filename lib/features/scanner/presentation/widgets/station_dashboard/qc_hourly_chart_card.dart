import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../state/scanner_state.dart';

class QcHourlyChartCard extends StatelessWidget {
  const QcHourlyChartCard({
    super.key,
    required this.title,
    required this.points,
  });

  final String title;
  final List<QcHourlyPoint> points;

  static const Color _goodColor = Color(0xFF16A34A);
  static const Color _repairColor = Color(0xFFF59E0B);
  static const Color _rejectColor = Color(0xFFDC2626);

  @override
  Widget build(BuildContext context) {
    final hasData = points.isNotEmpty;
    final maxValue = hasData
        ? points.fold<int>(0, (max, p) {
            final m = [
              p.good,
              p.repair,
              p.reject,
            ].reduce((a, b) => a > b ? a : b);
            return m > max ? m : max;
          })
        : 0;
    final maxY = (maxValue + 1).toDouble();
    final interval = maxY <= 5 ? 1.0 : (maxY / 4).ceilToDouble();

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
            title,
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 13),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 200,
            child: hasData
                ? LineChart(
                    LineChartData(
                      minY: 0,
                      maxY: maxY,
                      gridData: const FlGridData(show: true, drawVerticalLine: false),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            interval: interval,
                            getTitlesWidget: (value, meta) => Text(
                              value.toInt().toString(),
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                color: const Color(0xFF98A2B3),
                              ),
                            ),
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: 1,
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt();
                              if (index < 0 || index >= points.length) {
                                return const SizedBox.shrink();
                              }
                              return Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  points[index].hour,
                                  style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    color: const Color(0xFF98A2B3),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      lineBarsData: <LineChartBarData>[
                        _buildSeries((p) => p.good.toDouble(), _goodColor),
                        _buildSeries((p) => p.repair.toDouble(), _repairColor),
                        _buildSeries((p) => p.reject.toDouble(), _rejectColor),
                      ],
                    ),
                  )
                : Center(
                    child: Text(
                      'Belum ada data per jam',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 14,
            runSpacing: 6,
            children: const <Widget>[
              _Legend(label: 'Good', color: _goodColor),
              _Legend(label: 'Repair', color: _repairColor),
              _Legend(label: 'Reject', color: _rejectColor),
            ],
          ),
        ],
      ),
    );
  }

  LineChartBarData _buildSeries(
    double Function(QcHourlyPoint) selector,
    Color color,
  ) {
    return LineChartBarData(
      spots: <FlSpot>[
        for (var i = 0; i < points.length; i++)
          FlSpot(i.toDouble(), selector(points[i])),
      ],
      color: color,
      barWidth: 2.4,
      isCurved: true,
      dotData: FlDotData(
        show: true,
        getDotPainter: (spot, percent, line, index) => FlDotCirclePainter(
          radius: 2.5,
          color: color,
          strokeColor: Colors.white,
          strokeWidth: 1.2,
        ),
      ),
      belowBarData: BarAreaData(show: false),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 11,
            color: const Color(0xFF475467),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
