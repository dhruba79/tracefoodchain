import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trace_foodchain_app/providers/app_state.dart';
import 'package:trace_foodchain_app/services/scanning_service.dart';
import 'package:trace_foodchain_app/services/open_ral_service.dart';
import 'package:trace_foodchain_app/main.dart';
import 'package:trace_foodchain_app/services/service_functions.dart';
import 'package:uuid/uuid.dart';

Future<void> aggregateItems(
    BuildContext context, Set<String> selectedItemUIDs) async {
  // Step 1: Scan for receiving container
  String? receivingContainerUID = await ScanningService.showScanDialog(
    context,
    Provider.of<AppState>(context, listen: false),
  );

  if (receivingContainerUID == null) {
    await fshowInfoDialog(
        context, "No receiving container selected. Aggregation cancelled.");
    return;
  }

  // Step 2: Get or create the receiving container object
  Map<String, dynamic> receivingContainer = await getObjectOrGenerateNew(
      receivingContainerUID,
      ["container", "bag", "building", "transportVehicle"],
      "alternateUid");

  if (getObjectMethodUID(receivingContainer).isEmpty) {
    // HAVE TO GENERATE DIGITAL SIBLING OF THIS CONTAINER FROM SCRATCH
    receivingContainer["identity"]["UID"] = const Uuid().v4();
    receivingContainer["identity"]["alternateIDs"] ??= [];
    receivingContainer["identity"]["alternateIDs"]
        .add({"UID": receivingContainerUID, "issuedBy": "owner"});
    receivingContainer["currentOwners"] = [
      {"UID": getObjectMethodUID(appUserDoc!), "role": "owner"}
    ];

    final addItem = await getOpenRALTemplate("generateDigitalSibling");
    //Add Executor
    addItem["executor"] = appUserDoc;
    addItem["methodState"] = "finished";
    //Step 1: get method an uuid (for method history entries)
    setObjectMethodUID(addItem, const Uuid().v4());
    //Step 2: save the objects a first time to get it the method history change
    await setObjectMethod(receivingContainer, false, false);
    //Step 3: add the output objects with updated method history to the method
    addOutputobject(addItem, receivingContainer, "item");
    //Step 4: update method history in all affected objects (will also tag them for syncing)
    await updateMethodHistories(addItem);
    //Step 5: persist process
    await setObjectMethod(addItem, true, true); //sign it!

    receivingContainer = await getObjectMethod(getObjectMethodUID(
        receivingContainer)); //Reload new item with correct method history
  }

  // Step 3: Process each selected item
  for (String itemUID in selectedItemUIDs) {
    Map<String, dynamic> item = await getObjectMethod(itemUID);

    if (item.isNotEmpty) {
      // Create changeContainer process
      Map<String, dynamic> changeContainerProcess =
          await getOpenRALTemplate("changeContainer");
      changeContainerProcess =
          addInputobject(changeContainerProcess, item, "item");
      changeContainerProcess = addInputobject(
          changeContainerProcess, receivingContainer, "newContainer");

      // Update item's container location
      item["currentGeolocation"]["container"]["UID"] =
          getObjectMethodUID(receivingContainer);

      changeContainerProcess["executor"] = appUserDoc;
      changeContainerProcess["methodState"] = "finished";

      // Persist changes
      //Step 1: get method an uuid (for method history entries)
      setObjectMethodUID(changeContainerProcess, const Uuid().v4());
      //Step 2: save the objects a first time to get it the method history change
      await setObjectMethod(item, false, false);
      //Step 3: add the output objects with updated method history to the method
      addOutputobject(changeContainerProcess, item, "item");
      //Step 4: update method history in all affected objects (will also tag them for syncing)
      await updateMethodHistories(changeContainerProcess);
      //Step 5: persist process
      await setObjectMethod(changeContainerProcess, true, true); //sign it!
    }
  }

  // Step 4: Show completion dialog
  // await fshowInfoDialog(context,
  //     "Aggregation complete. ${selectedItemUIDs.length} items moved to the new container.");
}
