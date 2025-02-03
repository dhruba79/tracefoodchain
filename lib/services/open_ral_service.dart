//This is a collection of services for working with openRAL
//It has to work online and offline, so we have to use Hive to store templates
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:json_path/json_path.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:trace_foodchain_app/main.dart';
import 'package:trace_foodchain_app/repositories/initial_data.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;

var uuid = const Uuid();

//! 1. CloudConnectors

Map<String, Map<String, dynamic>> getCloudConnectors() {
  debugPrint("loading cloud connectors from initial repo");
  Map<String, Map<String, dynamic>> rList = {};

  //Always populate with cloudConnectors from initial repo
  for (final cc in initialCloudConnectors) {
    final domain = getSpecificPropertyfromJSON(cc, "cloudDomain");
    rList.addAll({domain: cc});
    //update local storage
    localStorage.put(getObjectMethodUID(cc), cc);
  }

  return rList;
}

dynamic getCloudConnectionProperty(String domain, connectorType, property) {
  dynamic rObject;
  try {
    // domain und subconnector suchen (connectorType)
    Map<String, dynamic> subConnector = Map<String, dynamic>.from(
        cloudConnectors[domain]!["linkedObjects"].firstWhere(
            (subConnector) => subConnector["role"] == connectorType));
    //read requested property
    rObject = getSpecificPropertyfromJSON(subConnector, property);
  } catch (e) {
    debugPrint(
        "The requested cloud function property $property does not exist!");
    rObject = null;
  }

  return rObject;
}

//! 2. getTemplate: get an empty openRAL object or method template from local template storage

Future<Map<String, dynamic>> getOpenRALTemplate(String templateName) async {
  Map<String, dynamic> rMap = {};
  try {
    Map<String, dynamic> res =
        json.decode(json.encode(openRALTemplates.get(templateName)));
    rMap = Map<String, dynamic>.from(res);
  } catch (e) {
    debugPrint("Problem");
  }
  return rMap;
}

Future<Map<String, dynamic>> getRALObjectMethodTemplateAsJSON(
    String objectType) async {
  Map<String, dynamic> json = {};

  try {
// Get a JSON template via REST API from RAL mothership
    var url2 =
        '${getCloudConnectionProperty("open-ral.io", "cloudFunctionsConnector", "smartRequestTemplateWeb")["url"]}?apiKey=${getCloudConnectionProperty("open-ral.io", "cloudFunctionsConnector", "apiKey")}&templateName=$objectType&returnFormat=JSON'; //no version requested = most current version
    Uri uri2 = Uri.parse(url2);

    var response2 = await http.get(uri2);
    if (response2.statusCode == 200) {
      //Valides Template kam zurück
      try {
        json = jsonDecode(response2.body);
      } catch (e) {
        print("ERROR: Could not pars json from RAL!");
      }
    } else {
      print("Error requesting RAL template via REST");
    }

    // _json = jsonDecode(jsonString);
  } catch (e) {
    //ToDo: Handle errors
  }

  return json;
}

//! 3.#######  getters for working with openRAL objects ############

Future<Map<String, dynamic>> getRALObjectFromDomain(
    String domain, String objectUID) async {
  Map<String, dynamic> returnObject = {};
  if (cloudConnectors.isEmpty) getCloudConnectors();

  String? dscMetadataUrl;
  String dscMetadataUuidField =
      "databaseID"; //ToDo: this is permarobotics specific - read from object connector
  String dscMetadataEndpoint =
      "getSensorInfo"; //ToDo: this is permarobotics specific - read from object connector

  if (domain != "") {
    dscMetadataUrl = getCloudConnectionProperty(
        domain, "cloudFunctionsConnector", dscMetadataEndpoint)["url"];
    debugPrint("url is $dscMetadataUrl");

//ToDo: ÄNDERN, API KEY IM HEADER ÜBERMITTELN!!!!!

    // var url2 =
    //     '$dsc_metadata_url?${dsc_metadata_uuid_field}=${objectUID}?apiKey=${getCloudConnectionProperty("permarobotics.com", "cloudFunctionsConnector", "apiKey")}'; //databaseID
    var url2 = '$dscMetadataUrl?$dscMetadataUuidField=$objectUID'; //databaseID
    Uri uri2 = Uri.parse(url2);

    var response2 = await http.get(uri2);
    if (response2.statusCode == 200) {
      returnObject = jsonDecode(response2.body)[0];
    } else {
      debugPrint("could not get object from domain $domain");
      returnObject = {};
    }
  } else {
    debugPrint("ERROR: no domain specified!");
    returnObject = {};
  }
  return returnObject;
}

