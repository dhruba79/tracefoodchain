import 'package:flutter/material.dart';
import 'package:trace_foodchain_app/services/service_functions.dart';
import 'package:trace_foodchain_app/widgets/online_sale_dialog.dart';
import 'package:trace_foodchain_app/widgets/shared_widgets.dart';
import 'package:trace_foodchain_app/widgets/stepper_sell_coffee.dart';

class CoffeeActionsMenu extends StatelessWidget {
  final Map<String, dynamic> coffee;
  final Function(Map<String, dynamic>) onProcessingStateChange;
  final VoidCallback onRepaint;
  final bool isConnected;

  const CoffeeActionsMenu({
    Key? key,
    required this.coffee,
    required this.onProcessingStateChange,
    required this.onRepaint,
    required this.isConnected,
  }) : super(key: key);

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
              title: Text("Sell coffee offline",
                  style: TextStyle(color: Colors.black)),
              onTap: () async {
                Navigator.pop(context, "close menu");
                StepperSellCoffee sellCoffeeProcess = StepperSellCoffee();
                await sellCoffeeProcess.startProcess(context);
                onRepaint();
              },
            ),
          ),
          if (isConnected && coffee["needsSync"] == null)
            PopupMenuItem(
              child: ListTile(
                leading: Image.asset(
                  'assets/images/cappuccino.png',
                  width: 24,
                  height: 24,
                ),
                title: Text("Sell coffee online",
                    style: TextStyle(color: Colors.black)),
                onTap: () async {
                  Navigator.pop(context, "close menu");
                  Map<String, dynamic> itemToSell = coffee;
                  if (itemToSell.isNotEmpty) {
                    await showDialog(
                      context: context,
                      builder: (context) =>
                          OnlineSaleDialog(itemsToSell: [itemToSell]),
                    );
                  } else {
                    await fshowInfoDialog(
                        context, "Please select an item to sell first.");
                  }
                  onRepaint();
                },
              ),
            ),
          PopupMenuItem(
            child: ListTile(
              leading: Icon(Icons.change_circle, size: 20),
              title: Text("Change processing state",
                  style: TextStyle(color: Colors.black)),
              onTap: () async {
                Navigator.pop(context, "close menu");
                await showProcessingStateDialog(coffee, context);
                onRepaint();
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
                  showChangeContainerDialog(context, coffee);
                  onRepaint();
                }),
          ),
        ],
      ),
    );
  }
}
