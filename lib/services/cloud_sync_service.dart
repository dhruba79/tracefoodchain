// This service syncs local hive database to/from the clouds
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:trace_foodchain_app/helpers/database_helper.dart';
import 'package:trace_foodchain_app/main.dart';
import 'package:trace_foodchain_app/services/open_ral_service.dart';

class CloudApiClient {
  final String domain;
  CloudApiClient({required this.domain});

  Future<Map<String, dynamic>> executeRalMethod(
      String domain, Map<String, dynamic> method) async {
    final urlString = getCloudConnectionProperty(
        domain, "cloudFunctionsConnector", "executeRalMethod")["url"];
    final apiKey =
        getCloudConnectionProperty(domain, "cloudFunctionsConnector", "apiKey");
    final response = await http.post(
      Uri.parse(urlString),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({'method': method}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to execute RalMethod: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> getRalObjectByUid(
      String domain, String uid) async {
    dynamic urlString;
    try {
      urlString = getCloudConnectionProperty(
          domain, "cloudFunctionsConnector", "getRalObjectByUid")["url"];
    } catch (e) {}
    final apiKey =
        getCloudConnectionProperty(domain, "cloudFunctionsConnector", "apiKey");
    if (urlString != null && apiKey != null) {
      final response = await http.get(
        Uri.parse('$urlString?uid=$uid'),
        headers: {'Authorization': 'Bearer $apiKey'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 404) {
        throw Exception('RalObject not found');
      } else {
        throw Exception('Failed to get RalObject: ${response.statusCode}');
      }
    } else {
      throw Exception("no valid cloud connection properties found!");
    }
  }

  Future<Map<String, dynamic>> syncMethodToCloud(
      String domain, Map<String, dynamic> ralMethod) async {
    dynamic urlString;
    try {
      urlString = getCloudConnectionProperty(
          domain, "cloudFunctionsConnector", "getRalObjectByUid")["url"];//! ??????
    } catch (e) {}
    final apiKey =
        getCloudConnectionProperty(domain, "cloudFunctionsConnector", "apiKey");
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
        return jsonDecode(response.body);
      } else {
        throw Exception(
            'Failed to sync method to cloud: ${response.statusCode}');
      }
    } else {
      throw Exception("no valid cloud connection properties found!");
    }
  }

  Future<Map<String, dynamic>> syncObjectToCloud(String domain,
      Map<String, dynamic> ralObject, String mergePreference) async {
    dynamic urlString;
    try {
      urlString = getCloudConnectionProperty(
          domain, "cloudFunctionsConnector", "getRalObjectByUid")["url"];//! ?????? 
    } catch (e) {}
    final apiKey =
        getCloudConnectionProperty(domain, "cloudFunctionsConnector", "apiKey");
    if (urlString != null && apiKey != null) {
      final response = await http.post(
        // Uri.parse('$baseUrl/syncObjectToCloud'),
        Uri.parse(urlString),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'ralObject': ralObject,
          'mergePreference': mergePreference,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 419) {
        throw Exception('No common syncObject method found');
      } else {
        throw Exception(
            'Failed to sync object to cloud: ${response.statusCode}');
      }
    } else {
      throw Exception("no valid cloud connection properties found!");
    }
  }
}

class CloudSyncService {
  final CloudApiClient _apiClient;

  CloudSyncService(String domain) : _apiClient = CloudApiClient(domain: domain);

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

  Future<void> syncObjectsAndMethods(String domain) async {
    final databaseHelper = DatabaseHelper();
    try {
      //* 1. Sync local objects and methods TO CLOUD

      List<Map<String, dynamic>> objectsToSyncToCloud = [];
      List<Map<String, dynamic>> methodsToSyncToCloud = [];
      for (var doc in localStorage.values) {
        final doc2 = Map<String, dynamic>.from(doc);
        if (doc2["needsSync"] != null) {
          doc2.remove("needsSync");
          if (doc2["methodHistoryRef"] != null) {
//This is an object
            objectsToSyncToCloud.add(doc2);
          } else {
//This is a method
            methodsToSyncToCloud.add(doc2);
          }
        }
      }

      //* SYNC OBJECTS TO CLOUD
      for (var object in objectsToSyncToCloud) {
        final doc2 = Map<String, dynamic>.from(object);
        final objectUid = getObjectMethodUID(doc2);
        try {
          final cloudObject =
              await _apiClient.getRalObjectByUid(domain, objectUid);
          if (cloudObject.isEmpty) {
            // Object doesn't exist in cloud, push to cloud
            //! await _apiClient.syncObjectToCloud(doc2, 'external');
            debugPrint('Pushed object $objectUid to cloud');
            //Auch local ohne "needsSync" abspeichern
            //!setObjectMethod(doc2,false);
          } else {
            // Object exists in both places, merge
            //! final mergedObject =
            //!     await _apiClient.syncObjectToCloud(doc2, 'external');
            //!setObjectMethod(mergedObject,false);
            debugPrint('Merged object $objectUid');
          }
        } catch (e) {
          debugPrint('Error syncing object $objectUid: $e');
        }
      }

      //* SYNC METHODS TO CLOUD
      for (final method in methodsToSyncToCloud) {
        //ToDo this is atm unidirectonal since they are never changed after local execution
        //ToDO in general openRAL settings, this would be bidirectional too
        final doc2 = Map<String, dynamic>.from(method);
        final methodUid = getObjectMethodUID(doc2);
        try {
          //! await _apiClient.syncMethodToCloud(doc2);
          //!setObjectMethod(doc2,false);
        } catch (e) {
          debugPrint('Error syncing method {$methodUid}: $e');
        }
      }

      //TODO * 2. Look for objects and methods in the cloud that should be on the users device but are not
      //This happens in case a user has logged into a second device (e.g., webapp on PC)
      //
    } catch (e) {
      debugPrint("Error during syncing to cloud!");
    }
    String ownerUID = FirebaseAuth.instance.currentUser!.uid;
    // ownerUID = "OSOHGLJtjwaGU2PCqajgfaqE5fI2"; //!REMOVE
    inbox = await databaseHelper.getInboxItems(ownerUID);
    inboxCount.value = inbox.length;
    repaintContainerList.value =
        true; //Repaint the list of items when sync is done
  }
}
