import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import 'package:trace_foodchain_app/main.dart';
import 'package:trace_foodchain_app/services/asset_registry_api_service.dart';
import 'package:trace_foodchain_app/services/user_registry_api_service.dart';
import 'package:trace_foodchain_app/services/open_ral_service.dart';
import 'package:trace_foodchain_app/screens/settings_screen.dart';

class FieldRegistryScreen extends StatefulWidget {
  const FieldRegistryScreen({super.key});

  @override
  State<FieldRegistryScreen> createState() => _FieldRegistryScreenState();
}

class _FieldRegistryScreenState extends State<FieldRegistryScreen> {
  List<Map<String, dynamic>> registeredFields = [];
  bool isLoading = false;
  bool isRegistering = false;

  /// Prüft, ob alle erforderlichen globalen Variablen initialisiert sind
  bool _isAppFullyInitialized() {
    try {
      // Prüfe localStorage
      if (!localStorage.isOpen) {
        debugPrint('localStorage is not open');
        return false;
      }

      // Prüfe ob localStorage tatsächlich funktioniert
      localStorage.values.length; // Test access

      // Weitere Prüfungen können hier hinzugefügt werden
      return true;
    } catch (e) {
      debugPrint('Error checking app initialization: $e');
      return false;
    }
  }

  /// Wartet auf die vollständige Initialisierung der App mit Timeout
  Future<bool> _waitForAppInitialization(
      {Duration timeout = const Duration(seconds: 10)}) async {
    final stopwatch = Stopwatch()..start();

    while (stopwatch.elapsed < timeout) {
      if (_isAppFullyInitialized()) {
        return true;
      }

      // Warte 100ms bevor nächster Check
      await Future.delayed(const Duration(milliseconds: 100));
    }

    return false;
  }

  @override
  void initState() {
    super.initState();
    _loadRegisteredFields();
  }

