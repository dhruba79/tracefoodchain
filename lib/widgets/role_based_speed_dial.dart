import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:provider/provider.dart';
import 'package:trace_foodchain_app/main.dart';
import 'package:trace_foodchain_app/providers/app_state.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:trace_foodchain_app/screens/home_screen.dart';
import 'package:trace_foodchain_app/screens/peer_transfer_screen.dart';
import 'package:trace_foodchain_app/services/open_ral_service.dart';
import 'package:trace_foodchain_app/services/service_functions.dart';
import 'package:trace_foodchain_app/widgets/add_empty_item_dialog.dart';
import 'package:trace_foodchain_app/widgets/items_list_widget.dart';
import 'package:trace_foodchain_app/widgets/shared_widgets.dart';
import 'package:trace_foodchain_app/widgets/stepper_buy_coffee.dart';
import 'package:trace_foodchain_app/widgets/stepper_first_sale.dart';

class RoleBasedSpeedDial extends StatefulWidget {
  final String displayContext;

  const RoleBasedSpeedDial({Key? key, required this.displayContext})
      : super(key: key);

  @override
  State<RoleBasedSpeedDial> createState() => _RoleBasedSpeedDialState();
}

class _RoleBasedSpeedDialState extends State<RoleBasedSpeedDial> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final l10n = AppLocalizations.of(context)!;

    return ValueListenableBuilder(
        valueListenable: rebuildSpeedDial,
        builder: (context, bool value, child) {
          rebuildSpeedDial.value = false;
          return SpeedDial(
            backgroundColor: Color(0xFF35DB00),
            foregroundColor: Colors.white,
            icon: Icons.menu,
            activeIcon: Icons.close,
            spacing: 3,
            childPadding: const EdgeInsets.all(5),
            spaceBetweenChildren: 4,
            renderOverlay: false,
            overlayColor: Colors.black,
            overlayOpacity: 0.5,
            children: _getSpeedDialChildren(appState.userRole,
                appState.isConnected, this.widget.displayContext, l10n),
          );
        });
  }

  List<SpeedDialChild> _getSpeedDialChildren(String? userRole,
      bool? isConnected, String displayContext, AppLocalizations l10n) {
    switch (userRole) {
      case 'Farmer':
        return _getFarmerSpeedDialChildren(displayContext, l10n, isConnected!);
      case 'Farm Manager':
        return _getFarmManagerSpeedDialChildren(
            displayContext, l10n, isConnected!);
      case 'Trader':
        return _getTraderSpeedDialChildren(displayContext, l10n, isConnected!);

      case 'Processor':
        return _getProcessorSpeedDialChildren(
            displayContext, l10n, isConnected!);
      case 'Importer':
        return _getImporterSpeedDialChildren(
            displayContext, l10n, isConnected!);
      //ToDo Add more cases for other roles
      default:
        return [];
    }
  }

  //!########################## FARMER OPTIONS ####################

  List<SpeedDialChild> _getFarmerSpeedDialChildren(
      String displayContext, AppLocalizations l10n, bool isConnected) {
    return [
      SpeedDialChild(
        child: const Icon(Icons.agriculture),
        label: l10n.startHarvestOffline,
        labelStyle: TextStyle(color: Colors.black54),
        onTap: () {
          // TODO: Implement start harvest action
        },
      ),
      SpeedDialChild(
        child: const Icon(Icons.transfer_within_a_station),
        label: l10n.handOverHarvestToTrader,
        labelStyle: TextStyle(color: Colors.black54),
        onTap: () {
          // TODO: Implement hand over harvest action
        },
      ),
    ];
  }

  //!########################## FARM MANAGER OPTIONS ####################
  List<SpeedDialChild> _getFarmManagerSpeedDialChildren(
      String displayContext, AppLocalizations l10n, bool isConnected) {
    return [
      SpeedDialChild(
        child: const Icon(Icons.person_add),
        label: l10n.addEmployee,
        labelStyle: TextStyle(color: Colors.black54),
        onTap: () {
          // TODO: Implement add employee action
        },
      ),
      SpeedDialChild(
        child: const Icon(Icons.add_box),
        label: l10n.addContainer,
        labelStyle: TextStyle(color: Colors.black54),
        onTap: () {
          // TODO: Implement add container action
        },
      ),
    ];
  }

  //!########################## TRADER OPTIONS ####################
  List<SpeedDialChild> _getTraderSpeedDialChildren(
      String displayContext, AppLocalizations l10n, bool isConnected) {
    return [
      SpeedDialChild(
        child: const Icon(Icons.shopping_basket),
        label: "Buy Coffee",
        labelStyle: TextStyle(color: Colors.black54),
        onTap: () async {
          showBuyCoffeeOptions(context);
        },
      ),
      //ToDo: Make conditional only if there are selected containers
      // if (batchSalePossible)
      //   SpeedDialChild(
      //     child: const Icon(Icons.devices),
      //     label: "Bulk Sell Coffee online",
      //     labelStyle: TextStyle(color: Colors.black54),
      //     onTap: () async {
      //       _showSellCoffeeOptions(context);
      //     },
      //   ),
      if (batchSalePossible)
        SpeedDialChild(
          child: const Icon(Icons.merge_outlined),
          label: "Aggregate items",
          labelStyle: TextStyle(color: Colors.black54),
          onTap: () async {
            await showAggregateItemsDialog(context, selectedItems);
            setState(() {});
          },
        ),
      SpeedDialChild(
        child: const Icon(Icons.add_box),
        label: "Add new empty item",
        labelStyle: TextStyle(color: Colors.black54),
        onTap: () async {
          await _showAddEmptyItemDialog(context);
          setState(() {});
        },
      )
    ];
  }

