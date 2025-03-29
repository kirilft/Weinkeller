import 'dart:async';
import 'package:flutter/foundation.dart';
import 'api_service.dart';

class SyncService with ChangeNotifier {
  final ApiService apiService;
  final Duration syncInterval;
  Timer? _timer;

  SyncService({
    required this.apiService,
    this.syncInterval = const Duration(minutes: 5),
  });

  /// Starts a periodic timer to sync pending fermentation entries.
  void startSync(String token) {
    _timer?.cancel(); // Cancel any existing timer.
    _timer = Timer.periodic(syncInterval, (timer) async {
      debugPrint('[SyncService] Initiating sync...');
      await apiService.syncPendingFermentationEntries(token: token);
    });
  }

  /// Stops the periodic synchronization.
  void stopSync() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    stopSync();
    super.dispose();
  }
}
