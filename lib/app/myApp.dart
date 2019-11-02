import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:provider/provider.dart';
import 'package:qu_me/core/model/connectionModel.dart';
import 'package:qu_me/core/model/sendGroupModel.dart';
import 'package:qu_me/widget/pageLogin.dart';

class MyApp extends StatelessWidget {
  static final themeData = ThemeData(
    brightness: Brightness.dark,
    // e.g. ios appbar buttons
    primarySwatch: Colors.blue,
    // e.g. android AppBar Background Color
    primaryColor: Color(0xFF111111),
    scaffoldBackgroundColor: Color(0xFF010101),
    // e.g. android progress bar
    accentColor: Colors.blue,
    dialogBackgroundColor:
        Platform.isIOS ? Color(0x80000000) : Color(0xFF161616),
  );
  static final cupertinoThemeData = MaterialBasedCupertinoThemeData(
    materialTheme: themeData.copyWith(
      cupertinoOverrideTheme: const CupertinoThemeData(
        barBackgroundColor: Color(0xFF111111),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: ConnectionModel()),
        ChangeNotifierProvider.value(value: SendGroupModel()),
      ],
      child: Theme(
        data: themeData,
        child: PlatformProvider(
          builder: (context) => PlatformApp(
            title: 'QU ME',
            localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
              DefaultMaterialLocalizations.delegate,
              DefaultWidgetsLocalizations.delegate,
            ],
            ios: (context) => CupertinoAppData(theme: cupertinoThemeData),
            home: PageLogin(),
          ),
        ),
      ),
    );
  }
}
