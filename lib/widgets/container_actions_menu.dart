import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:trace_foodchain_app/helpers/database_helper.dart';
import 'package:trace_foodchain_app/services/open_ral_service.dart';
import 'package:trace_foodchain_app/widgets/online_sale_dialog.dart';
import 'package:trace_foodchain_app/widgets/shared_widgets.dart';
import 'package:trace_foodchain_app/widgets/stepper_sell_coffee.dart';
import 'package:trace_foodchain_app/services/service_functions.dart';

class ContainerActionsMenu extends StatefulWidget {
  final Map<String, dynamic> container;
  final List<Map<String, dynamic>> contents;
  final Function(List<String>) onPerformAnalysis;
  final Function(List<Map<String, dynamic>>) onGenerateAndSharePdf;
  final Function() onRepaint;
  final bool isConnected;
  final Function(String) onDeleteContainer;

  const ContainerActionsMenu({
    Key? key,
    required this.container,
    required this.contents,
    required this.onPerformAnalysis,
    required this.onGenerateAndSharePdf,
    required this.onRepaint,
    required this.isConnected,
    required this.onDeleteContainer,
  }) : super(key: key);

  @override
  _ContainerActionsMenuState createState() => _ContainerActionsMenuState();
}

class _ContainerActionsMenuState extends State<ContainerActionsMenu> {
  bool _isBuilding = false;
  final ValueNotifier<bool> rebuildDDS = ValueNotifier<bool>(false);
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 0, 8, 0),
      child: PopupMenuButton(
        icon: Icon(Icons.more_vert, color: Colors.black54),
        surfaceTintColor: Colors.white,
        tooltip: "",
        itemBuilder: (context) => [
          PopupMenuItem(
            child: ListTile(
              leading: Image.asset(
                'assets/images/cappuccino.png',
                width: 24,
                height: 24,
              ),
              title: Text("Buy coffee for this container",
                  style: TextStyle(color: Colors.black)),
              onTap: () => _buyCoffeeForContainer(context),
            ),
          ),
          PopupMenuItem(
            child: ListTile(
              leading: Icon(Icons.shopping_cart, size: 20),
              title: Text("Sell container offline",
                  style: TextStyle(color: Colors.black)),
              onTap: () => _sellContainerOffline(context),
            ),
          ),
          // if (widget.isConnected && widget.container["needsSync"] != null)
          if (widget.isConnected) //! DEBUG ONLY
            PopupMenuItem(
              child: ListTile(
                leading: Icon(Icons.shopping_cart, size: 20),
                title: Text("Sell container online",
                    style: TextStyle(color: Colors.black)),
                onTap: () async {
                  Navigator.pop(context, "close menu");
                  //1. Add selected item to the outgoing items list
                  List<Map<String, dynamic>> outgoingItems = [widget.container];
                  //2. Add nested Items
                  final nestedItems =
                      await _databaseHelper.getNestedContainedItems(
                          getObjectMethodUID(widget.container));
                  for (final item in nestedItems) {
                    outgoingItems.add(item);
                  }

                  for (final item in outgoingItems) {
                    if (item["needsSync"] != null) {
                      await fshowInfoDialog(context,
                          "Not all items are synced, please wait until all items are synced!");
                      return; //!reactivate
                    }
                  }

                  if (outgoingItems.isNotEmpty) {
                    await showDialog(
                      context: context,
                      builder: (context) =>
                          OnlineSaleDialog(itemsToSell: outgoingItems),
                    );
                  } else {
                    await fshowInfoDialog(
                        context, "Please select an item to sell first.");
                  }

                  widget.onRepaint();
                },
              ),
            ),
          PopupMenuItem(
            child: ListTile(
                leading: Icon(Icons.swap_horiz, size: 20),
                title: Text("Change location/container",
                    style: TextStyle(color: Colors.black)),
                onTap: () {
                  Navigator.pop(context, "close menu");
                  showChangeContainerDialog(context, widget.container);
                  widget.onRepaint();
                }),
          ),
          PopupMenuItem(
            child: Builder(
              builder: (context) {
                return ListTile(
                  leading: Icon(Icons.picture_as_pdf, size: 20),
                  title: ValueListenableBuilder(
                    valueListenable: rebuildDDS,
                    builder: (context, bool value, child) {
                      rebuildDDS.value = false;
                      return _isBuilding
                          ? SizedBox(
                              width: 10,
                              child: CircularProgressIndicator(
                                color: Color(0xFF35DB00),
                              ),
                            )
                          : Text("Generate DDS",
                              style: TextStyle(color: Colors.black));
                    },
                  ),
                  onTap: () => _generateDDS(context),
                );
              },
            ),
          ),
          if (kDebugMode)
            PopupMenuItem(
              child: ListTile(
                leading: Icon(Icons.delete_forever, size: 20),
                title: Text("DEBUG: Delete Container",
                    style: TextStyle(color: Colors.black)),
                onTap: () => _deleteContainer(context),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _generateDDS(BuildContext context) async {
    setState(() {
      _isBuilding = true;
      rebuildDDS.value = true;
    });

    List<String> plotList = [];
    for (final coffee in widget.contents) {
      final firstSale = await _databaseHelper.getFirstSale(coffee);
      final field = firstSale["inputObjects"][1];
      plotList.add(field["identity"]["alternateIDs"][0]["UID"]
          .replaceAll(RegExp(r'\s+'), ''));
      debugPrint(field["identity"]["alternateIDs"][0]["UID"]);
    }

    await fshowInfoDialog(context,
        "The generated DDS is only for demonstration purposes. It contains the real deforestation risks of plots but only mock data for operator and product.");

    final results = await widget.onPerformAnalysis(plotList);
    await widget.onGenerateAndSharePdf(results);

    setState(() {
      _isBuilding = false;
      rebuildDDS.value = true;
    });

    Navigator.pop(context, "close menu");
  }

  void _buyCoffeeForContainer(BuildContext context) async {
    Navigator.of(context).pop();
    await showBuyCoffeeOptions(
      context,
      receivingContainerUID: widget.container["identity"]["alternateIDs"][0]
          ["UID"],
    );
    widget.onRepaint();
  }

  void _sellContainerOffline(BuildContext context) async {
    Navigator.pop(context, "close menu");
    StepperSellCoffee sellCoffeeProcess = new StepperSellCoffee();
    await sellCoffeeProcess.startProcess(context);
    widget.onRepaint();
  }

  void _deleteContainer(BuildContext context) async {
    Navigator.pop(context, "close menu");
    await widget.onDeleteContainer(widget.container["identity"]["UID"]);
    for (var content in widget.contents) {
      await widget.onDeleteContainer(content["identity"]["UID"]);
    }
    widget.onRepaint();
  }
}
