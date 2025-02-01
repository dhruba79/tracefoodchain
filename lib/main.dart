//! Generate new localisation: flutter gen-l10n

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_preview/device_preview.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:trace_foodchain_app/firebase_options.dart';
import 'package:trace_foodchain_app/providers/app_state.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:camera/camera.dart';
// import 'package:nfc_manager/nfc_manager.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:trace_foodchain_app/repositories/initial_data.dart';
import 'package:trace_foodchain_app/screens/splash_screen.dart';
import 'package:trace_foodchain_app/services/cloud_sync_service.dart';
// import 'package:trace_foodchain_app/services/cloud_sync_service.dart';
import 'package:trace_foodchain_app/services/open_ral_service.dart';
import 'package:trace_foodchain_app/helpers/key_management.dart';
// import 'dart:html' as html;

late Box<Map<dynamic, dynamic>> localStorage;
late Box<Map<dynamic, dynamic>> openRALTemplates;
late Map<String, Map<String, dynamic>> cloudConnectors;
Map<String, dynamic>? appUserDoc;
ValueNotifier<bool> repaintContainerList = ValueNotifier<bool>(false);
ValueNotifier<bool> rebuildSpeedDial = ValueNotifier<bool>(false);

List<Map<String, dynamic>> inbox = [];
ValueNotifier<int> inboxCount = ValueNotifier<int>(0);

bool batchSalePossible = false;
CloudSyncService cloudSyncService = CloudSyncService('permarobotics.com');
late KeyManager keyManager;

