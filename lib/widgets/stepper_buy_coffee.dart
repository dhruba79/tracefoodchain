import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:trace_foodchain_app/main.dart';
import 'package:trace_foodchain_app/providers/app_state.dart';
import 'package:trace_foodchain_app/screens/peer_transfer_screen.dart';
import 'package:trace_foodchain_app/services/open_ral_service.dart';
import 'package:trace_foodchain_app/services/scanning_service.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

Map<String, dynamic> receivingContainer = {};
Map<String, dynamic> field = {};
Map<String, dynamic> seller = {};
Map<String, dynamic> coffee = {};
Map<String, dynamic> transfer_ownership = {};
Map<String, dynamic> change_container = {};
String receivingContainerUID = "";

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

class StepperBuyCoffee {
  Future<void> startProcess(BuildContext context,
      {String? receivingContainerUID}) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return BuyCoffeeStepper(receivingContainerUID: receivingContainerUID);
      },
    );
  }
}

class BuyCoffeeStepper extends StatefulWidget {
  // final SaleInfo saleInfo;
  // CoffeeSaleStepper({required this.saleInfo});
  final String? receivingContainerUID;
  const BuyCoffeeStepper({super.key, this.receivingContainerUID});

  @override
  _BuyCoffeeStepperState createState() => _BuyCoffeeStepperState();
}

class _BuyCoffeeStepperState extends State<BuyCoffeeStepper> {
  int _currentStep = 0;
  SaleInfo saleInfo = SaleInfo();

  @override
  void initState() {
    super.initState();
    if (widget.receivingContainerUID != null) {
      saleInfo.receivingContainerUID = widget.receivingContainerUID;
    }
  }

  List<Step> get _steps {
    final l10n = AppLocalizations.of(context)!;
    List<Step> steps = [];

    if (widget.receivingContainerUID == null) {
      steps.add(Step(
        title: Text(l10n.scanSelectFutureContainer,
            style: const TextStyle(color: Colors.black)),
        content: Text(l10n.scanContainerInstructions,
            style: const TextStyle(color: Colors.black)),
        isActive: _currentStep >= 0,
      ));
    }

    steps.addAll([
      Step(
        title: Text(l10n.presentInfoToSeller,
            style: const TextStyle(color: Colors.black)),
        content: Text(l10n.presentInfoToSellerInstructions,
            style: const TextStyle(color: Colors.black)),
        isActive:
            _currentStep >= (widget.receivingContainerUID == null ? 1 : 0),
      ),
      Step(
        title: Text(l10n.receiveDataFromSeller,
            style: const TextStyle(color: Colors.black)),
        content: Text(l10n.receiveDataFromSellerInstructions,
            style: const TextStyle(color: Colors.black)),
        isActive:
            _currentStep >= (widget.receivingContainerUID == null ? 2 : 1),
      ),
    ]);

    return steps;
  }

  void _nextStep() async {
    switch (_currentStep) {
      case 0:
        if (widget.receivingContainerUID == null) {
          // Scan or select container
          var scannedCode = await ScanningService.showScanDialog(
              context, Provider.of<AppState>(context, listen: false));
          if (scannedCode != null) {
            saleInfo.receivingContainerUID = scannedCode;
            setState(() {
              _currentStep += 1;
            });
          }
        } else {
          // If container UID is provided, move directly to presenting information
          _presentInformationToSeller();
        }
        break;
      case 1:
        if (widget.receivingContainerUID == null) {
          _presentInformationToSeller();
        } else {
          _receiveDataFromSeller();
        }
        break;
      case 2:
        _receiveDataFromSeller();
        break;
      default:
        Navigator.of(context).pop();
    }
  }

  void _presentInformationToSeller() async {
    final transmittedList =
        await initBuyCoffee(saleInfo.receivingContainerUID!);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PeerTransferScreen(
          transferMode: "send",
          transferredDataOutgoing: transmittedList,
        ),
      ),
    ).then((result) {
      setState(() {
        _currentStep += 1;
      });
    });
  }

  void _receiveDataFromSeller() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const PeerTransferScreen(
          transferMode: "receive",
          transferredDataOutgoing: [],
        ),
      ),
    ).then((receivedData) {
      if (receivedData != null) finishBuyCoffee(receivedData);
      Navigator.of(context).pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.buyCoffeeDeviceToDevice,
          style: const TextStyle(color: Colors.black)),
      content: SizedBox(
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
            String buttonText;
            if (widget.receivingContainerUID != null) {
              buttonText = _currentStep == 0 ? l10n.present : l10n.receive;
            } else {
              switch (_currentStep) {
                case 0:
                  buttonText = l10n.scan;
                  break;
                case 1:
                  buttonText = l10n.present;
                  break;
                case 2:
                  buttonText = l10n.receive;
                  break;
                default:
                  buttonText = l10n.next;
              }
            }

            return Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ElevatedButton(
                    onPressed: _nextStep,
                    child: Text(buttonText,
                        style: const TextStyle(color: Colors.white)),
                  ),
                ),
                if (_currentStep != 0)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextButton(
                      onPressed: details.onStepCancel,
                      child: Text(l10n.back,
                          style: const TextStyle(color: Colors.black)),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: Text(l10n.cancel, style: const TextStyle(color: Colors.black)),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}

Future<List<Map<String, dynamic>>> initBuyCoffee(
    String receivingContainerUID) async {
  List<Map<String, dynamic>> rList = [];

  receivingContainer = await getObjectOrGenerateNew(
      receivingContainerUID, ["container","bag","building","transportVehicle"], "alternateUid");
  if (getObjectMethodUID(receivingContainer) == "") {
    receivingContainer["identity"]["alternateIDs"]
        .add({"UID": receivingContainerUID, "issuedBy": "owner"});
    receivingContainer["currentOwners"] = [
      {"UID": getObjectMethodUID(appUserDoc!), "role": "owner"}
    ];
    receivingContainer = await setObjectMethod(receivingContainer, true);
  }
  debugPrint(
      "generated/loaded container ${getObjectMethodUID(receivingContainer)}");

  transfer_ownership = await getOpenRALTemplate("changeOwner");
  transfer_ownership = addInputobject(transfer_ownership, appUserDoc!, "buyer");
  transfer_ownership["methodState"] = "planned";

  change_container = await getOpenRALTemplate("changeContainer");
  change_container =
      addInputobject(change_container, receivingContainer, "newContainer");
  change_container["executor"] = appUserDoc!;
  change_container["methodState"] = "planned";

  rList.add(transfer_ownership);
  rList.add(change_container);

  return rList;
}

Future<void> finishBuyCoffee(dynamic receivedData) async {
  // This function persists all outputobjects and jobs in local database
  //The jobs are received in finished form from the seller

  for (final jobOrObject in receivedData) {
    await setObjectMethod(jobOrObject, true);
    //ToDo: Wenn es ein job ist, dann outputobjects persistieren

    //!CAVE all nested objects of the container must be transmitted too
    //! If container changes owner, who is owner of the contained items
    //ToDo: persist objects
  }
}
