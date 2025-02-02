import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trace_foodchain_app/helpers/fade_route.dart';
import 'package:trace_foodchain_app/main.dart';
import 'package:trace_foodchain_app/providers/app_state.dart';
import 'package:trace_foodchain_app/screens/role_selection_screen.dart';
import 'package:trace_foodchain_app/screens/sign_up_screen.dart';
import 'package:trace_foodchain_app/screens/home_screen.dart';
import 'package:trace_foodchain_app/services/open_ral_service.dart';
import 'package:trace_foodchain_app/services/service_functions.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:trace_foodchain_app/widgets/data_loading_indicator.dart';
import 'package:trace_foodchain_app/widgets/status_bar.dart';
import 'package:trace_foodchain_app/constants.dart';

bool canResendEmail = true;

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _disposed = false;
  Timer? _verificationTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );
    _controller.forward();
    _initializeApp();
  }

  @override
  void dispose() {
    _disposed = true;
    _controller.dispose();
    _verificationTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    final appState = Provider.of<AppState>(context, listen: false);

    await Future.delayed(_controller.duration ?? Duration.zero);

    if (_disposed) return;

    // Check internet connectivity
    dynamic connectivityResult;
    try {
      // await (Connectivity().checkConnectivity())
      //     .then((connectivityResult) async {
      //   appState.setConnected(connectivityResult != ConnectivityResult.none);
      // Check authentication status
      await appState.checkAuthStatus().then((onValue) async {
        if (appState.isAuthenticated) {
          //* AUTHENTICATED
          if (appState.isEmailVerified) {
            //* VERIFIED
            await _navigateToNextScreen();
          } else {
            //*NOT VERIFIED
            // Show email verification overlay
            _showEmailVerificationOverlay();
          }
        } else {
          //* NOT AUTHENTICATED YET
          if (!appState.isConnected) {
            await fshowInfoDialog(context,
                "To activate the app the first time, please connect to the internet for authentication!");
            //ToDo You might want to add a retry mechanism here
            return;
          }
          Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const AuthScreen()));
        }
        // });
      });
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  void _showEmailVerificationOverlay() {
    if (_disposed) return;

    _verificationTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _checkEmailVerification();
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        final l10n = AppLocalizations.of(context)!;
        return AlertDialog(
          title: Text(l10n.emailVerification),
          content: SizedBox(
              height: 150,
              child: DataLoadingIndicator(
                  text: l10n.waitingForEmailVerification,
                  textColor: Colors.black54,
                  spinnerColor: const Color(0xFF35DB00))),
          actions: <Widget>[
            if (canResendEmail)
              TextButton(
                child: Text(l10n.resendEmail),
                onPressed: () async {
                  await sendVerificationEmail();
                },
              ),
            TextButton(
              child: Text(l10n.signOut),
              onPressed: () async {
                _signOut();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _signOut() async {
    _verificationTimer?.cancel();
    await FirebaseAuth.instance.signOut();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userId');

    final appState = Provider.of<AppState>(context, listen: false);
    appState.setAuthenticated(false);
    appState.setEmailVerified(false);

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const AuthScreen()),
      (Route<dynamic> route) => false,
    );
  }

  Future<void> _checkEmailVerification() async {
    if (_disposed) return;

    await FirebaseAuth.instance.currentUser?.reload();
    if (FirebaseAuth.instance.currentUser?.emailVerified ?? false) {
      _verificationTimer?.cancel();
      Navigator.of(context).pop(); // Close the dialog
      await _navigateToNextScreen();
    }
  }

  Future sendVerificationEmail() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final user = FirebaseAuth.instance.currentUser!;
      await user.sendEmailVerification();
      setState(() {
        canResendEmail = false;
      });
      await Future.delayed(const Duration(seconds: 5));
      setState(() {
        canResendEmail = true;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(l10n.errorSendingEmailWithError + " " + e.toString())));
    }
  }

  Future<void> _navigateToNextScreen() async {
// At this stage, we have to sync first with the cloud, e.g. to download an existing user doc!

    final appState = Provider.of<AppState>(context, listen: false);

    if (appState.isConnected) {
      //ToDo: Display screenblocker "syncing data with cloud - please wait"
      // openRAL: Update Templates
      debugPrint("syncing openRAL");
      await cloudSyncService.syncOpenRALTemplates('open-ral.io');

      // sync all non-open-ral methods with it's clouds on startup
      for (final cloudKey in cloudConnectors.keys) {
        if (cloudKey != "open-ral.io") {
          debugPrint("syncing $cloudKey");
          await cloudSyncService.syncMethods(cloudKey);
        }
      }
      cloudConnectors =
          getCloudConnectors(); //refresh cloud connectors (if updates where downloaded)
    }

    for (var doc in localStorage.values) {
      if (doc['template'] != null && doc['template']["RALType"] == "human") {
        final doc2 = Map<String, dynamic>.from(doc);

        if (getObjectMethodUID(doc2) ==
            FirebaseAuth.instance.currentUser!.uid) {
          appUserDoc = doc2;
          break;
        }
      }
    }

    if (appUserDoc == null) {
      //User profile does not yet exist
      debugPrint(
          "user profile not found in local database - creating new one...");
      Map<String, dynamic> newUser = await getOpenRALTemplate("human");
      newUser["identity"]["UID"] = FirebaseAuth.instance.currentUser?.uid;
      setSpecificPropertyJSON(
          newUser, "email", FirebaseAuth.instance.currentUser?.email, "String");
      newUser["email"] = FirebaseAuth.instance.currentUser
          ?.email; // Necessary to find the user later by email!
      newUser = await setObjectMethod(newUser,false, true);
      appUserDoc = await getObjectMethod(getObjectMethodUID(newUser));
    } else {
      //User mit dieser deviceId schon vorhanden.
      debugPrint("user profile found in local database");
    }
    //Schaun ob user role vorhanden ist
    //! atm we skip role selection - everybody can do everything
    //! Role is set to trader for all users
    // final userRole = getSpecificPropertyfromJSON(appUserDoc!, "userRole");
    // if (userRole != "" && userRole != "-no data found-") {
    appState.setUserRole("Trader");
    // }

    if (appState.userRole == null) {
      //! atm we skip role selection - everybody can do everything
      //! Role is set to trader for all users
      // Navigator.of(context).pushReplacement(
      //   FadeRoute(builder: (_) => const
      // RoleSelectionScreen()),
      // );
      final appState = Provider.of<AppState>(context, listen: false);
      appState.setUserRole('Trader');
      appUserDoc = await getObjectMethod(getObjectMethodUID(appUserDoc!));
      appUserDoc =
          setSpecificPropertyJSON(appUserDoc!, "userRole", 'Trader', "String");
      appUserDoc = await setObjectMethod(appUserDoc!,false, true);
    }
    // Check if private key exists, if not generate new keypair
    final privateKey = await keyManager.getPrivateKey();
    if (privateKey == null) {
      debugPrint("No private key found - generating new keypair...");
      final success = await keyManager.generateAndStoreKeys();
      if (!success) {
        debugPrint("WARNING: Failed to initialize key management!");
        secureCommunicationEnabled = false;
      }
    } else {
      debugPrint("Found existing private key");
      secureCommunicationEnabled = true;
    }
    //  else {

    if (secureCommunicationEnabled == false) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          final l10n = AppLocalizations.of(context)!;
          return AlertDialog(
            title: Text(l10n.securityError),
            content: Text(l10n.securityErrorMessage),
            actions: <Widget>[
              TextButton(
                child: Text(l10n.closeApp),
                onPressed: () =>
                    Navigator.of(context).pop(() => SystemNavigator.pop()),
              ),
            ],
          );
        },
      );
    } else {
      Navigator.of(context).pushReplacement(
        FadeRoute(builder: (_) => const HomeScreen()),
      );
    }
    // }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (l10n == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: const AssetImage('assets/images/background.png'),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.white.withOpacity(0.5), // Adjust the opacity as needed
                  BlendMode.dstATop,
                ),
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FadeTransition(
                    opacity: _animation,
                    child: Image.asset(
                      'assets/images/diasca_logo.png',
                      width: 200,
                      height: 200,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    l10n.traceTheFoodchain,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'powered by openRAL by permarobotics',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text(
                      APP_VERSION,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Positioned(
            bottom: 16,
            left: 16,
            child: StatusBar(isSmallScreen: false),
          ),
        ],
      ),
    );
  }
}
