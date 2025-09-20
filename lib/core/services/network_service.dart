import 'dart:async';
import 'dart:math';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

import '../logging/logger.dart';

/// Service for handling network connectivity and offline behavior
class NetworkService {
  static NetworkService? _instance;
  static NetworkService get instance => _instance ??= NetworkService._();
  NetworkService._();

  final Connectivity _connectivity = Connectivity();
  final List<VoidCallback> _onlineCallbacks = [];
  final List<VoidCallback> _offlineCallbacks = [];

  bool _isOnline = true;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  /// Initialize network monitoring
  Future<void> initialize() async {
    // Check initial connectivity
    final result = await _connectivity.checkConnectivity();
    _isOnline = !result.contains(ConnectivityResult.none);

    // Listen for connectivity changes
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((result) {
      final wasOnline = _isOnline;
      _isOnline = !result.contains(ConnectivityResult.none);

      if (wasOnline != _isOnline) {
        Logger.info('Network status changed: ${_isOnline ? "Online" : "Offline"}');

        if (_isOnline) {
          for (final callback in _onlineCallbacks) {
            callback();
          }
        } else {
          for (final callback in _offlineCallbacks) {
            callback();
          }
        }
      }
    });
  }

  /// Check if device is currently online
  bool get isOnline => _isOnline;

  /// Check if device is currently offline
  bool get isOffline => !_isOnline;

  /// Register callback for when device comes online
  void onOnline(VoidCallback callback) {
    _onlineCallbacks.add(callback);
  }

  /// Register callback for when device goes offline
  void onOffline(VoidCallback callback) {
    _offlineCallbacks.add(callback);
  }

  /// Remove callback
  void removeOnlineCallback(VoidCallback callback) {
    _onlineCallbacks.remove(callback);
  }

  /// Remove callback
  void removeOfflineCallback(VoidCallback callback) {
    _offlineCallbacks.remove(callback);
  }

  /// Dispose resources
  void dispose() {
    _connectivitySubscription?.cancel();
    _onlineCallbacks.clear();
    _offlineCallbacks.clear();
  }
}

/// Queue for handling operations when offline
class NetworkAwareQueue {
  final List<QueuedOperation> _queue = [];
  bool _isProcessing = false;

  /// Add operation to queue
  void enqueue(QueuedOperation operation) {
    _queue.add(operation);
    Logger.info('Operation queued: ${operation.description}');

    // Try to process immediately if online
    if (NetworkService.instance.isOnline) {
      _processQueue();
    }
  }

  /// Process queued operations with retry logic
  Future<void> _processQueue() async {
    if (_isProcessing || _queue.isEmpty) return;

    _isProcessing = true;

    while (_queue.isNotEmpty && NetworkService.instance.isOnline) {
      final operation = _queue.removeAt(0);

      try {
        await _executeWithRetry(operation);
        Logger.info('Operation completed: ${operation.description}');
      } catch (e) {
        Logger.error('Operation failed: ${operation.description}', error: e);

        // Re-queue if retries remaining
        if (operation.retryCount > 0) {
          operation.retryCount--;
          _queue.insert(0, operation);

          // Wait before retry with exponential backoff
          final delay = Duration(seconds: pow(2, 3 - operation.retryCount).toInt());
          await Future.delayed(delay);
        }
      }
    }

    _isProcessing = false;
  }

  /// Execute operation with retry logic
  Future<void> _executeWithRetry(QueuedOperation operation) async {
    const maxRetries = 3;

    for (int attempt = 0; attempt < maxRetries; attempt++) {
      try {
        await operation.execute();
        return;
      } catch (e) {
        if (attempt == maxRetries - 1) rethrow;

        // Exponential backoff
        final delay = Duration(milliseconds: 500 * pow(2, attempt).toInt());
        await Future.delayed(delay);
      }
    }
  }

  /// Initialize queue processing when network comes online
  void initialize() {
    NetworkService.instance.onOnline(() {
      Logger.info('Network online - processing queued operations');
      _processQueue();
    });
  }

  /// Get number of queued operations
  int get queueLength => _queue.length;

  /// Clear all queued operations
  void clear() {
    _queue.clear();
    Logger.info('Operation queue cleared');
  }
}

/// Represents a queued operation that can be retried
class QueuedOperation {
  final String description;
  final Future<void> Function() execute;
  int retryCount;

  QueuedOperation({required this.description, required this.execute, this.retryCount = 3});
}
