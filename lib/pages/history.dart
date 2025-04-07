import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  late Future<List<Map<String, dynamic>>> _entriesFuture;

  @override
  void initState() {
    super.initState();
    _entriesFuture = _loadHistoryFromFile();
  }

  Future<File> _getHistoryFile() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/fermentation_history.json');
    debugPrint('[HistoryPage] History file path: ${file.path}');
    return file;
  }

  Future<List<Map<String, dynamic>>> _loadHistoryFromFile() async {
    try {
      final file = await _getHistoryFile();
      if (await file.exists()) {
        final content = await file.readAsString();
        debugPrint('[HistoryPage] Loaded history content: $content');
        return List<Map<String, dynamic>>.from(jsonDecode(content));
      } else {
        debugPrint('[HistoryPage] History file does not exist.');
        return [];
      }
    } catch (e) {
      debugPrint('[HistoryPage] Error loading history: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verlauf'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _entriesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Fehler: ${snapshot.error}'));
          } else if (snapshot.data == null || snapshot.data!.isEmpty) {
            return const Center(child: Text('Keine Historie verfügbar.'));
          } else {
            final entries = snapshot.data!;
            return ListView.builder(
              itemCount: entries.length,
              itemBuilder: (context, index) {
                final entry = entries[index];
                String operationType = entry['operationType'] ?? 'Unbekannt';

                // Format the recorded timestamp
                String formattedTimestamp;
                try {
                  final ts = DateTime.parse(entry['timestamp']);
                  formattedTimestamp = DateFormat('y MMM d HH:mm').format(ts);
                } catch (e) {
                  formattedTimestamp = entry['timestamp'].toString();
                }

                if (operationType == 'addFermentationEntry') {
                  final payload = entry['payload'] is String
                      ? jsonDecode(entry['payload'])
                      : entry['payload'];
                  String wineId =
                      payload['wineId']?.toString() ?? 'Nicht verfügbar';
                  String density =
                      payload['density']?.toString() ?? 'Nicht verfügbar';
                  String dateStr = payload['date']?.toString() ?? '';
                  String formattedDate;
                  try {
                    final dateTime = DateTime.parse(dateStr);
                    formattedDate =
                        DateFormat('y MMM d HH:mm').format(dateTime);
                  } catch (e) {
                    formattedDate = dateStr;
                  }
                  return ListTile(
                    title: Text('Wein-Barrel: $wineId'),
                    subtitle: Text(
                      'Dichte: $density\nDatum: $formattedDate\nAufgezeichnet: $formattedTimestamp',
                    ),
                    isThreeLine: true,
                  );
                } else {
                  return ListTile(
                    title: Text('Vorgang: $operationType'),
                    subtitle: Text(
                      'Details: ${entry['payload']}\nAufgezeichnet: $formattedTimestamp',
                    ),
                    isThreeLine: true,
                  );
                }
              },
            );
          }
        },
      ),
    );
  }
}
