import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';

class ConnectivityManager extends ChangeNotifier {
  static final ConnectivityManager _instance = ConnectivityManager._internal();
  factory ConnectivityManager() => _instance;
  ConnectivityManager._internal();

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;

  bool _isOnline = true;
  bool _hasBeenOnline = false;
  DateTime? _lastOnlineTime;
  DateTime? _lastOfflineTime;

  bool get isOnline => _isOnline;
  bool get isOffline => !_isOnline;
  bool get hasBeenOnline => _hasBeenOnline;
  DateTime? get lastOnlineTime => _lastOnlineTime;
  DateTime? get lastOfflineTime => _lastOfflineTime;

  // Callbacks for connectivity changes
  Function()? onConnected;
  Function()? onDisconnected;

  /// Initialize connectivity monitoring
  Future<void> initialize() async {
    try {
      // Check initial connectivity
      final result = await _connectivity.checkConnectivity();
      _updateConnectivityStatus(result);

      // Listen for connectivity changes
      _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
        _updateConnectivityStatus,
        onError: (error) {
          debugPrint('ConnectivityManager: Error listening to connectivity changes: $error');
        },
      );

      debugPrint('ConnectivityManager: Initialized. Initial status: ${_isOnline ? 'Online' : 'Offline'}');
    } catch (e) {
      debugPrint('ConnectivityManager: Failed to initialize: $e');
      // Assume online if we can't check connectivity
      _isOnline = true;
      _hasBeenOnline = true;
    }
  }

  /// Update connectivity status based on connectivity result
  void _updateConnectivityStatus(ConnectivityResult result) {
    final wasOnline = _isOnline;
    _isOnline = _isConnected(result);

    // Update timestamps
    if (_isOnline && !wasOnline) {
      // Just came online
      _lastOnlineTime = DateTime.now();
      _hasBeenOnline = true;
      debugPrint('ConnectivityManager: Device came online');
      onConnected?.call();
    } else if (!_isOnline && wasOnline) {
      // Just went offline
      _lastOfflineTime = DateTime.now();
      debugPrint('ConnectivityManager: Device went offline');
      onDisconnected?.call();
    }

    if (wasOnline != _isOnline) {
      notifyListeners();
    }
  }

  /// Check if the connectivity result indicates an active connection
  bool _isConnected(ConnectivityResult result) {
    switch (result) {
      case ConnectivityResult.wifi:
      case ConnectivityResult.mobile:
      case ConnectivityResult.ethernet:
        return true;
      case ConnectivityResult.none:
      case ConnectivityResult.bluetooth:
      case ConnectivityResult.vpn:
      case ConnectivityResult.other:
        return false;
    }
  }

  /// Get a human-readable connectivity status
  String get connectivityStatus {
    if (_isOnline) {
      return 'Online';
    } else {
      if (_lastOfflineTime != null) {
        final duration = DateTime.now().difference(_lastOfflineTime!);
        return 'Offline for ${_formatDuration(duration)}';
      } else {
        return 'Offline';
      }
    }
  }

  /// Get detailed connectivity information
  Future<Map<String, dynamic>> getConnectivityInfo() async {
    try {
      final result = await _connectivity.checkConnectivity();
      return {
        'isOnline': _isOnline,
        'connectionType': result.toString(),
        'hasBeenOnline': _hasBeenOnline,
        'lastOnlineTime': _lastOnlineTime?.toIso8601String(),
        'lastOfflineTime': _lastOfflineTime?.toIso8601String(),
        'status': connectivityStatus,
      };
    } catch (e) {
      debugPrint('ConnectivityManager: Error getting connectivity info: $e');
      return {
        'isOnline': _isOnline,
        'connectionType': 'unknown',
        'hasBeenOnline': _hasBeenOnline,
        'error': e.toString(),
      };
    }
  }

  /// Manually refresh connectivity status
  Future<void> refreshConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      _updateConnectivityStatus(result);
      debugPrint('ConnectivityManager: Manually refreshed connectivity status: ${_isOnline ? 'Online' : 'Offline'}');
    } catch (e) {
      debugPrint('ConnectivityManager: Error refreshing connectivity: $e');
    }
  }

  /// Check if device has been offline for a significant amount of time
  bool get hasBeenOfflineLong {
    if (_isOnline || _lastOfflineTime == null) return false;
    final duration = DateTime.now().difference(_lastOfflineTime!);
    return duration.inMinutes > 5; // Consider 5+ minutes as "long"
  }

  /// Get time since last connectivity change
  Duration? get timeSinceLastChange {
    final lastChange = _isOnline ? _lastOnlineTime : _lastOfflineTime;
    if (lastChange == null) return null;
    return DateTime.now().difference(lastChange);
  }

  /// Format duration for display
  String _formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays}d ${duration.inHours % 24}h';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m';
    } else {
      return '${duration.inSeconds}s';
    }
  }

  /// Stream of connectivity changes
  Stream<bool> get onConnectivityChanged =>
      _connectivity.onConnectivityChanged.map(_isConnected);

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }
}