import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:weinkeller/services/database_service.dart';
import 'dart:ui'; // for FontFeature

class PendingChanges extends StatefulWidget {
  /// Callback to notify HomeScreen that pending operations changed.
  final VoidCallback? onChangesUpdated;

  const PendingChanges({super.key, this.onChangesUpdated});

  @override
  State<PendingChanges> createState() => _PendingChangesState();
}

const _title1Style = TextStyle(
  color: Color(0xFF000000),
  fontFamily: 'SF Pro',
  fontSize: 28,
  fontStyle: FontStyle.normal,
  fontWeight: FontWeight.w400,
  height: 34 / 28,
  letterSpacing: 0.38,
  fontFeatures: [
    FontFeature.disable('liga'),
    FontFeature.disable('clig'),
  ],
);

const _footnoteStyle = TextStyle(
  color: Color(0xFF000000),
  fontFamily: 'SF Pro',
  fontSize: 13,
  fontStyle: FontStyle.normal,
  fontWeight: FontWeight.w400,
  height: 18 / 13,
  letterSpacing: -0.08,
  fontFeatures: [
    FontFeature.disable('liga'),
    FontFeature.disable('clig'),
  ],
);

class _PendingChangesState extends State<PendingChanges> {
  late Future<List<Map<String, dynamic>>> _pendingOperationsFuture;
  List<Map<String, dynamic>> _operations = [];

  @override
  void initState() {
    super.initState();
    _loadPendingOperations();
  }

  void _loadPendingOperations() {
    _pendingOperationsFuture = DatabaseService().getPendingOperations();
  }

  /// Deletes all pending operations.
  Future<void> _deleteAllOperations() async {
    try {
      await DatabaseService().deleteAllPendingOperations();
    } catch (e) {
      debugPrint('Error deleting all operations: $e');
    } finally {
      widget.onChangesUpdated?.call();
      _loadPendingOperations();
      setState(() {});
    }
  }

  /// Deletes a single operation by its ID.
  Future<void> _deleteSingleOperation(int operationId) async {
    try {
      await DatabaseService().deletePendingOperation(operationId);
    } catch (e) {
      debugPrint('Error deleting operation $operationId: $e');
    } finally {
      widget.onChangesUpdated?.call();
      _loadPendingOperations();
      setState(() {});
    }
  }

  /// Re-uploads all pending operations.
  Future<void> _reuploadAllOperations() async {
    try {
      await DatabaseService().reuploadAllPendingOperations();
    } catch (e) {
      debugPrint('Error reuploading operations: $e');
    } finally {
      widget.onChangesUpdated?.call();
      _loadPendingOperations();
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Top Row with delete-all and reupload buttons.
        Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 40, top: 32, bottom: 24),
              child: SizedBox(
                width: 28,
                height: 32,
                child: IconButton(
                  onPressed: _deleteAllOperations,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon:
                      const FaIcon(FontAwesomeIcons.trash, color: Colors.black),
                  iconSize: 24,
                  tooltip: 'Delete all pending operations',
                ),
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.only(top: 34, right: 32, bottom: 26),
              child: SizedBox(
                width: 40,
                height: 28,
                child: IconButton(
                  onPressed: _reuploadAllOperations,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const FaIcon(FontAwesomeIcons.upload,
                      color: Colors.black),
                  iconSize: 22,
                  tooltip: 'Reupload all pending operations',
                ),
              ),
            ),
          ],
        ),
        // Expanded list of pending operations.
        Expanded(
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _pendingOperationsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                      'Error loading pending operations: ${snapshot.error}'),
                );
              }
              final operations = snapshot.data ?? [];
              if (operations.isEmpty) {
                return const Center(child: Text('No pending operations'));
              }
              _operations = operations;
              return ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _operations.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final operation = _operations[index];
                  final operationId = operation['id'] ?? 0;
                  final operationType = operation['operationType'] ?? 'Unknown';
                  final payload = operation['payload'] ?? '{}';
                  final timestampStr = operation['timestamp'] ?? '';
                  DateTime dateTime;
                  try {
                    dateTime = DateTime.parse(timestampStr);
                  } catch (_) {
                    dateTime = DateTime.now();
                  }
                  final formattedTime =
                      DateFormat('EEE MMM d HH:mm').format(dateTime);
                  return Container(
                    color: const Color(0xFFEFEFF0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 16.0, horizontal: 16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  operationType.toString(),
                                  style: _title1Style,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Payload: $payload',
                                  style: _footnoteStyle,
                                ),
                                Text(
                                  formattedTime,
                                  style: _footnoteStyle,
                                ),
                              ],
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(
                              top: 23, right: 16, bottom: 23),
                          child: SizedBox(
                            child: IconButton(
                              onPressed: () =>
                                  _deleteSingleOperation(operationId),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              icon: const FaIcon(FontAwesomeIcons.trash),
                              iconSize: 24,
                              color: Colors.black,
                              tooltip: 'Delete this operation',
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
