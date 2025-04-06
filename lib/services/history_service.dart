import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';

class HistoryService {
  Future<File> _getHistoryFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/fermentation_history.json');
  }

  Future<List<Map<String, dynamic>>> getHistoryEntries() async {
    try {
      final file = await _getHistoryFile();
      if (await file.exists()) {
        final content = await file.readAsString();
        return List<Map<String, dynamic>>.from(jsonDecode(content));
      } else {
        return [];
      }
    } catch (e) {
      print('[HistoryService] Error reading history: $e');
      return [];
    }
  }

  Future<void> addHistoryEntry(Map<String, dynamic> entry) async {
    try {
      final file = await _getHistoryFile();
      List<Map<String, dynamic>> entries = [];
      if (await file.exists()) {
        final content = await file.readAsString();
        entries = List<Map<String, dynamic>>.from(jsonDecode(content));
      }
      // Append the new entry
      entries.add(entry);
      await file.writeAsString(jsonEncode(entries));
    } catch (e) {
      print('[HistoryService] Error writing history: $e');
    }
  }
}
