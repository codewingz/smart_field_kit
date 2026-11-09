import 'package:flutter/material.dart';

import 'src/app_shell.dart';
import 'src/settings.dart';

void main() => runApp(const ExampleApp());

class ExampleApp extends StatefulWidget {
  const ExampleApp({super.key});

  @override
  State<ExampleApp> createState() => _ExampleAppState();
}

class _ExampleAppState extends State<ExampleApp> {
  final ShowcaseSettings _settings = ShowcaseSettings();

  @override
  void dispose() {
    _settings.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _settings,
      builder: (context, _) {
        return MaterialApp(
          title: 'smart_field_kit showcase',
          debugShowCheckedModeBanner: false,
          themeMode: _settings.themeMode,
          theme: ThemeData(
            colorSchemeSeed: Colors.teal,
            useMaterial3: true,
            brightness: Brightness.light,
          ),
          darkTheme: ThemeData(
            colorSchemeSeed: Colors.teal,
            useMaterial3: true,
            brightness: Brightness.dark,
          ),
          builder: (context, child) {
            return Directionality(
              textDirection: _settings.rtl
                  ? TextDirection.rtl
                  : TextDirection.ltr,
              child: MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TextScaler.linear(_settings.textScale)),
                child: child!,
              ),
            );
          },
          restorationScopeId: 'showcase',
          home: AppShell(settings: _settings),
        );
      },
    );
  }
}
