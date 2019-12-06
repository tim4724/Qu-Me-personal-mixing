import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:provider/provider.dart';
import 'package:qu_me/app/localizations.dart';
import 'package:qu_me/core/model/connectionModel.dart';
import 'package:qu_me/core/model/sendGroupModel.dart';
import 'package:qu_me/entities/QuItemColors.dart';
import 'package:qu_me/widget/pageLogin.dart';
import 'package:qu_me/widget/quTheme.dart';

class MyApp extends StatelessWidget {
  static const _accentColor = Colors.blue;

  static final themeData = ThemeData(
    brightness: Brightness.dark,
    // e.g. ios appbar buttons
    primarySwatch: Colors.blue,
    // e.g. android AppBar Background Color
    primaryColor: Color(0xFF111111),
    scaffoldBackgroundColor: Color(0xFF010101),
    // e.g. android progress bar
    accentColor: _accentColor,
    textSelectionHandleColor: _accentColor,
    cardColor: Color(0xFF161616),
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
  static final quThemeData = QuThemeData(
    itemRadius: 4.0,
    buttonTextStyle: TextStyle(
      color: Colors.black,
      fontSize: 14.0,
    ),
    buttonColor: Colors.grey,
    buttonCheckColor: Colors.green,
    buttonPressedOpacity: 0.3,
    borderWidth: 1.0,
    defaultGroupColors: QuItemColors(
      borderColor: Color(0xFF424242),
      backgroundColor: Color(0xFF070707),
      activebackgroundColor: Color(0xFF010101),
      labelColor: Color(0xFF424242).withAlpha(148),
      activeLabelColor: Color(0xFF424242),
    ),
    groupLabelTextStyle: TextStyle(),
    meColors: QuItemColors(
      borderColor: _accentColor,
      backgroundColor: Color(0xFF070707),
      activebackgroundColor: Color(0xFF010101),
      labelColor: _accentColor.withAlpha(148),
      activeLabelColor: _accentColor,
    ),
    labelBackgroundAlpha: 148,
    wheelColor: Color(0xFF9A9A9A),
    wheelInactiveColor: Color(0xC9A9A9A9),
    wheelCarveColor: Color(0xFF212121),
    mutedColor: Colors.red,
    faderBackgroundColor: Color(0xFF010101),
    faderInactiveBackgroundColor: Color(0xFF070707),
    // Colors.red with alpha
    faderMutedBackgroundColor: Color(0x40F44336),
    sliderRadius: 9.0,
    // Colors.grey[600]
    sliderPanBackgroundColor: Color(0xFF757575),
    sliderValueLabelColor: Color(0xC9000000),
    // Colors.red with alpha
    sliderMuteLabelColor: Color(0xC9F44336),
    sliderLevelShadowColor: Color(0x80000000),
    // Colors.gray[800]
    sliderZeroMarkerColor: Color(0xFF424242),
    sliderLevelColors: [Colors.green, Colors.green, Colors.yellow, Colors.red],
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
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
              AppLocalizationsDelegate(),
            ],
            supportedLocales: [const Locale('en'), const Locale('de')],
            ios: (context) => CupertinoAppData(theme: cupertinoThemeData),
            home: PageLogin(),
          ),
        ),
      ),
    );
  }
}
