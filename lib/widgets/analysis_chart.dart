import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/disease_tracking.dart';

class AnalysisChart extends StatelessWidget {
  final List<DiseaseAnalysis> analyses;

  const AnalysisChart({super.key, required this.analyses});

  @override
  Widget build(BuildContext context) {
    if (analyses.isEmpty) {
      return const Center(
        child: Text('No data available for chart'),
      );
    }

    // Sort analyses by date
    final sortedAnalyses = List<DiseaseAnalysis>.from(analyses);
    sortedAnalyses.sort((a, b) => a.analyzedAt.compareTo(b.analyzedAt));

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: 0.2,
          verticalInterval: 1,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey[300]!,
              strokeWidth: 1,
            );
          },
          getDrawingVerticalLine: (value) {
            return FlLine(
              color: Colors.grey[300]!,
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 1,
              getTitlesWidget: (value, meta) {
                if (value.toInt() < sortedAnalyses.length) {
                  final date = sortedAnalyses[value.toInt()].analyzedAt;
                  return Text(
                    '${date.day}/${date.month}',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 0.2,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${(value * 100).toInt()}%',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.grey[300]!),
        ),
        minX: 0,
        maxX: (sortedAnalyses.length - 1).toDouble(),
        minY: 0,
        maxY: 1,
        lineBarsData: [
          LineChartBarData(
            spots: sortedAnalyses.asMap().entries.map((entry) {
              return FlSpot(entry.key.toDouble(), entry.value.riskScore);
            }).toList(),
            isCurved: true,
            gradient: LinearGradient(
              colors: [
                Colors.blue[400]!,
                Colors.blue[600]!,
              ],
            ),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: _getRiskColor(sortedAnalyses[index].riskScore),
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  Colors.blue[400]!.withOpacity(0.3),
                  Colors.blue[600]!.withOpacity(0.1),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((touchedSpot) {
                final index = touchedSpot.x.toInt();
                if (index < sortedAnalyses.length) {
                  final analysis = sortedAnalyses[index];
                  return LineTooltipItem(
                    'Risk: ${(analysis.riskScore * 100).toStringAsFixed(0)}%\n'
                    'Confidence: ${(analysis.confidence * 100).toStringAsFixed(0)}%',
                    const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                }
                return null;
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  Color _getRiskColor(double riskScore) {
    if (riskScore >= 0.8) return Colors.red;
    if (riskScore >= 0.6) return Colors.orange;
    if (riskScore >= 0.4) return Colors.yellow[700]!;
    return Colors.green;
  }
}