//Get object or method from local database
Future<Map<String, dynamic>> getObjectMethod(String objectMethodUID) async {
  Map<String, dynamic> doc2 = {};
  try {
    for (var doc in localStorage.values) {
      if (doc['identity'] != null &&
          doc['identity']["UID"] == objectMethodUID) {
        doc2 = Map<String, dynamic>.from(doc);
        break;
      }
      //return doc2;
    }
  } catch (e) {
    return {};
  }
  return doc2;
}

// a) IDENTITY
String getObjectMethodUID(Map<String, dynamic> objectMethod) {
  try {
    return objectMethod["identity"]["UID"];
  } catch (e) {
    return "";
  }
}

// b) LOCATION

// c) METHODHISTORY

// d) SPECIFIC PROPERTIES
dynamic getSpecificPropertyfromJSON(
    Map<String, dynamic> jsonDoc, String property) {
  dynamic rstring;
  final ssnodes = jsonDoc["specificProperties"];

//! ***************** Legacy Map ************************
  if (ssnodes is Map) {
    try {
      rstring = ssnodes[property];
      if (rstring == null) return "-no data found-";
      return rstring;
    } catch (e) {
      return "-no data found-";
    }
  } else {
    try {
      for (var node in ssnodes) {
        if (node["name"] != null) {
          if (node["name"] == property) {
            rstring = node["value"];
          }
        } else {
          if (node["key"] == property) {
            rstring = node["value"];
          }
        }
      }
    } catch (e) {}
    rstring ??= '-no data found-';
    return rstring;
  }
}

String getSpecificPropertyUnitfromJSON(
    Map<String, dynamic> jsonDoc, String property) {
  String rstring = '-no data found-';
  final ssnodes = jsonDoc["specificProperties"];
  for (var node in ssnodes) {
    if (node["name"] != null) {
      if (node["name"] == property) {
        rstring = node["unit"];
      }
    } else {
      if (node["key"] == property) {
        rstring = node["unit"];
      }
    }
  }
  return rstring;
}
// e) LINKED OBJECTS / OBJECT REFERENCES

// f) INPUTOBJECTS

// d) OUTPUTOBJECTS

//! 4.#########  setters for working with openRAL objects ########

