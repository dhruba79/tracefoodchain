import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trace_foodchain_app/providers/app_state.dart';

class StatusBar extends StatelessWidget {
  final bool isSmallScreen;

  const StatusBar({super.key, required this.isSmallScreen});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    List<Widget> statusIcons = [
      _buildStatusIcon(Icons.camera_alt, appState.hasCamera),
      _buildStatusIcon(Icons.nfc, appState.hasNFC),
      _buildStatusIcon(Icons.wifi, appState.isConnected),
      _buildStatusIcon(Icons.gps_fixed, appState.hasGPS),
    ];

    if (isSmallScreen) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        color: Colors.grey[200],
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: statusIcons,
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: statusIcons,
        ),
      );
    }
  }

  Widget _buildStatusIcon(IconData icon, bool isActive) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
      child: Icon(
        icon,
        color: isActive ? Colors.green : Colors.red,
        size: 24,
      ),
    );
  }
}
