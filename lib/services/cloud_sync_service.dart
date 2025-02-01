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
import 'package:uuid/uuid.dart';

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
            'userId': apiKey,
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

  Future<void> syncMethodToCloud(
      String domain, Map<String, dynamic> ralMethod) async {
    dynamic urlString;
    try {
      urlString = getCloudConnectionProperty(
          domain, "cloudFunctionsConnector", "syncMethodToCloud")["url"];
    } catch (e) {}
    final apiKey = await FirebaseAuth.instance.currentUser?.getIdToken();
    // getCloudConnectionProperty(domain, "cloudFunctionsConnector", "apiKey");
    if (urlString != null && apiKey != null) {
      final response = await http.post(
        // Uri.parse('$baseUrl/syncMethodToCloud'),
        Uri.parse(urlString),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({'ralMethod': ralMethod}),
      );

      if (response.statusCode == 200) {
       // return jsonDecode(response.body);
      } else {
        //Response codes? 400: Bad Request, 401: Unauthorized, 403: Forbidden, 404: Not Found, 500: Internal Server Error
       debugPrint(
            'Failed to sync method to cloud: ${response.statusCode}');
      }
    } else {
      throw Exception("no valid cloud connection properties found!");
    }
  }

  Future<void> syncObjectsMethodsFromCloud(String domain) async {
     dynamic urlString;
    try {
      urlString = getCloudConnectionProperty(
          domain, "cloudFunctionsConnector", "syncObjectsMethodsFromCloud")["url"];
    } catch (e) {}
    final apiKey = await FirebaseAuth.instance.currentUser?.getIdToken();
  
    if (urlString != null && apiKey != null) {
      final response = await http.post(

        Uri.parse(urlString),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({'userId': apiKey}),
      );

      if (response.statusCode == 200) {
          //Todo: Eine Liste von Objekten und Methoden aus der Cloud bekommen und im Local Storage speichern
       // return jsonDecode(response.body);
      } else {
        //Response codes? 400: Bad Request, 401: Unauthorized, 403: Forbidden, 404: Not Found, 500: Internal Server Error
       debugPrint(
            'Failed to sync objects and methods from cloud: ${response.statusCode}');
      }
    } else {
      throw Exception("no valid cloud connection properties found!");
    }


  }
}

class CloudSyncService {
  final CloudApiClient apiClient;

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
    final databaseHelper = DatabaseHelper();
    try {
      //* 1. Sync methods TO CLOUD

      List<Map<String, dynamic>> methodsToSyncToCloud = [];
      for (var doc in localStorage.values) {
        final doc2 = Map<String, dynamic>.from(doc);
        if (doc2["needsSync"] != null) {
          doc2.remove("needsSync");
          if (doc2["methodHistoryRef"] != null) {
//This is an object
          } else {
//This is a method
            methodsToSyncToCloud.add(doc2);
          }
        }
      }

      //* SYNC METHODS TO CLOUD
      for (final method in methodsToSyncToCloud) {
        //ToDo this is atm unidirectonal since they are never changed after local execution
        //ToDO in general openRAL settings, this would be bidirectional too
        final doc2 = Map<String, dynamic>.from(method);
        final methodUid = getObjectMethodUID(doc2);
        try {
          //! await apiClient.syncMethodToCloud(doc2);
          //!setObjectMethod(doc2,false);
        } catch (e) {
          debugPrint('Error syncing method {$methodUid}: $e');
        }
      }

      //TODO * 2. Look for objects and methods in the cloud that should be on the users device but are not
      //This happens in case a user has logged into a second device (e.g., webapp on PC)
      //! await apiClient.syncObjectsMethodsFromCloud(***);
      //
    } catch (e) {
      debugPrint("Error during syncing to cloud!");
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
