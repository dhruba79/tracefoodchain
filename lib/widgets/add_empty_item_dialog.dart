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

  const AddEmptyItemDialog({Key? key, required this.onItemAdded})
      : super(key: key);

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
      title: Text(l10n.addEmptyItem),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTypeSelector(),
            SizedBox(height: 16),
            CustomTextField(
              controller: _capacityController,
              hintText: l10n.maxCapacity,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                DecimalTextInputFormatter(),
                LengthLimitingTextInputFormatter(10),
              ],
              validator: _validateCapacity,
              errorText: _capacityError,
            ),
            SizedBox(height: 8),
            _buildUnitDropdown(),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    controller: _uidController,
                    hintText: l10n.uid,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.qr_code_scanner),
                  onPressed: _scanUID,
                ),
              ],
            ),
            SizedBox(height: 16),
            Text(l10n.geolocation,
                style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    controller: _latitudeController,
                    hintText: l10n.latitude,
                    keyboardType:
                        TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [DecimalTextInputFormatter()],
                    errorText: _latitudeError,
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: CustomTextField(
                    controller: _longitudeController,
                    hintText: l10n.longitude,
                    keyboardType:
                        TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [DecimalTextInputFormatter()],
                    errorText: _longitudeError,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            if (appState.hasGPS)
              ElevatedButton(
                onPressed: _getCurrentLocation,
                child: Text(l10n.useCurrentLocation),
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
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
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
        padding: EdgeInsets.all(8),
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
            SizedBox(height: 4),
            Text(label,
                textAlign: TextAlign.center, style: TextStyle(fontSize: 12)),
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
          border: OutlineInputBorder(),
        ),
        items: _weightUnits.map((unit) {
          return DropdownMenuItem<String>(
            value: unit['name'],
            child: Text(unit['name']),
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
      setState(() => _uidController.text = scannedCode);
    }
  }

  Future<void> _addItem() async {
    final l10n = AppLocalizations.of(context)!;

    setState(() {
      _capacityError = _validateCapacity(_capacityController.text);
      // _latitudeError = _validateCoordinate(_latitudeController.text, true);
      // _longitudeError = _validateCoordinate(_longitudeController.text, false);
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
