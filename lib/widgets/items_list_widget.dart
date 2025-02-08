import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:trace_foodchain_app/helpers/database_helper.dart';
import 'package:trace_foodchain_app/main.dart';
import 'package:trace_foodchain_app/models/whisp_result_model.dart';
import 'package:trace_foodchain_app/providers/app_state.dart';
import 'package:trace_foodchain_app/screens/settings_screen.dart';
import 'package:trace_foodchain_app/services/open_ral_service.dart';
import 'package:trace_foodchain_app/services/pdf_generator_service.dart';
import 'package:trace_foodchain_app/services/service_functions.dart';
import 'package:trace_foodchain_app/services/whisp_api_service.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:trace_foodchain_app/widgets/coffe_actions_menu.dart';
import 'package:trace_foodchain_app/widgets/container_actions_menu.dart';

// Helper function: Conversion of quantity based on units
double convertQuantity(double quantity, String fromUnit, String toUnit) {
  // Example: Currently no conversion factor is applied. Extend if necessary.
  if (fromUnit == toUnit) {
    return quantity;
  }
  final weightUnits = getWeightUnits(country);
  final toKgFactorFrom = weightUnits.firstWhere(
      (uni) => uni["name"] == fromUnit,
      orElse: () => {"factor": 1.0})["factor"];
  final toKgFactorTo = weightUnits.firstWhere(
      (uni) => uni["name"] == toUnit,
      orElse: () => {"factor": 1.0})["factor"];
  // Convert the given quantity from its current unit to kilograms
  final quantityInKg = quantity * toKgFactorFrom;
  // Convert the quantity from kilograms to the target unit
  return quantityInKg / toKgFactorTo;

}

