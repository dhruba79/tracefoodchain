import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:trace_foodchain_app/helpers/database_helper.dart';
import 'package:trace_foodchain_app/main.dart';
import 'package:trace_foodchain_app/widgets/items_list_widget.dart';
import 'package:trace_foodchain_app/widgets/shared_widgets.dart';

class TraderScreen extends StatefulWidget {
  const TraderScreen({super.key});

  @override
  _TraderScreenState createState() => _TraderScreenState();
}

class _TraderScreenState extends State<TraderScreen> {
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Theme(
      data: customTheme,
      child: Scaffold(
        body: ItemsList(
          context: context,
          onSelectionChanged: (selectedItems) {
            if (selectedItems.length > 1) {
              batchSalePossible = true;
              rebuildSpeedDial.value = true;
            } else {
              batchSalePossible = false;
              rebuildSpeedDial.value = true;
            }
          },
         
        ),
      ),
    );
  }

  void _showBuyHarvestDialog(
      BuildContext context, Map<String, dynamic> harvest) {
    final quantityController = TextEditingController();
    final priceController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.buyHarvest),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
                '${harvest['crop_type']} - ${harvest['quantity']} ${harvest['unit']}'),
            TextField(
              controller: quantityController,
              decoration: const InputDecoration(labelText: 'Quantity to buy'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: priceController,
              decoration: const InputDecoration(labelText: 'Price per unit'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              final quantity = double.tryParse(quantityController.text);
              final price = double.tryParse(priceController.text);
              if (quantity != null && price != null) {
                try {
                  // await _databaseHelper.buyHarvest(harvest['id'], quantity, price);//ToDo Missing => HarvestModel
                  await _databaseHelper.buyHarvest({}, quantity, price);
                  Navigator.pop(context);
                  setState(() {});
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content:
                          Text(AppLocalizations.of(context)!.invalidInput)),
                );
              }
            },
            child: Text(AppLocalizations.of(context)!.confirm),
          ),
        ],
      ),
    );
  }

  void _showSellHarvestDialog(
      BuildContext context, Map<String, dynamic> inventoryItem) {
    final quantityController = TextEditingController();
    final priceController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.sellHarvest),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
                '${inventoryItem['crop_type']} - ${inventoryItem['quantity']} ${inventoryItem['unit']}'),
            TextField(
              controller: quantityController,
              decoration: const InputDecoration(labelText: 'Quantity to sell'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: priceController,
              decoration: const InputDecoration(labelText: 'Price per unit'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              final quantity = double.tryParse(quantityController.text);
              final price = double.tryParse(priceController.text);
              if (quantity != null && price != null) {
                try {
                  await _databaseHelper.sellHarvest(
                      inventoryItem['id'], quantity, price);
                  Navigator.pop(context);
                  setState(() {});
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.toString())),
                  );
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content:
                          Text(AppLocalizations.of(context)!.invalidInput)),
                );
              }
            },
            child: Text(AppLocalizations.of(context)!.confirm),
          ),
        ],
      ),
    );
  }

  void _showEditInventoryItemDialog(
      BuildContext context, Map<String, dynamic> item) {
    final quantityController =
        TextEditingController(text: item['quantity'].toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.editInventoryItem),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${item['crop_type']} (${item['unit']})'),
            TextField(
              controller: quantityController,
              decoration: const InputDecoration(labelText: 'Quantity'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              final quantity = double.tryParse(quantityController.text);
              if (quantity != null) {
                try {
                  await _databaseHelper.updateInventoryItem({
                    'id': item['id'],
                    'crop_type': item['crop_type'],
                    'quantity': quantity,
                    'unit': item['unit'],
                  });
                  Navigator.pop(context);
                  setState(() {});
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error updating inventory: $e')),
                  );
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content:
                          Text(AppLocalizations.of(context)!.invalidInput)),
                );
              }
            },
            child: Text(AppLocalizations.of(context)!.save),
          ),
        ],
      ),
    );
  }
}