ThemeData customTheme = ThemeData(
  useMaterial3: true,
  visualDensity: VisualDensity.adaptivePlatformDensity,

  //* TEXT
  textTheme: Typography.englishLike2018.apply(fontSizeFactor: 1),
  //  const TextTheme(//
  //   displayLarge: TextStyle(
  //       fontSize: 72.0, fontWeight: FontWeight.bold, color: Colors.black),
  //   titleLarge: TextStyle(
  //       fontSize: 36.0, fontStyle: FontStyle.italic, color: Colors.black),
  //   bodyMedium: TextStyle(fontSize: 14.0, color: Colors.black),
  //   labelLarge: TextStyle(color: Colors.white),
  //   labelMedium: TextStyle(color: Colors.black),
  //   labelSmall: TextStyle(color: Colors.black),
  // ),
  textSelectionTheme: const TextSelectionThemeData(
    cursorColor: Color(0xFF35DB00),
    selectionColor: Color(0xFF35DB00),
    selectionHandleColor: Color(0xFF35DB00),
  ),

  //* CHECKBOX

  checkboxTheme: CheckboxThemeData(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(5.0),
    ),
    fillColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return const Color(0xFF35DB00); // Farbe wenn ausgewählt
      }
      return Colors.grey; // Farbe wenn nicht ausgewählt
    }),
    checkColor: WidgetStateProperty.all(Colors.white),
  ),

  //* APPBAR
  appBarTheme: const AppBarTheme(
    surfaceTintColor: Colors.white,

    elevation: 0.0, // Shadow the AppBar casts
    iconTheme:
        IconThemeData(color: Colors.black54), // Color of icons in the AppBar
  ),

  //* SWITCH
  switchTheme: SwitchThemeData(
    trackOutlineColor: WidgetStateProperty.resolveWith<Color>(
      (Set<WidgetState> states) {
        if (states.contains(WidgetState.disabled)) {
          return Colors
              .white; // Farbe der Umrandung, wenn der Schalter deaktiviert ist
        }
        if (states.contains(WidgetState.selected)) {
          return const Color(
              0xFF35DB00); //  Farbe der Umrandung, wenn der Schalter aktiviert ist
        }
        return Colors.white; // Standardfarbe  Farbe der Umrandung
      },
    ),
    thumbColor: WidgetStateProperty.resolveWith<Color>(
      (Set<WidgetState> states) {
        if (states.contains(WidgetState.disabled)) {
          return Colors
              .grey; // Farbe des Schaltknopfes, wenn der Schalter deaktiviert ist
        }
        if (states.contains(WidgetState.selected)) {
          return const Color(
              0xFF35DB00); // Farbe des Schaltknopfes, wenn der Schalter aktiviert ist
        }
        return Colors.white; // Standardfarbe des Schaltknopfes
      },
    ),
    trackColor: WidgetStateProperty.resolveWith<Color>(
      (Set<WidgetState> states) {
        if (states.contains(WidgetState.disabled)) {
          return Colors.black26;
          // Color.fromARGB(94, 55, 219,
          //     0); // Farbe der Schalterspur, wenn der Schalter deaktiviert ist
        }
        if (states.contains(WidgetState.selected)) {
          return Colors
              .white; // Farbe der Schalterspur, wenn der Schalter aktiviert ist
        }
        return Colors.black26;
        // Color.fromARGB(94, 55, 219, 0); // Standardfarbe der Schalterspur
      },
    ),
  ),
  //* CARD
  cardTheme: const CardTheme(surfaceTintColor: Colors.white),

  colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.white,
      primary: const Color(0xFF35DB00), // Color for active step
      onPrimary: Colors.white, // Text color for active step
      secondary: Colors.grey),
  primaryColor: const Color(0xFF35DB00),

  cardColor: Colors.white,
  scaffoldBackgroundColor: Colors.white,
  //* BUTTONS
  buttonTheme: const ButtonThemeData(
    hoverColor: Colors.white24,
    buttonColor: Color(0xFF35DB00), // Background color (blue in this case)
    textTheme: ButtonTextTheme
        .primary, // Use the primary color for text (white by default)
  ),
  // Style for text in buttons

  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ButtonStyle(
      backgroundColor: WidgetStateProperty.resolveWith<Color>(
        (Set<WidgetState> states) {
          if (states.contains(WidgetState.hovered)) {
            return const Color(0xFF35DB00); // Color when hovered
          }
          return const Color(0xFF35DB00); // Default color
        },
      ),
      // Set the foreground color (text color)
      foregroundColor: WidgetStateProperty.resolveWith<Color>(
        (Set<WidgetState> states) {
          if (states.contains(WidgetState.hovered)) {
            return Colors.white; // Color when hovered
          }
          return Colors.white; // Default color
        },
      ),
      // Set the overlay color (hover color)
      overlayColor: WidgetStateProperty.resolveWith<Color>(
        (Set<WidgetState> states) {
          if (states.contains(WidgetState.hovered)) {
            return const Color(0xFF35DB00).withAlpha(124); // Hover color
          }
          return Colors.transparent; // Default (no color)
        },
      ),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: ButtonStyle(
      // Set the foreground color (text color)
      foregroundColor: WidgetStateProperty.resolveWith<Color>(
        (Set<WidgetState> states) {
          if (states.contains(WidgetState.hovered)) {
            return Colors.black; // Color when hovered
          }
          return Colors.black87; // Default color
        },
      ),
      // Set the overlay color (hover color)
      overlayColor: WidgetStateProperty.resolveWith<Color>(
        (Set<WidgetState> states) {
          if (states.contains(WidgetState.hovered)) {
            return Colors.black12; // Hover color
          }
          return Colors.transparent; // Default (no color)
        },
      ),
    ),
  ),
);

extension CustomColorScheme on ColorScheme {
  // Tertiary Scheme
  Color get primary1 => const Color(0xFFFF8118);
  Color get primary2 => const Color(0xFFFF8118);
  Color get primary3 => const Color(0xFFAA6C39);
  Color get primary4 => const Color(0xFF513E2E);
  Color get primary5 => const Color(0xFF42372D);

  Color get secondary1_1 => const Color(0xFF191B18);
  Color get secondary1_2 => const Color(0xFF42563C);
  Color get secondary1_3 => const Color(0xFF479030);
  Color get secondary1_4 => const Color(0xFF31CA00);
  Color get secondary1_5 => const Color(0xFF35DB00);

  Color get secondary2_1 => const Color(0xFF6A000F);
  Color get secondary2_2 => const Color(0xFF860819);
  Color get secondary2_3 => const Color(0xFFA23645);
  Color get secondary2_4 => const Color(0xFFBE747E);
  Color get secondary2_5 => const Color(0xFFDAC1C4);

