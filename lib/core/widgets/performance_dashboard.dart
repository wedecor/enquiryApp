import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/performance_monitor.dart';

/// A dashboard widget for monitoring app performance metrics
class PerformanceDashboard extends ConsumerStatefulWidget {
  const PerformanceDashboard({super.key});

  @override
  ConsumerState<PerformanceDashboard> createState() => _PerformanceDashboardState();
}

class _PerformanceDashboardState extends ConsumerState<PerformanceDashboard> {
  Map<String, dynamic> _performanceSummary = {};
  Map<String, Map<String, dynamic>> _allStats = {};
  Map<String, dynamic> _healthStatus = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPerformanceData();
  }

  Future<void> _loadPerformanceData() async {
    setState(() => _isLoading = true);
    
    try {
      final summary = PerformanceTracker.getSummary();
      final allStats = PerformanceTracker.getAllStats();
      final health = PerformanceTracker.getHealth();
      
      setState(() {
        _performanceSummary = summary;
        _allStats = allStats;
        _healthStatus = health;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Performance Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPerformanceData,
          ),
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: () {
              PerformanceTracker.clearData();
              _loadPerformanceData();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadPerformanceData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHealthStatusCard(),
                    const SizedBox(height: 16),
                    _buildSummaryCard(),
                    const SizedBox(height: 16),
                    _buildOperationsList(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHealthStatusCard() {
    final isHealthy = _healthStatus['is_healthy'] as bool? ?? false;
    final issues = _healthStatus['issues'] as List<dynamic>? ?? [];
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isHealthy ? Icons.check_circle : Icons.warning,
                  color: isHealthy ? Colors.green : Colors.orange,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Performance Health',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              isHealthy ? 'All systems healthy' : 'Performance issues detected',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: isHealthy ? Colors.green : Colors.orange,
              ),
            ),
            if (issues.isNotEmpty) ...[
              const SizedBox(height: 8),
              ...issues.map((issue) => Padding(
                padding: const EdgeInsets.only(left: 8, top: 4),
                child: Text(
                  '• $issue',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.red,
                  ),
                ),
              )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    final hasData = _performanceSummary['has_data'] as bool? ?? false;
    
    if (!hasData) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'No performance data available yet. Start using the app to see metrics.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );
    }

    final totalOperations = _performanceSummary['total_operations'] as int? ?? 0;
    final totalErrors = _performanceSummary['total_errors'] as int? ?? 0;
    final errorRate = _performanceSummary['error_rate'] as double? ?? 0.0;
    final avgDuration = _performanceSummary['avg_duration_ms'] as double? ?? 0.0;
    final slowOperations = _performanceSummary['slow_operations'] as int? ?? 0;
    final verySlowOperations = _performanceSummary['very_slow_operations'] as int? ?? 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Performance Summary',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildMetricTile(
                    'Total Operations',
                    totalOperations.toString(),
                    Icons.functions,
                  ),
                ),
                Expanded(
                  child: _buildMetricTile(
                    'Error Rate',
                    '${(errorRate * 100).toStringAsFixed(1)}%',
                    Icons.error,
                    color: errorRate > 0.1 ? Colors.red : Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildMetricTile(
                    'Avg Duration',
                    '${avgDuration.toStringAsFixed(0)}ms',
                    Icons.timer,
                    color: avgDuration > 1000 ? Colors.orange : Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildMetricTile(
                    'Slow Operations',
                    '$slowOperations',
                    Icons.speed,
                    color: slowOperations > 5 ? Colors.red : Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricTile(String label, String value, IconData icon, {Color? color}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color ?? Colors.blue),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildOperationsList() {
    if (_allStats.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'No operation data available.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Operation Details',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ..._allStats.entries.map((entry) => _buildOperationTile(entry.key, entry.value)),
          ],
        ),
      ),
    );
  }

  Widget _buildOperationTile(String operationName, Map<String, dynamic> stats) {
    final hasData = stats['has_data'] as bool? ?? false;
    
    if (!hasData) {
      return ListTile(
        title: Text(operationName),
        subtitle: const Text('No data available'),
        trailing: Text('${stats['count']} calls'),
      );
    }

    final count = stats['count'] as int? ?? 0;
    final errors = stats['errors'] as int? ?? 0;
    final avgDuration = stats['avg_duration_ms'] as double? ?? 0.0;
    final errorRate = stats['error_rate'] as double? ?? 0.0;
    final slowOps = stats['slow_operations'] as int? ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(operationName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Calls: $count, Errors: $errors'),
            Text('Avg: ${avgDuration.toStringAsFixed(0)}ms'),
            if (slowOps > 0) Text('Slow ops: $slowOps', style: const TextStyle(color: Colors.orange)),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${(errorRate * 100).toStringAsFixed(1)}%',
              style: TextStyle(
                color: errorRate > 0.1 ? Colors.red : Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'error rate',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }
}

/// A floating action button that shows performance metrics
class PerformanceFAB extends ConsumerWidget {
  const PerformanceFAB({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FloatingActionButton(
      onPressed: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const PerformanceDashboard(),
          ),
        );
      },
      child: const Icon(Icons.analytics),
      tooltip: 'Performance Dashboard',
    );
  }
}
