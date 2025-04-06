import 'dart:math';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:provider/provider.dart';
import 'package:weinkeller/services/database_service.dart';
import 'package:weinkeller/config/app_colors.dart';
import 'package:weinkeller/components/pending_changes.dart';
import 'package:weinkeller/services/auth_service.dart';
import 'package:weinkeller/services/api_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey _qrKey = GlobalKey(debugLabel: 'QR');

  QRViewController? _qrController;
  String? _scannedCode;
  String? _errorMessage;

  final List<String> _greetings = [
    'Hallo',
    'Hallo',
    'Bonjour',
    'Ciao',
    'Konnichiwa',
    'Namaste',
  ];
  late String _randomGreeting;

  @override
  void initState() {
    super.initState();
    _pickRandomGreeting();
  }

  void _pickRandomGreeting() {
    final randomIndex = Random().nextInt(_greetings.length);
    _randomGreeting = _greetings[randomIndex];
  }

  @override
  void dispose() {
    _qrController?.dispose();
    super.dispose();
  }

  /// Öffnet das Bottom Sheet für ausstehende Änderungen.
  void _showPendingChanges() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          constraints: const BoxConstraints(maxHeight: 414),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(54)),
          ),
          child: const PendingChanges(),
        );
      },
    );
  }

  /// Ruft die Liste der Weinsorten über die API ab.
  Future<List<Map<String, dynamic>>> _fetchWines() async {
    final apiService = Provider.of<ApiService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);
    final token = authService.authToken;
    if (token != null && token.isNotEmpty) {
      return await apiService.getAllWineTypes(token: token);
    } else {
      return [];
    }
  }

  /// Öffnet ein Bottom Sheet, in dem der Benutzer manuell einen Wein aus einer Liste auswählen kann.
  void _showManualSelectDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return FutureBuilder<List<Map<String, dynamic>>>(
          future: _fetchWines(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Fehler beim Laden der Weine',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontFamily: 'SF Pro',
                    fontSize: 16,
                  ),
                ),
              );
            }
            final wines = snapshot.data ?? [];
            return Container(
              constraints: const BoxConstraints(maxHeight: 414),
              padding: const EdgeInsets.only(top: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(54)),
              ),
              child: ListView.separated(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                itemCount: wines.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final wine = wines[index];
                  final wineName = wine['name'] ?? 'Unbekannter Wein';
                  return ListTile(
                    title: Text(wineName,
                        style: const TextStyle(fontFamily: 'SF Pro')),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/entryDetails',
                          arguments: wine['id'].toString());
                    },
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final dbService = Provider.of<DatabaseService>(context, listen: false);

    return Scaffold(
      key: _scaffoldKey,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const SizedBox(width: 64), // Linker Abstand
            Text(
              'Startseite',
              style: TextStyle(
                color: Colors.white,
                fontFeatures: const [
                  FontFeature.disable('liga'),
                  FontFeature.disable('clig'),
                ],
                fontFamily: 'SF Pro',
                fontSize: 28,
                fontStyle: FontStyle.normal,
                fontWeight: FontWeight.w400,
                height: 34 / 28,
                letterSpacing: 0.38,
              ),
            ),
            // Abzeichen für ausstehende Änderungen.
            StreamBuilder<int>(
              stream: dbService.pendingOperationsStream,
              initialData: 0,
              builder: (context, snapshot) {
                final count = snapshot.data ?? 0;
                return count > 0
                    ? Padding(
                        padding: const EdgeInsets.only(right: 32),
                        child: GestureDetector(
                          onTap: _showPendingChanges,
                          child: Stack(
                            children: [
                              Icon(
                                FontAwesomeIcons.arrowsRotate,
                                size: 32,
                                color: theme.colorScheme.error,
                              ),
                              Positioned(
                                right: 0,
                                child: CircleAvatar(
                                  radius: 8,
                                  backgroundColor: theme.colorScheme.onError,
                                  child: Text(
                                    '$count',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: theme.colorScheme.error,
                                      fontFamily: 'SF Pro',
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : const SizedBox(width: 64);
              },
            ),
          ],
        ),
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            SizedBox(
              height: 100,
              child: DrawerHeader(
                margin: EdgeInsets.zero,
                padding: EdgeInsets.zero,
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey[800] : AppColors.red,
                ),
                child: Center(
                  child: Text(
                    _randomGreeting,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: theme.colorScheme.onSurface,
                      fontFamily: 'SF Pro',
                      fontSize: 24,
                    ),
                  ),
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.settings, color: theme.colorScheme.onSurface),
              title: const Text('Einstellungen',
                  style: TextStyle(fontFamily: 'SF Pro')),
              onTap: () => Navigator.pushNamed(context, '/settings'),
            ),
            ListTile(
              leading: FaIcon(FontAwesomeIcons.cloud,
                  color: theme.colorScheme.onSurface),
              title: const Text('Web-Oberfläche',
                  style: TextStyle(fontFamily: 'SF Pro')),
              onTap: () => Navigator.pushNamed(context, '/webui'),
            ),
            ListTile(
              leading: Icon(Icons.history, color: theme.colorScheme.onSurface),
              title:
                  const Text('Verlauf', style: TextStyle(fontFamily: 'SF Pro')),
              onTap: () => Navigator.pushNamed(context, '/history'),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          // Hintergrundbild.
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/background/weinkeller.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Dunkle Überlagerung im Dunkelmodus.
          if (isDarkMode)
            Container(
              color: Color.alphaBlend(
                Colors.black.withAlpha(80),
                Colors.transparent,
              ),
            ),
          // Falls ein Fehler vorliegt, wird ein zentrierter Button mit Fehlermeldung zur manuellen Auswahl angezeigt.
          if (_errorMessage != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _errorMessage!,
                      style: const TextStyle(
                        fontFamily: 'SF Pro',
                        fontSize: 16,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _showManualSelectDialog,
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          backgroundColor: const Color(0xFFEFEFF0),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 15,
                            fontFamily: 'SF Pro',
                            fontStyle: FontStyle.normal,
                            fontWeight: FontWeight.w400,
                            height: 1.333,
                            letterSpacing: -0.23,
                          ),
                        ),
                        child: Text(
                          'Manuell auswählen',
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontFamily: 'SF Pro',
                            fontSize: 15,
                            fontStyle: FontStyle.normal,
                            fontWeight: FontWeight.w400,
                            height: 1.333,
                            letterSpacing: -0.23,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            // Zeigt den QRView an, falls kein Fehler vorliegt.
            QRView(
              key: _qrKey,
              onQRViewCreated: (QRViewController controller) {
                _qrController = controller;
                controller.scannedDataStream.listen((scanData) {
                  if (scanData.code != null && _scannedCode != scanData.code) {
                    setState(() {
                      _scannedCode = scanData.code;
                    });
                    Navigator.pushNamed(context, '/entryDetails',
                        arguments: scanData.code);
                  }
                });
              },
              onPermissionSet: (ctrl, isGranted) {
                if (!isGranted) {
                  setState(() {
                    _errorMessage = 'Kamerazugriff verweigert.';
                  });
                }
              },
            ),
          // Untere Navigationsleiste.
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SizedBox(
              height: 100,
              child: ClipRect(
                child: Container(
                  color: const Color(0xCC000000),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.menu,
                            size: 30, color: Colors.white),
                        onPressed: () =>
                            _scaffoldKey.currentState?.openDrawer(),
                        tooltip: 'Menü öffnen',
                      ),
                      ElevatedButton(
                        onPressed: _showManualSelectDialog,
                        style: ElevatedButton.styleFrom(
                          shape: const CircleBorder(),
                          padding: const EdgeInsets.all(18),
                          backgroundColor: Colors.white,
                          elevation: 0,
                        ),
                        child: const Icon(
                          FontAwesomeIcons.qrcode,
                          size: 40,
                          color: Colors.black,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.person,
                            size: 30, color: Colors.white),
                        onPressed: () =>
                            Navigator.pushNamed(context, '/account'),
                        tooltip: 'Konto öffnen',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