Future<Map<String, dynamic>> setObjectMethod(Map<String, dynamic> objectMethod,
    bool signMethod, bool markForSyncToCloud) async {
  //Make sure it gets a valid
  if (getObjectMethodUID(objectMethod) == "") {
    
    //***************  NEW OBJECT OR METHOD ***************

    setObjectMethodUID(objectMethod, uuid.v4());
    if (objectMethod.containsKey("existenceStarts")) {

    //***************  NEW METHOD ***************

      if (signMethod == true) {
        //!DIGITAL SIGNATURE FOR A NEW METHOD
        //check which parts of the method need to be signed. In general, the whole method is signed,
        // but in some cases like offline sales, only parts are signed

        String signingObject = "";
        List<String> pathsToSign = ["\$."];

        switch (objectMethod["template"]["RALType"]) {
          case "changeContainer":
            //! Check if it is part of a sales process, buyer side or local change
            bool isLocal = false;
            if (objectMethod["inputObjects"] != null) {
              isLocal = objectMethod["inputObjects"]
                  .any((obj) => obj["role"] == "oldContainer");
            }
            if (isLocal) {
              pathsToSign = [
                //local change of container
                "\$"
              ];
            } else {
              pathsToSign = [
                //sales process buyer side, only sign parts that are relevant for the buyer
                "\$.identity.UID",
                "\$.inputObjects[?(@.role=='newContainer')]",
                "\$.inputObjects[?(@.role=='buyer')]"
              ];
            }
            break;
          case "changeOwner": //This is the buyer side process
            pathsToSign = [
              "\$.identity.UID",
              "\$.inputObjects[?(@.role=='newContainer')]"
                  "\$.inputObjects[?(@.role=='buyer')]"
            ];

            break;
          default:
            pathsToSign = [
              "\$."
            ]; //aggregateItems, changeProcessingState, addChangeItem
        }
        signingObject = createSigningObject(pathsToSign, objectMethod);

        final signature =
            await digitalSignature.generateSignature(signingObject);
        if (objectMethod["digitalSignatures"] == null) {
          objectMethod["digitalSignatures"] = [];
        }
        objectMethod["digitalSignatures"].add({
          "signature": signature,
          "signerUID": FirebaseAuth.instance.currentUser?.uid,
          "signedContent": pathsToSign
        });
      }
      if (objectMethod["existenceStarts"] == null) {
        objectMethod["existenceStarts"] = DateTime
            .now(); //ToDo: Test: Can this be stored in Hive? Otherwise ISO8601 String!
      }
    }
  } else {

        //***************  EXISTING OBJECT OR METHOD ***************

    if (objectMethod.containsKey("existenceStarts") && signMethod == true) {
       
          //***************  EXISTING METHOD TO SIGN ***************

      //!DIGITAL SIGNATURE FOR AN EXISTING METHOD, ALWAYS SIGN THE WHOLE METHOD
      String signingObject = jsonEncode(objectMethod);
      final signature = await digitalSignature.generateSignature(signingObject);
      if (objectMethod["digitalSignatures"] == null) {
        objectMethod["digitalSignatures"] = [];
      }
      objectMethod["digitalSignatures"].add({
        "signature": signature,
        "signerUID": FirebaseAuth.instance.currentUser?.uid,
        "signedContent": ["\$."]
      });
    }
  }

  if (objectMethod["role"] != null) {
    objectMethod.remove("role");
    //Remove unwanted role declaration of objects
  }

  //!tag for syncing with cloud
  if (markForSyncToCloud) objectMethod["needsSync"] = true;

  //Local storage
  await localStorage.put(getObjectMethodUID(objectMethod), objectMethod);

  // sync with cloud if tagged for this and device is connected to the internet
  var connectivityResult = await (Connectivity().checkConnectivity());
  if (objectMethod["needsSync"] != null) {
    if ((objectMethod["needsSync"] == true) &&
        (!connectivityResult.contains(ConnectivityResult.none))) {
      await cloudSyncService.syncMethods('tracefoodchain.org');
     
    }
  }
  return objectMethod;
}

// a) IDENTITY
Map<String, dynamic> setObjectMethodUID(
    Map<String, dynamic> objectMethod, String uid) {
  Map<String, dynamic> rMap = objectMethod;
  objectMethod["identity"]["UID"] = uid;
  return rMap;
}

// b) LOCATION

// c) METHODHISTORY

