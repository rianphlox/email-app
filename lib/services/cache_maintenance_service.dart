import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'advanced_email_cache_service.dart';

/// Background service for automatic cache maintenance and policy enforcement
/// Runs periodically to keep cache size under control and maintain performance
class CacheMaintenanceService {
  static final CacheMaintenanceService _instance = CacheMaintenanceService._internal();
  factory CacheMaintenanceService() => _instance;
  CacheMaintenanceService._internal();

  Timer? _maintenanceTimer;
  Timer? _adaptiveMaintenanceTimer;
  bool _isRunning = false;
  bool _isAdaptiveModeEnabled = true;
  Duration _maintenanceInterval = const Duration(hours: 6); // Default 6 hours
  final Map<String, DateTime> _lastMaintenanceByAccount = {};
  final Map<String, int> _cacheGrowthRates = {}; // MB per day
  int _deviceMemoryMB = 0;
  int _availableStorageGB = 0;

  /// Start background cache maintenance with adaptive scheduling
  Future<void> startMaintenance({
    Duration interval = const Duration(hours: 6),
    bool runImmediately = false,
    bool enableAdaptiveMode = true,
  }) async {
    if (_isRunning) {
      debugPrint('CacheMaintenanceService: Maintenance already running');
      return;
    }

    // Initialize device capabilities
    await _initializeDeviceInfo();

    _maintenanceInterval = interval;
    _isRunning = true;
    _isAdaptiveModeEnabled = enableAdaptiveMode;

    debugPrint('CacheMaintenanceService: Starting adaptive maintenance every ${interval.inHours} hours');
    debugPrint('CacheMaintenanceService: Device RAM: ${_deviceMemoryMB}MB, Storage: ${_availableStorageGB}GB');

    // Run immediately if requested
    if (runImmediately) {
      await _performMaintenanceForAllAccounts();
    }

    // Schedule periodic maintenance
    _maintenanceTimer = Timer.periodic(interval, (_) async {
      await _performMaintenanceForAllAccounts();
    });

    // Start adaptive maintenance if enabled
    if (_isAdaptiveModeEnabled) {
      _startAdaptiveMaintenance();
    }
  }

  /// Stop background cache maintenance
  Future<void> stopMaintenance() async {
    if (!_isRunning) return;

    _maintenanceTimer?.cancel();
    _adaptiveMaintenanceTimer?.cancel();
    _maintenanceTimer = null;
    _adaptiveMaintenanceTimer = null;
    _isRunning = false;

    debugPrint('CacheMaintenanceService: Stopped all maintenance timers');
  }

  /// Initialize device capabilities for adaptive maintenance
  Future<void> _initializeDeviceInfo() async {
    try {
      final deviceInfo = DeviceInfoPlugin();

      if (Platform.isAndroid) {
        // Estimate RAM based on Android device model (simplified)
        // Android devices typically range from 2-8GB
        _deviceMemoryMB = 4096; // Default 4GB for Android
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        // iOS devices typically have consistent RAM by model
        _deviceMemoryMB = _estimateIOSMemory(iosInfo.model);
      } else {
        _deviceMemoryMB = 4096; // Default 4GB for other platforms
      }

      // Get available storage (simplified estimation)
      // This is a simplified approach - in production you'd use platform channels
      _availableStorageGB = 32; // Default assumption

    } catch (e) {
      debugPrint('CacheMaintenanceService: Error initializing device info: $e');
      _deviceMemoryMB = 4096; // Safe defaults
      _availableStorageGB = 32;
    }
  }

  /// Estimate iOS device memory based on model
  int _estimateIOSMemory(String model) {
    if (model.contains('iPhone')) {
      if (model.contains('15') || model.contains('14')) return 6144; // 6GB
      if (model.contains('13') || model.contains('12')) return 4096; // 4GB
      return 3072; // 3GB for older models
    }
    if (model.contains('iPad')) {
      return 8192; // 8GB for iPads
    }
    return 4096; // Default
  }

  /// Start adaptive maintenance based on device capabilities and usage patterns
  void _startAdaptiveMaintenance() {
    // More frequent maintenance for low-memory devices or heavy cache usage
    final adaptiveInterval = _calculateAdaptiveInterval();

    _adaptiveMaintenanceTimer = Timer.periodic(adaptiveInterval, (_) async {
      await _performAdaptiveMaintenance();
    });

    debugPrint('CacheMaintenanceService: Started adaptive maintenance every ${adaptiveInterval.inHours} hours');
  }

