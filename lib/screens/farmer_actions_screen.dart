import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:trace_foodchain_app/helpers/database_helper.dart';
import 'package:trace_foodchain_app/main.dart';
import 'package:trace_foodchain_app/models/harvest_model.dart';
import 'package:trace_foodchain_app/providers/app_state.dart';
import 'package:trace_foodchain_app/services/scanning_service.dart';
import 'package:trace_foodchain_app/widgets/items_list_widget.dart';
import 'package:trace_foodchain_app/widgets/shared_widgets.dart';
import 'package:uuid/uuid.dart';

var uuid = Uuid();

class FarmerActionsScreen extends StatefulWidget {
  const FarmerActionsScreen({super.key});

  @override
  _FarmerActionsScreenState createState() => _FarmerActionsScreenState();
}

class _FarmerActionsScreenState extends State<FarmerActionsScreen> {
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final appState = Provider.of<AppState>(context);
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
          }
        ),
      ),
    );
  }
}