// d) SPECIFIC PROPERTIES
Map<String, dynamic> setSpecificPropertyJSON(
    Map<String, dynamic> jsonDoc, String name, dynamic value, String unit) {
  Map<String, dynamic> jdoc = Map<String, dynamic>.from(jsonDoc);
  String newUnit = "";
  if (unit == "") {
    newUnit = getSpecificPropertyUnitfromJSON(jsonDoc, name);
  } else {
    newUnit = unit;
  }
  try {
    jdoc["specificProperties"]
            .firstWhere((o) => o["name"] == name || o["key"] == name)['value'] =
        value;
    jdoc["specificProperties"]
            .firstWhere((o) => o["name"] == name || o["key"] == name)['unit'] =
        newUnit;
  } catch (e) {
//Property does not exist, add...
    try {
      (jdoc["specificProperties"] as List)
          .add({"key": name, "value": value, "unit": newUnit});
    } catch (e) {
      Map<String, dynamic> myAdd = {
        "key": name,
        "value": value,
        "unit": newUnit
      };

      Map<String, String> stringMap = myAdd.cast<String, String>();
      List<Map<String, dynamic>> sp = jdoc["specificProperties"];
      sp.add(stringMap);
    }
  }
  return jdoc;
}
// e) LINKED OBJECTS / OBJECT REFERENCES

// f) INPUTOBJECTS
Map<String, dynamic> addInputobject(
    Map<String, dynamic> method, Map<String, dynamic> object, String role) {
  if (method['inputObjects'] == null) {
    method['inputObjects'] = [];
  }

  // Extract UID from the object to be added
  var newObjectUID = object['identity']?['UID'];

  // Check if 'inputObjects' already contains an object with the same UID
  bool exists =
      method['inputObjects'].any((o) => o['identity']?['UID'] == newObjectUID);

  if (!exists) {
    object["role"] = role;
    method['inputObjects'].add(object);
  } else {
    debugPrint(
        'An object with UID $newObjectUID already exists in inputObjects.');
  }

  return method;
}

// d) OUTPUTOBJECTS
Map<String, dynamic> addOutputobject(
    Map<String, dynamic> method, Map<String, dynamic> object, String role) {
  if (method['outputObjects'] == null) {
    method['outputObjects'] = [];
  }

  // Extract UID from the object to be added
  var newObjectUID = object['identity']?['UID'];

  // Find the index of the object with the same UID, if it exists
  int index = method['outputObjects']
      .indexWhere((o) => o['identity']?['UID'] == newObjectUID);

  if (index == -1) {
    // If the object does not exist, add it to the list
    object["role"] = role;
    method['outputObjects'].add(object);
  } else {
    // If the object exists, replace it
    debugPrint(
        'An object with UID $newObjectUID already exists in outputObjects, replacing...');
    object["role"] = role; // Ensure the role is updated
    method['outputObjects'][index] = object;
  }

  return method;
}

Future updateMethodHistories(Map<String, dynamic> jsonDoc) async {
  final methodUID = jsonDoc["identity"]["UID"];
  final methodRALType = jsonDoc["template"]["RALType"];
//Alle inputObject und outputobjects extrahieren
//Für jedes Objekt: Objekt laden, MethodHistoryRef holen - schaun ob das Objekt schon dranhängt, ansonsten dranhängen
  final ouidList = [];
  if (jsonDoc["inputObjects"] != null)
    for (final obj in jsonDoc["inputObjects"]) {
      ouidList.add(obj["identity"]["UID"]);
    }

  if (jsonDoc["inputObjectsRef"] != null)
    for (final obj in jsonDoc["inputObjectsRef"]) {
      if (!ouidList.contains(obj["UID"])) ouidList.add(obj["UID"]);
    }

  if (jsonDoc["outputObjects"] != null)
    for (final obj in jsonDoc["outputObjects"]) {
      if (!ouidList.contains(obj["UID"])) ouidList.add(obj["identity"]["UID"]);
    }

  if (jsonDoc["outputObjectsRef"] != null)
    for (final obj in jsonDoc["outputObjectsRef"]) {
      if (!ouidList.contains(obj["UID"])) ouidList.add(obj["UID"]);
    }

  for (final uid in ouidList) {
    debugPrint("checking $uid");
    final oDoc = await getObjectMethod(uid);
    if (oDoc.isNotEmpty) {
      try {
        if (oDoc["methodHistoryRef"]
            .firstWhere((element) => element["UID"] == methodUID,
                orElse: () => {})
            .isEmpty) {
          //Check if already in List
          debugPrint(
              "Eintrag $methodUID existiert noch nicht in Methodhistory!");
          oDoc["methodHistoryRef"]
              .add({"UID": methodUID, "RALType": methodRALType});

          await setObjectMethod(oDoc, false,true);
        } else {
          debugPrint("Eintrag $methodUID existiert schon in Methodhistory");
        }
      } catch (e) {
        debugPrint("Knoten MethodHistory existiert noch nicht in $uid");
        oDoc["methodHistoryRef"] = {"UID": methodUID, "RALType": methodRALType};

        await setObjectMethod(oDoc,false, true);
      }
    }
  }
}

