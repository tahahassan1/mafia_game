import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/app_locale.dart';
import 'core/strings_ar.dart';
import 'core/theme.dart';
import 'features/placeholder/placeholder_screen.dart';

class MafiaApp extends StatelessWidget {
  const MafiaApp({super.key, this.home});

  final Widget? home;

  @override
  Widget build(BuildContext context) {
    final theme = buildAppTheme();

    return MaterialApp(
      title: AppStrings.appTitle,
      debugShowCheckedModeBanner: false,
      theme: theme,
      darkTheme: theme,
      themeMode: ThemeMode.dark,
      locale: AppLocale.arabic,
      supportedLocales: AppLocale.supported,
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(
        value: AppSystemUi.overlay,
        child: child ?? const SizedBox.shrink(),
      ),
      home: home ?? const PlaceholderScreen(),
    );
  }
}
