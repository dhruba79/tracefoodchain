// online_sale_dialog.dart

import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:trace_foodchain_app/main.dart';
import 'package:trace_foodchain_app/services/open_ral_service.dart';
import 'package:trace_foodchain_app/services/service_functions.dart';
import 'package:trace_foodchain_app/widgets/custom_text_field.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;

class OnlineSaleDialog extends StatefulWidget {
  final List<Map<String, dynamic>> itemsToSell;

  const OnlineSaleDialog({super.key, required this.itemsToSell});

  @override
  _OnlineSaleDialogState createState() => _OnlineSaleDialogState();
}

class _OnlineSaleDialogState extends State<OnlineSaleDialog> {
  final TextEditingController _emailController = TextEditingController();
  String? _emailError;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.sellOnline),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomTextField(
            controller: _emailController,
            hintText: l10n.recipientEmail,
            keyboardType: TextInputType.emailAddress,
            errorText: _emailError,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        ElevatedButton(
          onPressed: _processSale,
          child: Text(l10n.sell),
        ),
      ],
    );
  }

  Future<void> _processSale() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _emailError = null;
    });

    if (!_isValidEmail(_emailController.text)) {
      setState(() {
      _emailError = l10n.invalidEmail;
      });
      return;
    }

    try {
      Map<String, dynamic>? receiverDoc = await _findUserByEmail(_emailController.text);
      if (receiverDoc != null) {
      await _performSale(receiverDoc);
      Navigator.of(context).pop();
      await fshowInfoDialog(context, l10n.saleCompleted);
      } else {
      await fshowInfoDialog(context, l10n.userNotFound);
      }
    } catch (e) {
      await fshowInfoDialog(context, l10n.saleError);
    }
    }

    bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,}$').hasMatch(email);
    }

    //For the prototype, we use user verification by permarobotics cloud!
    Future<Map<String, dynamic>?> _findUserByEmail(String email) async {
    Map<String, dynamic>? userDoc;
    String? urlString;
    try {
      urlString = getCloudConnectionProperty("tracefoodchain.org",
        "cloudFunctionsConnector", "findUserByEmail")["url"];
    } catch (e) {}

    if (urlString != null) {
      var url2 = '$urlString?email=$email';
      Uri uri2 = Uri.parse(url2);
      try {
      // Wait for the HTTP response or timeout after 10 seconds.
      var response = await http.get(uri2).timeout(const Duration(seconds: 20));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);//Return userdoc
      }
      } on TimeoutException {
      // Timeout occurred
      // throw Exception("Server timeout");
      }
    }
    return userDoc;
    }

  Future<void> _performSale(Map<String,dynamic> receiverDoc) async {
    //Deprecated: Generate transfer container
    // final transferContainer = await _generateTransferContainer(receiver);

    // Perform changeOwnership of the item to sell AND ALL NESTED ITEMS
    for (final item in widget.itemsToSell) {
      await _changeOwnership(item, getObjectMethodUID(receiverDoc));
    }

    // Perform changeContainer of the primary container, use the USER as container to tag as "INBOX"
    await _changeContainer(widget.itemsToSell[0], receiverDoc);

    //ToDo Send push notification to the new owner
    await _sendPushNotification(getObjectMethodUID(receiverDoc));
  }

  Future<void> _changeOwnership(
      Map<String, dynamic> item, String newOwnerUID) async {
    final changeOwnershipMethod = await getOpenRALTemplate("changeOwner");

    addInputobject(changeOwnershipMethod, item, "item");
    item["currentOwners"] = [
      {"UID": newOwnerUID, "role": "owner"}
    ];

    //Add Executor
    changeOwnershipMethod["executor"] = appUserDoc;
    changeOwnershipMethod["methodState"] = "finished";
    //Step 1: get method an uuid (for method history entries)
    setObjectMethodUID(changeOwnershipMethod, const Uuid().v4());
    //Step 2: save the objects a first time to get it the method history change
    await setObjectMethod(item, false, false);
    //Step 3: add the output objects with updated method history to the method
    addOutputobject(changeOwnershipMethod, item, "item");
    //Step 4: update method history in all affected objects (will also tag them for syncing)
    await updateMethodHistories(changeOwnershipMethod);
    //Step 5: persist process
    await setObjectMethod(changeOwnershipMethod, true, true); //sign it!
  }

  Future<void> _changeContainer(Map<String, dynamic> item, receiverDoc) async {
    final changeContainerMethod = await getOpenRALTemplate("changeContainer");
    changeContainerMethod["inputObjects"] = [item];
    item["currentGeolocation"]["container"]["UID"] = "";//We do not now the receiving container yet
    //Add Executor
    changeContainerMethod["executor"] = receiverDoc;
    changeContainerMethod["methodState"] = "running";
    //Step 1: get method an uuid (for method history entries)
    setObjectMethodUID(changeContainerMethod, const Uuid().v4());
    //Step 2: save the objects a first time to get it the method history change
    await setObjectMethod(item, false, false);
    //Step 3: add the output objects with updated method history to the method
    changeContainerMethod["outputObjects"] =
        [item]; 
    //Step 4: update method history in all affected objects (will also tag them for syncing)
    await updateMethodHistories(changeContainerMethod);
    //Step 5: persist process
    await setObjectMethod(changeContainerMethod, true, true); //sign it!
  }

  Future<void> _sendPushNotification(receiverUID) async {
    //ToDo: This will be implemented in the next step
    //For the prototype, we will use the permarobotics notification pipeline
  }
}
