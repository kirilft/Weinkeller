// components/pending_changes.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:weinkeller/services/database_service.dart';

class PendingChanges extends StatefulWidget {
  const PendingChanges({Key? key}) : super(key: key);

  @override
  State<PendingChanges> createState() => _PendingChangesState();
}

class _PendingChangesState extends State<PendingChanges> {
  late Future<List<Map<String, dynamic>>> _pendingEntriesFuture;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadPendingEntries();
  }

  void _loadPendingEntries() {
    // Retrieve pending entries from the local database.
    _pendingEntriesFuture = DatabaseService().getPendingEntries();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _pendingEntriesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 200,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return Center(
            child: Text('Error loading pending changes: ${snapshot.error}'),
          );
        }
        final entries = snapshot.data ?? [];
        if (entries.isEmpty) {
          return const Center(child: Text('No pending changes'));
        }
        return Scrollbar(
          controller: _scrollController,
          thumbVisibility: entries.length > 3,
          child: ListView.separated(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            shrinkWrap: true,
            itemCount: entries.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final entry = entries[index];
              final wineId = entry['wineId'];
              final density = entry['density'];
              final dateStr = entry['date'] as String? ?? '';
              DateTime dateTime;
              try {
                dateTime = DateTime.parse(dateStr);
              } catch (_) {
                dateTime = DateTime.now();
              }
              // Format full date and time (e.g. "2025 Jan 14, 16:30").
              final formattedTime =
                  DateFormat('y MMM d, HH:mm').format(dateTime);
              // Calculate opacity to decrease by 0.1 per item (adjust as needed).
              final computedOpacity = (1.0 - index * 0.1).clamp(0.0, 1.0);
              return Opacity(
                opacity: computedOpacity,
                child: Card(
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // WineID as header.
                        Text(
                          'WineID: #$wineId',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Density in the middle.
                        Text(
                          'Density: $density',
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 8),
                        // Full date/time below.
                        Text(
                          formattedTime,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
