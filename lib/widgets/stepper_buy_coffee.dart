import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:trace_foodchain_app/main.dart';
import 'package:trace_foodchain_app/providers/app_state.dart';
import 'package:trace_foodchain_app/screens/peer_transfer_screen.dart';
import 'package:trace_foodchain_app/services/open_ral_service.dart';
import 'package:trace_foodchain_app/services/scanning_service.dart';

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
        return AlertDialog(
          title: Text('Buy Coffee (device-to-device)',
              style: TextStyle(color: Colors.black)),
          content:
              BuyCoffeeStepper(receivingContainerUID: receivingContainerUID),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel', style: TextStyle(color: Colors.black)),
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



class BuyCoffeeStepper extends StatefulWidget {
  // final SaleInfo saleInfo;
  // CoffeeSaleStepper({required this.saleInfo});
  final String? receivingContainerUID;
  BuyCoffeeStepper({this.receivingContainerUID});

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
    List<Step> steps = [];

    if (widget.receivingContainerUID == null) {
      steps.add(Step(
        title: Text('Scan/Select future container',
            style: TextStyle(color: Colors.black)),
        content: Text(
            'Use QR-Code/NFC or select manually to specify where the coffee will be stored.',
            style: TextStyle(color: Colors.black)),
        isActive: _currentStep >= 0,
      ));
    }

    steps.addAll([
      Step(
        title: Text('Present information to seller',
            style: TextStyle(color: Colors.black)),
        content: Text(
            'Show the QR code or NFC tag to the seller to initiate the transaction.',
            style: TextStyle(color: Colors.black)),
        isActive:
            _currentStep >= (widget.receivingContainerUID == null ? 1 : 0),
      ),
      Step(
        title: Text('Receive data from seller',
            style: TextStyle(color: Colors.black)),
        content: Text(
            'Scan the QR code or NFC tag from the seller\'s device to complete the transaction.',
            style: TextStyle(color: Colors.black)),
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
    return Container(
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
            // When UID is provided
            buttonText = _currentStep == 0 ? "PRESENT" : "RECEIVE";
          } else {
            // When no UID is provided
            switch (_currentStep) {
              case 0:
                buttonText = "SCAN";
                break;
              case 1:
                buttonText = "PRESENT";
                break;
              case 2:
                buttonText = "RECEIVE";
                break;
              default:
                buttonText = "NEXT";
            }
          }

          return Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: ElevatedButton(
                  onPressed: _nextStep,
                  child:
                      Text(buttonText, style: TextStyle(color: Colors.white)),
                ),
              ),
              if (_currentStep != 0)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextButton(
                    onPressed: details.onStepCancel,
                    child: Text('BACK', style: TextStyle(color: Colors.black)),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

String getLanguageSpecificState(Map<String, dynamic> state) {
  dynamic rState;
  rState = state['name']['spanish']; //ToDo specify

  if (rState == null) rState = state['name']['english'];
  return rState as String;
}

Future<List<Map<String, dynamic>>> initBuyCoffee(
    String receivingContainerUID) async {
  List<Map<String, dynamic>> rList = [];

  receivingContainer = await getObjectOrGenerateNew(
      receivingContainerUID, "container", "alternateUid");
  if (getObjectMethodUID(receivingContainer) == "") {
    receivingContainer["identity"]["alternateIDs"]
        .add({"UID": receivingContainerUID, "issuedBy": "owner"});
    receivingContainer["currentOwners"] = [
      {"UID": getObjectMethodUID(appUserDoc!), "role": "owner"}
    ];
    receivingContainer = await setObjectMethod(receivingContainer,true);
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
    await setObjectMethod(jobOrObject,true);
    //ToDo: Wenn es ein job ist, dann outputobjects persistieren

    //!CAVE all nested objects of the container must be transmitted too
    //! If container changes owner, who is owner of the contained items
    //ToDo: persist objects
  }
}
