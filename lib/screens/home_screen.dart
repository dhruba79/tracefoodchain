import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trace_foodchain_app/main.dart';
import 'package:trace_foodchain_app/providers/app_state.dart';
import 'package:trace_foodchain_app/repositories/roles.dart';
import 'package:trace_foodchain_app/screens/farmer_actions_screen.dart';
import 'package:trace_foodchain_app/screens/farm_manager_screen.dart';
import 'package:trace_foodchain_app/screens/importer_screen.dart';
import 'package:trace_foodchain_app/screens/inbox_screen.dart';
import 'package:trace_foodchain_app/screens/trader_screen.dart';
import 'package:trace_foodchain_app/screens/transporter_screen.dart';
import 'package:trace_foodchain_app/screens/storage_screen.dart';
import 'package:trace_foodchain_app/screens/settings_screen.dart';
import 'package:trace_foodchain_app/widgets/language_selector.dart';
import 'package:trace_foodchain_app/widgets/role_based_speed_dial.dart';
import 'package:trace_foodchain_app/widgets/status_bar.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

String displayContext = "action";
ValueNotifier<bool> rebuildList = ValueNotifier<bool>(false);

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final isSmallScreen = MediaQuery.of(context).size.width < 600;
    final l10n = AppLocalizations.of(context);

    return Theme(
      data: customTheme,
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          leading: LanguageSelector(),
          title: Text("TraceFoodChain"),
          //  Text(l10n!.welcomeMessage(roles.firstWhere(
          //         (element) => element.key == appState.userRole).getLocalizedName(l10n)
          //     as String)),
          actions: [
            
            ValueListenableBuilder(
                              valueListenable: inboxCount,
                              builder: (context, int value, child) {
                return Stack(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.inbox),
                      onPressed: () => _navigateToInbox(context),
                    ),
                    if (inboxCount.value > 0)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          constraints: BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            '${inboxCount.value}',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                );
              }
            ),
            IconButton(
              icon: const Icon(Icons.feedback),
              onPressed: () => _launchFeedbackEmail(context),
            ),
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () => _navigateToSettings(context),
            ),
          ],
        ),
        body: Column(
          children: [
            const StatusBar(isSmallScreen: true),
            Expanded(
              child: Row(
                children: [
                  // if (!isSmallScreen) _buildSideMenu(context),
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ValueListenableBuilder(
                              valueListenable: rebuildList,
                              builder: (context, bool value, child) {
                                rebuildList.value = false;
                                Widget? screen;
                                switch (appState.userRole) {
                                  case 'Farmer':
                                    screen = const FarmerActionsScreen();
                                    break;
                                  case 'Farm Manager':
                                    screen = const FarmManagerScreen();
                                    break;
                                  case 'Trader':
                                    screen = const TraderScreen();
                                    break;
                                  case 'Processor':
                                    screen = const TraderScreen();
                                    break;
                                  case 'Transporter':
                                    screen = const TransporterScreen();
                                    break;
                                  case 'Importer':
                                    screen = const ImporterScreen();
                                    break;
                                  default:
                                    screen = Text("NOT IMPLEMENTED");
                                }
                                return Expanded(
                                    child: displayContext == "action"
                                        ? screen
                                        : StorageScreen());
                              }),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: ValueListenableBuilder(
            valueListenable: rebuildList,
            builder: (context, bool value, child) {
              rebuildList.value = false;
              return RoleBasedSpeedDial(displayContext: displayContext);
            }),
        // bottomNavigationBar: isSmallScreen ? _buildBottomMenu(context) : null,
      ),
    );
  }

  Widget _buildSideMenu(BuildContext context) {
    return Container(
      width: 200,
      color: Colors.grey[200],
      child: Column(
        children: [
          Expanded(child: _buildMenuItems(context)),
          const StatusBar(isSmallScreen: false),
        ],
      ),
    );
  }

  Widget _buildBottomMenu(BuildContext context) {
    return (Container());
    // final l10n = AppLocalizations.of(context)!;
    // return BottomNavigationBar(
    //   items: [
    //     BottomNavigationBarItem(
    //         icon: const Icon(Icons.play_arrow), label: l10n.actions),
    //     BottomNavigationBarItem(
    //         icon: const Icon(Icons.storage), label: l10n.storage),
    //     BottomNavigationBarItem(
    //         icon: const Icon(Icons.settings), label: l10n!.settings),
    //   ],
    //   onTap: (index) {
    //     switch (index) {
    //       case 0:
    //         displayContext = "action";
    //         rebuildList.value = true;
    //         break;
    //       case 1:
    //         displayContext = "storage";
    //         rebuildList.value = true;
    //         break;
    //       case 2:
    //         _navigateToSettings(context);
    //         break;
    //     }
    //   },
    // );
  }

  Widget _buildMenuItems(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    String selectedContext = "action";
    return StatefulBuilder(builder: (context, setState) {
      return ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.play_arrow),
            title: Text('Actions', style: const TextStyle(fontSize: 16)),
            selected: selectedContext == "action",
            selectedTileColor: Color(0xFF35DB00),
            tileColor:
                selectedContext == "action" ? Color(0xFF35DB00) : Colors.white,
            onTap: () {
              displayContext = "action";
              selectedContext = "action";
              rebuildList.value = true;
              setState(() {});
            },
          ),
          ListTile(
            leading: const Icon(Icons.storage),
            title: Text('Storage', style: const TextStyle(fontSize: 16)),
            selected: selectedContext == "storage",
            selectedTileColor: Color(0xFF35DB00),
            tileColor:
                selectedContext == "storage" ? Color(0xFF35DB00) : Colors.white,
            onTap: () {
              displayContext = "storage";
              selectedContext = "storage";
              rebuildList.value = true;
              setState(() {});
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: Text('Settings', style: const TextStyle(fontSize: 16)),
            selected: selectedContext == "settings",
            selectedTileColor: Color(0xFF35DB00),
            tileColor: selectedContext == "settings"
                ? Color(0xFF35DB00)
                : Colors.white,
            onTap: () {
              selectedContext = "settings";
              _navigateToSettings(context);
            },
          ),
        ],
      );
    });
  }

  void _navigateToSettings(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );
  }

  void _navigateToInbox(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => InboxScreen()),
    );
  }

  void _launchFeedbackEmail(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'feedback@tracefoodchain.org',
      queryParameters: {
        'subject': l10n.feedbackEmailSubject,
        'body': l10n.feedbackEmailBody,
      },
    );

    if (await canLaunch(emailLaunchUri.toString())) {
      await launch(emailLaunchUri.toString());
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n!.unableToLaunchEmail)),
      );
    }
  }
}
