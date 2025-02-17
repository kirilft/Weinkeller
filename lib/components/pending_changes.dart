import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:weinkeller/services/database_service.dart';
// For disabling ligatures

class PendingChanges extends StatefulWidget {
  /// Callback to notify HomeScreen that pending entries changed
  final VoidCallback? onChangesUpdated;

  const PendingChanges({super.key, this.onChangesUpdated});

  @override
  State<PendingChanges> createState() => _PendingChangesState();
}

// Reusable text styles (SF Pro) with specified letter spacing, line heights, etc.
const _title1Style = TextStyle(
  color: Color(0xFF000000),
  fontFamily: 'SF Pro',
  fontSize: 28,
  fontStyle: FontStyle.normal,
  fontWeight: FontWeight.w400,
  // line-height: 34 px => 34 / 28 = ~1.2143
  height: 34 / 28,
  // letter-spacing: 0.38 px
  letterSpacing: 0.38,
  // disable ligatures
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
  // line-height: 18 px => 18 / 13 = ~1.3846
  height: 18 / 13,
  // letter-spacing: -0.08 px
  letterSpacing: -0.08,
  fontFeatures: [
    FontFeature.disable('liga'),
    FontFeature.disable('clig'),
  ],
);

class _PendingChangesState extends State<PendingChanges> {
  late Future<List<Map<String, dynamic>>> _pendingEntriesFuture;
  List<Map<String, dynamic>> _entries = [];

  @override
  void initState() {
    super.initState();
    _loadPendingEntries();
  }

  void _loadPendingEntries() {
    _pendingEntriesFuture = DatabaseService().getPendingEntries();
  }

  /// Deletes *all* pending entries
  Future<void> _deleteAllEntries() async {
    try {
      await DatabaseService().deleteAllPendingEntries();
    } catch (e) {
      debugPrint('Error deleting all entries: $e');
    } finally {
      // Notify parent screen
      widget.onChangesUpdated?.call();

      _loadPendingEntries();
      setState(() {});
    }
  }

  /// Deletes a single entry by ID
  Future<void> _deleteSingleEntry(int entryId) async {
    try {
      await DatabaseService().deletePendingEntry(entryId);
    } catch (e) {
      debugPrint('Error deleting entry $entryId: $e');
    } finally {
      // Notify parent screen
      widget.onChangesUpdated?.call();

      _loadPendingEntries();
      setState(() {});
    }
  }

  /// Re-upload all pending entries
  Future<void> _reuploadAllEntries() async {
    try {
      await DatabaseService().reuploadAllPendingEntries();
    } catch (e) {
      debugPrint('Error reuploading entries: $e');
    } finally {
      // Notify parent screen
      widget.onChangesUpdated?.call();

      _loadPendingEntries();
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Top Row
        Row(
          children: [
            // Left trash icon (28×32) with padding left:40, top:32, bottom:24
            Padding(
              padding: const EdgeInsets.only(left: 40, top: 32, bottom: 24),
              child: SizedBox(
                width: 28,
                height: 32,
                child: IconButton(
                  onPressed: _deleteAllEntries,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon:
                      const FaIcon(FontAwesomeIcons.trash, color: Colors.black),
                  iconSize: 24,
                  tooltip: 'Delete all local entries',
                ),
              ),
            ),

            const Spacer(),

            // Right upload icon (40×28) with padding top:34, right:32, bottom:26
            Padding(
              padding: const EdgeInsets.only(top: 34, right: 32, bottom: 26),
              child: SizedBox(
                width: 40,
                height: 28,
                child: IconButton(
                  onPressed: _reuploadAllEntries,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const FaIcon(FontAwesomeIcons.upload,
                      color: Colors.black),
                  iconSize: 22,
                  tooltip: 'Reupload all local entries',
                ),
              ),
            ),
          ],
        ),

        // Expanded list of pending entries
        Expanded(
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _pendingEntriesFuture,
            builder: (context, snapshot) {
              // Still loading
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              // Error
              if (snapshot.hasError) {
                return Center(
                  child:
                      Text('Error loading pending changes: ${snapshot.error}'),
                );
              }

              // Retrieve data
              final entries = snapshot.data ?? [];
              if (entries.isEmpty) {
                return const Center(child: Text('No pending changes'));
              }

              _entries = entries;

              // Plain, normal list with each entry in a light gray container
              return ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _entries.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final entry = _entries[index];
                  final entryId = entry['id'] ?? 0;
                  final nameOrId =
                      entry['wineName'] ?? entry['wineId'] ?? 'Unknown';
                  final density = entry['density'] ?? entry['sulfur'] ?? 0.0;
                  final dateStr = entry['date'] as String? ?? '';

                  // Parse date, format for display
                  DateTime dateTime;
                  try {
                    dateTime = DateTime.parse(dateStr);
                  } catch (_) {
                    dateTime = DateTime.now();
                  }
                  final formattedTime =
                      DateFormat('EEE MMM d HH:mm').format(dateTime);

                  // Each entry is a simple Container with no rounding
                  return Container(
                    color: const Color(0xFFEFEFF0), // #EFEFF0
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Left text area
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 16.0,
                              horizontal: 16.0,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Title1: nameOrId
                                Text(
                                  nameOrId.toString(),
                                  style: _title1Style,
                                ),
                                const SizedBox(height: 4),
                                // Footnote: "Value: x"
                                Text(
                                  'Value: $density',
                                  style: _footnoteStyle,
                                ),
                                // Footnote: date/time
                                Text(
                                  formattedTime,
                                  style: _footnoteStyle,
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Trash icon at top=23, right=16, bottom=23
                        Padding(
                          padding: const EdgeInsets.only(
                            top: 23,
                            right: 16,
                            bottom: 23,
                          ),
                          child: SizedBox(
                            child: IconButton(
                              onPressed: () => _deleteSingleEntry(entryId),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              icon: const FaIcon(FontAwesomeIcons.trash),
                              iconSize: 24,
                              color: Colors.black,
                              tooltip: 'Delete this entry',
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
