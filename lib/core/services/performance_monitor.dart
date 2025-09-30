import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'performance_service.dart';

/// A mixin that provides performance monitoring capabilities to widgets
mixin PerformanceMonitor {
  final PerformanceService _performanceService = PerformanceService();

  /// Monitor a function execution
  Future<T> monitorOperation<T>(
    String operationName,
    Future<T> Function() operation, {
    bool trackErrors = true,
  }) async {
    _performanceService.startOperation(operationName);

    try {
      final result = await operation();
      _performanceService.endOperation(operationName, isError: false);
      return result;
    } catch (e) {
      if (trackErrors) {
        _performanceService.endOperation(operationName, isError: true);
      }
      rethrow;
    }
  }

  /// Monitor a synchronous function execution
  T monitorSyncOperation<T>(
    String operationName,
    T Function() operation, {
    bool trackErrors = true,
  }) {
    _performanceService.startOperation(operationName);

    try {
      final result = operation();
      _performanceService.endOperation(operationName, isError: false);
      return result;
    } catch (e) {
      if (trackErrors) {
        _performanceService.endOperation(operationName, isError: true);
      }
      rethrow;
    }
  }

  /// Monitor network requests
  void monitorNetworkRequest(String endpoint, Duration duration, {bool isError = false}) {
    _performanceService.trackNetworkRequest(endpoint, duration, isError: isError);
  }

  /// Monitor Firestore operations
  void monitorFirestoreOperation(
    String operation,
    String collection,
    Duration duration, {
    bool isError = false,
  }) {
    _performanceService.trackFirestoreOperation(operation, collection, duration, isError: isError);
  }

  /// Get performance statistics
  Map<String, dynamic> getPerformanceStats(String operationName) {
    return _performanceService.getOperationStats(operationName);
  }

  /// Get all performance statistics
  Map<String, Map<String, dynamic>> getAllPerformanceStats() {
    return _performanceService.getAllStats();
  }

  /// Get performance summary
  Map<String, dynamic> getPerformanceSummary() {
    return _performanceService.getPerformanceSummary();
  }

  /// Check if performance is healthy
  bool isPerformanceHealthy() {
    return _performanceService.isPerformanceHealthy();
  }

  /// Get performance health status
  Map<String, dynamic> getPerformanceHealth() {
    return _performanceService.getPerformanceHealth();
  }
}

/// A utility class for performance monitoring
class PerformanceTracker {
  static final PerformanceService _service = PerformanceService();

  /// Track a function execution with automatic timing
  static Future<T> track<T>(
    String operationName,
    Future<T> Function() operation, {
    bool trackErrors = true,
  }) async {
    _service.startOperation(operationName);

    try {
      final result = await operation();
      _service.endOperation(operationName, isError: false);
      return result;
    } catch (e) {
      if (trackErrors) {
        _service.endOperation(operationName, isError: true);
      }
      rethrow;
    }
  }

  /// Track a synchronous function execution
  static T trackSync<T>(String operationName, T Function() operation, {bool trackErrors = true}) {
    _service.startOperation(operationName);

    try {
      final result = operation();
      _service.endOperation(operationName, isError: false);
      return result;
    } catch (e) {
      if (trackErrors) {
        _service.endOperation(operationName, isError: true);
      }
      rethrow;
    }
  }

  /// Track network request performance
  static void trackNetwork(String endpoint, Duration duration, {bool isError = false}) {
    _service.trackNetworkRequest(endpoint, duration, isError: isError);
  }

  /// Track Firestore operation performance
  static void trackFirestore(
    String operation,
    String collection,
    Duration duration, {
    bool isError = false,
  }) {
    _service.trackFirestoreOperation(operation, collection, duration, isError: isError);
  }

  /// Get performance statistics for an operation
  static Map<String, dynamic> getStats(String operationName) {
    return _service.getOperationStats(operationName);
  }

  /// Get all performance statistics
  static Map<String, Map<String, dynamic>> getAllStats() {
    return _service.getAllStats();
  }

  /// Get performance summary
  static Map<String, dynamic> getSummary() {
    return _service.getPerformanceSummary();
  }

  /// Check if performance is healthy
  static bool isHealthy() {
    return _service.isPerformanceHealthy();
  }

  /// Get performance health status
  static Map<String, dynamic> getHealth() {
    return _service.getPerformanceHealth();
  }

  /// Clear performance data
  static void clearData() {
    _service.clearData();
  }
}

/// A widget that monitors its build performance
mixin BuildPerformanceMonitor {
  final PerformanceService _performanceService = PerformanceService();

  /// Monitor widget build performance
  Widget monitorBuild(String widgetName, Widget Function() buildWidget) {
    return PerformanceTracker.trackSync('build_$widgetName', () => buildWidget());
  }
}

/// Performance monitoring configuration
class PerformanceConfig {
  static bool enabled = kDebugMode; // Enable by default in debug mode
  static bool trackNetwork = true;
  static bool trackFirestore = true;
  static bool trackBuilds = false; // Disable by default as it can be noisy
  static bool trackUI = false; // Disable by default as it can be noisy

  static void configure({
    bool? enabled,
    bool? trackNetwork,
    bool? trackFirestore,
    bool? trackBuilds,
    bool? trackUI,
  }) {
    PerformanceConfig.enabled = enabled ?? PerformanceConfig.enabled;
    PerformanceConfig.trackNetwork = trackNetwork ?? PerformanceConfig.trackNetwork;
    PerformanceConfig.trackFirestore = trackFirestore ?? PerformanceConfig.trackFirestore;
    PerformanceConfig.trackBuilds = trackBuilds ?? PerformanceConfig.trackBuilds;
    PerformanceConfig.trackUI = trackUI ?? PerformanceConfig.trackUI;
  }
}