//!########################## PROCESSOR OPTIONS ####################

  List<SpeedDialChild> _getProcessorSpeedDialChildren(
      String displayContext, AppLocalizations l10n, bool isConnected) {
    return [
      SpeedDialChild(
        child: const Icon(Icons.shopping_basket),
        label: "Buy Coffee",
        labelStyle: TextStyle(color: Colors.black54),
        onTap: () async {
          showBuyCoffeeOptions(context);
        },
      ),
      //ToDo: Make conditional only if there are selected containers
      // if (batchSalePossible)
      //   SpeedDialChild(
      //     child: const Icon(Icons.devices),
      //     label: "Bulk-Sell Coffee online",
      //     labelStyle: TextStyle(color: Colors.black54),
      //     onTap: () async {
      //       await fshowInfoDialog(context, "Not implemented.");
      //     },
      //   ),
      if (batchSalePossible)
        SpeedDialChild(
          child: const Icon(Icons.merge_outlined),
          label: "Aggregate items",
          labelStyle: TextStyle(color: Colors.black54),
          onTap: () async {
            await _showAddEmptyItemDialog(context);
            setState(() {});
          },
        ),
      SpeedDialChild(
        child: const Icon(Icons.add_box),
        label: "Add new empty item",
        labelStyle: TextStyle(color: Colors.black54),
        onTap: () async {
          await fshowInfoDialog(context, "Not yet implemented.");
        },
      ),
      // SpeedDialChild(
      //   child: const Icon(Icons.add_box),
      //   label: "ToDo: Import/Export Data",
      //   labelStyle: TextStyle(color: Colors.black54),
      //   onTap: () {
      //     //ToDo
      //   },
      // ),
    ];
  }

