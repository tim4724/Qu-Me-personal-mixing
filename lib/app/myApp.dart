import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qu_me/core/faderModel.dart';
import 'package:qu_me/core/metersModel.dart';
import 'package:qu_me/core/mixerConnectionModel.dart';
import 'package:qu_me/core/personalMixingModel.dart';
import 'package:qu_me/widget/pageLogin.dart';

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(builder: (context) => MixerConnectionModel()),
        ChangeNotifierProvider(builder: (context) => MixingModel()),
        ChangeNotifierProvider(builder: (context) => FaderModel()),
        ChangeNotifierProvider(builder: (context) => MetersModel()),
      ],
      child: MaterialApp(
        title: 'QU ME',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          brightness: Brightness.dark,
        ),
        home: PageLogin(),
      ),
    );
  }
}