  /// Calculate optimal maintenance interval based on device capabilities
  Duration _calculateAdaptiveInterval() {
    // Base interval on device memory and storage
    int intervalHours = 6; // Default

    if (_deviceMemoryMB < 3072) { // Low memory device
      intervalHours = 3; // More frequent cleanup
    } else if (_deviceMemoryMB < 6144) { // Medium memory
      intervalHours = 4;
    } else { // High memory device
      intervalHours = 8; // Less frequent cleanup
    }

    // Adjust based on available storage
    if (_availableStorageGB < 16) {
      intervalHours = (intervalHours * 0.7).round(); // More aggressive on low storage
    }

    return Duration(hours: intervalHours.clamp(2, 12)); // Between 2-12 hours
  }

  /// Perform adaptive maintenance based on current conditions
  Future<void> _performAdaptiveMaintenance() async {
    if (!_isRunning) return;

    try {
      final cacheService = AdvancedEmailCacheService();
      await cacheService.initialize();

      final accounts = await cacheService.getAccounts();

      for (final account in accounts) {
        if (!_isRunning) break;

        final stats = await cacheService.getCacheStats(account.id);
        final sizeMB = (stats['totalSizeBytes'] as int) / (1024 * 1024);

        // Track growth rate
        final lastMaintenance = _lastMaintenanceByAccount[account.id];
        if (lastMaintenance != null) {
          final daysSinceLastMaintenance = DateTime.now().difference(lastMaintenance).inDays;
          if (daysSinceLastMaintenance > 0) {
            final growthRate = sizeMB / daysSinceLastMaintenance;
            _cacheGrowthRates[account.id] = growthRate.round();
          }
        }

        // Determine if this account needs immediate attention
        final needsAggressiveCleanup = _shouldPerformAggressiveCleanup(account.id, sizeMB);

        if (needsAggressiveCleanup) {
          await _performOptimizedMaintenanceForAccount(account.id, cacheService, aggressive: true);
        } else {
          await _performLightMaintenance(account.id, cacheService);
        }

        _lastMaintenanceByAccount[account.id] = DateTime.now();
      }

    } catch (e) {
      debugPrint('CacheMaintenanceService: Adaptive maintenance error: $e');
    }
  }

  /// Determine if aggressive cleanup is needed
  bool _shouldPerformAggressiveCleanup(String accountId, double sizeMB) {
    // Consider device memory constraints
    final memoryPressureThreshold = _deviceMemoryMB < 4096 ? 200.0 : 400.0;

    if (sizeMB > memoryPressureThreshold) return true;

    // Consider growth rate
    final growthRate = _cacheGrowthRates[accountId] ?? 0;
    if (growthRate > 50) return true; // Growing more than 50MB per day

    // Consider storage pressure
    if (_availableStorageGB < 8 && sizeMB > 100) return true;

    return false;
  }

  /// Perform maintenance for all accounts
  Future<void> _performMaintenanceForAllAccounts() async {
    if (!_isRunning) return;

    try {
      debugPrint('CacheMaintenanceService: Starting maintenance cycle');

      final cacheService = AdvancedEmailCacheService();
      await cacheService.initialize();

      final accounts = await cacheService.getAccounts();

      for (final account in accounts) {
        if (!_isRunning) break; // Exit early if service was stopped

        await _performOptimizedMaintenanceForAccount(account.id, cacheService);
      }

      debugPrint('CacheMaintenanceService: Maintenance cycle complete');
    } catch (e) {
      debugPrint('CacheMaintenanceService: Maintenance cycle error: $e');
    }
  }

  /// Optimized maintenance for specific account with batch processing
  Future<void> _performOptimizedMaintenanceForAccount(
    String accountId,
    AdvancedEmailCacheService cacheService, {
    bool aggressive = false,
  }) async {
    try {
      debugPrint('CacheMaintenanceService: Performing ${aggressive ? 'aggressive' : 'standard'} maintenance for $accountId');

      // Get current cache stats
      final stats = await cacheService.getCacheStats(accountId);
      final sizeMB = (stats['totalSizeBytes'] as int) / (1024 * 1024);
      final emailCount = stats['emailCount'] as int;

      debugPrint('CacheMaintenanceService: Account $accountId - Size: ${sizeMB.toStringAsFixed(1)}MB, Emails: $emailCount');

      // Calculate dynamic thresholds based on device capabilities
      final memoryAwareMaxStorage = _calculateOptimalStorageLimit();
      final memoryAwareMaxEmails = _calculateOptimalEmailLimit();

      if (aggressive || sizeMB > memoryAwareMaxStorage) {
        // Aggressive batch cleanup with memory-aware limits
        await cacheService.performIntelligentCacheEviction(
          accountId: accountId,
          maxStorageMB: (memoryAwareMaxStorage * 0.7).round(), // Target 70% of optimal
          maxEmailsPerFolder: (memoryAwareMaxEmails * 0.7).round(),
          preserveImportantMessages: true,
          maxUnusedAge: Duration(days: _deviceMemoryMB < 4096 ? 14 : 30), // Shorter retention on low memory
        );
        debugPrint('CacheMaintenanceService: Performed aggressive cleanup for $accountId');
      } else if (sizeMB > memoryAwareMaxStorage * 0.6) {
        // Moderate cleanup with batch processing
        await cacheService.performBatchMaintenance(
          accountId: accountId,
          maxStorageMB: (memoryAwareMaxStorage * 0.8).round(),
          batchSize: 100, // Process 100 emails at a time
        );
        debugPrint('CacheMaintenanceService: Performed moderate batch cleanup for $accountId');
      } else {
        // Light maintenance with minimal impact
        await _performLightMaintenance(accountId, cacheService);
        debugPrint('CacheMaintenanceService: Performed light maintenance for $accountId');
      }

    } catch (e) {
      debugPrint('CacheMaintenanceService: Error in optimized maintenance for $accountId: $e');
    }
  }

