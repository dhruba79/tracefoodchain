import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:trace_foodchain_app/helpers/database_helper.dart';
import 'package:trace_foodchain_app/main.dart';
import 'package:trace_foodchain_app/widgets/items_list_widget.dart';
import 'package:trace_foodchain_app/constants.dart';

class TraderScreen extends StatefulWidget {
  const TraderScreen({super.key});

  @override
  _TraderScreenState createState() => _TraderScreenState();
}

class _TraderScreenState extends State<TraderScreen> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (l10n == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return Theme(
      data: customTheme,
      child: Scaffold(
        body: Stack(
          children: [
            ItemsList(
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
            const Positioned(
              left: 16,
              bottom: 16,
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: Text(
                  APP_VERSION,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
