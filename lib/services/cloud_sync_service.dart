// This service syncs local hive database to/from the clouds
import 'dart:convert';
import 'dart:io';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' if (dart.library.io) 'dart:io' as html;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:trace_foodchain_app/helpers/database_helper.dart';
import 'package:trace_foodchain_app/main.dart';
import 'package:trace_foodchain_app/services/open_ral_service.dart';
import 'package:trace_foodchain_app/widgets/global_snackbar_listener.dart';
import 'package:uuid/uuid.dart';
import 'package:crypto/crypto.dart';

class CloudApiClient {
  final String domain;
  CloudApiClient({required this.domain});

  Future<bool> sendPublicKeyToFirebase(List<int> publicKeyBytes) async {
    dynamic urlString;
    try {
      urlString = getCloudConnectionProperty(
          domain, "cloudFunctionsConnector", "persistPublicKey")["url"];
    } catch (e) {
      debugPrint("Error getting cloud connection properties: $e");
      return false;
    }

    final publicKeyBase64 = base64Encode(publicKeyBytes);
    final deviceId = await getDeviceId();
    final apiKey = await FirebaseAuth.instance.currentUser?.getIdToken();

    if (urlString != null && apiKey != null) {
      try {
        final response = await http.post(
          Uri.parse(urlString),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $apiKey',
          },
          body: jsonEncode({
            'userId': FirebaseAuth.instance.currentUser?.uid,
            'publicKey': publicKeyBase64,
            'deviceId': deviceId
          }),
        );

        if (response.statusCode == 200) {
          // final responseData = jsonDecode(response.body);
          // return responseData['success'] ?? false;
          return true;
        }
      } catch (e) {
        debugPrint("Error sending public key to Firebase: $e");
        return false;
      }
    }
    return false;
  }

  Future<String> syncMethodToCloud(
      String domain, Map<String, dynamic> ralMethod) async {
    dynamic urlString;
    try {
      urlString = getCloudConnectionProperty(
          domain, "cloudFunctionsConnector", "syncMethodToCloud")["url"];
    } catch (e) {}
    final apiKey = await FirebaseAuth.instance.currentUser?.getIdToken();

    if (urlString != null && apiKey != null) {
      final response = await http.post(
        Uri.parse(urlString),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({'ralMethod': ralMethod}),
      );

      if (response.statusCode == 200) {
        // return jsonDecode(response.body);
        return "success";
      } else {
        //Response codes? 400: Bad Request, 401: Unauthorized, 403: Forbidden, 404: Not Found, 500: Internal Server Error
        //Merge Conflict: 409
        debugPrint('Failed to sync method to cloud: ${response.statusCode}');
        return "${response.statusCode}";
      }
    } else {
      // throw Exception("no valid cloud connection properties found!");
      return "no valid cloud connection properties found!";
    }
  }

  Future<List<Map<String, dynamic>>> syncObjectsMethodsFromCloud(
      String domain, Map<String, String> deviceHashes) async {
    dynamic urlString;
    try {
      urlString = getCloudConnectionProperty(domain, "cloudFunctionsConnector",
          "syncObjectsMethodsFromCloud")["url"];
    } catch (e) {
      return [];
    }
    final apiKey = await FirebaseAuth.instance.currentUser?.getIdToken();

    if (urlString != null && apiKey != null) {
      try {
        final response = await http.post(
          Uri.parse(urlString),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $apiKey',
          },
          body: jsonEncode(deviceHashes),
        );

        if (response.statusCode == 200) {
          final List<dynamic> jsonResponse = jsonDecode(response.body);
          return jsonResponse.cast<Map<String, dynamic>>();
        } else {
          debugPrint(
              'Failed to sync objects and methods from cloud: ${response.statusCode}');
          return [];
        }
      } catch (e) {
        debugPrint('Error syncing from cloud: $e');
        return [];
      }
    } else {
      throw Exception("no valid cloud connection properties found!");
    }
  }
}

class CloudSyncService {
  final CloudApiClient apiClient;
  bool _isSyncing =
      false; // Neues Flag, um parallele Sync-Aufrufe zu verhindern

  CloudSyncService(String domain) : apiClient = CloudApiClient(domain: domain);