// Calculates the total sum of quantities of coffee items within a container
double computeCoffeeSum(Map<String, dynamic> container, double max_capacity) {
  double sum = 0.0;
  // Assumption: The container may have a "contents" field that contains all nested items.
  List<Map<String, dynamic>> stack = [];

  // Instead of directly using container["contents"], we recursively scan localStorage
  // to fetch all contained items using valid geolocation UIDs until no valid UID ("") is found.

  void addContainedItems(
      Map<String, dynamic> parentContainer, List<Map<String, dynamic>> stack) {
    if (parentContainer.containsKey("identity") &&
        parentContainer["identity"]["UID"] != null) {
      for (var doc in localStorage.values) {
        try {
          final childContainerUID =
              doc["currentGeolocation"]["container"]["UID"];
          // Check if this doc is a child of the current container and has a valid UID
          if (childContainerUID == parentContainer["identity"]["UID"] &&
              childContainerUID != "") {
            final child = Map<String, dynamic>.from(doc);
            if (child["template"] != null &&
                child["template"]["RALType"] == "coffee") {
              if ((isTestmode && child.containsKey("isTestmode")) ||
                  (!isTestmode && !child.containsKey("isTestmode")))
                stack.add(child);
            }
            // Recursively add children of this found container
            addContainedItems(child, stack);
          }
        } catch (e) {
          // Ignore any parsing errors
        }
      }
    }
  }

  addContainedItems(container, stack);

  while (stack.isNotEmpty) {
    final item = stack.removeLast();

    if (item["template"] != null && item["template"]["RALType"] == "coffee") {
      // Determine the quantity of the coffee item
      var qtyRaw = getSpecificPropertyfromJSON(item, "amount");
      double qty = double.tryParse(qtyRaw.toString()) ?? 0.0;
      // Determine units
      String containerUnit =
          getSpecificPropertyUnitfromJSON(container, "max capacity") ?? "";
      String coffeeUnit = getSpecificPropertyUnitfromJSON(item, "amount") ?? "";
      // Convert quantity (if necessary)
      double converted = convertQuantity(qty, coffeeUnit, containerUnit);
      //ToDo: Now we must know which quality the coffee was when initially purchased
      //ToDo: Based on this we need to know which quality the coffee has now and use the weightCorrectionFactor to calculate the current weight
      sum += converted;
    }
    // If the item contains further nested contents
    if (item.containsKey("contents") && item["contents"] is List) {
      stack.addAll(List<Map<String, dynamic>>.from(item["contents"]));
    }
  }

  return double.parse((max_capacity - sum).toStringAsFixed(2));
}

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
                              "unknown" ||
                          delivery["currentGeolocation"]["container"]["UID"] ==
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
              SizedBox(height: 8),
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
    // Share.share(coffee.toString());
    final appState = Provider.of<AppState>(context);
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,

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
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                          getSpecificPropertyfromJSON(coffee, "species"),
                          style: const TextStyle(
                            fontSize: 13,
                            // fontWeight: FontWeight.w100,
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
                          getSpecificPropertyfromJSON(coffee, "amount")
                              .toString(),
                          getSpecificPropertyUnitfromJSON(coffee, "amount")) +
                      " ${l10n.processingStep(getSpecificPropertyfromJSON(coffee, "processingState")) as String}",
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
                // const SizedBox(height: 4),
                // Text(
                //   (l10n.processingStep(getSpecificPropertyfromJSON(
                //       coffee, "processingState")) as String),
                //   style: const TextStyle(
                //     fontSize: 14,
                //     color: Colors.black54,
                //   ),
                // ),
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
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        child: ListTile(
          titleAlignment: ListTileTitleAlignment.top,
          leading: multiselectPossible
              ? Checkbox(
                  value: selectedItems.contains(container["identity"]["UID"]),
                  onChanged: (bool? value) {
                    _toggleItemSelection(container["identity"]["UID"]);
                  },
                )
              : null,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              getContainerIcon(container["template"]["RALType"]),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  (container["identity"]["name"] != null &&
                          container["identity"]["name"]
                              .toString()
                              .trim()
                              .isNotEmpty)
                      ? container["identity"]["name"]
                      : getContainerTypeName(
                          container["template"]["RALType"], context),
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
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
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text(
                  "ID: ${truncateUID(container["identity"]["alternateIDs"][0]["UID"])}",
                  style: TextStyle(color: Colors.black38)),
              Text(
                "${l10n.capacity}: ${getSpecificPropertyfromJSON(container, "max capacity") ?? "???"} ${getSpecificPropertyUnitfromJSON(container, "max capacity")}",
                style: const TextStyle(color: Colors.black38),
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
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start, //spaceBetween,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12.0, 0, 0, 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
                        child:
                            getContainerIcon(container["template"]["RALType"]),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        width: MediaQuery.of(context).size.width * 0.3,
                        child: AutoSizeText(
                          (container["identity"]["name"] != null &&
                                  container["identity"]["name"]
                                      .toString()
                                      .trim()
                                      .isNotEmpty)
                              ? container["identity"]["name"]
                              : getContainerTypeName(
                                  container["template"]["RALType"],
                                  context), // l10n.unnamedObject,
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  Text(
                      "ID: ${truncateUID(container["identity"]["alternateIDs"][0]["UID"])}",
                      style: TextStyle(
                        color: Colors.black38,
                        fontSize: 13,
                      )),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${l10n.freeCapacity}:\n${computeCoffeeSum(container, (getSpecificPropertyfromJSON(container, "max capacity") is num ? getSpecificPropertyfromJSON(container, "max capacity").toDouble() : double.tryParse(getSpecificPropertyfromJSON(container, "max capacity").toString()) ?? 0.0))} / ${(getSpecificPropertyfromJSON(container, "max capacity") is num ? getSpecificPropertyfromJSON(container, "max capacity").toDouble() : double.tryParse(getSpecificPropertyfromJSON(container, "max capacity").toString()) ?? "???")} ${getSpecificPropertyUnitfromJSON(container, "max capacity")}",
                        style: const TextStyle(
                          color: Colors.black38,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Animated progress bar for fill level
                      LayoutBuilder(builder: (context, constraints) {
                        double maxCapacity = getSpecificPropertyfromJSON(
                                container, "max capacity") is num
                            ? getSpecificPropertyfromJSON(
                                    container, "max capacity")
                                .toDouble()
                            : double.tryParse(getSpecificPropertyfromJSON(
                                        container, "max capacity")
                                    .toString()) ??
                                0.0;
                        double computedCapacity = computeCoffeeSum(container, maxCapacity);
                        double freeCapacity = computedCapacity < 0 ? 0 : computedCapacity;
                        // Calculate progress as a fraction of the available max capacity.
                        double progress = (maxCapacity > 0)
                            ? (freeCapacity / maxCapacity)
                            : 0.0;
                        progress = progress.clamp(0.0, 1.0);
                        return Stack(
                          children: [
                            Container(
                              width: 150,
                              height: 10,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(5),
                              ),
                            ),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 500),
                              width: 150 * progress,
                              height: 10,
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(5),
                              ),
                              curve: Curves.easeInOut,
                            ),
                          ],
                        );
                      })
                    ],
                  )
                ],
              ),
            ],
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
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
