import 'package:flutter/material.dart';

import 'dashboard_kpi_grid.dart';

/// Responsive KPI layout for the dashboard — delegates to [DashboardKpiGrid].
class DashboardKpiRow extends StatelessWidget {
  const DashboardKpiRow({super.key, required this.items});

  final List<Widget> items;

  @override
  Widget build(BuildContext context) => DashboardKpiGrid(items: items);
}