  /// Light maintenance with minimal performance impact
  Future<void> _performLightMaintenance(
    String accountId,
    AdvancedEmailCacheService cacheService,
  ) async {
    // Only perform non-blocking operations
    await cacheService.performBackgroundMaintenance(
      accountId: accountId,
      enableAutoEviction: false, // No eviction in light mode
    );
  }

  /// Calculate optimal storage limit based on device memory
  int _calculateOptimalStorageLimit() {
    if (_deviceMemoryMB <= 3072) return 150; // 150MB for low memory
    if (_deviceMemoryMB <= 4096) return 300; // 300MB for medium memory
    if (_deviceMemoryMB <= 6144) return 500; // 500MB for good memory
    return 750; // 750MB for high memory devices
  }

  /// Calculate optimal email count limit based on device capabilities
  int _calculateOptimalEmailLimit() {
    if (_deviceMemoryMB <= 3072) return 2000; // 2K emails for low memory
    if (_deviceMemoryMB <= 4096) return 3500; // 3.5K emails for medium memory
    if (_deviceMemoryMB <= 6144) return 5000; // 5K emails for good memory
    return 7500; // 7.5K emails for high memory devices
  }

  /// Force maintenance run for a specific account
  Future<void> forceMaintenanceForAccount(String accountId) async {
    try {
      final cacheService = AdvancedEmailCacheService();
      await cacheService.initialize();
      await _performOptimizedMaintenanceForAccount(accountId, cacheService);
    } catch (e) {
      debugPrint('CacheMaintenanceService: Error in forced maintenance for $accountId: $e');
    }
  }

  /// Get maintenance service status
  Map<String, dynamic> getStatus() {
    return {
      'isRunning': _isRunning,
      'intervalHours': _maintenanceInterval.inHours,
      'deviceMemoryMB': _deviceMemoryMB,
      'availableStorageGB': _availableStorageGB,
      'adaptiveModeEnabled': _isAdaptiveModeEnabled,
      'nextRunTime': _isRunning && _maintenanceTimer != null
          ? DateTime.now().add(_maintenanceInterval).toIso8601String()
          : null,
    };
  }

  /// Configure maintenance policies
  Future<void> configureMaintenance({
    Duration interval = const Duration(hours: 6),
    bool restartIfRunning = true,
  }) async {
    if (_isRunning && restartIfRunning) {
      await stopMaintenance();
      await startMaintenance(interval: interval);
    } else if (!_isRunning) {
      _maintenanceInterval = interval;
    }

    debugPrint('CacheMaintenanceService: Configured maintenance interval to ${interval.inHours} hours');
  }
}

/// Background cache maintenance worker
/// This can be used for running cache maintenance in a separate isolate
class CacheMaintenanceWorker {
  static Future<void> runMaintenanceInBackground() async {
    try {
      // This would run in a background isolate
      final maintenanceService = CacheMaintenanceService();
      await maintenanceService.startMaintenance(
        interval: const Duration(hours: 12), // Less frequent in background
        runImmediately: true,
      );

      // Keep the worker alive for periodic maintenance
      // In a real app, this might be managed by WorkManager or similar
      await Future.delayed(const Duration(hours: 24));

      await maintenanceService.stopMaintenance();
    } catch (e) {
      debugPrint('CacheMaintenanceWorker: Background maintenance error: $e');
    }
  }

  /// Calculate optimal cache settings based on device specs
  static Map<String, int> calculateOptimalCacheSettings() {
    // In a real app, this could check available storage, RAM, etc.
    // For now, return conservative defaults
    return {
      'maxStorageMB': 500,
      'maxEmailsPerFolder': 5000,
      'maintenanceIntervalHours': 6,
      'maxEmailAgeDays': 90,
    };
  }
}