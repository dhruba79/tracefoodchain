import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:trace_foodchain_app/helpers/database_helper.dart';
import 'package:trace_foodchain_app/main.dart';
import 'package:trace_foodchain_app/widgets/items_list_widget.dart';

class TraderScreen extends StatefulWidget {
  const TraderScreen({super.key});

  @override
  _TraderScreenState createState() => _TraderScreenState();
}

class _TraderScreenState extends State<TraderScreen> {

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
}
