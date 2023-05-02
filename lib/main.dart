import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'package:google_fonts/google_fonts.dart';

import 'router.dart';
import 'config/constants.dart';

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  LicenseRegistry.addLicense(() async* {
    final license = await rootBundle.loadString('assets/fonts/license.txt');
    yield LicenseEntryWithLineBreaks(['Fonts'], license);
  });

  WidgetsFlutterBinding.ensureInitialized();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final _appRouter = AppRouter();

  MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Open Squeezer',
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerDelegate: _appRouter.delegate(),
      routeInformationParser: _appRouter.defaultRouteParser(),
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: ThemeMode.system,
    );
  }
}