  Future<void> _loadRegisteredFields() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Lade registrierte Felder aus der lokalen OpenRAL-Datenbank
      final fields = await _getFieldsFromLocalDatabase();
      setState(() {
        registeredFields = fields;
      });
    } catch (e) {
      debugPrint('Error loading fields: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<List<Map<String, dynamic>>> _getFieldsFromLocalDatabase() async {
    final List<Map<String, dynamic>> fields = [];

    try {
      // Verwende getMyObjectsStream aus open_ral_service
      final streamSubscription = getMyObjectsStream().listen((querySnapshot) {
        fields.clear(); // Lösche vorherige Einträge

        for (final doc in querySnapshot.docs) {
          final fieldData = doc.data() as Map<String, dynamic>;

          // Filtere nur "field" Objekte
          if (fieldData['template']?["RALType"] != "field") {
            continue;
          }

          // Prüfe ob es sich um ein testmode-Objekt handelt, wenn wir nicht im Testmodus sind
          if (!isTestmode &&
              fieldData.containsKey("isTestmode") &&
              fieldData["isTestmode"] == true) {
            continue;
          }
          if (isTestmode && !fieldData.containsKey("isTestmode")) {
            continue;
          }

          // Extrahiere relevante Informationen
          final String fieldName =
              fieldData["identity"]?["name"] ?? "Unbenanntes Feld";
          final String fieldUID = fieldData["identity"]?["UID"] ?? "";
          String geoId = "";

          // Versuche geoID aus alternateIDs zu extrahieren
          if (fieldData["identity"]?["alternateIDs"] != null) {
            for (final altId in fieldData["identity"]["alternateIDs"]) {
              if (altId["issuedBy"] == "Asset Registry") {
                geoId = altId["UID"];
                break;
              }
            }
          }

          // Extrahiere Fläche
          String area =
              getSpecificPropertyfromJSON(fieldData, "area")?.toString() ?? "";

          fields.add({
            "name": fieldName,
            "uid": fieldUID,
            "geoId": geoId,
            "area": area,
          });
        }
      });

      // Warte kurz auf die ersten Daten und schließe dann den Stream
      await Future.delayed(const Duration(seconds: 2));
      await streamSubscription.cancel();
    } catch (e) {
      debugPrint('Error getting fields from stream: $e');
    }
    return fields;
  }

  Future<void> _uploadCsvFile() async {
    final l10n = AppLocalizations.of(context)!;

    try {
      debugPrint("Uploading CSV file...");
      FilePickerResult? result = await FilePicker.platform
          .pickFiles(withReadStream: true, allowMultiple: false);

      if (result != null) {
        String csvContent = "";

        if (kIsWeb) {
          debugPrint("Reading CSV file in web...");
          for (PlatformFile file in result.files) {
            csvContent = "";
            await file.readStream
                ?.transform(utf8.decoder)
                .listen((chunk) {
                  csvContent += chunk;
                })
                .asFuture()
                .then((value) async {
                  await _processCsvData(csvContent);
                });
            // csvContent = String.fromCharCodes(result.files.single.bytes!);
          }
        } else {
          // Für mobile Plattformen
          File file = File(result.files.single.path!);
          csvContent = await file.readAsString();
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${l10n.csvUploadError}: $e')),
      );
    }
  }

  /// Konvertiert Koordinaten vom CSV-Format in WKT-Format
  String _convertCoordinatesToWKT(String csvCoordinates) {
    try {
      // Entferne Leerzeichen und teile bei Semikolon
      final coordinatePairs = csvCoordinates.trim().split(';');

      List<String> wktCoordinates = [];

      for (String pair in coordinatePairs) {
        // Entferne eckige Klammern und teile bei Komma
        final cleanPair = pair.replaceAll('[', '').replaceAll(']', '').trim();
        final coords = cleanPair.split(',');

        if (coords.length == 2) {
          final lon = coords[0].trim();
          final lat = coords[1].trim();
          // WKT Format: lon lat (mit Leerzeichen, nicht Komma)
          wktCoordinates.add('$lon $lat');
        }
      }

      if (wktCoordinates.isNotEmpty) {
        // Stelle sicher, dass das Polygon geschlossen ist
        if (wktCoordinates.first != wktCoordinates.last) {
          wktCoordinates.add(wktCoordinates.first);
        }

        return 'POLYGON ((${wktCoordinates.join(', ')}))';
      }
    } catch (e) {
      debugPrint('Error converting coordinates: $e');
    }

    // Fallback: Gib die ursprünglichen Koordinaten zurück
    return csvCoordinates;
  }

  Future<void> _processCsvData(String csvContent) async {
    final l10n = AppLocalizations.of(context)!;

    setState(() {
      isRegistering = true;
    });

    try {
      List<List<dynamic>> csvData =
          const CsvToListConverter().convert(csvContent);

      if (csvData.isEmpty) {
        throw Exception(l10n.invalidCsvFormat);
      }

      int successCount = 0;
      int errorCount = 0;
      List<String> errors = [];

      for (int i = 1; i < csvData.length; i++) {
        //Skip header row
        final row = csvData[i];

        // Erwarte mindestens 3 Spalten: Name, Beschreibung, Koordinaten
        if (row.length < 3) {
          errors.add('Zeile ${i + 1}: ${l10n.invalidCsvFormat}');
          errorCount++;
          continue;
        }
        final String registrar = row[0]?.toString().trim() ?? '';
        final String fieldNameDNI = row[1]?.toString().trim() ?? '';
        //Intermediary
        //Municipality
        //Community
        //Logo
        final String coordinatesRaw = row[6]?.toString().trim() ?? '';

        // Konvertiere Koordinaten vom CSV-Format zu WKT-Format
        final String coordinates = _convertCoordinatesToWKT(coordinatesRaw);

        if (fieldNameDNI.isEmpty || coordinatesRaw.isEmpty) {
          errors.add('Line ${i + 1}: Name and coordinates are required');
          errorCount++;
          continue;
        }

        try {
          await _registerSingleField(fieldNameDNI, coordinates);
          successCount++;
        } catch (e) {
          errors.add('Line ${i + 1}: Registration error - $e');
          errorCount++;
        }
      }

      // Zeige Ergebnisse
      String message = '$successCount fields successfully registered';
      if (errorCount > 0) {
        message += ', $errorCount errors';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 3),
        ),
      );

      if (errors.isNotEmpty && errors.length <= 5) {
        // Zeige erste paar Fehler
        _showErrorDialog(errors.take(5).join('\n'));
      }

      // Aktualisiere die Liste
      await _loadRegisteredFields();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${l10n.csvUploadError}: $e')),
      );
    } finally {
      setState(() {
        isRegistering = false;
      });
    }
  }

  Future<void> _registerSingleField(
      String fieldName, String coordinates) async {
    // Sicherheitsprüfungen für globale Variablen
    if (!localStorage.isOpen) {
      throw Exception('localStorage ist nicht initialisiert');
    }

    UserRegistryService? userRegistryService;
    try {
      // Schritt 1: Asset Registry Services initialisieren (basierend auf settings_screen.dart Code)
      userRegistryService = UserRegistryService();
      await userRegistryService.initialize();

      // Anmeldedaten aus der .env-Datei lesen
      final userEmail = dotenv.env['USER_REGISTRY_EMAIL'] ?? '';
      final userPassword = dotenv.env['USER_REGISTRY_PASSWORD'] ?? '';

      if (userEmail.isEmpty || userPassword.isEmpty) {
        throw Exception('User Registry credentials not configured in .env file');
      }

      // Anmelden mit User Registry
      final loginSuccess = await userRegistryService.login(
        email: userEmail,
        password: userPassword,
      );

      if (!loginSuccess) {
        throw Exception('User Registry Login fehlgeschlagen');
      }

      // Asset Registry Service erstellen
      final assetRegistryService = await AssetRegistryService.withUserRegistry(
        userRegistryService: userRegistryService,
      ); // Schritt 2: Feld bei Asset Registry registrieren
      final registerResponse = await assetRegistryService.registerFieldBoundary(
        s2Index:
            '8, 13', // Beispiel S2 Index, könnte aus Koordinaten berechnet werden
        wkt:
            coordinates, // Erwartet WKT-Format für Polygon (z.B. POLYGON ((-93.69805256358295 41.9757745318825, -93.69249086165937 41.97576056598778, -93.69245431117128 41.96883250535657, -93.69804142643369 41.97220658289061, -93.69805256358295 41.9757745318825)))
      );

      String? geoId;

      if (registerResponse.statusCode == 200) {
        // Erfolgreiche Registrierung
        debugPrint('New field successfully registered: ${registerResponse.body}');
        try {
          final responseData =
              jsonDecode(registerResponse.body) as Map<String, dynamic>;
          geoId = responseData['geoid'] as String?;
        } catch (e) {
          throw Exception('Could not extract geoID from response: $e');
            //ToDo In case we get no geoID back, something went wrong and we need to display this!
        }
      } else if (registerResponse.statusCode == 400) {
        // Feld existiert bereits
        try {
          debugPrint('Field already exists, trying to extract geoID...');
          final responseData =
              jsonDecode(registerResponse.body) as Map<String, dynamic>;
          debugPrint(registerResponse.body);
          final matchedGeoIds =
              responseData['matched geo ids'] as List<dynamic>?;
          if (matchedGeoIds != null && matchedGeoIds.isNotEmpty) {
            geoId = matchedGeoIds.first as String;
          }
        } catch (e) {
          throw Exception(
              'Field already exists, but could not extract geoID: $e');
                //ToDo In case we get no geoID back, something went wrong and we need to display this!
        }
      } else {
        throw Exception(
            'Asset Registry ERROR: ${registerResponse.statusCode} - ${registerResponse.body}');
            //ToDo In case we get no geoID back, something went wrong and we need to display this!  
      }
      if (geoId == null) {
        throw Exception('Keine geoID erhalten');
        //ToDo In case we get no geoID back, something went wrong and we need to display this!
      }

      // Schritt 3: Prüfen ob Feld mit dieser GeoID bereits in der zentralen Firebase-Datenbank existiert
      debugPrint(
          'Prüfe ob Feld mit GeoID $geoId bereits in Firebase existiert...');
      final existingFirebaseObjects =
          await getFirebaseObjectsByAlternateUID(geoId);

      if (existingFirebaseObjects.isNotEmpty) {
        debugPrint(
            'Feld mit GeoID $geoId existiert bereits in der zentralen Datenbank');
        //ToDo how to handle this??    
        throw Exception(
            'Feld mit GeoID $geoId ist bereits in der zentralen Datenbank registriert');
      }

      debugPrint(
          'Feld mit GeoID $geoId existiert noch nicht in der zentralen Datenbank - Fortfahren mit lokaler Registrierung');

      // Schritt 4: Prüfen ob bereits als openRAL Objekt existiert
      // HINWEIS: Dieser Code ist derzeit deaktiviert, da die OpenRAL-Integration noch nicht vollständig implementiert ist
      if (1 == 2) {
        // Zusätzliche Sicherheitsprüfungen für OpenRAL-Integration
        if (!openRALTemplates.isOpen) {
          throw Exception('openRALTemplates ist nicht initialisiert');
        }

        if (appUserDoc == null) {
          throw Exception('appUserDoc ist nicht initialisiert');
        }

        // final existingField =
        //     await getObjectOrGenerateNew(geoId, ["field"], "alternateUid");

        // if (getObjectMethodUID(existingField).isNotEmpty) {
        //   // Feld existiert bereits in der lokalen Datenbank
        //   throw Exception('Feld bereits in lokaler Datenbank vorhanden');
        // }

        // // Schritt 4: Neues openRAL Field Objekt erstellen
        // final fieldObject = await getOpenRALTemplate("field");
        // setObjectMethodUID(fieldObject, const Uuid().v4());

        // // Identity setzen
        // fieldObject["identity"]["name"] = fieldName;
        // fieldObject["identity"]["alternateIDs"] = [
        //   {"UID": geoId, "issuedBy": "Asset Registry"}
        // ];

        // // Koordinaten als spezifische Eigenschaft hinzufügen
        // setSpecificPropertyJSON(fieldObject, "coordinates", coordinates, "String");

        // // Schritt 5: generateDigitalSibling verwenden
        // final generateMethod = await getOpenRALTemplate("generateDigitalSibling");
        // setObjectMethodUID(generateMethod, const Uuid().v4());

        // // Executor setzen (aktueller Benutzer)
        // if (appUserDoc != null) {
        //   generateMethod["executor"] = appUserDoc!;
        // }
        // generateMethod["methodState"] = "finished";

        // // Objekt speichern
        // await setObjectMethod(fieldObject, false, false);

        // // Output Object zur Methode hinzufügen
        // addOutputobject(generateMethod, fieldObject, "item");

        // // Method history aktualisieren
        // await updateMethodHistoryInAllAffectedObjects(
        //   getObjectMethodUID(generateMethod),
        //   generateMethod["template"]["RALType"],
        // );

        // // Methode speichern und signieren
        // await setObjectMethod(generateMethod, true, true);
      }
    } catch (e) {
      // Fehlerbehandlung
      debugPrint('Error in _registerSingleField: $e');
      rethrow;
    } finally {
      // Abmelden (falls userRegistryService initialisiert wurde)
      if (userRegistryService != null) {
        try {
          await userRegistryService.logout();
        } catch (e) {
          debugPrint('Error during logout: $e');
        }
      }
    }
  }

  void _showErrorDialog(String errors) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Registrierungsfehler'),
        content: SingleChildScrollView(
          child: Text(errors),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.fieldRegistry),
        actions: [
          if (kIsWeb) // Nur im Web-Modus CSV-Upload anbieten
            IconButton(
              icon: const Icon(Icons.upload_file),
              onPressed: (isRegistering || !_isAppFullyInitialized())
                  ? null
                  : _uploadCsvFile,
              tooltip: l10n.uploadCsv,
            ),
        ],
      ),
      body: Column(
        children: [
          if (kIsWeb) // Info über CSV-Format nur im Web anzeigen
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.csvFormatInfo,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Beispiel:\nRegistrator,Feldname,,,,,\"[-88.364428,14.793867];[-88.364428,14.794047];[-88.364242,14.794047];[-88.364242,14.793867];[-88.364428,14.793867]\"',
                    style: TextStyle(fontFamily: 'monospace', fontSize: 12),
                  ),
                ],
              ),
            ),
          if (isRegistering) const LinearProgressIndicator(),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : registeredFields.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.agriculture,
                              size: 64,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              l10n.noFieldsRegistered,
                              style: const TextStyle(
                                fontSize: 18,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadRegisteredFields,
                        child: ListView.builder(
                          itemCount: registeredFields.length,
                          itemBuilder: (context, index) {
                            final field = registeredFields[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              child: ListTile(
                                leading: const CircleAvatar(
                                  backgroundColor: Colors.green,
                                  child: Icon(
                                    Icons.agriculture,
                                    color: Colors.white,
                                  ),
                                ),
                                title: Text(
                                  field["name"] ?? "Unbenanntes Feld",
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (field["geoId"]?.isNotEmpty == true)
                                      Text('${l10n.geoId}: ${field["geoId"]}'),
                                    if (field["area"]?.isNotEmpty == true)
                                      Text('${l10n.area}: ${field["area"]} ha'),
                                  ],
                                ),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () {
                                  // TODO: Implementiere Detailansicht für Feld
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'Felddetails noch nicht implementiert'),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: kIsWeb
          ? FloatingActionButton.extended(
              onPressed: (isRegistering || !_isAppFullyInitialized())
                  ? null
                  : _uploadCsvFile,
              icon: const Icon(Icons.upload_file),
              label: Text(l10n.uploadCsv),
            )
          : null,
    );
  }
}
