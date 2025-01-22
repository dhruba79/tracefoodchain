import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:trace_foodchain_app/main.dart';
import 'package:trace_foodchain_app/widgets/custom_text_field.dart';
import 'package:trace_foodchain_app/services/scanning_service.dart';
import 'package:trace_foodchain_app/services/open_ral_service.dart';
import 'package:trace_foodchain_app/services/service_functions.dart';
import 'package:trace_foodchain_app/helpers/helpers.dart';
import 'package:trace_foodchain_app/providers/app_state.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

//ToDo: Offer to add 1-n additional ID tags like GeoId

class AddEmptyItemDialog extends StatefulWidget {
  final Function(Map<String, dynamic>) onItemAdded;

  const AddEmptyItemDialog({super.key, required this.onItemAdded});

  @override
  _AddEmptyItemDialogState createState() => _AddEmptyItemDialogState();
}

class _AddEmptyItemDialogState extends State<AddEmptyItemDialog> {
  String? _capacityError;
  String? _selectedType;
  final TextEditingController _capacityController = TextEditingController();
  String? _selectedUnit;
  final TextEditingController _uidController = TextEditingController();
  late List<Map<String, dynamic>> _weightUnits;
  final TextEditingController _latitudeController = TextEditingController();
  final TextEditingController _longitudeController = TextEditingController();
  String? _latitudeError;
  String? _longitudeError;
  String? _uidError;  // Add this line

