import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trace_foodchain_app/helpers/fade_route.dart';
import 'package:trace_foodchain_app/main.dart';
import 'package:trace_foodchain_app/providers/app_state.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:trace_foodchain_app/screens/sign_up_screen.dart';
import 'package:trace_foodchain_app/services/service_functions.dart';

// Globale Variable zum Speichern des Modus
bool isTestmode = false;

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final appState = Provider.of<AppState>(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: ListView(
        children: [
          // Neuer Switch zur Auswahl des Datenmodus (Test-/Echt-Modus)
          StatefulBuilder(
            builder: (context, setState) {
              return SwitchListTile(
                title: Text(
                    l10n.dataMode), // Lokalisierter Titel, z. B. "Datenmodus"
                subtitle: Text(isTestmode
                    ? l10n.testMode
                    : l10n.realMode), // z. B. "Testmodus" bzw. "Echtmodus"
                value: isTestmode,
                onChanged: (bool value) {
                  setState(() {
                    isTestmode = value;
                  });
                },
              );
            },
          ),
          ListTile(
            contentPadding: const EdgeInsets.all(12),
            leading: const Icon(Icons.arrow_circle_right),
            title: const Text("Log out"),
            onTap: appState.isConnected
                ? () async {
                    await FirebaseAuth.instance.signOut();

                    final prefs = await SharedPreferences.getInstance();
                    await prefs.remove('userId');

                    final appState =
                        Provider.of<AppState>(context, listen: false);
                    appState.setAuthenticated(false);
                    appState.setEmailVerified(false);

                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                          builder: (context) => const AuthScreen()),
                      (Route<dynamic> route) => false,
                    );
                  }
                : () async {
                    fshowInfoDialog(context, l10n.nologoutpossible);
                  },
          ),
        
          // if (appState.userRole == 'Farmer') ...[
          //   ListTile(
          //     title: Text(l10n.changeFarmerId,
          //         style: TextStyle(color: Colors.black54)),
          //     onTap: () => _showChangefarmerIdDialog(context),
          //   ),
          //   ListTile(
          //     title: Text(l10n.associateWithDifferentFarm,
          //         style: TextStyle(color: Colors.black54)),
          //     onTap: () => _showAssociateFarmDialog(context),
          //   ),
          // ],
          // Add more role-specific settings here
        ],
      ),
    );
  }

  void _showChangefarmerIdDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.changeFarmerId,
            style: const TextStyle(color: Colors.black54)),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: l10n.enterNewFarmerID),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Implement changing farmer ID logic
              Navigator.pop(context);
            },
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );
  }

  void _showAssociateFarmDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.associateWithDifferentFarm,
            style: const TextStyle(color: Colors.black54)),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: l10n.enterNewFarmID),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Implement associating with a different farm logic
              Navigator.pop(context);
            },
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );
  }
}
