import 'package:flutter/material.dart';
import '../services/user_registry_api_service.dart';
import '../services/asset_registry_api_service.dart';

/// Ein Beispiel-Widget, das zeigt, wie man sich bei der User Registry anmeldet
/// und dann auf die Asset Registry zugreift.
class UserRegistryExample extends StatefulWidget {
  const UserRegistryExample({super.key});

  @override
  State<UserRegistryExample> createState() => _UserRegistryExampleState();
}

class _UserRegistryExampleState extends State<UserRegistryExample> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  String _statusMessage = '';
  String? _assetInfo;

  // Services
  final _userRegistryService = UserRegistryService();
  AssetRegistryService? _assetRegistryService;

  @override
  void initState() {
    super.initState();
    // Initialisiere den UserRegistryService
    _initializeUserRegistry();
  }

  Future<void> _initializeUserRegistry() async {
    setState(() => _isLoading = true);
    try {
      // Lade vorhandene Tokens
      await _userRegistryService.initialize();

      setState(() {
        _statusMessage = _userRegistryService.isLoggedIn
            ? 'Bereits angemeldet'
            : 'Nicht angemeldet';
      });

      // Wenn bereits angemeldet, initialisiere den AssetRegistryService
      if (_userRegistryService.isLoggedIn) {
        await _initializeAssetRegistry();
      }
    } catch (e) {
      setState(() => _statusMessage = 'Fehler: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _initializeAssetRegistry() async {
    try {
      _assetRegistryService = await AssetRegistryService.withUserRegistry(
        userRegistryService: _userRegistryService,
      );
      setState(() => _statusMessage = 'Asset Registry initialisiert');
    } catch (e) {
      setState(() => _statusMessage = 'Asset Registry Fehler: $e');
    }
  }

  Future<void> _login() async {
    final email = _emailController.text;
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() => _statusMessage = 'Bitte E-Mail und Passwort eingeben');
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = 'Anmeldung läuft...';
    });

    try {
      final success = await _userRegistryService.login(
        email: email,
        password: password,
      );

      setState(() {
        _statusMessage =
            success ? 'Anmeldung erfolgreich' : 'Anmeldung fehlgeschlagen';
      });

      // Nach erfolgreicher Anmeldung AssetRegistryService initialisieren
      if (success) {
        await _initializeAssetRegistry();
      }
    } catch (e) {
      setState(() => _statusMessage = 'Anmeldefehler: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _getAssetExample() async {
    if (_assetRegistryService == null) {
      setState(() => _statusMessage = 'Asset Registry nicht initialisiert');
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = 'Asset-Informationen werden abgerufen...';
    });

    try {
      // Beispiel für den Abruf von Asset-Informationen
      // Ersetze 'example_geoid' mit einer tatsächlichen Geo-ID
      final assetInfo = await _assetRegistryService!.getAsset(
        geoid: 'example_geoid',
      );

      setState(() {
        _assetInfo = 'Asset-Info: ${assetInfo.toString()}';
        _statusMessage = 'Asset-Informationen abgerufen';
      });
    } catch (e) {
      setState(() => _statusMessage = 'Asset-Abruf Fehler: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Abmeldung läuft...';
    });

    try {
      await _userRegistryService.logout();
      _assetRegistryService = null;

      setState(() {
        _statusMessage = 'Abgemeldet';
        _assetInfo = null;
      });
    } catch (e) {
      setState(() => _statusMessage = 'Abmeldefehler: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Registry Beispiel'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Status: $_statusMessage',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'E-Mail',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _passwordController,
                    decoration: const InputDecoration(
                      labelText: 'Passwort',
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _userRegistryService.isLoggedIn ? null : _login,
                    child: const Text('Anmelden'),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: _userRegistryService.isLoggedIn
                        ? _getAssetExample
                        : null,
                    child: const Text('Asset-Informationen abrufen'),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: _userRegistryService.isLoggedIn ? _logout : null,
                    child: const Text('Abmelden'),
                  ),
                  if (_assetInfo != null) ...[
                    const SizedBox(height: 20),
                    const Text(
                      'Asset-Informationen:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 5),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Text(_assetInfo!),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
