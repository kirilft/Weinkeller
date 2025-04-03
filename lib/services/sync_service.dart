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

  /// Starts a periodic timer to re-upload pending operations
  /// AND fetch fresh data from the API.
  void startSync(String token) {
    _timer?.cancel(); // Cancel any existing timer.
    _timer = Timer.periodic(syncInterval, (timer) async {
      debugPrint('[SyncService] Initiating sync...');
      await updatePendingOperationsAndFetch(token);
    });
  }

  /// Stops the periodic synchronization.
  void stopSync() {
    _timer?.cancel();
    _timer = null;
  }

  /// Performs a full sync: re-upload pending ops, then fetch from the API.
  Future<void> updatePendingOperationsAndFetch(String token) async {
    debugPrint('[SyncService] Updating pending operations...');
    // 1) Re-upload anything stored locally
    await databaseService.reuploadAllPendingOperations();

    // 2) Now fetch new data from the server
    try {
      debugPrint('[SyncService] Fetching latest WineTypes...');
      final wineTypes = await apiService.getAllWineTypes(token: token);
      // Clear local cache, then store them
      await databaseService.clearCachedWineTypes();
      for (final w in wineTypes) {
        await databaseService.insertOrUpdateWineType(w);
      }
      debugPrint('[SyncService] WineTypes updated successfully.');

      debugPrint('[SyncService] Fetching latest AdditiveTypes...');
      final additiveTypes = await apiService.getAllAdditiveTypes(token: token);
      // Clear local cache, then store them
      await databaseService.clearCachedAdditiveTypes();
      for (final a in additiveTypes) {
        await databaseService.insertOrUpdateAdditiveType(a);
      }
      debugPrint('[SyncService] AdditiveTypes updated successfully.');
    } catch (e) {
      debugPrint('[SyncService] Error fetching data from API: $e');
    }
  }

  /// Returns how many pending operations are stored locally.
  Future<int> getLocalCacheSize() async {
    return await databaseService.getPendingOperationsCount();
  }

  @override
  void dispose() {
    stopSync();
    super.dispose();
  }
}
