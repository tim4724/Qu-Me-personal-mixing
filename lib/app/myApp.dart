import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qu_me/core/FaderModel.dart';
import 'package:qu_me/core/MixerConnectionModel.dart';
import 'package:qu_me/core/PersonalMixingModel.dart';
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
