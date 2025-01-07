import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  // Method to open the account management website
  Future<void> _launchAccountWebsite(BuildContext context) async {
    const url =
        'https://kasai.tech/account'; // Replace with the actual URL for account management
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(
        Uri.parse(url),
        mode: LaunchMode
            .externalApplication, // Opens in the user's default browser
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Could not open the account management website')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Account'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context); // Go back to the previous screen
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0), // Add padding to the content
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Manage your account details.',
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => _launchAccountWebsite(context),
              icon: const Icon(Icons.open_in_browser),
              label: const Text('Visit Account Management'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue, // Blue button
                foregroundColor: Colors.white, // White text
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
