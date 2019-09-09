import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qu_me/core/MixerModel.dart';
import 'package:qu_me/widget/pageLogin.dart';

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      builder: (context) => MixerModel(),
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
