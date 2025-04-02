import 'dart:async';
import 'package:flutter/foundation.dart';
import 'api_service.dart';
import 'database_service.dart';

class SyncService with ChangeNotifier {
  final ApiService apiService;
  final DatabaseService databaseService;
  final Duration syncInterval;
  Timer? _timer;

  SyncService({
    required this.apiService,
    required this.databaseService,
    this.syncInterval = const Duration(minutes: 5),
  });

  /// Starts a periodic timer to update the local cache and re-upload pending operations.
  void startSync(String token) {
    _timer?.cancel(); // Cancel any existing timer.
    _timer = Timer.periodic(syncInterval, (timer) async {
      debugPrint('[SyncService] Initiating sync...');
      await updatePendingOperations();
    });
  }

  /// Stops the periodic synchronization.
  void stopSync() {
    _timer?.cancel();
    _timer = null;
  }

  /// Attempts to re-upload all pending operations stored in the local database.
  Future<void> updatePendingOperations() async {
    debugPrint('[SyncService] Updating pending operations...');
    await databaseService.reuploadAllPendingOperations();
  }

  /// Returns the number of pending operations stored locally.
  Future<int> getLocalCacheSize() async {
    return await databaseService.getPendingOperationsCount();
  }

  @override
  void dispose() {
    stopSync();
    super.dispose();
  }
}
