import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:trace_foodchain_app/models/harvest_model.dart';
import 'package:uuid/uuid.dart';

import '../helpers/database_helper.dart';

var uuid = Uuid();

class FarmManagerScreen extends StatefulWidget {
  const FarmManagerScreen({super.key});

  @override
  _FarmManagerScreenState createState() => _FarmManagerScreenState();
}

class _FarmManagerScreenState extends State<FarmManagerScreen> {
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n!.farmManagerActions),
          bottom: TabBar(
            tabs: [
              Tab(text: l10n!.manageFarmEmployees),
              Tab(text: l10n!.manageHarvests),
              Tab(text: l10n!.manageContainers),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildEmployeeManagement(context),
            _buildHarvestManagement(context),
            _buildContainerManagement(context),
          ],
        ),
      ),
    );
  }

  Widget _buildEmployeeManagement(BuildContext context) {
    // TODO: Replace with actual employee data
    final employees = List.generate(10, (index) => 'Employee ${index + 1}');
    return ListView.builder(
      itemCount: employees.length + 1, // +1 for the "Add Employee" button
      itemBuilder: (context, index) {
        if (index == 0) {
          return ListTile(
            leading: const Icon(Icons.add),
            title: Text(AppLocalizations.of(context)!.addEmployee),
            onTap: () => _showAddEmployeeDialog(context),
          );
        }
        return ListTile(
          title: Text(employees[index - 1]),
          trailing: IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              _showEditEmployeeDialog(context, employees[index - 1]);
            },
          ),
        );
      },
    );
  }

  Widget _buildHarvestManagement(BuildContext context) {
    // TODO: Replace with actual harvest data
    final harvests = List.generate(5, (index) => 'Harvest ${index + 1}');
    return ListView.builder(
      itemCount: harvests.length + 1, // +1 for the "Add Harvest" button
      itemBuilder: (context, index) {
        if (index == 0) {
          return ListTile(
            leading: const Icon(Icons.add),
            title: Text(AppLocalizations.of(context)!.addHarvest),
            onTap: () => _showAddHarvestDialog(context),
          );
        }
        return ListTile(
          title: Text(harvests[index - 1]),
          trailing: IconButton(
            icon: const Icon(Icons.info),
            onPressed: () {
              _showHarvestDetails(
                  context, {}); //ToDo Fix: harvests[index - 1]);
            },
          ),
        );
      },
    );
  }

  Widget _buildContainerManagement(BuildContext context) {
    // TODO: Replace with actual container data
    final containers = List.generate(8, (index) => 'Container ${index + 1}');
    return ListView.builder(
      itemCount: containers.length + 1, // +1 for the "Add Container" button
      itemBuilder: (context, index) {
        if (index == 0) {
          return ListTile(
            leading: const Icon(Icons.add),
            title: Text(AppLocalizations.of(context)!.addContainer),
            onTap: () => _showAddContainerDialog(context),
          );
        }
        return ListTile(
          title: Text(containers[index - 1]),
          trailing: IconButton(
            icon: const Icon(Icons.qr_code),
            onPressed: () {
              _showContainerQRCode(context, {
                "name": "",
                "unit": "",
                "capacity": "",
                "id": containers[index - 1]
              }); //ToDo:Fix
            },
          ),
        );
      },
    );
  }

  void _showAddEmployeeDialog(BuildContext context) {
    // TODO: Implement add employee functionality
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.addEmployee),
        content: Text(AppLocalizations.of(context)!.notImplementedYet),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.ok),
          ),
        ],
      ),
    );
  }

  void _showEditEmployeeDialog(BuildContext context, String employee) {
    // TODO: Implement edit employee functionality
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.editEmployee),
        content: Text(
            '${AppLocalizations.of(context)!.notImplementedYet}: $employee'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.ok),
          ),
        ],
      ),
    );
  }

  void _showAddHarvestDialog(BuildContext context) {
    final cropTypeController = TextEditingController();
    final quantityController = TextEditingController();
    final unitController = TextEditingController();
    final dateController =
        TextEditingController(text: DateTime.now().toIso8601String());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.addHarvest),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: cropTypeController,
              decoration: const InputDecoration(labelText: 'Crop Type'),
            ),
            TextField(
              controller: quantityController,
              decoration: const InputDecoration(labelText: 'Quantity'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: unitController,
              decoration: const InputDecoration(labelText: 'Unit'),
            ),
            TextField(
              controller: dateController,
              decoration: const InputDecoration(labelText: 'Harvest Date'),
              readOnly: true,
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now(),
                );
                if (date != null) {
                  dateController.text = date.toIso8601String();
                }
              },
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
              await _databaseHelper.insertHarvest(HarvestModel(id: uuid.v4(), cropType: cropTypeController.text, quantity: double.parse(quantityController.text), unit: unitController.text, harvestDate:DateTime.parse(dateController.text) ));
                
              Navigator.pop(context);
              setState(() {});
            },
            child: Text(AppLocalizations.of(context)!.add),
          ),
        ],
      ),
    );
  }

  void _showHarvestDetails(BuildContext context, Map<String, dynamic> harvest) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.harvestDetails),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Crop Type: ${harvest['crop_type']}'),
            Text('Quantity: ${harvest['quantity']} ${harvest['unit']}'),
            Text('Harvest Date: ${harvest['harvest_date']}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.ok),
          ),
        ],
      ),
    );
  }

  void _showAddContainerDialog(BuildContext context) {
    final nameController = TextEditingController();
    final capacityController = TextEditingController();
    final unitController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.addContainer),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: capacityController,
              decoration: const InputDecoration(labelText: 'Capacity'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: unitController,
              decoration: const InputDecoration(labelText: 'Unit'),
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
              await _databaseHelper.insertContainer({
                'name': nameController.text,
                'capacity': double.parse(capacityController.text),
                'unit': unitController.text,
              });
              Navigator.pop(context);
              setState(() {});
            },
            child: Text(AppLocalizations.of(context)!.add),
          ),
        ],
      ),
    );
  }

  void _showContainerQRCode(
      BuildContext context, Map<String, dynamic> container) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.containerQRCode),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
                '${container['name']} - ${container['capacity']} ${container['unit']}'),
            const SizedBox(height: 20),
            QrImageView(
              data: 'container:${container['id']}',
              version: QrVersions.auto,
              size: 200.0,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.ok),
          ),
        ],
      ),
    );
  }
}
