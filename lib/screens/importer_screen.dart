import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:trace_foodchain_app/helpers/database_helper.dart';
import 'package:intl/intl.dart';
import 'package:trace_foodchain_app/main.dart';
import 'package:trace_foodchain_app/models/whisp_result_model.dart';
import 'package:trace_foodchain_app/providers/app_state.dart';
import 'package:trace_foodchain_app/services/pdf_generator_service.dart';
import 'package:trace_foodchain_app/services/whisp_api_service.dart';
import 'package:trace_foodchain_app/widgets/items_list_widget.dart';
import 'package:trace_foodchain_app/widgets/shared_widgets.dart';

ValueNotifier<bool> rebuildDDS = ValueNotifier<bool>(false);

class ImporterScreen extends StatefulWidget {
  const ImporterScreen({super.key});

  @override
  _ImporterScreenState createState() => _ImporterScreenState();
}

class _ImporterScreenState extends State<ImporterScreen> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final appState = Provider.of<AppState>(context);
    return Theme(
      data: customTheme,
      child: Scaffold(
        body: (!appState.isConnected)
            ? Center(
                child: Text("Please connect to internet to sync data",
                    style: TextStyle(color: Colors.black54)),
              )
            : ItemsList(
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

  String _getStatusText(String status, AppLocalizations l10n) {
    switch (status) {
      case 'in_transit':
        return l10n!.inTransit;
      case 'delivered':
        return l10n!.delivered;
      case 'completed':
        return l10n!.completed;
      default:
        return status;
    }
  }
}
