import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:trace_foodchain_app/helpers/helpers.dart';
import 'package:trace_foodchain_app/main.dart';
import 'package:trace_foodchain_app/providers/app_state.dart';
import 'package:trace_foodchain_app/screens/peer_transfer_screen.dart';
import 'package:trace_foodchain_app/services/open_ral_service.dart';
import 'package:trace_foodchain_app/widgets/stepper_first_sale.dart';
import '../services/service_functions.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart'; // Add this import

Map<String, dynamic> receivingContainer = {};
Map<String, dynamic> field = {};
Map<String, dynamic> seller = {};
Map<String, dynamic> coffee = {};
dynamic transfer_ownership;
dynamic change_container;

class CoffeeInfo {
  String country;
  String species;
  double quantity;
  String weightUnit;
  String processingState;
  List<String> qualityReductionCriteria;

  CoffeeInfo({
    this.country = 'Honduras',
    this.species = "",
    this.quantity = 0.0,
    this.weightUnit = "t",
    this.processingState = "",
    this.qualityReductionCriteria = const [],
  });
}

class SaleInfo {
  CoffeeInfo? coffeeInfo;
  String? geoId;
  String? receivingContainerUID;
}

class StepperSellCoffee {
  Future<void> startProcess(
      BuildContext context,
      Map<String, dynamic> itemToSell,
      Map<String, dynamic> sellerInfo,
      Map<String, dynamic> oldContainer) async {
    coffee = itemToSell; // Set the global coffee variable
    seller = sellerInfo; // Set the global seller variable
    field = oldContainer; // Set the global field variable

    final l10n = AppLocalizations.of(context)!;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(l10n.sellCoffeeDeviceToDevice,
              style: const TextStyle(color: Colors.black)),
          content: CoffeeSaleStepper(),
          actions: <Widget>[
            TextButton(
              child: Text(l10n.cancel,
                  style: const TextStyle(color: Colors.black)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}

class CoffeeSaleStepper extends StatefulWidget {
  const CoffeeSaleStepper({super.key});

  // final SaleInfo saleInfo;
  // CoffeeSaleStepper({required this.saleInfo});

  @override
  _CoffeeSaleStepperState createState() => _CoffeeSaleStepperState();
}

class _CoffeeSaleStepperState extends State<CoffeeSaleStepper> {
  int _currentStep = 0;
  SaleInfo saleInfo = SaleInfo();
  List<Step> get _steps {
    final l10n = AppLocalizations.of(context)!;
    return [
      Step(
        title: Text(l10n.scanBuyerInfo,
            style: const TextStyle(color: Colors.black)),
        content: Text(l10n.scanBuyerInfoInstructions,
            style: const TextStyle(color: Colors.black)),
        isActive: _currentStep >= 0,
      ),
      Step(
        title: Text(l10n.presentInfoToBuyer,
            style: const TextStyle(color: Colors.black)),
        content: Text(l10n.presentInfoToBuyerInstructions,
            style: const TextStyle(color: Colors.black)),
        isActive: _currentStep >= 1,
      ),
    ];
  }

  void _nextStep() async {
    switch (_currentStep) {
      case 0:
        debugPrint("scan information from buyer");
        break;
      case 1:
        debugPrint("Send finished sales process back to buyer");

        break;
      // case 2:
      //   debugPrint("if bidirectional - display tag for scanning by seller");

      //   break;

      // case 2:

      //   break;
      default:
    }
    if (_currentStep < _steps.length - 1) {
      setState(() {
        _currentStep += 1;
      });
      // Here you would trigger the actual actions for each step
    } else {
      Navigator.of(context).pop(); // Close the dialog when done
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final l10n = AppLocalizations.of(context)!;
    return SizedBox(
      height: 500,
      width: 300,
      child: Stepper(
        currentStep: _currentStep,
        onStepContinue: _nextStep,
        onStepCancel: () {
          if (_currentStep > 0) {
            setState(() {
              _currentStep -= 1;
            });
          }
        },
        steps: _steps,
        controlsBuilder: (BuildContext context, ControlsDetails details) {
          String firstButtonText;
          switch (_currentStep) {
            case 0:
              firstButtonText = l10n.scan;
              break;
            case 1:
              firstButtonText = l10n.present;
              break;
            default:
              firstButtonText = l10n.next;
          }
          return Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: ElevatedButton(
                  onPressed: () async {
                    switch (_currentStep) {
                      case 0:
                        //Scan Movie or NFC from buyer
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const PeerTransferScreen(
                                  transferMode: "receive",
                                  transferredDataOutgoing: [])),
                        ).then((receivedJobs) async {
                          try {
                            transfer_ownership = receivedJobs.firstWhere(
                                (job) =>
                                    job["template"]["RALType"] ==
                                    "changeOwner");
                            change_container = receivedJobs.firstWhere((job) =>
                                job["template"]["RALType"] ==
                                "changeContainer");
                          } catch (e) {}
                          if (transfer_ownership == null ||
                              change_container == null) {
                            await fshowInfoDialog(context,
                                l10n.errorIncorrectData //"ERROR: The received data are not valid!"
                                );
                          } else {
                            _nextStep();
                          } //Present finished job to buyer
                        });
                        break;
                      case 1:
                        //ToDo Jobs vervollständigen

                        transfer_ownership = addInputobject(
                            transfer_ownership, coffee, "soldItem");
                        transfer_ownership = addInputobject(
                            transfer_ownership, seller, "seller");

                        transfer_ownership = addOutputobject(
                            transfer_ownership, coffee, "boughtItem");

                        transfer_ownership["executor"] = seller;
                        transfer_ownership["methodState"] = "finished";
                        transfer_ownership =
                            await setObjectMethod(transfer_ownership, true);

                        //"execute method changeOwner"
                        coffee["currentOwners"] = [
                          {//ToDO: use the buyer's UID from the transfer ownership job!
                            "UID": getObjectMethodUID(appUserDoc!),
                            "role": "owner"
                          }
                        ];
                        coffee = await setObjectMethod(coffee, true);

                        await updateMethodHistories(transfer_ownership);
                        //Make sure the outputobject is present in the post-transfer form.
                        transfer_ownership = addOutputobject(
                            transfer_ownership, coffee, "boughtItem");
                        transfer_ownership =
                            await setObjectMethod(transfer_ownership, true);

                        change_container =
                            addInputobject(change_container, coffee, "item");
                        if (field.isNotEmpty) {
                          change_container = addInputobject(
                              change_container, field, "oldContainer");
                        }

                        //"execute method changeContainer" => change container of coffee or other containers
                        coffee["currentGeolocation"]["container"]["UID"] =
                            getObjectMethodUID(receivingContainer);
                        change_container =
                            addOutputobject(change_container, coffee, "item");

                        change_container["methodState"] = "finished";
                        change_container =
                            await setObjectMethod(change_container, true);

                        coffee = await setObjectMethod(coffee, true);

                        //an method histories  von field (Ernte), receiving container, coffee anhängen
                        await updateMethodHistories(change_container);
                        //Make sure the sold object is present in post-process form in method!
                        change_container =
                            addOutputobject(change_container, coffee, "item");
                        change_container =
                            await setObjectMethod(change_container, true);

                        List<Map<String, dynamic>> transmittedList = [];
                        transmittedList.add(transfer_ownership);
                        transmittedList.add(change_container);
                        //!CAVE all nested objects of the container must be transmitted too
                        //! If container changes owner, who is owner of the contained items
                        final containedItemsList =
                            await getContainedItems(coffee);
                        for (final item in containedItemsList) {
                          transmittedList.add(item);
                        }

                        //Present Movie and/or NFC to buyer

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => PeerTransferScreen(
                                  transferMode: "send",
                                  transferredDataOutgoing: transmittedList)),
                        ).then((result) async {
                          final transSuccess = await fshowQuestionDialog(
                              context,
                              l10n.confirmTransfer, //"Did the buyer receive the information correctly?",
                              l10n.yes,
                              l10n.no);
                          if (transSuccess == true) {
                            _nextStep();
                          } else {
                            //Container and Owner back to old state
                            coffee["currentOwners"] = [
                              {
                                "UID": getObjectMethodUID(appUserDoc!),
                                "role": "owner"
                              }
                            ];
                            coffee["currentGeolocation"]["container"]["UID"] =
                            getObjectMethodUID(field);
                            await setObjectMethod(coffee, true);
                            //Jobs als cancelled markieren
                            transfer_ownership["methodState"] = "cancelled";

                            transfer_ownership =
                                await setObjectMethod(transfer_ownership, true);
                          }
                        });
                        break;
                      default:
                    }
                  },
                  child: Text(firstButtonText,
                      style: const TextStyle(color: Colors.white)),
                ),
              ),
              // const SizedBox(height: 8),
              // if (_currentStep != 0)
              //   Padding(
              //     padding: const EdgeInsets.all(8.0),
              //     child: TextButton(
              //       onPressed: details.onStepCancel,
              //       child: Text('back',
              //           style: TextStyle(
              //               color: Colors
              //                   .black)), // Umbenennen des "Cancel"-Buttons
              //     ),
              //   ),
              // if (_currentStep == 2) const SizedBox(height: 8),
              // if (_currentStep == 2)
              //   Padding(
              //     padding: const EdgeInsets.all(8.0),
              //     child: TextButton(
              //       onPressed: () {
              //         _nextStep();
              //       },
              //       child: Text('skip',
              //           style: TextStyle(
              //               color: Colors
              //                   .black)), // Umbenennen des "Cancel"-Buttons
              //     ),
              //   ),
            ],
          );
        },
      ),
    );
  }

  Future<CoffeeInfo?> _showCoffeeInfoDialog() async {
    final l10n = AppLocalizations.of(context)!;
    final countries = ['Honduras', 'Colombia', 'Brazil', 'Ethiopia', 'Vietnam'];
    final coffeeSpecies = loadCoffeeSpecies();
    String? selectedCountry = 'Honduras';
    String? selectedSpecies;
    double quantity = 0.0;
    String? selectedUnit;
    String? selectedProcessingState;
    List<String> selectedQualityCriteria = [];

    return showDialog<CoffeeInfo>(
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(
            builder: (context, setState) {
              List<Map<String, dynamic>> weightUnits = selectedCountry != null
                  ? getWeightUnits(selectedCountry!)
                  : [];
              final processingStates = selectedCountry != null
                  ? getProcessingStates(selectedCountry!)
                  : [];
              final qualityCriteria = selectedCountry != null
                  ? getQualityReductionCriteria(selectedCountry!)
                  : [];

              return Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.8,
                    maxWidth: MediaQuery.of(context).size.width * 0.9,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        height: 55,
                        width: MediaQuery.of(context).size.width * 0.9,
                        padding: const EdgeInsets.all(16),
                        decoration: const BoxDecoration(
                          color: Color(0xFF35DB00),
                          borderRadius:
                              BorderRadius.vertical(top: Radius.circular(16)),
                        ),
                        child: Text(
                          l10n.coffeeInformation,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Flexible(
                        child: SingleChildScrollView(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildDropdownField(
                                  label: l10n.countryOfOrigin,
                                  value: selectedCountry,
                                  items: countries,
                                  hintText: l10n.selectCountry,
                                  onChanged: (String? newValue) {
                                    setState(() {
                                      selectedCountry = newValue;
                                      selectedUnit = null;
                                      selectedProcessingState = null;
                                      selectedQualityCriteria = [];
                                    });
                                  },
                                ),
                                const SizedBox(height: 16),
                                _buildDropdownField(
                                  label: l10n.species,
                                  value: selectedSpecies,
                                  items: coffeeSpecies,
                                  hintText: l10n.selectSpecies,
                                  onChanged: (String? newValue) {
                                    setState(() {
                                      selectedSpecies = newValue;
                                    });
                                  },
                                ),
                                const SizedBox(height: 16),
                                _buildQuantityField(
                                  quantity: quantity,
                                  selectedUnit: selectedUnit,
                                  weightUnits: weightUnits,
                                  onQuantityChanged: (value) {
                                    String parseValue =
                                        value.replaceAll(',', '.');
                                    quantity =
                                        double.tryParse(parseValue) ?? 0.0;
                                  },
                                  onUnitChanged: (String? newValue) {
                                    setState(() {
                                      selectedUnit = newValue;
                                    });
                                  },
                                ),
                                const SizedBox(height: 16),
                                _buildDropdownField(
                                  label: l10n.processingState,
                                  value: selectedProcessingState,
                                  items: processingStates
                                      .map((state) => getLanguageSpecificState(
                                          state, context))
                                      .toList(),
                                  hintText: l10n.selectProcessingState,
                                  onChanged: (String? newValue) {
                                    setState(() {
                                      selectedProcessingState = newValue;
                                    });
                                  },
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  l10n.qualityReductionCriteria,
                                  style: const TextStyle(
                                    color: Colors.black87,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                ...qualityCriteria.map((criteria) {
                                  return CheckboxListTile(
                                    title: Text(criteria,
                                        style: const TextStyle(
                                            color: Colors.black87)),
                                    value: selectedQualityCriteria
                                        .contains(criteria),
                                    onChanged: (bool? value) {
                                      setState(() {
                                        if (value == true) {
                                          selectedQualityCriteria.add(criteria);
                                        } else {
                                          selectedQualityCriteria
                                              .remove(criteria);
                                        }
                                      });
                                    },
                                    activeColor: const Color(0xFF35DB00),
                                  );
                                }),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const Divider(height: 1),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
                        child: OverflowBar(
                          overflowAlignment: OverflowBarAlignment.center,
                          children: [
                            TextButton(
                              child: Text(l10n.cancel,
                                  style: TextStyle(color: Colors.black87)),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF35DB00),
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () async {
                                if (selectedCountry == null ||
                                    selectedSpecies == null ||
                                    quantity <= 0 ||
                                    selectedUnit == null ||
                                    selectedProcessingState == null) {
                                  await fshowInfoDialog(
                                      context, l10n.fillInReminder);
                                } else {
                                  Navigator.of(context).pop(CoffeeInfo(
                                    country: selectedCountry!,
                                    species: selectedSpecies!,
                                    quantity: quantity,
                                    weightUnit: selectedUnit!,
                                    processingState: selectedProcessingState!,
                                    qualityReductionCriteria:
                                        selectedQualityCriteria,
                                  ));
                                }
                              },
                              child: Text(l10n.confirm,
                                  style: const TextStyle(color: Colors.white)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        });
  }
}

Widget _buildDropdownField({
  required String label,
  required String? value,
  required List<String> items,
  required String hintText,
  required void Function(String?) onChanged,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(
          color: Colors.black87,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 8),
      (items.isEmpty)
          ? const Text("Please select country first!",
              style: TextStyle(color: Colors.red))
          : Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButton<String>(
                value: value,
                hint: Text(hintText,
                    style: const TextStyle(color: Colors.black87)),
                isExpanded: true,
                underline: const SizedBox(),
                items: items.map((String item) {
                  return DropdownMenuItem<String>(
                    value: item,
                    child: Text(item,
                        style: const TextStyle(color: Colors.black87)),
                  );
                }).toList(),
                onChanged: onChanged,
              ),
            ),
    ],
  );
}

// Anpassung des Mengenfeldes
Widget _buildQuantityField({
  required double quantity,
  required String? selectedUnit,
  required List<Map<String, dynamic>> weightUnits,
  required void Function(String) onQuantityChanged,
  required void Function(String?) onUnitChanged,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        "Quantity",
        style: TextStyle(
          color: Colors.black87,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 8),
      (weightUnits.isEmpty)
          ? const Text("Please select country first!",
              style: TextStyle(color: Colors.red))
          : Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: TextField(
                      style: const TextStyle(color: Colors.black87),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Enter quantity',
                        hintStyle: TextStyle(color: Colors.grey),
                      ),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        DecimalTextInputFormatter(),
                        LengthLimitingTextInputFormatter(10),
                      ],
                      onChanged: onQuantityChanged,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButton<String>(
                    value: selectedUnit,
                    hint: const Text("Unit",
                        style: TextStyle(color: Colors.black87)),
                    underline: const SizedBox(),
                    items: weightUnits.map((unit) {
                      return DropdownMenuItem<String>(
                        value: unit['name'],
                        child: Text(unit['name'],
                            style: const TextStyle(color: Colors.black87)),
                      );
                    }).toList(),
                    onChanged: onUnitChanged,
                  ),
                ),
              ],
            ),
    ],
  );
}

Future<Map<String, dynamic>> getObjectOrGenerateNew(
    String uid, type, field) async {
  Map<String, dynamic> rDoc = {};
  //check all items with this type: do they have the id on the field?
  List<Map<dynamic, dynamic>> candidates = localStorage.values
      .where((candidate) => candidate['template']["RALType"] == type)
      .toList();
  for (dynamic candidate in candidates) {
    Map<String, dynamic> candidate2 = Map<String, dynamic>.from(candidate);
    switch (field) {
      case "uid":
        if (candidate2["identity"]["UID"] == uid) rDoc = candidate2;
        break;
      case "alternateUid":
        if (candidate2["identity"]["alternateIDs"].length != 0) {
          if (candidate2["identity"]["alternateIDs"][0]["UID"] == uid) {
            rDoc = candidate2;
          }
        }
        break;
      default:
    }
    if (rDoc.isNotEmpty) break;
  }
  if (rDoc.isEmpty) {
    Map<String, dynamic> rDoc2 = await getOpenRALTemplate(type);
    rDoc = rDoc2;
    rDoc["identity"]["UID"] = "";
    debugPrint("generated new template for $type");
  }
  return rDoc;
}