//!########################## IMPORTER OPTIONS ####################

  List<SpeedDialChild> _getImporterSpeedDialChildren(
      String displayContext, AppLocalizations l10n, bool isConnected) {
    if (displayContext == 'action' && isConnected) {
      return [
        SpeedDialChild(
          child: const Icon(Icons.shopping_basket),
          label: "Buy Coffee",
          labelStyle: TextStyle(color: Colors.black54),
          onTap: () async {
            showBuyCoffeeOptions(context);
          },
        ),
        // SpeedDialChild(
        //   child: const Icon(Icons.add_box),
        //   label: l10n.addContainer,
        //   labelStyle: TextStyle(color: Colors.black54),
        //   onTap: () {
        //     // TODO: Implement add container action
        //   },
        // ),
      ];
    } else {
      return [];
    }
  }

  // void showBuyCoffeeOptions(BuildContext context,{String? receivingContainerUID}) {
  //   showDialog(
  //     context: context,
  //     builder: (BuildContext context) {
  //       return AlertDialog(
  //         title: Text(
  //           'Select Buy Coffee Option',
  //           style: TextStyle(color: Colors.black),
  //           textAlign: TextAlign.center,
  //         ),
  //         content: ConstrainedBox(
  //           constraints: BoxConstraints(maxWidth: 300),
  //           child: Container(
  //             width: double.maxFinite,
  //             child: Column(
  //               mainAxisAlignment: MainAxisAlignment.center,
  //               mainAxisSize: MainAxisSize.min,
  //               children: [
  //                 Row(
  //                   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
  //                   children: [
  //                     Expanded(
  //                       child: _buildOptionButton(
  //                         context,
  //                         icon: Icons.credit_card,
  //                         label: 'CIAT first sale',
  //                         onTap: () async {
  //                           Navigator.of(context).pop();
  //                           //ToDo: Find out if First Sale or sale of selling container
  //                           FirstSaleProcess buyCoffeeProcess =
  //                               new FirstSaleProcess();
  //                           if (receivingContainerUID==null)
  //                           await buyCoffeeProcess.startProcess(context);
  //                           else
  //                           await buyCoffeeProcess.startProcess(context,receivingContainerUID:receivingContainerUID);

  //                           repaintContainerList.value = true;
  //                         },
  //                       ),
  //                     ),
  //                     SizedBox(width: 16), // Add spacing between buttons
  //                     Expanded(
  //                       child: _buildOptionButton(
  //                         context,
  //                         icon: Icons.devices,
  //                         label: 'Device-to-device',
  //                         onTap: () async {
  //                           Navigator.of(context).pop();
  //                           // TODO: Implement device-to-device process
  //                           StepperBuyCoffee buyCoffeeProcess =
  //                               new StepperBuyCoffee();
  //                           await buyCoffeeProcess.startProcess(context);

  //                           repaintContainerList.value = true;

  //                           // await fshowInfoDialog(
  //                           //     context, "Not implemented yet.");
  //                           // print('Device-to-device selected');
  //                         },
  //                       ),
  //                     ),
  //                   ],
  //                 ),
  //                 // SizedBox(height: 16), // Add vertical spacing
  //                 // _buildOptionButton(
  //                 //   context,
  //                 //   icon: Icons.cloud_upload,
  //                 //   label: 'Device-to-cloud',
  //                 //   onTap: () {
  //                 //     Navigator.of(context).pop();
  //                 //     // TODO: Implement device-to-cloud process
  //                 //     print('Device-to-cloud selected');
  //                 //   },
  //                 // ),
  //               ],
  //             ),
  //           ),
  //         ),
  //       );
  //     },
  //   );
  // }

  void _showSellCoffeeOptions(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Select Sell Coffee Option',
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
                          icon: Icons.cloud_upload,
                          label: 'Device-to-cloud',
                          onTap: () async {
                            Navigator.of(context).pop();
                            // TODO: Implement device-to-cloud process
                            await fshowInfoDialog(
                                context, "Not implemented yet.");
                            print('Device-to-cloud selected');
                          },
                        ),
                      ),
                      SizedBox(width: 16), // Add spacing between buttons
                      Expanded(
                        child: _buildOptionButton(
                          context,
                          icon: Icons.devices,
                          label: 'Device-to-device',
                          onTap: () async {
                            Navigator.of(context).pop();
                            // TODO: Implement device-to-device process
                            await fshowInfoDialog(
                                context, "Not implemented yet.");
                            print('Device-to-device selected');
                          },
                        ),
                      ),
                    ],
                  ),
                  // SizedBox(height: 16), // Add vertical spacing
                  // _buildOptionButton(
                  //   context,
                  //   icon: Icons.cloud_upload,
                  //   label: 'Device-to-cloud',
                  //   onTap: () {
                  //     Navigator.of(context).pop();
                  //     // TODO: Implement device-to-cloud process
                  //     print('Device-to-cloud selected');
                  //   },
                  // ),
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
          maxLines: 2, // Allow text to wrap to two lines if needed
          overflow: TextOverflow.ellipsis, // Add ellipsis if text is too long
        ),
      ],
    );
  }

  Future<void> _showAddEmptyItemDialog(BuildContext context) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AddEmptyItemDialog(
          onItemAdded: (Map<String, dynamic> newItem) {
            // Handle the newly added item
            print("New item added: ${newItem["identity"]["UID"]}");
            repaintContainerList.value = true;
          },
        );
      },
    );
  }
}
