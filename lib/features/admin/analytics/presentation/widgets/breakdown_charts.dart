import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/theme/tokens.dart';
import '../../../../../services/dropdown_lookup.dart';
import '../../domain/analytics_models.dart';
import 'analytics_section_card.dart';

/// Pie chart for event type breakdown
class EventTypePieChart extends StatelessWidget {
  final List<CategoryCount> data;
  final String title;

  const EventTypePieChart({super.key, required this.data, required this.title});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return AnalyticsSectionCard(
        title: title,
        child: SizedBox(height: 200, child: _buildEmptyState(context)),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < AppTokens.breakpointMobile + 80;
        return AnalyticsSectionCard(
          title: title,
          child: narrow
              ? _buildChart(context)
              : SizedBox(height: 300, child: _buildChart(context)),
        );
      },
    );
  }

  Widget _buildChart(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < AppTokens.breakpointMobile + 80;

        if (narrow) {
          return SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(
                  height: 200,
                  child: PieChart(
                    PieChartData(
                      sections: _getPieSections(context),
                      centerSpaceRadius: 36,
                      sectionsSpace: 2,
                      startDegreeOffset: -90,
                    ),
                  ),
                ),
                const SizedBox(height: AppTokens.space3),
                _buildLegend(context),
              ],
            ),
          );
        }

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
            const SizedBox(width: AppTokens.space4),
            Expanded(child: _buildLegend(context)),
          ],
        );
      },
    );
  }

  Widget _buildLegend(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
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
                  '${_labelFor(item)} (${item.count})',
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
    return AppColorScheme.chartPalette[index %
        AppColorScheme.chartPalette.length];
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.pie_chart,
            size: 48,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'No data available',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  String _labelFor(CategoryCount item) =>
      item.label ?? DropdownLookup.titleCase(item.key);
}

/// Horizontal bar chart for source breakdown
class SourceBarChart extends StatelessWidget {
  final List<CategoryCount> data;
  final String title;

  const SourceBarChart({super.key, required this.data, required this.title});

  @override
  Widget build(BuildContext context) {
    return AnalyticsSectionCard(
      title: title,
      child: SizedBox(
        height: 300,
        child: data.isEmpty ? _buildEmptyState(context) : _buildChart(context),
      ),
    );
  }

  Widget _buildChart(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
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
                  '${_labelFor(item)}\n${item.count} (${item.percentage.toStringAsFixed(1)}%)',
                  const TextStyle(color: Colors.white),
                );
              }
              return null;
            },
          ),
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
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < data.length) {
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    child: Text(
                      _truncateLabel(_labelFor(data[index])),
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColorScheme.neutralGrey,
                      ),
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
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColorScheme.neutralGrey,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        barGroups: _getBarGroups(primary),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: _getHorizontalInterval(),
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Theme.of(context).colorScheme.outlineVariant,
              strokeWidth: 1,
            );
          },
        ),
      ),
    );
  }

  List<BarChartGroupData> _getBarGroups(Color primary) {
    return data.take(10).map((item) {
      final index = data.indexOf(item);
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: item.count.toDouble(),
            color: primary,
            width: 20,
            borderRadius: AppRadius.only(
              topLeft: AppTokens.radiusSmall,
              topRight: AppTokens.radiusSmall,
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
          Icon(
            Icons.bar_chart,
            size: 48,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'No data available',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

String _labelFor(CategoryCount item) =>
    item.label ?? DropdownLookup.titleCase(item.key);

/// Stacked bar chart for status breakdown
class StatusStackedBarChart extends StatelessWidget {
  final List<CategoryCount> data;
  final String title;

  const StatusStackedBarChart({
    super.key,
    required this.data,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return AnalyticsSectionCard(
        title: title,
        child: SizedBox(height: 200, child: _buildEmptyState(context)),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < AppTokens.breakpointMobile + 80;
        return AnalyticsSectionCard(
          title: title,
          child: narrow
              ? _buildChart(context)
              : SizedBox(height: 300, child: _buildChart(context)),
        );
      },
    );
  }

  Widget _buildChart(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < AppTokens.breakpointMobile + 80;

        if (narrow) {
          return SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(
                  height: 200,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.center,
                      maxY: data.fold<double>(
                        0,
                        (sum, item) => sum + item.count.toDouble(),
                      ),
                      barTouchData: BarTouchData(
                        enabled: true,
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            if (rodIndex < data.length) {
                              final item = data[rodIndex];
                              return BarTooltipItem(
                                '${_statusLabel(item)}: ${item.count}',
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
                              toY: data.fold<double>(
                                0,
                                (sum, item) => sum + item.count.toDouble(),
                              ),
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
                const SizedBox(height: AppTokens.space3),
                _buildLegend(context),
              ],
            ),
          );
        }

        return Row(
          children: [
            Expanded(
              flex: 3,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.center,
                  maxY: data.fold<double>(
                    0,
                    (sum, item) => sum + item.count.toDouble(),
                  ),
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        if (rodIndex < data.length) {
                          final item = data[rodIndex];
                          return BarTooltipItem(
                            '${_statusLabel(item)}: ${item.count}',
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
                          toY: data.fold<double>(
                            0,
                            (sum, item) => sum + item.count.toDouble(),
                          ),
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
            const SizedBox(width: AppTokens.space4),
            Expanded(flex: 2, child: _buildLegend(context)),
          ],
        );
      },
    );
  }

  List<BarChartRodStackItem> _getStackItems() {
    final stackItems = <BarChartRodStackItem>[];
    double currentY = 0;

    for (int i = 0; i < data.length; i++) {
      final item = data[i];
      final color = _getStatusColor(item.key);
      stackItems.add(
        BarChartRodStackItem(currentY, currentY + item.count.toDouble(), color),
      );
      currentY += item.count.toDouble();
    }

    return stackItems;
  }

  Widget _buildLegend(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: data.map((item) {
        final color = _getStatusColor(item.key);
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${_statusLabel(item)} (${item.count})',
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

  Color _getStatusColor(String status) => AppColorScheme.statusColorFor(status);

  String _statusLabel(CategoryCount item) =>
      item.label ?? _formatStatusName(item.key);

  String _formatStatusName(String status) {
    return status
        .split('_')
        .map(
          (word) =>
              word.isNotEmpty ? word[0].toUpperCase() + word.substring(1) : '',
        )
        .join(' ');
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.stacked_bar_chart,
            size: 48,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'No data available',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
