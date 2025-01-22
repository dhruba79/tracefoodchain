import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:trace_foodchain_app/helpers/database_helper.dart';
import 'package:trace_foodchain_app/main.dart';
import 'package:trace_foodchain_app/models/whisp_result_model.dart';
import 'package:trace_foodchain_app/providers/app_state.dart';
import 'package:trace_foodchain_app/services/open_ral_service.dart';
import 'package:trace_foodchain_app/services/pdf_generator_service.dart';
import 'package:trace_foodchain_app/services/service_functions.dart';
import 'package:trace_foodchain_app/services/whisp_api_service.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:trace_foodchain_app/widgets/coffe_actions_menu.dart';
import 'package:trace_foodchain_app/widgets/container_actions_menu.dart';

final Set<String> selectedItems = {};

ValueNotifier<bool> rebuildDDS = ValueNotifier<bool>(false);
bool multiselectPossible = false;

class ItemsList extends StatefulWidget {
  final BuildContext context;
  final Function(Set<String>) onSelectionChanged;

  const ItemsList({
    super.key,
    required this.context,
    required this.onSelectionChanged,
  });

  @override
  State<ItemsList> createState() => _ItemsListState();
}

class _ItemsListState extends State<ItemsList> {
  final Set<String> _allContainerUids = {};
  final ValueNotifier<bool> _selectionChanged = ValueNotifier<bool>(false);
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  final WhispApiService _apiService =
      WhispApiService(baseUrl: 'https://whisp.openforis.org');
  //ToDo: Read from WHISP cloudConnector
  AnalysisResult? _result;

  final PdfGenerator _pdfGenerator = PdfGenerator();

  String? _errorMessage;

  bool _isLoading = false;

  bool _isGeneratingPdf = false;

  void _toggleItemSelection(String uid) {
    if (selectedItems.contains(uid)) {
      selectedItems.remove(uid);
    } else {
      selectedItems.add(uid);
    }
    _selectionChanged.value = !_selectionChanged.value;
    widget.onSelectionChanged(selectedItems);
  }