  Color get complement1 => const Color(0xFF19C4C4);
  Color get complement2 => const Color(0xFF208A8A);
  Color get complement3 => const Color(0xFF226666);
  Color get complement4 => const Color(0xFF1D4242);
  Color get complement5 => const Color(0xFF101E1E);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // Initialize Firestore
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
  );

  await Hive.initFlutter();

  //*Start accessing local data storage
  localStorage = await Hive.openBox<Map<dynamic, dynamic>>(
      'localStorage'); //ToDo: 1 Hive DB per logged-in user
  // await localStorage.deleteFromDisk(); //DEBUG: DELETE DATABASE

  //*Start accessing local template storage
  openRALTemplates =
      await Hive.openBox<Map<dynamic, dynamic>>('openRALTemplates');
  // await openRALTemplates.deleteFromDisk(); //DEBUG: DELETE TEMPLATE DATABASE

  //FIRST-EVER STARTUP OF APP: Add initial templates if they are not in the local database
  for (final ot in initialTemplates) {
    //add inital templates from static storage to hive if not in local database
    if (!openRALTemplates.containsKey(ot["template"]["RALType"])) {
      Map<String, dynamic> mot = Map.from(ot);
      openRALTemplates.put(ot["template"]["RALType"], mot);
    }
  }

  cloudConnectors =
      getCloudConnectors(); //get available cloudConnectors to talk to clouds if available from localStorage

  final appState = AppState();
  await appState.initializeApp(); // Initialize locale
  await _initializeAppState(appState);

  runApp(
    ChangeNotifierProvider.value(
      value: appState,
      child: DevicePreview(
        enabled: !kReleaseMode,
        builder: (context) => MyApp(), // Wrap your app
      ),
    ),
  );
}

Future<void> _initializeAppState(AppState appState) async {
  keyManager = KeyManager();
  
  // Check if private key exists, if not generate new keypair
  final privateKey = await keyManager.getPrivateKey();
  if (privateKey == null) {
    debugPrint("No private key found - generating new keypair...");
    final success = await keyManager.generateAndStoreKeys();
    if (!success) {
      debugPrint("WARNING: Failed to initialize key management!");
      // Hier könnte man dem Benutzer eine Warnung anzeigen
      // oder die App in einen eingeschränkten Modus versetzen
    }
  } else {
    debugPrint("Found existing private key");
  }

  // Check internet connectivity at startup
  debugPrint("checking connectivity on startup...");
  var connectivityResult = await (Connectivity().checkConnectivity());
  bool cr = false;
  debugPrint("inital connection state is $cr");
  appState.setConnected(connectivityResult != [ConnectivityResult.none]);

  // Start the connectivity listener to see changes in connectivity
  debugPrint("starting connectivity listener...");
  appState.startConnectivityListener();

  // Check camera availability
  // String userAgent = html.window.navigator.userAgent.toLowerCase();

  debugPrint("checking camera availability...");
  try {
    if (1 == 1) {
      // if (!userAgent.contains('macintosh')) {
      final cameras = await availableCameras();
      debugPrint("camera state is ${cameras.isNotEmpty}");
      appState.setHasCamera(cameras.isNotEmpty);
    } else {
      appState.setHasCamera(false);
      debugPrint("!!! camera access is not yet working on browser on Mac!");
//! Does not work in Flutter Web on MacOS!
    }
  } catch (_) {
    appState.setHasCamera(false);
  }

  // Check NFC availability
  debugPrint("checking nfc availability...");
  bool hasNFC = false;
  NFCAvailability availability = await FlutterNfcKit.nfcAvailability;
  try {
    if (availability == NFCAvailability.available) {
      hasNFC = true;
      debugPrint("NFC available");
    } else {
      hasNFC = false;
      debugPrint("NFC not available");
    }
  } catch (e) {
    debugPrint("error checking for nfc");
    hasNFC = false;
  }

  appState.setHasNFC(hasNFC);

  // Check GPS availability
  debugPrint("checking geolocator availability");
  bool hasGPS = await Geolocator.isLocationServiceEnabled();
  debugPrint("geolocator state is $hasGPS");
  appState.setHasGPS(hasGPS);
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(builder: (context, appState, _) {
      return MaterialApp(

          // locale: DevicePreview.locale(context),
          locale: appState
              .locale, // Re-enable this line to use the locale from the appState
          builder: DevicePreview.appBuilder,
          debugShowCheckedModeBanner: false,
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en', ''), // English
            Locale('es', ''), // Spanish
            Locale('de', ''), // German
            Locale('fr', ''), // French
          ],
          title: 'TraceFoodChain App',
          theme: customTheme,
          home: const SplashScreen());
    });
  }
}
