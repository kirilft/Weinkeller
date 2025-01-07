import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ChangelogPage extends StatefulWidget {
  const ChangelogPage({super.key});

  @override
  State<ChangelogPage> createState() => _ChangelogPageState();
}

class _ChangelogPageState extends State<ChangelogPage> {
  @override
  void initState() {
    super.initState();
    _launchChangelogWebsite();
  }

  // Method to open the webpage
  Future<void> _launchChangelogWebsite() async {
    const url = 'https://kasai.tech'; // URL to open
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication, // Opens in the default browser
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the changelog website')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Changelog'),
        actions: const [],
      ),
      body: const Center(
        child: Text('Redirecting to the changelog...'),
      ),
    );
  }
}