  @override
  void initState() {
    super.initState();
    final appState = Provider.of<AppState>(context, listen: false);
    String country = 'Honduras'; // Fallback country
    // Hier könnten Sie das Land aus dem AppState holen, wenn verfügbar
    // String country = appState.userCountry ?? 'Honduras';
    _weightUnits = getWeightUnits(country);
    if (_weightUnits.isNotEmpty) {
      _selectedUnit = _weightUnits[0]['name'];
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(
        l10n.addEmptyItem,
        style: const TextStyle(color: Colors.black),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTypeSelector(),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _capacityController,
              hintText: l10n.maxCapacity,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                DecimalTextInputFormatter(),
                LengthLimitingTextInputFormatter(10),
              ],
              validator: _validateCapacity,
              errorText: _capacityError,
            ),
            const SizedBox(height: 8),
            _buildUnitDropdown(),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    controller: _uidController,
                    hintText: l10n.uid,
                    errorText: _uidError,  // Add error text
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.qr_code_scanner),
                  tooltip: l10n.scanQRCode,
                  onPressed: _scanUID,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(l10n.geolocation,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    controller: _latitudeController,
                    hintText: l10n.latitude,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [DecimalTextInputFormatter()],
                    errorText: _latitudeError,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: CustomTextField(
                    controller: _longitudeController,
                    hintText: l10n.longitude,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [DecimalTextInputFormatter()],
                    errorText: _longitudeError,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (appState.hasGPS)
              ElevatedButton(
                onPressed: _getCurrentLocation,
                child: Center(
                  child: Text(
                    l10n.useCurrentLocation,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        ElevatedButton(
          onPressed: _addItem,
          child: Text(l10n.add),
        ),
      ],
    );
  }

  String? _validateCapacity(String? value) {
    if (value == null || value.isEmpty) {
      return AppLocalizations.of(context)!.fieldRequired;
    }
    if (double.tryParse(value) == null) {
      return AppLocalizations.of(context)!.invalidNumber;
    }
    return null;
  }

  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw 'Location permissions are denied';
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw 'Location permissions are permanently denied';
      }

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
        ),
      );
      setState(() {
        _latitudeController.text = position.latitude.toString();
        _longitudeController.text = position.longitude.toString();
      });
    } catch (e) {
      await fshowInfoDialog(
        context,
        AppLocalizations.of(context)!.locationError,
      );
    }
  }

  String? _validateCoordinate(String? value, bool isLatitude) {
    if (value == null || value.isEmpty) {
      return AppLocalizations.of(context)!.fieldRequired;
    }
    double? coordinate = double.tryParse(value);
    if (coordinate == null) {
      return AppLocalizations.of(context)!.invalidNumber;
    }
    if (isLatitude && (coordinate < -90 || coordinate > 90)) {
      return AppLocalizations.of(context)!.invalidLatitude;
    }
    if (!isLatitude && (coordinate < -180 || coordinate > 180)) {
      return AppLocalizations.of(context)!.invalidLongitude;
    }
    return null;
  }

  Widget _buildTypeSelector() {
    final l10n = AppLocalizations.of(context)!;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildTypeOption('bag', Icons.shopping_bag, l10n.bag),
        _buildTypeOption('container', Icons.inventory_2, l10n.container),
        _buildTypeOption('building', Icons.business, l10n.building),
        _buildTypeOption(
            'transportVehicle', Icons.local_shipping, l10n.transportVehicle),
      ],
    );
  }

  Widget _buildTypeOption(String type, IconData icon, String label) {
    final isSelected = _selectedType == type;
    return GestureDetector(
      onTap: () => setState(() => _selectedType = type),
      child: Container(
        width: 80,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).primaryColor.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Theme.of(context).primaryColor : Colors.grey,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(icon,
                size: 32,
                color:
                    isSelected ? Theme.of(context).primaryColor : Colors.grey),
            const SizedBox(height: 4),
            Text(label,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: Colors.black)),
          ],
        ),
      ),
    );
  }

  Widget _buildUnitDropdown() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: DropdownButtonFormField<String>(
        value: _selectedUnit,
        decoration: InputDecoration(
          labelText: AppLocalizations.of(context)!.unit,
          border: const OutlineInputBorder(),
        ),
        items: _weightUnits.map((unit) {
          return DropdownMenuItem<String>(
            value: unit['name'],
            child:
                Text(unit['name'], style: const TextStyle(color: Colors.black)),
          );
        }).toList(),
        onChanged: (String? newValue) {
          setState(() {
            _selectedUnit = newValue;
          });
        },
      ),
    );
  }

  Future<void> _scanUID() async {
    final scannedCode = await ScanningService.showScanDialog(
        context, Provider.of<AppState>(context, listen: false));
    if (scannedCode != null) {
      // Check if UID exists before setting
      final isUIDTaken = await checkAlternateIDExists(scannedCode);
      if (isUIDTaken) {
        setState(() {
          _uidError = AppLocalizations.of(context)!.uidAlreadyExists;
          _uidController.text = '';
        });
        await fshowInfoDialog(context, AppLocalizations.of(context)!.uidAlreadyExists);
      } else {
        setState(() {
          _uidError = null;
          _uidController.text = scannedCode;
        });
      }
    }
  }

  Future<void> _addItem() async {
    final l10n = AppLocalizations.of(context)!;

    // Check if UID exists before adding item
    final isUIDTaken = await checkAlternateIDExists(_uidController.text);
    if (isUIDTaken) {
      setState(() => _uidError = l10n.uidAlreadyExists);
      await fshowInfoDialog(context, l10n.uidAlreadyExists);
      return;
    }

    setState(() {
      _capacityError = _validateCapacity(_capacityController.text);
      _uidError = null;
    });

    if (_selectedType == null ||
        _capacityController.text.isEmpty ||
        _selectedUnit == null ||
        _uidController.text.isEmpty) {
      await fshowInfoDialog(context, l10n.pleaseCompleteAllFields);
      return;
    }

    Map<String, dynamic> newItem = await getOpenRALTemplate(_selectedType!);
    newItem["identity"]["alternateIDs"] = [
      {"UID": _uidController.text, "issuedBy": "owner"}
    ];
    newItem = setSpecificPropertyJSON(newItem, "max capacity",
        double.parse(_capacityController.text), _selectedUnit!);
    newItem["currentOwners"] = [
      {"UID": getObjectMethodUID(appUserDoc!), "role": "owner"}
    ];

    if (_latitudeController.text != "" && _longitudeController.text != "") {
      newItem["currentGeolocation"]["geoCoordinates"] = {
        "latitude": double.parse(_latitudeController.text),
        "longitude": double.parse(_longitudeController.text),
      };
    }

    final savedItem = await setObjectMethod(newItem, true);
    widget.onItemAdded(savedItem);
    Navigator.of(context).pop();
  }
}
