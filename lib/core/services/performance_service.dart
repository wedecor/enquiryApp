import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../logging/safe_log.dart';

/// Service for monitoring and tracking app performance metrics
class PerformanceService {
  static final PerformanceService _instance = PerformanceService._internal();
  factory PerformanceService() => _instance;
  PerformanceService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Performance tracking
  final Map<String, DateTime> _operationStartTimes = {};
  final Map<String, List<Duration>> _operationDurations = {};
  final Map<String, int> _operationCounts = {};
  final Map<String, int> _operationErrors = {};

  // Performance thresholds (in milliseconds)
  static const int _slowOperationThreshold = 2000; // 2 seconds
  static const int _verySlowOperationThreshold = 5000; // 5 seconds

  /// Start tracking an operation
  void startOperation(String operationName) {
    _operationStartTimes[operationName] = DateTime.now();
    _operationCounts[operationName] = (_operationCounts[operationName] ?? 0) + 1;
    
    safeLog('performance_operation_started', {
      'operation': operationName,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// End tracking an operation and record metrics
  void endOperation(String operationName, {bool isError = false}) {
    final startTime = _operationStartTimes.remove(operationName);
    if (startTime == null) {
      safeLog('performance_operation_not_found', {
        'operation': operationName,
        'warning': 'Operation was not started',
      });
      return;
    }

    final duration = DateTime.now().difference(startTime);
    
    // Record duration
    _operationDurations[operationName] ??= [];
    _operationDurations[operationName]!.add(duration);
    
    // Keep only last 100 measurements to prevent memory issues
    if (_operationDurations[operationName]!.length > 100) {
      _operationDurations[operationName]!.removeAt(0);
    }

    // Record error if applicable
    if (isError) {
      _operationErrors[operationName] = (_operationErrors[operationName] ?? 0) + 1;
    }

    // Log performance metrics
    final metrics = {
      'operation': operationName,
      'duration_ms': duration.inMilliseconds,
      'is_slow': duration.inMilliseconds > _slowOperationThreshold,
      'is_very_slow': duration.inMilliseconds > _verySlowOperationThreshold,
      'is_error': isError,
      'timestamp': DateTime.now().toIso8601String(),
    };

    safeLog('performance_operation_completed', metrics);

    // Log slow operations
    if (duration.inMilliseconds > _slowOperationThreshold) {
      safeLog('performance_slow_operation', {
        'operation': operationName,
        'duration_ms': duration.inMilliseconds,
        'threshold_ms': _slowOperationThreshold,
        'severity': duration.inMilliseconds > _verySlowOperationThreshold ? 'critical' : 'warning',
      });
    }

    // Send to analytics if in debug mode or if operation is very slow
    if (kDebugMode || duration.inMilliseconds > _verySlowOperationThreshold) {
      _sendToAnalytics(operationName, duration, isError);
    }
  }

  /// Track network request performance
  void trackNetworkRequest(String endpoint, Duration duration, {bool isError = false}) {
    final operationName = 'network_$endpoint';
    
    _operationDurations[operationName] ??= [];
    _operationDurations[operationName]!.add(duration);
    
    if (_operationDurations[operationName]!.length > 100) {
      _operationDurations[operationName]!.removeAt(0);
    }

    if (isError) {
      _operationErrors[operationName] = (_operationErrors[operationName] ?? 0) + 1;
    }

    _operationCounts[operationName] = (_operationCounts[operationName] ?? 0) + 1;

    safeLog('performance_network_request', {
      'endpoint': endpoint,
      'duration_ms': duration.inMilliseconds,
      'is_error': isError,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Track Firestore operation performance
  void trackFirestoreOperation(String operation, String collection, Duration duration, {bool isError = false}) {
    final operationName = 'firestore_${operation}_$collection';
    
    _operationDurations[operationName] ??= [];
    _operationDurations[operationName]!.add(duration);
    
    if (_operationDurations[operationName]!.length > 100) {
      _operationDurations[operationName]!.removeAt(0);
    }

    if (isError) {
      _operationErrors[operationName] = (_operationErrors[operationName] ?? 0) + 1;
    }

    _operationCounts[operationName] = (_operationCounts[operationName] ?? 0) + 1;

    safeLog('performance_firestore_operation', {
      'operation': operation,
      'collection': collection,
      'duration_ms': duration.inMilliseconds,
      'is_error': isError,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Get performance statistics for an operation
  Map<String, dynamic> getOperationStats(String operationName) {
    final durations = _operationDurations[operationName] ?? [];
    final count = _operationCounts[operationName] ?? 0;
    final errors = _operationErrors[operationName] ?? 0;

    if (durations.isEmpty) {
      return {
        'operation': operationName,
        'count': count,
        'errors': errors,
        'error_rate': count > 0 ? errors / count : 0.0,
        'has_data': false,
      };
    }

    // Calculate statistics
    final sortedDurations = List<Duration>.from(durations)..sort();
    final totalMs = durations.fold<int>(0, (sum, duration) => sum + duration.inMilliseconds);
    
    return {
      'operation': operationName,
      'count': count,
      'errors': errors,
      'error_rate': count > 0 ? errors / count : 0.0,
      'avg_duration_ms': totalMs / durations.length,
      'min_duration_ms': sortedDurations.first.inMilliseconds,
      'max_duration_ms': sortedDurations.last.inMilliseconds,
      'median_duration_ms': sortedDurations[durations.length ~/ 2].inMilliseconds,
      'p95_duration_ms': sortedDurations[(durations.length * 0.95).floor()].inMilliseconds,
      'slow_operations': durations.where((d) => d.inMilliseconds > _slowOperationThreshold).length,
      'very_slow_operations': durations.where((d) => d.inMilliseconds > _verySlowOperationThreshold).length,
      'has_data': true,
    };
  }

  /// Get all performance statistics
  Map<String, Map<String, dynamic>> getAllStats() {
    final allStats = <String, Map<String, dynamic>>{};
    
    for (final operation in _operationDurations.keys) {
      allStats[operation] = getOperationStats(operation);
    }
    
    return allStats;
  }

  /// Get performance summary
  Map<String, dynamic> getPerformanceSummary() {
    final allStats = getAllStats();
    final operationsWithData = allStats.values.where((stats) => stats['has_data'] == true).toList();
    
    if (operationsWithData.isEmpty) {
      return {
        'total_operations': _operationCounts.values.fold<int>(0, (sum, count) => sum + count),
        'total_errors': _operationErrors.values.fold<int>(0, (sum, errors) => sum + errors),
        'has_data': false,
      };
    }

    final totalOperations = operationsWithData.fold<int>(0, (sum, stats) => sum + (stats['count'] as int));
    final totalErrors = operationsWithData.fold<int>(0, (sum, stats) => sum + (stats['errors'] as int));
    final avgDuration = operationsWithData.fold<double>(0, (sum, stats) => sum + (stats['avg_duration_ms'] as double)) / operationsWithData.length;
    final slowOperations = operationsWithData.fold<int>(0, (sum, stats) => sum + (stats['slow_operations'] as int));
    final verySlowOperations = operationsWithData.fold<int>(0, (sum, stats) => sum + (stats['very_slow_operations'] as int));

    // Find slowest operations
    final slowestOperations = operationsWithData
        .where((stats) => stats['has_data'] == true)
        .toList()
      ..sort((a, b) => (b['avg_duration_ms'] as double).compareTo(a['avg_duration_ms'] as double));

    return {
      'total_operations': totalOperations,
      'total_errors': totalErrors,
      'error_rate': totalOperations > 0 ? totalErrors / totalOperations : 0.0,
      'avg_duration_ms': avgDuration,
      'slow_operations': slowOperations,
      'very_slow_operations': verySlowOperations,
      'slowest_operations': slowestOperations.take(5).map((stats) => {
        'operation': stats['operation'],
        'avg_duration_ms': stats['avg_duration_ms'],
        'count': stats['count'],
      }).toList(),
      'has_data': true,
    };
  }

  /// Clear performance data
  void clearData() {
    _operationStartTimes.clear();
    _operationDurations.clear();
    _operationCounts.clear();
    _operationErrors.clear();
    
    safeLog('performance_data_cleared', {
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Send performance data to analytics
  Future<void> _sendToAnalytics(String operation, Duration duration, bool isError) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      await _firestore.collection('performance_analytics').add({
        'operation': operation,
        'duration_ms': duration.inMilliseconds,
        'is_error': isError,
        'user_id': currentUser.uid,
        'platform': Platform.isAndroid ? 'android' : Platform.isIOS ? 'ios' : 'unknown',
        'timestamp': FieldValue.serverTimestamp(),
        'app_version': '1.0.1+10', // TODO: Get from package_info
        'is_debug': kDebugMode,
      });
    } catch (e) {
      safeLog('performance_analytics_error', {
        'error': e.toString(),
        'operation': operation,
      });
    }
  }

  /// Get memory usage information
  Map<String, dynamic> getMemoryInfo() {
    // Note: Flutter doesn't provide direct memory access
    // This is a placeholder for future implementation
    return {
      'available': false,
      'note': 'Memory monitoring not available in Flutter',
    };
  }

  /// Check if app performance is healthy
  bool isPerformanceHealthy() {
    final summary = getPerformanceSummary();
    
    if (!(summary['has_data'] as bool)) return true;
    
    final errorRate = summary['error_rate'] as double;
    final avgDuration = summary['avg_duration_ms'] as double;
    final verySlowOperations = summary['very_slow_operations'] as int;
    
    // Consider performance unhealthy if:
    // - Error rate is too high (>10%)
    // - Average duration is too slow (>1000ms)
    // - Too many very slow operations (>5%)
    return errorRate < 0.1 && avgDuration < 1000 && verySlowOperations < 5;
  }

  /// Get performance health status
  Map<String, dynamic> getPerformanceHealth() {
    final summary = getPerformanceSummary();
    final isHealthy = isPerformanceHealthy();
    
    final issues = <String>[];
    
    if (summary['has_data'] as bool) {
      final errorRate = summary['error_rate'] as double;
      final avgDuration = summary['avg_duration_ms'] as double;
      final verySlowOperations = summary['very_slow_operations'] as int;
      
      if (errorRate > 0.1) {
        issues.add('High error rate: ${(errorRate * 100).toStringAsFixed(1)}%');
      }
      
      if (avgDuration > 1000) {
        issues.add('Slow average response time: ${avgDuration.toStringAsFixed(0)}ms');
      }
      
      if (verySlowOperations > 5) {
        issues.add('Too many very slow operations: $verySlowOperations');
      }
    }
    
    return {
      'is_healthy': isHealthy,
      'issues': issues,
      'summary': summary,
    };
  }
}
