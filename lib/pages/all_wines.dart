import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';

class AllWinesPage extends StatelessWidget {
  const AllWinesPage({Key? key}) : super(key: key);

  Future<List<Map<String, dynamic>>> _fetchWines(BuildContext context) async {
    final apiService = Provider.of<ApiService>(context, listen: false);
    return await apiService.getAllWineNames();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Wines'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchWines(context),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final wines = snapshot.data ?? [];
          return ListView.builder(
            itemCount: wines.length,
            itemBuilder: (context, index) {
              final wine = wines[index];
              final wineId = wine['id'];
              final wineName = wine['name'] ?? '';
              // If more information is available, adjust this as needed.
              final otherInfo = wine['other'] ?? 'Additional info';

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top small: WineID
                      Text(
                        'WineID: #$wineId',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Winename as headline top
                      Text(
                        wineName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Small other information
                      Text(
                        otherInfo,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
