import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import 'package:weinkeller/services/auth_service.dart';

class AllWinesPage extends StatelessWidget {
  const AllWinesPage({super.key});

  Future<List<Map<String, dynamic>>> _fetchWines(BuildContext context) async {
    final apiService = Provider.of<ApiService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);
    final token = authService.authToken;

    // If the token is null or empty, return an empty list (or handle accordingly)
    if (token == null || token.isEmpty) {
      return [];
    }

    return await apiService.getAllWineNames(token: token);
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
              // Extracting all available fields
              final wineId = wine['id'];
              final userId = wine['userId'];
              final name = wine['name'];
              final mostWeight = wine['mostWeight'];
              final harvestDate = wine['harvestDate'];
              final volumeInHectoLitre = wine['volumeInHectoLitre'];
              final container = wine['container'];
              final productionType = wine['productionType'];
              final mostTreatmentId = wine['mostTreatmentId'];

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Display Wine ID
                      Text(
                        'WineID: #$wineId',
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 4),
                      // Display Wine Name
                      Text(
                        name ?? '',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Display all additional fields
                      Text('User ID: ${userId ?? 'N/A'}'),
                      Text('Most Weight: ${mostWeight ?? 'N/A'}'),
                      Text('Harvest Date: ${harvestDate ?? 'N/A'}'),
                      Text(
                          'Volume (HectoLitre): ${volumeInHectoLitre ?? 'N/A'}'),
                      Text('Container: ${container ?? 'N/A'}'),
                      Text('Production Type: ${productionType ?? 'N/A'}'),
                      Text('Most Treatment ID: ${mostTreatmentId ?? 'N/A'}'),
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
