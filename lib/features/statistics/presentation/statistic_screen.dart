import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../content/application/content_provider.dart';

class StatisticScreen extends ConsumerWidget {
  const StatisticScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Progress'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ref.watch(contentStatsProvider).when(
        data: (stats) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Summary Cards
                Row(
                  children: [
                    Expanded(child: _buildSummaryCard(context, 'Total XP', '${stats.totalXp}', Colors.amber)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildSummaryCard(context, 'Current Streak', '${stats.currentStreakDays} Days', AppTheme.secondary)),
                  ],
                ),
                
                const SizedBox(height: 32),
                Text(
                  'Daily Completions (This Week)',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 24),
                
                // Bar Chart
                Container(
                  height: 250,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: 10,
                      barTouchData: BarTouchData(enabled: false),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (double value, TitleMeta meta) {
                              const style = TextStyle(color: AppTheme.textSecondary, fontSize: 12);
                              String text;
                              switch (value.toInt()) {
                                case 0: text = 'Mon'; break;
                                case 1: text = 'Tue'; break;
                                case 2: text = 'Wed'; break;
                                case 3: text = 'Thu'; break;
                                case 4: text = 'Fri'; break;
                                case 5: text = 'Sat'; break;
                                case 6: text = 'Sun'; break;
                                default: text = ''; break;
                              }
                              return SideTitleWidget(axisSide: meta.axisSide, child: Text(text, style: style));
                            },
                          ),
                        ),
                        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      gridData: const FlGridData(show: false),
                      borderData: FlBorderData(show: false),
                      barGroups: _buildChartGroups(stats.dailyCompletions),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  List<BarChartGroupData> _buildChartGroups(List<dynamic> dailyCompletions) {
    // If the backend returns an empty array, return 0s for all 7 days
    if (dailyCompletions.isEmpty) {
      return List.generate(7, (index) => _makeGroupData(index, 0));
    }
    // Otherwise map real data
    return List.generate(7, (index) {
      final value = (index < dailyCompletions.length) ? (dailyCompletions[index] as num).toDouble() : 0.0;
      return _makeGroupData(index, value);
    });
  }

  Widget _buildSummaryCard(BuildContext context, String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border(bottom: BorderSide(color: color, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: Colors.white)),
        ],
      ),
    );
  }

  BarChartGroupData _makeGroupData(int x, double y) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: AppTheme.primary,
          width: 16,
          borderRadius: BorderRadius.circular(4),
          backDrawRodData: BackgroundBarChartRodData(
            show: true,
            toY: 10,
            color: AppTheme.background,
          ),
        ),
      ],
    );
  }
}
