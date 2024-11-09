import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:trace_foodchain_app/main.dart';
import 'package:trace_foodchain_app/providers/app_state.dart';

class LanguageSelector extends StatelessWidget {
  const LanguageSelector({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final currentLocale = appState.locale;
    final l10n = AppLocalizations.of(context)!;

    return Theme(
      data: customTheme,
      child: PopupMenuButton<Locale>(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Image.asset(
            'assets/flags/${currentLocale.languageCode}.png',
            width: 24,
            height: 24,
          ),
        ),
        onSelected: (Locale locale) {
          appState.setLocale(locale);
        },
        itemBuilder: (BuildContext context) => <PopupMenuEntry<Locale>>[
          PopupMenuItem<Locale>(
            value: Locale('en'),
            child: _buildLanguageItem(l10n.languageEnglish, 'en'),
          ),
          PopupMenuItem<Locale>(
            value: Locale('es'),
            child: _buildLanguageItem(l10n.languageSpanish, 'es'),
          ),
          PopupMenuItem<Locale>(
            value: Locale('de'),
            child: _buildLanguageItem(l10n.languageGerman, 'de'),
          ),
          PopupMenuItem<Locale>(
            value: Locale('fr'),
            child: _buildLanguageItem(l10n.languageFrench, 'fr'),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageItem(String languageName, String languageCode) {
    return Row(
      children: [
        Image.asset(
          'assets/flags/$languageCode.png',
          width: 24,
          height: 24,
        ),
        SizedBox(width: 10),
        Text(languageName),
      ],
    );
  }
}
