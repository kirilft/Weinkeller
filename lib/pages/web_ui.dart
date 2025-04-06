import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WebUIView extends StatefulWidget {
  const WebUIView({super.key});

  @override
  State<WebUIView> createState() => _WebUIViewState();
}

class _WebUIViewState extends State<WebUIView> {
  late final WebViewController _controller;
  String? _errorMessage; // Holds error details if a loading error occurs.

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (NavigationRequest request) {
            // Allow all navigations.
            return NavigationDecision.navigate;
          },
          onPageStarted: (String url) {
            // Reset any previous error messages when a new page starts loading.
            setState(() {
              _errorMessage = null;
            });
          },
          onPageFinished: (String url) {
            // Optionally, handle any post-loading actions here.
          },
          onWebResourceError: (WebResourceError error) {
            // Update the state with error details.
            setState(() {
              _errorMessage =
                  "Failed to load page.\nError Code: ${error.errorCode}\nDescription: ${error.description}";
            });
          },
        ),
      )
      ..loadRequest(Uri.parse('https://google.at'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Web UI'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () async {
            if (await _controller.canGoBack()) {
              _controller.goBack();
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // Reset the error message and attempt to reload.
              setState(() {
                _errorMessage = null;
              });
              _controller.reload();
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
              ),
              child: const Text(
                'Menu',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Home'),
              onTap: () {
                Navigator.pushReplacementNamed(context, '/');
              },
            ),
            // Additional menu items can be added here.
          ],
        ),
      ),
      body: _errorMessage != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage!,
                      style: const TextStyle(fontSize: 16, color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        // Retry loading the page.
                        setState(() {
                          _errorMessage = null;
                        });
                        _controller.reload();
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          : WebViewWidget(controller: _controller),
    );
  }
}
