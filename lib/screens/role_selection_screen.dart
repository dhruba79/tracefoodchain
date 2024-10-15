import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:trace_foodchain_app/main.dart';
import 'package:trace_foodchain_app/providers/app_state.dart';
import 'package:trace_foodchain_app/repositories/roles.dart';
import 'package:trace_foodchain_app/screens/home_screen.dart';
import 'package:trace_foodchain_app/services/open_ral_service.dart';
import 'package:trace_foodchain_app/widgets/language_selector.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.selectRole),
        centerTitle: true,
        actions: [
          LanguageSelector(),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 600),
          child: ListView.builder(
            itemCount: roles.length,
            itemBuilder: (context, index) {
              final role = roles[index];
              return Card(
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: Icon(role.icon as IconData,
                      size: 30, color: Theme.of(context).primaryColor),
                  title: Text(
                    role.getLocalizedName(l10n),
                    style: TextStyle(fontSize: 18),
                  ),
                  onTap: () => _selectRole(context, role.key as String),
                  trailing: Icon(Icons.arrow_forward_ios),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _selectRole(BuildContext context, String role) async {
    final appState = Provider.of<AppState>(context, listen: false);
    appState.setUserRole(role);
    appUserDoc = await getObjectMethod(getObjectMethodUID(appUserDoc!));
    appUserDoc =
        setSpecificPropertyJSON(appUserDoc!, "userRole", role, "String");
    appUserDoc = await setObjectMethod(appUserDoc!,true);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }
}
