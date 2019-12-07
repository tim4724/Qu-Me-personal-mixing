import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:provider/provider.dart';
import 'package:qu_me/app/localizations.dart';
import 'package:qu_me/core/model/connectionModel.dart';
import 'package:qu_me/core/model/sendGroupModel.dart';
import 'package:qu_me/entities/faderInfo.dart';
import 'package:qu_me/widget/pageLogin.dart';
import 'package:qu_me/widget/quTheme.dart';

class MyApp extends StatelessWidget {
  static const _accentColor = Colors.blue;
  static final _faderInfoColors = {
    FaderInfoCategory.Drum:
        QuColorSwatch.fromSingleColor(Color(0xFF323232), 0x94),
    FaderInfoCategory.String:
        QuColorSwatch.fromSingleColor(Color(0xE0DE431F), 0x94),
    FaderInfoCategory.Key:
        QuColorSwatch.fromSingleColor(Color(0xE01F43DE), 0x94),
    FaderInfoCategory.Voc:
        QuColorSwatch.fromSingleColor(Color(0xFFC9C9C9), 0x94),
    FaderInfoCategory.Guide:
        QuColorSwatch.fromSingleColor(Color(0xE0C4C4C4), 0x94),
    FaderInfoCategory.Speaker:
        QuColorSwatch.fromSingleColor(Color(0xE0D2DE1F), 0x94),
    FaderInfoCategory.Aux:
        QuColorSwatch.fromSingleColor(Color(0xE0D2DE1F), 0x94),
    FaderInfoCategory.Unknown:
        QuColorSwatch.fromSingleColor(Color(0xE0D2DE1F), 0x94)
  };

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
    // Button
    buttonTextStyle: TextStyle(
      color: Colors.black,
      fontSize: 14.0,
    ),
    buttonColor: Colors.grey,
    buttonCheckColor: Colors.green,
    buttonPressedOpacity: 0.3,
    mutedButtonColor: Colors.red,
    // Faderitem/ Groupitem
    itemRadius: 4.0,
    itemBorderWidth: 1.0,
    itemBackgroundColor: QuColorSwatch(0xFF010101, 0xFF070707),
    // Fader
    faderColors: _faderInfoColors,
    faderMixColors: QuColorSwatch.fromSingleColor(_accentColor, 0x94),
    faderFxReturnColors: QuColorSwatch.fromSingleColor(Color(0xE00000A0), 0x94),
    faderMutedBackgroundColor: Color(0x40F44336),
    // Group
    defaultGroupColors: QuColorSwatch.fromSingleColor(Color(0xFF424242), 0x94),
    meGroupColors: QuColorSwatch.fromSingleColor(_accentColor, 0x94),
    // GroupWheel
    wheelColor: QuColorSwatch(0xFF9A9A9A, 0xC9A9A9A9),
    wheelCarveColor: Color(0xFF212121),
    // Slider
    sliderRadius: 9.0,
    sliderPanBackgroundColor: Color(0xFF757575),
    sliderValueLabelColor: Color(0xC9000000),
    sliderMuteTextColor: Color(0xC9F44336),
    sliderLevelShadowColor: Color(0x80000000),
    sliderZeroMarkerColor: Color(0xFF424242),
    sliderLevelColors: [Colors.green, Colors.green, Colors.yellow, Colors.red],
    sliderIconColor: QuColorSwatch.fromSingleColor(Color(0xFFFFFFFF), 0x94),
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
