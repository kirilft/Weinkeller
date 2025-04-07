import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class HistoryService {
  Future<File> _getHistoryFile() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/fermentation_history.json');
    debugPrint('[HistoryService] History file path: ${file.path}');
    return file;
  }

  Future<List<Map<String, dynamic>>> getHistoryEntries() async {
    try {
      final file = await _getHistoryFile();
      if (await file.exists()) {
        final content = await file.readAsString();
        debugPrint('[HistoryService] Loaded history content: $content');
        return List<Map<String, dynamic>>.from(jsonDecode(content));
      } else {
        debugPrint('[HistoryService] History file does not exist.');
        return [];
      }
    } catch (e) {
      debugPrint('[HistoryService] Error reading history: $e');
      return [];
    }
  }

  Future<void> addHistoryEntry(Map<String, dynamic> entry) async {
    try {
      final file = await _getHistoryFile();
      List<Map<String, dynamic>> entries = [];
      if (await file.exists()) {
        final content = await file.readAsString();
        debugPrint('[HistoryService] Existing history content: $content');
        entries = List<Map<String, dynamic>>.from(jsonDecode(content));
      } else {
        debugPrint(
            '[HistoryService] History file not found. Creating new file.');
        await file.create(recursive: true);
      }
      entries.add(entry);
      await file.writeAsString(jsonEncode(entries));
      debugPrint(
          '[HistoryService] Entry saved successfully. New history: ${jsonEncode(entries)}');
    } catch (e) {
      debugPrint('[HistoryService] Error writing history: $e');
    }
  }
}
