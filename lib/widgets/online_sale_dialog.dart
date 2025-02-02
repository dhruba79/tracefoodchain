// online_sale_dialog.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:trace_foodchain_app/main.dart';
import 'package:trace_foodchain_app/services/open_ral_service.dart';
import 'package:trace_foodchain_app/services/service_functions.dart';
import 'package:trace_foodchain_app/widgets/custom_text_field.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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
      final receiverUser = await _findUserByEmail(_emailController.text);
      if (receiverUser != null) {
        await _performSale(receiverUser);
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
    //ToDo replace with REST-API call to a specific cloud function
    try {
      final userDocSnap = await FirebaseFirestore.instance
          .collection('PR_objects')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      return userDocSnap.docs.first.data();
    } catch (e) {
      debugPrint(e.toString());
    }

    return null;
  }

  Future<void> _performSale(Map<String, dynamic> receiver) async {
    //Deprecated: Generate transfer container
    // final transferContainer = await _generateTransferContainer(receiver);

    // Perform changeOwnership of the item to sell AND ALL NESTED ITEMS
    for (final item in widget.itemsToSell) {
      await _changeOwnership(item, receiver);
    }

    // Perform changeContainer of the primary container, use the USER as container to tag as "INBOX"
    await _changeContainer(widget.itemsToSell[0], receiver);

    //ToDo Send push notification to the new owner
    await _sendPushNotification(receiver);
  }

  // Future<Map<String, dynamic>> _generateTransferContainer(
  //     Map<String, dynamic> receiver) async {
  //   final transferContainer = await getOpenRALTemplate("container");
  //   transferContainer["currentOwners"] = [
  //     {"UID": receiver['uid'], "role": "owner"}
  //   ];
  //   transferContainer["specificProperties"] = [
  //     {"key": "type", "value": "transferContainer", "unit": "String"},
  //   ];
  //   return await setObjectMethod(transferContainer, true);
  // }

  Future<void> _changeOwnership(
      Map<String, dynamic> item, Map<String, dynamic> newOwner) async {
    final changeOwnershipMethod = await getOpenRALTemplate("changeOwner");
    changeOwnershipMethod["inputObjects"] = [item];
    changeOwnershipMethod["outputObjects"] = [item];
    item["currentOwners"] = [
      {"UID": newOwner['uid'], "role": "owner"}
    ];
    await setObjectMethod(changeOwnershipMethod,true, true);//sign it!	
    await setObjectMethod(item,false, true);
  }

  Future<void> _changeContainer(
      Map<String, dynamic> item, Map<String, dynamic> newContainer) async {
    final changeContainerMethod = await getOpenRALTemplate("changeContainer");
    changeContainerMethod["inputObjects"] = [item, newContainer];
    changeContainerMethod["outputObjects"] = [item];
    item["currentGeolocation"]["container"]["UID"] =
        newContainer["identity"]["UID"];
    await setObjectMethod(changeContainerMethod, true,true);//sign it!
    await setObjectMethod(item, false,true);
  }

  Future<void> _sendPushNotification(Map<String, dynamic> receiver) async {
    //ToDo: This will be implemented in the next step
    //For the prototype, we will use the permarobotics notification pipeline
  }
}
