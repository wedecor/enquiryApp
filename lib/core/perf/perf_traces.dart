import 'dart:async';

import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/foundation.dart';

import '../app_config.dart';
import '../logging/logger.dart';

/// Performance tracing utility for monitoring app performance
/// Only active when AppConfig.enablePerformance is true
class PerfTraces {
  static final Map<String, Trace> _activeTraces = {};
  static final Map<String, DateTime> _startTimes = {};

  // Performance budgets (in milliseconds)
  static const int _appStartBudget = 2000;
  static const int _enquiryListLoadBudget = 1000;
  static const int _loginBudget = 3000;
  static const int _imageUploadBudget = 5000;

  /// Start a performance trace
  static Future<void> startTrace(String traceName) async {
    if (!AppConfig.enablePerformance || !kReleaseMode) {
      Logger.debug('Performance trace started (debug): $traceName');
      _startTimes[traceName] = DateTime.now();
      return;
    }

    try {
      final trace = FirebasePerformance.instance.newTrace(traceName);
      await trace.start();
      _activeTraces[traceName] = trace;
      _startTimes[traceName] = DateTime.now();
      Logger.info('Performance trace started: $traceName');
    } catch (e) {
      Logger.error('Failed to start trace: $traceName', error: e);
    }
  }

  /// Stop a performance trace and check against budget
  static Future<void> stopTrace(String traceName, {Map<String, String>? attributes}) async {
    final startTime = _startTimes[traceName];
    if (startTime == null) {
      Logger.warn('Attempted to stop non-existent trace: $traceName');
      return;
    }

    final duration = DateTime.now().difference(startTime);
    final durationMs = duration.inMilliseconds;

    // Check performance budget
    _checkPerformanceBudget(traceName, durationMs);

    if (!AppConfig.enablePerformance || !kReleaseMode) {
      Logger.debug('Performance trace stopped (debug): $traceName - ${durationMs}ms');
      _startTimes.remove(traceName);
      return;
    }

    try {
      final trace = _activeTraces[traceName];
      if (trace != null) {
        // Add custom attributes
        if (attributes != null) {
          for (final entry in attributes.entries) {
            trace.putAttribute(entry.key, entry.value);
          }
        }

        trace.stop();
        _activeTraces.remove(traceName);
        Logger.info('Performance trace stopped: $traceName - ${durationMs}ms');
      }
    } catch (e) {
      Logger.error('Failed to stop trace: $traceName', error: e);
    }

    _startTimes.remove(traceName);
  }

  /// Check if duration exceeds performance budget
  static void _checkPerformanceBudget(String traceName, int durationMs) {
    int? budget;

    switch (traceName) {
      case 'app_start':
        budget = _appStartBudget;
        break;
      case 'enquiry_list_load':
        budget = _enquiryListLoadBudget;
        break;
      case 'user_login':
        budget = _loginBudget;
        break;
      case 'image_upload':
        budget = _imageUploadBudget;
        break;
    }

    if (budget != null && durationMs > budget) {
      Logger.warn(
        'Performance budget exceeded: $traceName took ${durationMs}ms (budget: ${budget}ms)',
        tag: 'Performance',
      );
    } else if (budget != null) {
      Logger.info(
        'Performance budget met: $traceName took ${durationMs}ms (budget: ${budget}ms)',
        tag: 'Performance',
      );
    }
  }

  /// Add custom metric to active trace (logged for debug)
  static void putMetric(String traceName, String metricName, int value) {
    // Note: putMetric is not available in current Firebase Performance API
    // Log the metric for debugging purposes
    Logger.info('Performance metric: $traceName.$metricName = $value', tag: 'Performance');
  }

  /// Convenience method for timing a future operation
  static Future<T> timeOperation<T>(
    String traceName,
    Future<T> Function() operation, {
    Map<String, String>? attributes,
  }) async {
    await startTrace(traceName);
    try {
      final result = await operation();
      await stopTrace(traceName, attributes: attributes);
      return result;
    } catch (e) {
      await stopTrace(traceName, attributes: {...?attributes, 'error': 'true'});
      rethrow;
    }
  }

  /// App startup trace (call from main.dart)
  static Future<void> startAppStartTrace() async {
    await startTrace('app_start');
  }

  /// Complete app startup trace (call when first screen is ready)
  static Future<void> completeAppStartTrace() async {
    await stopTrace(
      'app_start',
      attributes: {'environment': AppConfig.env, 'platform': defaultTargetPlatform.name},
    );
  }

  /// Enquiry list loading trace
  static Future<void> startEnquiryListTrace() async {
    await startTrace('enquiry_list_load');
  }

  static Future<void> completeEnquiryListTrace({int? itemCount}) async {
    await stopTrace(
      'enquiry_list_load',
      attributes: {'item_count': itemCount?.toString() ?? 'unknown'},
    );
  }

  /// User login trace
  static Future<void> startLoginTrace() async {
    await startTrace('user_login');
  }

  static Future<void> completeLoginTrace({bool? success}) async {
    await stopTrace('user_login', attributes: {'success': success?.toString() ?? 'unknown'});
  }

  /// Image upload trace
  static Future<void> startImageUploadTrace() async {
    await startTrace('image_upload');
  }

  static Future<void> completeImageUploadTrace({int? fileSizeBytes}) async {
    await stopTrace(
      'image_upload',
      attributes: {'file_size_bytes': fileSizeBytes?.toString() ?? 'unknown'},
    );
  }
}
