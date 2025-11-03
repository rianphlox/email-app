import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/pending_operation.dart';
import '../services/gmail_api_service.dart';
import '../services/auth_service.dart';
import 'dart:math';

class OperationQueue extends ChangeNotifier {
  static final OperationQueue _instance = OperationQueue._internal();
  factory OperationQueue() => _instance;
  OperationQueue._internal();

  Box<PendingOperation>? _operationsBox;
  List<PendingOperation> _pendingOperations = [];
  bool _isProcessing = false;

  List<PendingOperation> get pendingOperations => _pendingOperations;
  bool get isProcessing => _isProcessing;
  bool get hasPendingOperations => _pendingOperations.isNotEmpty;

  /// Initialize the operation queue
  Future<void> initialize() async {
    try {
      _operationsBox = await Hive.openBox<PendingOperation>('pending_operations');
      _loadPendingOperations();
      debugPrint('OperationQueue: Initialized with ${_pendingOperations.length} pending operations');
    } catch (e) {
      debugPrint('OperationQueue: Failed to initialize: $e');
    }
  }

  /// Load pending operations from storage
  void _loadPendingOperations() {
    if (_operationsBox == null) return;

    _pendingOperations = _operationsBox!.values
        .where((op) => !op.isProcessing) // Skip operations that were being processed
        .toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    notifyListeners();
  }

  /// Queue a new operation
  Future<void> queueOperation({
    required OperationType operationType,
    String? emailId,
    required Map<String, dynamic> data,
    required String accountId,
  }) async {
    if (_operationsBox == null) {
      debugPrint('OperationQueue: Box not initialized, cannot queue operation');
      return;
    }

    final operation = PendingOperation(
      id: _generateOperationId(),
      operationType: operationType,
      emailId: emailId,
      data: data,
      timestamp: DateTime.now(),
      accountId: accountId,
    );

    try {
      await _operationsBox!.put(operation.id, operation);
      _pendingOperations.add(operation);
      notifyListeners();

      debugPrint('OperationQueue: Queued operation ${operation.operationType} for email $emailId');

      // Try to process immediately if not already processing
      if (!_isProcessing) {
        await processPendingOperations();
      }
    } catch (e) {
      debugPrint('OperationQueue: Failed to queue operation: $e');
    }
  }

  /// Process all pending operations
  Future<void> processPendingOperations() async {
    if (_isProcessing || _pendingOperations.isEmpty) return;

    _isProcessing = true;
    notifyListeners();

    debugPrint('OperationQueue: Starting to process ${_pendingOperations.length} operations');

    final operationsToProcess = List<PendingOperation>.from(_pendingOperations);

    for (final operation in operationsToProcess) {
      try {
        // Mark as processing
        operation.isProcessing = true;
        await _operationsBox!.put(operation.id, operation);

        // Execute the operation
        final success = await _executeOperation(operation);

        if (success) {
          // Remove from queue
          await _operationsBox!.delete(operation.id);
          _pendingOperations.remove(operation);
          debugPrint('OperationQueue: Successfully executed ${operation.operationType}');
        } else {
          // Mark as failed and increment retry count
          operation.isProcessing = false;
          operation.incrementRetry();

          if (operation.canRetry) {
            await _operationsBox!.put(operation.id, operation);
            debugPrint('OperationQueue: Operation ${operation.operationType} failed, will retry (${operation.retryCount}/3)');
          } else {
            // Max retries reached, remove from queue
            await _operationsBox!.delete(operation.id);
            _pendingOperations.remove(operation);
            debugPrint('OperationQueue: Operation ${operation.operationType} failed after max retries, removing');
          }
        }
      } catch (e) {
        debugPrint('OperationQueue: Error executing operation ${operation.operationType}: $e');

        // Reset processing flag and increment retry
        operation.isProcessing = false;
        operation.incrementRetry();

        if (operation.canRetry) {
          await _operationsBox!.put(operation.id, operation);
        } else {
          await _operationsBox!.delete(operation.id);
          _pendingOperations.remove(operation);
        }
      }
    }

    _isProcessing = false;
    notifyListeners();

    debugPrint('OperationQueue: Finished processing. ${_pendingOperations.length} operations remaining');
  }