  Future<List<Map<String, dynamic>>> _performAnalysis(
      List<String> plotList) async {
    final l10n = AppLocalizations.of(context)!;
    _errorMessage = null;
    _isLoading = true;
    rebuildDDS.value = true;

    List<Map<String, dynamic>> rList = [];
    debugPrint("calling WHISP to get deforestation risk");
    try {
      final result = await _apiService.analyzeGeoIds(plotList);

      _result = result;
      for (final plot in result.data) {
        rList.add(
            {"geoid": plot["geoid"], "deforestation_risk": plot["EUDR_risk"]});
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            backgroundColor: Colors.red,
            content: Text(l10n.pdfGenerationError)),
      );
    } finally {
      _isLoading = false;
      rebuildDDS.value = true;
    }
    return rList;
  }

  Future<void> _generateAndSharePdf(List<Map<String, dynamic>> plots) async {
    final l10n = AppLocalizations.of(context)!;
    if (_result == null) {
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(content: Text('Please perform analysis first')),
      // );
      return;
    }

    setState(() {
      _isGeneratingPdf = true;
    });

    try {
      final pdfGenerator = PdfGenerator();
      final pdfBytes = await pdfGenerator.generatePdf(
        operatorName: l10n.sampleOperator,
        operatorAddress: l10n.sampleAddress,
        eoriNumber: l10n.sampleEori,
        hsCode: l10n.sampleHsCode,
        description: l10n.sampleDescription,
        tradeName: l10n.sampleTradeName,
        scientificName: l10n.sampleScientificName,
        quantity: l10n.sampleQuantity,
        country: l10n.sampleCountry,
        plots: plots,
        signatoryName: l10n.sampleName,
        signatoryFunction: l10n.sampleFunction,
        date: DateTime.now().toString(),
      );

      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: 'due_diligence_statement.pdf',
      );
    } catch (e) {
      print('Error generating or sharing PDF: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              (AppLocalizations.of(context)!.pdfError(e.toString()) as String)),
        ),
      );
    } finally {
      setState(() {
        _isGeneratingPdf = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final l10n = AppLocalizations.of(context)!;
    if (l10n == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return ValueListenableBuilder(
        valueListenable: repaintContainerList,
        builder: (context, bool value, child) {
          repaintContainerList.value = false;
          return ValueListenableBuilder(
              valueListenable: _selectionChanged,
              builder: (context, _, __) {
                return FutureBuilder<List<Map<String, dynamic>>>(
                  future: _databaseHelper
                      .getContainers(appUserDoc!["identity"]["UID"]),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                          child: CircularProgressIndicator(
                              color: Color(0xFF35DB00)));
                    }
                    if (snapshot.hasError) {
                      return Center(
                          child: Text('Error: ${snapshot.error}',
                              style: const TextStyle(color: Colors.black)));
                    }
                    // final deliveries = snapshot.data ?? [];
                    dynamic deliveries = [];

                    //ToDo: Nur Container anzeigen, die nicht genested sind
                    for (final delivery in snapshot.data!) {
                      if (delivery["currentGeolocation"]["container"]["UID"] ==
                          "unknown" ||delivery["currentGeolocation"]["container"]["UID"] ==
                          "") {
                        deliveries.add(delivery);
                      }
                    }

                    if (deliveries.isEmpty) {
                      return Center(
                          child: Text(
                              AppLocalizations.of(context)!.noActiveItems,
                              style: const TextStyle(color: Colors.black)));
                    }

                    if (deliveries.length > 1) {
                      multiselectPossible = true;
                    } else {
                      multiselectPossible = false;
                    }

                    _allContainerUids.clear();
                    for (var container in deliveries) {
                      _allContainerUids.add(container["identity"]["UID"]);
                    }
                    return CustomScrollView(
                      slivers: [
                        SliverToBoxAdapter(
                          child: _buildSelectAllCheckbox(deliveries.length),
                        ),
                        SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final container = deliveries[index];
                              dynamic results;
                              return _buildContainerItem(container); //!results
                            },
                            childCount: deliveries.length,
                          ),
                        ),
                      ],
                    );
                  },
                );
              });
        });
  }

  Widget _buildContainerItem(Map<String, dynamic> container) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _databaseHelper.getContainedItems(container["identity"]["UID"]),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingCard();
        }

        if (snapshot.hasError) {
          return _buildErrorCard(snapshot.error.toString());
        }

        final contents = snapshot.data ?? [];
        if (contents.isEmpty) {
          return _buildEmptyCard(container);
        }

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCardHeader(container, contents),
              ...contents.map((item) => _buildContentItem(item)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContentItem(Map<String, dynamic> item) {
    final l10n = AppLocalizations.of(context)!;
    final itemType = item['template']['RALType'];
    if (itemType != 'coffee') {
      return _buildNestedContainer(item);
    } else {
      return _buildCoffeeItem(item);
    }
  }

  Widget _buildNestedContainer(Map<String, dynamic> container) {
    final l10n = AppLocalizations.of(context)!;
    return FutureBuilder<List<Map<String, dynamic>>>(
        future: _databaseHelper.getContainedItems(container["identity"]["UID"]),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingIndicator();
          }
          if (snapshot.hasError) {
            return Text(snapshot.error.toString());
          }
          final nestedContents = snapshot.data ?? [];
          return ExpansionTile(
            // leading: Icon(Icons.inbox, color: Colors.black54),
            title: _buildCardHeader(container, nestedContents),
            children: [
              Column(
                children: nestedContents
                    .map((item) => _buildContentItem(item))
                    .toList(),
              )
            ],
          );
        });
  }

  Widget _buildCoffeeItem(Map<String, dynamic> coffee) {
    final appState = Provider.of<AppState>(context);
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start, // Align items to the top
        children: [
          // Icon positioned at the top-left
          Padding(
              padding: const EdgeInsets.only(top: 6.0, right: 16.0),
              child: Image.asset(
                'assets/images/cappuccino.png',
                width: 24, // You can adjust the size here
                height: 24,
              )
              //  Icon(FontAwesomeIcons.seedling, color: Colors.brown, size: 24),
              ),
          // Content column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(
                          l10n.coffee,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black54,
                          ),
                        ),
                        Text(
                          (l10n.speciesLabel(getSpecificPropertyfromJSON(
                              coffee, "species")) as String),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w100,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 8),
                    coffee["needsSync"] != null
                        ? Tooltip(
                            message: l10n.notSynced, //"Not synced to cloud",
                            child: Icon(Icons.cloud_off, color: Colors.black54))
                        : Tooltip(
                            message: l10n.synced, //"Synced with cloud",
                            child:
                                Icon(Icons.cloud_done, color: Colors.black54)),
                    CoffeeActionsMenu(
                      isConnected: appState.isConnected,
                      coffee: coffee,
                      onProcessingStateChange: (updatedCoffee) {
                        // Handle the updated coffee item
                        setState(() {
                          // Update your state or data as needed
                        });
                      },
                      onRepaint: () {
                        // Trigger a repaint of your list or parent widget
                        setState(() {
                          repaintContainerList.value = true;
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.amount(
                      getSpecificPropertyfromJSON(coffee, "amount").toString(),
                      getSpecificPropertyUnitfromJSON(coffee, "amount")),
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  (l10n.processingStep(getSpecificPropertyfromJSON(
                      coffee, "processingState")) as String),
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 4),
                FutureBuilder<Map<String, dynamic>>(
                  future: _databaseHelper.getFirstSale(coffee),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Color(0xFF35DB00),
                          strokeWidth: 2,
                        ),
                      );
                    }
                    if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}',
                          style:
                              const TextStyle(color: Colors.red, fontSize: 12));
                    }
                    final content = snapshot.data ?? {};
                    if (content.isEmpty) {
                      return Text(l10n.noPlotFound,
                          style: const TextStyle(
                              color: Colors.black54, fontSize: 12));
                    }
                    final field = content["inputObjects"][1];
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            (l10n.boughtOn(
                                formatTimestamp(content["existenceStarts"]) ??
                                    "unknown") as String),
                            style: const TextStyle(
                                fontSize: 12, color: Colors.black54)),
                        Text(
                          (l10n.fromPlot(truncateUID(
                                  field["identity"]["alternateIDs"][0]["UID"]))
                              as String),
                          style: const TextStyle(
                              fontSize: 12, color: Colors.black54),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingCard() {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: SizedBox(
        height: 100,
        child: const Center(
          child: SizedBox(
            width: 30,
            height: 30,
            child: CircularProgressIndicator(
              color: Color(0xFF35DB00),
              strokeWidth: 3,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorCard(String error) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: ListTile(
        leading: const Icon(Icons.error, color: Colors.red),
        title: Text(l10n.errorLabel),
        subtitle: Text(error),
      ),
    );
  }

  Widget _buildEmptyCard(Map<String, dynamic> container) {
    final l10n = AppLocalizations.of(context)!;
    final appState = Provider.of<AppState>(context);
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        child: ListTile(
          leading: multiselectPossible
              ? Checkbox(
                  value: selectedItems.contains(container["identity"]["UID"]),
                  onChanged: (bool? value) {
                    _toggleItemSelection(container["identity"]["UID"]);
                  },
                )
              : null,
          title: Row(
            children: [
              getContainerIcon(container["template"]["RALType"]),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                    (AppLocalizations.of(context)!.containerIsEmpty(
                            getContainerTypeName(container["template"]["RALType"], context) ,
                            container["identity"]["alternateIDs"][0]["UID"])
                        as String),
                    style: const TextStyle(color: Colors.black)),
              ),
              Row(
                children: [
                  //*Sync state with cloud

                  container["needsSync"] != null
                      ? Tooltip(
                          message: l10n.notSynced, // "Not synced to cloud",
                          child: Icon(Icons.cloud_off, color: Colors.black54))
                      : Tooltip(
                          message: l10n.synced, //"Synced with cloud",
                          child: Icon(Icons.cloud_done,
                              color: Colors.black54)), //cloud_done

                  const SizedBox(width: 12),
                  ContainerActionsMenu(
                    container: container,
                    contents: const [],
                    onPerformAnalysis: _performAnalysis,
                    onGenerateAndSharePdf: _generateAndSharePdf,
                    onRepaint: () {
                      setState(() {
                        repaintContainerList.value = true;
                      });
                    },
                    isConnected: appState.isConnected,
                    onDeleteContainer: (String uid) async {
                      await _databaseHelper
                          .deleteFromBox<Map<dynamic, dynamic>>(
                              'localStorage', uid);
                    },
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardHeader(
      Map<String, dynamic> container, List<Map<String, dynamic>> contents) {
    final l10n = AppLocalizations.of(context)!;
    final appState = Provider.of<AppState>(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12.0, 0, 0, 0),
          child: Row(
            children: [
              if (multiselectPossible)
                Checkbox(
                  value: selectedItems.contains(container["identity"]["UID"]),
                  onChanged: (bool? value) {
                    _toggleItemSelection(container["identity"]["UID"]);
                  },
                ),
              const SizedBox(width: 6),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(0, 4, 0, 0),
                        child:
                            getContainerIcon(container["template"]["RALType"]),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        getContainerTypeName(
                            container["template"]["RALType"], context),
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87),
                      ),
                    ],
                  ),
                  Text(
                    (AppLocalizations.of(context)!.idWithBrackets(truncateUID(
                            container["identity"]["alternateIDs"][0]["UID"]))
                        as String),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w100,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Row(
          children: [
            //*Sync state with cloud

            container["needsSync"] != null
                ? Tooltip(
                    message: l10n.notSynced, // "Not synced to cloud",
                    child: Icon(Icons.cloud_off, color: Colors.black54))
                : Tooltip(
                    message: l10n.synced, //"Synced with cloud",
                    child: Icon(Icons.cloud_done,
                        color: Colors.black54)), //cloud_done

            const SizedBox(width: 12),
            // Popupmenu

            ContainerActionsMenu(
              container: container,
              contents: contents,
              onPerformAnalysis: _performAnalysis,
              onGenerateAndSharePdf: _generateAndSharePdf,
              onRepaint: () {
                setState(() {
                  repaintContainerList.value = true;
                });
              },
              isConnected: appState.isConnected,
              onDeleteContainer: (String uid) async {
                await _databaseHelper.deleteFromBox<Map<dynamic, dynamic>>(
                    'localStorage', uid);
              },
            )
          ],
        )
      ],
    );
  }

  Widget _buildLoadingIndicator() {
    return const Center(
      child: SizedBox(
        width: 30,
        height: 30,
        child: CircularProgressIndicator(
          color: Color(0xFF35DB00),
          strokeWidth: 3,
        ),
      ),
    );
  }

  Widget _buildSelectAllCheckbox(int itemCount) {
    final l10n = AppLocalizations.of(context)!;
    if (itemCount <= 1) return const SizedBox.shrink();

    bool allSelected = selectedItems.length == itemCount;
    return CheckboxListTile(
      title: Text(l10n.selectAll, style: const TextStyle(color: Colors.black)),
      value: allSelected,
      onChanged: (bool? value) {
        if (value == true) {
          selectedItems.addAll(_allContainerUids);
        } else {
          selectedItems.clear();
        }
        _selectionChanged.value = !_selectionChanged.value;
        widget.onSelectionChanged(selectedItems);
      },
      controlAffinity: ListTileControlAffinity.leading,
    );
  }

  Widget getContainerIcon(String containerType) {
    switch (containerType) {
      case "bag":
        return const Icon(Icons.shopping_bag);
      case "container":
        return const Icon(Icons.inventory_2);
      case "building":
        return const Icon(Icons.business);
      case "transportVehicle":
        return const Icon(Icons.local_shipping);

      default:
        return const Icon(Icons.help);
    }
  }

  String getContainerTypeName(String containerType, BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    switch (containerType) {
      case "bag":
        return l10n.bag;
      case "container":
        return l10n.container;
      case "building":
        return l10n.building;
      case "transportVehicle":
        return l10n.transportVehicle;

      default:
        return l10n.container;
    }
  }
}
