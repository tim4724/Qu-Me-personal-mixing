import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qu_me/core/faderModel.dart';
import 'package:qu_me/core/metersModel.dart';
import 'package:qu_me/core/connectionModel.dart';
import 'package:qu_me/core/mixingModel.dart';
import 'package:qu_me/widget/pageLogin.dart';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(builder: (context) => ConnectionModel()),
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
