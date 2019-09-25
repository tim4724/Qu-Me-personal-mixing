import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:provider/provider.dart';
import 'package:qu_me/core/model/faderLevelModel.dart';
import 'package:qu_me/core/model/groupModel.dart';
import 'package:qu_me/core/model/metersModel.dart';
import 'package:qu_me/core/model/connectionModel.dart';
import 'package:qu_me/core/model/mixingModel.dart';
import 'package:qu_me/widget/pageLogin.dart';

class MyApp extends StatelessWidget {
  static final themeData = ThemeData(
    brightness: Brightness.dark,
    primarySwatch: Colors.blue,
    primaryColor: Colors.grey.shade900,
    accentColor: Colors.blue,
    textTheme: Typography.whiteMountainView,
    primaryTextTheme: Typography.whiteMountainView,
  );
  static final cupertinoThemeData = MaterialBasedCupertinoThemeData(
    materialTheme: ThemeData(
      brightness: Brightness.dark,
      textTheme: Typography.whiteCupertino,
      primaryTextTheme: Typography.whiteCupertino,
      accentTextTheme: Typography.whiteCupertino,
    ),
  );

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(builder: (context) => ConnectionModel()),
        ChangeNotifierProvider(builder: (context) => GroupModel()),
        ChangeNotifierProvider(builder: (context) => MixingModel()),
        ChangeNotifierProvider(builder: (context) => FaderLevelModel()),
        ChangeNotifierProvider(builder: (context) => MetersModel()),
      ],
      child: PlatformProvider(
        initialPlatform: TargetPlatform.iOS,
        builder: (context) => PlatformApp(
          title: 'QU ME',
          localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
            DefaultMaterialLocalizations.delegate,
            DefaultWidgetsLocalizations.delegate,
          ],
          android: (context) => MaterialAppData(theme: themeData),
          ios: (context) => CupertinoAppData(theme: cupertinoThemeData),
          home: PageLogin(),
        ),
      ),
    );
  }
}
