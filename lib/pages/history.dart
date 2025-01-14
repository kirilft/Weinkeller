import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart'; // <-- ADD THIS

class HistoryPage extends StatefulWidget {
  const HistoryPage({Key? key}) : super(key: key);

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

  /// Get the path for the local history file
  Future<File> _getHistoryFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/fermentation_history.json');
  }

  /// Load all history entries from the local file
  Future<List<Map<String, dynamic>>> _loadHistoryFromFile() async {
    try {
      final file = await _getHistoryFile();

      // Check if the file exists
      if (await file.exists()) {
        final content = await file.readAsString();
        return List<Map<String, dynamic>>.from(jsonDecode(content));
      } else {
        return []; // Return empty list if file doesn't exist
      }
    } catch (e) {
      print('[HistoryPage] Error loading history: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _entriesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.data == null || snapshot.data!.isEmpty) {
            return const Center(child: Text('No history available.'));
          } else {
            final entries = snapshot.data!;
            return ListView.builder(
              itemCount: entries.length,
              itemBuilder: (context, index) {
                final entry = entries[index];

                // Safely parse and format the date
                String formattedDate;
                try {
                  final dateTime = DateTime.parse(entry['date']);
                  formattedDate = DateFormat('y MMM d HH:mm').format(dateTime);
                  // Example format: Jan 14, 2025. 16:30
                } catch (e) {
                  // If parsing fails, just fall back to the raw string
                  formattedDate = entry['date'].toString();
                }

                return ListTile(
                  title: Text('Wine ID: ${entry['wineId']}'),
                  subtitle: Text(
                    'Density: ${entry['density']}\n'
                    'Date: $formattedDate',
                  ),
                  isThreeLine: true,
                );
              },
            );
          }
        },
      ),
    );
  }
}
