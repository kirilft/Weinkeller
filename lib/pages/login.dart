import 'package:flutter/material.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context); // Go back to the previous screen
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(50.0), // Add padding to the whole content
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: screenHeight * 0.2),
            const TextField(
              decoration: InputDecoration(
                labelText: 'E-Mail',
              ),
            ),
            const SizedBox(height: 20), // Add spacing between inputs
            const TextField(
              decoration: InputDecoration(
                labelText: 'Password',
              ),
              obscureText: true,
            ),
            const SizedBox(height: 10), // Add small spacing for the link
            Align(
              alignment: Alignment
                  .centerLeft, // Align the "Forgot Password" link to the right
              child: TextButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, '/password_reset');
                },
                icon: const Icon(Icons.link, size: 16),
                label: const Text('Forgot Password'),
              ),
            ),
            Align(
              alignment: Alignment
                  .centerRight, // Align the login button to the bottom-left
              child: ElevatedButton(
                onPressed: () {
                  // Add login logic here
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue, // Blue button
                  foregroundColor: Colors.white, // White text
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                ),
                child: const Text('Login'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
