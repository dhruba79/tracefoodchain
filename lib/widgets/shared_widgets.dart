// lib/widgets/shared_dialogs.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trace_foodchain_app/main.dart';
import 'package:trace_foodchain_app/providers/app_state.dart';
import 'package:trace_foodchain_app/screens/peer_transfer_screen.dart';
import 'package:trace_foodchain_app/services/aggregate_items.dart';
import 'package:trace_foodchain_app/services/open_ral_service.dart';
import 'package:trace_foodchain_app/services/scanning_service.dart';
import 'package:trace_foodchain_app/services/service_functions.dart';
import 'package:trace_foodchain_app/widgets/coffee_processing_state_selector.dart';
import 'package:trace_foodchain_app/widgets/stepper_buy_coffee.dart';
import 'package:trace_foodchain_app/widgets/stepper_first_sale.dart';

Future<void> showBuyCoffeeOptions(BuildContext context,
    {String? receivingContainerUID}) async {
  return showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(
          'Select Buy Coffee Option',
          style: TextStyle(color: Colors.black),
          textAlign: TextAlign.center,
        ),
        content: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 300),
          child: Container(
            width: double.maxFinite,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: _buildOptionButton(
                        context,
                        icon: Icons.credit_card,
                        label: 'CIAT first sale',
                        onTap: () async {
                          Navigator.of(context).pop();
                          FirstSaleProcess buyCoffeeProcess =
                              new FirstSaleProcess();
                          if (receivingContainerUID == null)
                            await buyCoffeeProcess.startProcess(context);
                          else
                            await buyCoffeeProcess.startProcess(context,
                                receivingContainerUID: receivingContainerUID);
                          repaintContainerList.value = true;
                        },
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: _buildOptionButton(
                        context,
                        icon: Icons.devices,
                        label: 'Device-to-device',
                        onTap: () async {
                          Navigator.of(context).pop();
                          // Implement device-to-device process

                          StepperBuyCoffee buyCoffeeProcess =
                              new StepperBuyCoffee();
                          if (receivingContainerUID == null)
                            await buyCoffeeProcess.startProcess(context);
                          else
                            await buyCoffeeProcess.startProcess(context,
                                receivingContainerUID: receivingContainerUID);

                          repaintContainerList.value = true;
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

Widget _buildOptionButton(
  BuildContext context, {
  required IconData icon,
  required String label,
  required VoidCallback onTap,
}) {
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      IconButton(
        icon: Icon(icon, size: 40, color: Theme.of(context).primaryColor),
        onPressed: onTap,
      ),
      SizedBox(height: 8),
      Text(
        label,
        style: TextStyle(color: Colors.black),
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    ],
  );
}

Future<void> showAggregateItemsDialog(
    BuildContext context, Set<String> selectedItemUIDs) async {
  return showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Aggregate Items'),
        content: Text(
            'You are about to aggregate ${selectedItemUIDs.length} items. Please scan or select the receiving container.'),
        actions: <Widget>[
          TextButton(
            child: Text('Cancel'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          ElevatedButton(
            child: Text('Start Aggregation'),
            onPressed: () {
              Navigator.of(context).pop();
              aggregateItems(context, selectedItemUIDs);
            },
          ),
        ],
      );
    },
  );
}

Future<void> showChangeContainerDialog(
    BuildContext context, Map<String, dynamic> item) async {
  return showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Change Location/Container'),
        content: Text(
            'You are about to change the location of this item. Please scan or select the receiving container.'),
        actions: <Widget>[
          TextButton(
            child: Text('Cancel'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          ElevatedButton(
            child: Text('Start Process'),
            onPressed: () async {
              Map<String, dynamic>? newContainer;
              String? receivingContainerUID =
                  await ScanningService.showScanDialog(
                context,
                Provider.of<AppState>(context, listen: false),
              );

              if (receivingContainerUID == null) {
                await fshowInfoDialog(context,
                    "No receiving container selected. Process cancelled.");
              } else {
                newContainer =
                    await getContainerByAlternateUID(receivingContainerUID);

                if (newContainer.isEmpty) {
                  await fshowInfoDialog(context,
                      "This container does not exist at your repository. Process cancelled.\n(Consider to add the container first to your repository!)");
                } else

                //4. Change container
                {
                  final changeContainerMethod =
                      await getOpenRALTemplate("changeContainer");
                  changeContainerMethod["inputObjects"] = [item, newContainer];
                  changeContainerMethod["outputObjects"] = [item];
                  item["currentGeolocation"]["container"]["UID"] =
                      newContainer["identity"]["UID"];
                  await setObjectMethod(changeContainerMethod, true);
                  await setObjectMethod(item, true);
                }
              }
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}

Future<void> showProcessingStateDialog(
    Map<String, dynamic> coffee, BuildContext context) async {
  String currentState = getSpecificPropertyfromJSON(coffee, "processingState");
  List<String> currentQualityCriteria =
      getSpecificPropertyfromJSON(coffee, "qualityState") ?? [];

  Map<String, dynamic>? result = await showDialog<Map<String, dynamic>>(
    context: context,
    builder: (BuildContext context) {
      return Dialog(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 400,
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Text(
                //   'Select Processing State and Quality Criteria',
                //   style: TextStyle(
                //     fontSize: 18,
                //     fontWeight: FontWeight.bold,
                //   ),
                // ),
                // SizedBox(height: 16),
                Flexible(
                  child: SingleChildScrollView(
                    child: CoffeeProcessingStateSelector(
                      currentState: currentState,
                      currentQualityCriteria: currentQualityCriteria,
                      onSelectionChanged: (state, criteria) {
                        Navigator.of(context).pop({
                          'state': state,
                          'criteria': criteria,
                        });
                      },
                      country: getSpecificPropertyfromJSON(coffee, "country") ??
                          'Honduras',
                    ),
                  ),
                ),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      child: Text('Cancel'),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
  );

  if (result != null &&
      (result["state"] != currentState ||
          result["criteria"] != currentQualityCriteria)) {
    // Changes are saved in case state or qc critera changed
    // Template changeProcessingState holen
    Map<String, dynamic> change_processing_state = {};
    change_processing_state = await getOpenRALTemplate("changeProcessingState");
    addInputobject(change_processing_state, coffee, "item");
    coffee = setSpecificPropertyJSON(
        coffee, "processingState", result["state"], "String");
    addOutputobject(change_processing_state, coffee, "item");
    coffee = setSpecificPropertyJSON(
        coffee, "qualityState", result["criteria"], "stringlist"); //ToDo Check!
    change_processing_state["executor"] = appUserDoc!;
    change_processing_state["methodState"] = "finished";

    await setObjectMethod(coffee, true);
    await setObjectMethod(change_processing_state, true);
    //Methode persistieren
    await updateMethodHistories(change_processing_state);
  }
}