Future<Map<String, dynamic>> getObjectOrGenerateNew(
    String uid, List<String> types, String field) async {
  Map<String, dynamic> rDoc = {};
  //check all items with these types: do they have the id on the field?
  List<Map<dynamic, dynamic>> candidates = localStorage.values
      .where((candidate) => types.contains(candidate['template']["RALType"]))
      .toList();
  for (dynamic candidate in candidates) {
    Map<String, dynamic> candidate2 = Map<String, dynamic>.from(candidate);
    switch (field) {
      case "uid":
        if (candidate2["identity"]["UID"] == uid) rDoc = candidate2;
        break;
      case "alternateUid":
        if (candidate2["identity"]["alternateIDs"].length != 0) {
          if (candidate2["identity"]["alternateIDs"][0]["UID"] == uid) {
            rDoc = candidate2;
          }
        }
        break;
      default:
    }
    if (rDoc.isNotEmpty) break;
  }
  if (rDoc.isEmpty) {
    Map<String, dynamic> rDoc2 = await getOpenRALTemplate(types[0]);
    rDoc = rDoc2;
    rDoc["identity"]["UID"] = "";
    debugPrint("generated new template for ${types[0]}");
  }
  return rDoc;
}

Future<bool> checkAlternateIDExists(String alternateID) async {
  List<Map<dynamic, dynamic>> allItems = localStorage.values
      .where((item) => item['identity']?['alternateIDs'] != null)
      .toList();

  for (dynamic item in allItems) {
    Map<String, dynamic> itemMap = Map<String, dynamic>.from(item);
    List alternateIDs = itemMap['identity']['alternateIDs'];

    if (alternateIDs.any((id) => id['UID'] == alternateID)) {
      return true;
    }
  }

  return false;
}

Future<Map<String, dynamic>> getContainerByAlternateUID(String uid) async {
  Map<String, dynamic> rDoc = {};
  //check all items with this type: do they have the id on the field?
  List<Map<dynamic, dynamic>> candidates = localStorage.values
      .where((candidate) => candidate['template']["RALType"] != "")
      .toList();
  for (dynamic candidate in candidates) {
    Map<String, dynamic> candidate2 = Map<String, dynamic>.from(candidate);

    if (candidate2["identity"]["alternateIDs"].length != 0) {
      if (candidate2["identity"]["alternateIDs"][0]["UID"] == uid) {
        rDoc = candidate2;
      }
    }

    if (rDoc.isNotEmpty) break;
  }

  return rDoc;
}

String createSigningObject(
    List<String> pathsToSign, Map<String, dynamic> objectMethod) {
  List<dynamic> partsToSign = [];
  for (String path in pathsToSign) {
    final jp = JsonPath(path);
    final matches = jp.read(objectMethod);
    if (matches.isNotEmpty) {
      if (matches.first.value is Map) {
        partsToSign.add(Map<String, dynamic>.from(matches.first.value as Map));
      } else if (matches.first.value is List) {
        partsToSign.add(matches.first.value as List);
      }
    }
  }
  return jsonEncode(partsToSign);
}
