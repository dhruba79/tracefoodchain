import 'dart:ui';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:trace_foodchain_app/main.dart';



class AppState extends ChangeNotifier {
  String? _userRole;
  String? _userId;
  bool _isConnected = false;
  bool _isAuthenticated = false;
  bool _isEmailVerified = false;
  bool _hasCamera = false;
  bool _hasNFC = false;
  bool _hasGPS = false;

  String? get userRole => _userRole;
  String? get userId => _userId;
  bool get isConnected => _isConnected;
  bool get isAuthenticated => _isAuthenticated;
  bool get isEmailVerified => _isEmailVerified;
  bool get hasCamera => _hasCamera;
  bool get hasNFC => _hasNFC;
  bool get hasGPS => _hasGPS;

  Locale _locale = Locale('en');

  Locale get locale => _locale;

  void setLocale(Locale newLocale) {
    if (_locale != newLocale) {
      _locale = newLocale;
      notifyListeners();
    }
  }

  Future<void> initializeApp() async {
    notifyListeners();
  }

  void setAuthenticated(bool value) {
    _isAuthenticated = value;
    notifyListeners();
  }

  void setEmailVerified(bool value) {
    _isEmailVerified = value;
    notifyListeners();
  }

  Future<void> setUserRole(String role) async {
    _userRole = role;
    notifyListeners();
  }

  void setUserId(String id) {
    _userId = id;
    notifyListeners();
  }

  void setConnected(bool connected) {
    if (_isConnected != connected) {
      _isConnected = connected;
      notifyListeners();
    }
  }

  void startConnectivityListener() {
    Connectivity().onConnectivityChanged.listen((dynamic result) {
      if (result is List<ConnectivityResult>) {
        _updateConnectionStatus(result);
      } else if (result is ConnectivityResult) {
        _updateConnectionStatus([result]);
      } else {
        print('Unexpected connectivity result type: ${result.runtimeType}');
        setConnected(false);
      }
    });
  }

  void _updateConnectionStatus(List<ConnectivityResult> results) {
    if (results.isEmpty) {
      setConnected(false);
    } else {
      // Consider the device connected if any result is not 'none'
      bool oldConnectionState = _isConnected;

      bool hasConnection =
          results.any((result) => result != ConnectivityResult.none);
      setConnected(hasConnection);
      if ((oldConnectionState == false) && (hasConnection == true)) {
        debugPrint(
            "connection state has changed to online - trying to sync to cloud");
        //If state changes from offline to online, sync data to cloud!

        for (final cloudKey in cloudConnectors.keys) {
          if (cloudKey != "open-ral.io") {
            debugPrint("syncing ${cloudKey}");
            cloudSyncService!.syncObjectsAndMethods(cloudKey);
          }
        }
      }
    }
  }

  // void setConnected(bool connected) {
  //   _isConnected = connected;
  //   notifyListeners();
  // }

  Future<void> checkAuthStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final String? userId = prefs.getString('userId');
    if (userId != null) {
      _isAuthenticated = true;
      _isEmailVerified =
          await FirebaseAuth.instance.currentUser?.emailVerified ?? false;
    }
    notifyListeners();
  }

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userId');
    _isAuthenticated = false;
    _isEmailVerified = false;
    notifyListeners();
  }

  void setHasCamera(bool hasCamera) {
    _hasCamera = hasCamera;
    notifyListeners();
  }

  void setHasNFC(bool hasNFC) {
    _hasNFC = hasNFC;
    notifyListeners();
  }

  void setHasGPS(bool hasGPS) {
    //ToDo: make work
    _hasGPS = hasGPS;
    notifyListeners();
  }
}
