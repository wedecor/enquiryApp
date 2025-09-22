import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../domain/analytics_models.dart';

/// Pie chart for event type breakdown
class EventTypePieChart extends StatelessWidget {
  final List<CategoryCount> data;
  final String title;

  const EventTypePieChart({super.key, required this.data, required this.title});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: data.isEmpty ? _buildEmptyState(context) : _buildChart(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChart(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: PieChart(
            PieChartData(
              sections: _getPieSections(context),
              centerSpaceRadius: 40,
              sectionsSpace: 2,
              startDegreeOffset: -90,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(child: _buildLegend(context)),
      ],
    );
  }

  Widget _buildLegend(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: data.take(8).map((item) {
        final color = _getColor(data.indexOf(item));
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${item.key} (${item.count})',
                  style: Theme.of(context).textTheme.bodySmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  List<PieChartSectionData> _getPieSections(BuildContext context) {
    return data.take(8).map((item) {
      final index = data.indexOf(item);
      final color = _getColor(index);
      final isLargest = index == 0;

      return PieChartSectionData(
        color: color,
        value: item.count.toDouble(),
        title: '${item.percentage.toStringAsFixed(1)}%',
        radius: isLargest ? 60 : 50,
        titleStyle: TextStyle(
          fontSize: isLargest ? 14 : 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  Color _getColor(int index) {
    final colors = [
      const Color(0xFF2563EB), // Blue
      const Color(0xFF059669), // Green
      const Color(0xFFF59E0B), // Amber
      const Color(0xFFDC2626), // Red
      const Color(0xFF7C3AED), // Purple
      const Color(0xFF0891B2), // Cyan
      const Color(0xFFEA580C), // Orange
      const Color(0xFF059669), // Emerald
    ];
    return colors[index % colors.length];
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.pie_chart, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'No data available',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}

/// Horizontal bar chart for source breakdown
class SourceBarChart extends StatelessWidget {
  final List<CategoryCount> data;
  final String title;

  const SourceBarChart({super.key, required this.data, required this.title});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: data.isEmpty ? _buildEmptyState(context) : _buildChart(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChart(BuildContext context) {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: data.isNotEmpty ? data.first.count.toDouble() * 1.2 : 10,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              if (groupIndex < data.length) {
                final item = data[groupIndex];
                return BarTooltipItem(
                  '${item.key}\n${item.count} (${item.percentage.toStringAsFixed(1)}%)',
                  const TextStyle(color: Colors.white),
                );
              }
              return null;
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < data.length) {
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    child: Text(
                      _truncateLabel(data[index].key),
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
              reservedSize: 30,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  child: Text(
                    value.toInt().toString(),
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: true, border: Border.all(color: Colors.grey.shade300)),
        barGroups: _getBarGroups(context),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: _getHorizontalInterval(),
          getDrawingHorizontalLine: (value) {
            return FlLine(color: Colors.grey.shade300, strokeWidth: 1);
          },
        ),
      ),
    );
  }

  List<BarChartGroupData> _getBarGroups(BuildContext context) {
    return data.take(10).map((item) {
      final index = data.indexOf(item);
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: item.count.toDouble(),
            color: Theme.of(context).primaryColor,
            width: 20,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
          ),
        ],
      );
    }).toList();
  }

  double _getHorizontalInterval() {
    if (data.isEmpty) return 1;
    final maxCount = data.first.count;
    if (maxCount <= 10) return 1;
    if (maxCount <= 50) return 5;
    if (maxCount <= 100) return 10;
    return (maxCount / 5).ceilToDouble();
  }

  String _truncateLabel(String label) {
    if (label.length <= 8) return label;
    return '${label.substring(0, 8)}...';
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bar_chart, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'No data available',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}

/// Stacked bar chart for status breakdown
class StatusStackedBarChart extends StatelessWidget {
  final List<CategoryCount> data;
  final String title;

  const StatusStackedBarChart({super.key, required this.data, required this.title});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: data.isEmpty ? _buildEmptyState(context) : _buildChart(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChart(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.center,
              maxY: data.fold<double>(0, (sum, item) => sum + item.count.toDouble()),
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    if (rodIndex < data.length) {
                      final item = data[rodIndex];
                      return BarTooltipItem(
                        '${item.key}: ${item.count}',
                        const TextStyle(color: Colors.white),
                      );
                    }
                    return null;
                  },
                ),
              ),
              titlesData: const FlTitlesData(show: false),
              borderData: FlBorderData(show: false),
              barGroups: [
                BarChartGroupData(
                  x: 0,
                  barRods: [
                    BarChartRodData(
                      toY: data.fold<double>(0, (sum, item) => sum + item.count.toDouble()),
                      rodStackItems: _getStackItems(),
                      width: 60,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                ),
              ],
              gridData: const FlGridData(show: false),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(flex: 2, child: _buildLegend(context)),
      ],
    );
  }

  List<BarChartRodStackItem> _getStackItems() {
    final stackItems = <BarChartRodStackItem>[];
    double currentY = 0;

    for (int i = 0; i < data.length; i++) {
      final item = data[i];
      final color = _getStatusColor(item.key);
      stackItems.add(BarChartRodStackItem(currentY, currentY + item.count.toDouble(), color));
      currentY += item.count.toDouble();
    }

    return stackItems;
  }

  Widget _buildLegend(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: data.map((item) {
        final color = _getStatusColor(item.key);
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${_formatStatusName(item.key)} (${item.count})',
                  style: Theme.of(context).textTheme.bodySmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase().replaceAll(' ', '_')) {
      case 'new':
        return Colors.orange;
      case 'in_talks':
        return const Color(0xFF2563EB);
      case 'quotation_sent':
        return const Color(0xFF009688); // Teal
      case 'confirmed':
        return Colors.indigo;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'not_interested':
        return Colors.red.shade300;
      default:
        return Colors.grey;
    }
  }

  String _formatStatusName(String status) {
    return status
        .split('_')
        .map((word) => word.isNotEmpty ? word[0].toUpperCase() + word.substring(1) : '')
        .join(' ');
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.stacked_bar_chart, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'No data available',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}