  Future<void> syncOpenRALTemplates(String domain) async {
    for (var templateName in openRALTemplates.keys) {
      try {
        //If possible, always use the cloud versions of the templates for locale database
        // final cloudTemplate = await _apiClient.getRalObjectByUid(domain,templateName);
        // openRALTemplates.put(templateName, cloudTemplate);
      } catch (e) {
        debugPrint('Error syncing template $templateName: $e');
      }
    }
  }

//This function syncs all methods and objects to the cloud if tagged as being changed/generated locally only

  Future<void> syncMethods(String domain) async {
    if (_isSyncing) {
      debugPrint("Sync bereits aktiv, überspringe $domain");
      return;
    }
    _isSyncing = true;
    final databaseHelper = DatabaseHelper();
    try {
      //****** 1. SYNC METHODS TO CLOUD - and build hash map for later syncing from cloud *********
      List<Map<String, dynamic>> methodsToSyncToCloud = [];
      Map<String, String> deviceHashes = {};
      for (var doc in localStorage.values) {
        final doc2 = Map<String, dynamic>.from(doc);
        if (doc2["methodHistoryRef"] != null) {
          //This is an object
          if (doc2["needsSync"] != null) {
            doc2.remove(
                "needsSync"); //!need to avoid needsSync being in the Hash!
          }
          final String hash = generateStableHash(doc2);
          final String uid = getObjectMethodUID(doc2);
          deviceHashes[uid] = hash;
        } else {
          //This is a method
          if (doc2["needsSync"] != null) {
            doc2.remove(
                "needsSync"); //!need to avoid needsSync being in the Hash!
            methodsToSyncToCloud.add(doc2);
          }

          final String hash = generateStableHash(doc2);
          final String uid = getObjectMethodUID(doc2);
          deviceHashes[uid] = hash;
        }
      }
      bool syncSuccess = true;
      for (final method in methodsToSyncToCloud) {
        final doc2 = Map<String, dynamic>.from(method);
        final methodUid = getObjectMethodUID(doc2);
        try {
          final syncresult = await apiClient.syncMethodToCloud(domain, doc2);
          if (syncresult == "success") {
            setObjectMethod(doc2, false, false); //removes sync flag
            //Todo: remove sync flag from all connected objects:outputobjects
          } else {
            syncSuccess = false;
            globalSnackBarNotifier.value = {
              'type': 'error',
              'text': "error syncing to cloud",
              'errorCode': syncresult
            };
          }
        } catch (e) {
          syncSuccess = false;
          globalSnackBarNotifier.value = {
            'type': 'error',
            'text':"error syncing to cloud",
            'errorCode': "unknown error"
          };
          debugPrint('Error syncing method {$methodUid}: $e');
        }
        if (syncSuccess) {
          globalSnackBarNotifier.value = {
            'type': 'info',
            'text': 'sync to cloud successful'
          };
        }
      }

      //******* 2. SYNC METHODS AND OBJECTS FROM CLOUD - independet of new methods on device ********
      //This happens in case a user has logged into a second device (e.g., webapp on PC)
      //1. Generate a hash list from all objects and methods on the device

      //2. Get all objects and methods from the cloud that are not on the device or need to be updated
      final returnList =
          await apiClient.syncObjectsMethodsFromCloud(domain, deviceHashes);

      for (final item in returnList) {
        final docData = Map<String, dynamic>.from(item);
        await setObjectMethod(docData, false, false);
      }
      //
    } catch (e) {
      debugPrint("Error during syncing to cloud: $e !");
    } finally {
      _isSyncing = false;
    }
    String ownerUID = FirebaseAuth.instance.currentUser!.uid;
    inbox = await databaseHelper.getInboxItems(ownerUID);
    inboxCount.value = inbox.length;
    repaintContainerList.value =
        true; //Repaint the list of items when sync is done
  }
}

Future<String> getDeviceId() async {
  if (kIsWeb) {
    // For web, generate a random ID and store it in local storage
    final storage = html.window.localStorage;
    var id = storage['deviceId'];
    if (id == null) {
      id = const Uuid().v4();
      storage['deviceId'] = id;
    }
    return id;
  } else if (Platform.isAndroid || Platform.isIOS) {
    // For mobile, use device_info_plus package
    final deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      return androidInfo.id;
    } else {
      final iosInfo = await deviceInfo.iosInfo;
      return iosInfo.identifierForVendor ?? const Uuid().v4();
    }
  }
  return const Uuid().v4(); // Fallback
}

String generateStableHash(Map<String, dynamic> docData) {
  final jsonString = jsonEncode(docData);
  final bytes = utf8.encode(jsonString);
  return sha256.convert(bytes).toString();
}
