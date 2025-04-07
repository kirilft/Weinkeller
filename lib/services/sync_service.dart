import 'dart:async';
import 'package:flutter/foundation.dart';
import 'api_service.dart'; // Make sure ApiService and exceptions are defined here
import 'database_service.dart';

/// SyncService handles periodic background synchronization.
/// It attempts to upload pending local changes and download+cache fresh data from the API.
class SyncService with ChangeNotifier {
  final ApiService apiService;
  final DatabaseService databaseService;
  final Duration syncInterval;
  Timer? _timer;
  bool _isSyncing = false; // Flag to prevent concurrent sync runs

  SyncService({
    required this.apiService,
    required this.databaseService,
    this.syncInterval = const Duration(minutes: 5), // Default to 5 minutes
  });

  /// Starts a periodic timer to trigger synchronization.
  /// Requires the authentication token to pass to API calls.
  void startSync(String token) {
    if (_timer != null && _timer!.isActive) {
      debugPrint('[SyncService] Sync timer already active.');
      return; // Don't start if already running
    }
    debugPrint(
        '[SyncService] Starting periodic sync timer with interval: $syncInterval');
    _timer = Timer.periodic(syncInterval, (timer) async {
      if (_isSyncing) {
        debugPrint(
            '[SyncService] Skipping sync cycle, previous cycle still running.');
        return;
      }
      _isSyncing = true; // Set flag
      debugPrint('[SyncService] Periodic sync triggered...');
      try {
        await updatePendingOperationsAndFetch(token);
      } catch (e) {
        // Catch errors during the sync process itself
        debugPrint('[SyncService] Error during periodic sync: $e');
      } finally {
        _isSyncing = false; // Reset flag
      }
    });
    // Optionally trigger an immediate sync on start
    // Future.microtask(() async {
    //    debugPrint('[SyncService] Performing initial sync...');
    //    await updatePendingOperationsAndFetch(token);
    // });
  }

  /// Stops the periodic synchronization timer.
  void stopSync() {
    if (_timer != null && _timer!.isActive) {
      debugPrint('[SyncService] Stopping sync timer.');
      _timer!.cancel();
      _timer = null;
    } else {
      debugPrint('[SyncService] Sync timer was not active.');
    }
    _isSyncing = false; // Reset flag if stopped externally
  }

  /// Performs a full sync cycle:
  /// 1. Attempts to re-upload pending local operations.
  /// 2. Fetches fresh data for key types (Barrels, AdditiveTypes, WineTypes) from the API.
  /// 3. Updates the local cache with the fetched data.
  Future<void> updatePendingOperationsAndFetch(String token) async {
    debugPrint(
        '[SyncService] Starting sync cycle: Upload Pending & Fetch Fresh Data...');

    // 1) Re-upload anything stored locally (Placeholder - needs real implementation)
    try {
      await databaseService.reuploadAllPendingOperations();
      debugPrint(
          '[SyncService] Pending operations re-upload attempt finished.');
    } catch (e) {
      debugPrint('[SyncService] Error during pending operations re-upload: $e');
      // Decide if fetching should continue despite upload errors
    }

    // 2) Fetch new data from the server and update local cache
    try {
      // Fetch and Cache WineBarrels
      try {
        debugPrint('[SyncService] Fetching latest WineBarrels...');
        final wineBarrels = await apiService.getAllWineBarrels(token: token);
        await databaseService.clearCachedWineBarrels();
        for (final w in wineBarrels) {
          // Ensure ID exists before caching
          if (w['id'] != null) {
            await databaseService
                .insertOrUpdateWineBarrel({'id': w['id'], 'name': w['name']});
          }
        }
        debugPrint(
            '[SyncService] WineBarrels cache updated (${wineBarrels.length} items).');
      } catch (e) {
        debugPrint('[SyncService] Error fetching/caching WineBarrels: $e');
        // Continue syncing other types even if one fails
      }

      // Fetch and Cache AdditiveTypes
      try {
        debugPrint('[SyncService] Fetching latest AdditiveTypes...');
        final additiveTypes =
            await apiService.getAllAdditiveTypes(token: token);
        await databaseService.clearCachedAdditiveTypes();
        for (final a in additiveTypes) {
          if (a['id'] != null) {
            await databaseService
                .insertOrUpdateAdditiveType({'id': a['id'], 'type': a['type']});
          }
        }
        debugPrint(
            '[SyncService] AdditiveTypes cache updated (${additiveTypes.length} items).');
      } catch (e) {
        debugPrint('[SyncService] Error fetching/caching AdditiveTypes: $e');
      }

      // ** NEW: Fetch and Cache WineTypes **
      try {
        debugPrint('[SyncService] Fetching latest WineTypes...');
        final wineTypes = await apiService.getAllWineTypes(
            token: token); // Use ApiService method
        await databaseService.clearCachedWineTypes(); // Use new DB method
        for (final wt in wineTypes) {
          // Ensure ID and name exist before caching
          if (wt['id'] != null) {
            await databaseService.insertOrUpdateWineType(
                {'id': wt['id'], 'name': wt['name']}); // Use new DB method
          }
        }
        debugPrint(
            '[SyncService] WineTypes cache updated (${wineTypes.length} items).');
      } catch (e) {
        debugPrint('[SyncService] Error fetching/caching WineTypes: $e');
      }

      // Add fetching for other data types here if needed...
    } catch (e) {
      // Catch broader errors during the API fetching phase
      debugPrint('[SyncService] Error during data fetching phase: $e');
      // Consider notifying the user or logging more details
    }
    debugPrint('[SyncService] Sync cycle finished.');
  }

  /// Returns how many pending operations are stored locally.
  Future<int> getLocalCacheSize() async {
    return await databaseService.getPendingOperationsCount();
  }

  @override
  void dispose() {
    stopSync(); // Ensure timer is cancelled when the service is disposed
    super.dispose();
    debugPrint('[SyncService] Disposed.');
  }
}