  /// Execute a specific operation
  Future<bool> _executeOperation(PendingOperation operation) async {
    final gmailService = AuthService.getGmailApiService();
    if (gmailService == null) {
      debugPrint('OperationQueue: Gmail service not available');
      return false;
    }

    try {
      switch (operation.operationType) {
        case OperationType.markRead:
          return await _markAsRead(gmailService, operation);

        case OperationType.markUnread:
          return await _markAsUnread(gmailService, operation);

        case OperationType.star:
          return await _starEmail(gmailService, operation);

        case OperationType.unstar:
          return await _unstarEmail(gmailService, operation);

        case OperationType.archive:
          return await _archiveEmail(gmailService, operation);

        case OperationType.delete:
          return await _deleteEmail(gmailService, operation);

        case OperationType.sendEmail:
          return await _sendEmail(gmailService, operation);

        case OperationType.moveToFolder:
          return await _moveToFolder(gmailService, operation);

        case OperationType.addLabel:
          return await _addLabel(gmailService, operation);

        case OperationType.removeLabel:
          return await _removeLabel(gmailService, operation);

      }
    } catch (e) {
      debugPrint('OperationQueue: Operation ${operation.operationType} failed: $e');
      return false;
    }
  }

  // Operation implementations
  Future<bool> _markAsRead(GmailApiService gmailService, PendingOperation operation) async {
    if (operation.emailId == null) return false;
    return await gmailService.markAsRead(operation.emailId!);
  }

  Future<bool> _markAsUnread(GmailApiService gmailService, PendingOperation operation) async {
    if (operation.emailId == null) return false;
    // TODO: Implement markAsUnread in GmailApiService
    return true; // Placeholder
  }

  Future<bool> _starEmail(GmailApiService gmailService, PendingOperation operation) async {
    if (operation.emailId == null) return false;
    // TODO: Implement star email in GmailApiService
    return true; // Placeholder
  }

  Future<bool> _unstarEmail(GmailApiService gmailService, PendingOperation operation) async {
    if (operation.emailId == null) return false;
    // TODO: Implement unstar email in GmailApiService
    return true; // Placeholder
  }

  Future<bool> _archiveEmail(GmailApiService gmailService, PendingOperation operation) async {
    if (operation.emailId == null) return false;
    // TODO: Implement archive email in GmailApiService
    return true; // Placeholder
  }

  Future<bool> _deleteEmail(GmailApiService gmailService, PendingOperation operation) async {
    if (operation.emailId == null) return false;
    return await gmailService.deleteEmail(operation.emailId!);
  }

  Future<bool> _sendEmail(GmailApiService gmailService, PendingOperation operation) async {
    final emailData = operation.data;
    return await gmailService.sendEmail(
      to: emailData['to'] ?? '',
      cc: emailData['cc'],
      bcc: emailData['bcc'],
      subject: emailData['subject'] ?? '',
      body: emailData['body'] ?? '',
      attachmentPaths: emailData['attachments']?.cast<String>(),
    );
  }

  Future<bool> _moveToFolder(GmailApiService gmailService, PendingOperation operation) async {
    if (operation.emailId == null) return false;
    // TODO: Implement move to folder in GmailApiService
    return true; // Placeholder
  }

  Future<bool> _addLabel(GmailApiService gmailService, PendingOperation operation) async {
    if (operation.emailId == null) return false;
    // TODO: Implement add label in GmailApiService
    return true; // Placeholder
  }

  Future<bool> _removeLabel(GmailApiService gmailService, PendingOperation operation) async {
    if (operation.emailId == null) return false;
    // TODO: Implement remove label in GmailApiService
    return true; // Placeholder
  }

  /// Clear all pending operations (useful for debugging or account switches)
  Future<void> clearAllOperations() async {
    if (_operationsBox == null) return;

    await _operationsBox!.clear();
    _pendingOperations.clear();
    notifyListeners();
    debugPrint('OperationQueue: Cleared all pending operations');
  }

  /// Clear operations for a specific account
  Future<void> clearOperationsForAccount(String accountId) async {
    if (_operationsBox == null) return;

    final operationsToRemove = _pendingOperations
        .where((op) => op.accountId == accountId)
        .toList();

    for (final operation in operationsToRemove) {
      await _operationsBox!.delete(operation.id);
      _pendingOperations.remove(operation);
    }

    notifyListeners();
    debugPrint('OperationQueue: Cleared ${operationsToRemove.length} operations for account $accountId');
  }

  /// Generate a unique operation ID
  String _generateOperationId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(999999);
    return '${timestamp}_$random';
  }

  /// Dispose resources
  @override
  Future<void> dispose() async {
    await _operationsBox?.close();
    super.dispose();
  }
}