import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:qu_me/app/localizations.dart';
import 'package:qu_me/app/myApp.dart';
import 'package:qu_me/core/model/connectionModel.dart';
import 'package:qu_me/core/model/mainSendMixModel.dart';
import 'package:qu_me/io/quFind.dart' as quFind;
import 'package:qu_me/widget/pageHome.dart';
import 'package:qu_me/widget/quCheckButton.dart';

class PageLogin extends StatefulWidget {
  PageLogin({Key key}) : super(key: key);

  @override
  _PageLoginState createState() => _PageLoginState();
}

class _PageLoginState extends State<PageLogin> {
  final connectionModel = ConnectionModel();
  final mixingModel = MainSendMixModel();
  final mixers = {
    QuLocalizations.get(Strings.Demo): InternetAddress.loopbackIPv4
  };
  var loading = false;
  String name = "";

  @protected
  void initState() {
    super.initState();
    connectionModel.addListener(connectStateChanged);
    quFind.findQuMixers((name, address, foundTime) {
      setState(() {
        mixers[name] = address;
      });
    });
    loading = false;
    // todo stop on stop ;)
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final quTheme = MyApp.quTheme;

    return PlatformScaffold(
      body: Center(
        child: OrientationBuilder(
          builder: (BuildContext context, Orientation orientation) {
            final landscape = orientation == Orientation.landscape;
            return SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Flex(
                    direction: landscape ? Axis.horizontal : Axis.vertical,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      FlutterLogo(size: landscape ? 32 : 64),
                      Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          QuLocalizations.get(Strings.AppName),
                          textScaleFactor: 2,
                        ),
                      ),
                    ],
                  ),
                  Stack(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8),
                        height: 200,
                        width: 200,
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: quTheme.borderRadius,
                        ),
                        child: ListView.builder(
                          itemCount: mixers.length,
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          itemBuilder: (BuildContext context, int i) {
                            return _MixerItem(
                              mixers.keys.elementAt(i),
                              onMixerSelected,
                              connectionModel.remoteAddress ==
                                  mixers.values.elementAt(i),
                            );
                          },
                        ),
                      ),
                      if (loading) PlatformCircularProgressIndicator(),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void onMixerSelected(String name) {
    ConnectionModel().startConnect(name, mixers[name]);
    setState(() => loading = true);
  }

  void connectStateChanged() {
    if (connectionModel.initialized) {
      connectionModel.removeListener(connectStateChanged);
      Navigator.of(context).pushReplacement(
        platformPageRoute(
          builder: (context) => PageHome(),
          context: context,
        ),
      );
      quFind.stop();
      setState(() => loading = false);
    }
  }
}

typedef _MixerSelectedCallback = Function(String name);

class _MixerItem extends StatelessWidget {
  final String name;
  final bool selected;
  final _MixerSelectedCallback selectedCallback;

  const _MixerItem(this.name, this.selectedCallback, this.selected, {Key key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 2, bottom: 2),
      child: QuCheckButton.simpleText(
        name,
        selected: selected,
        onSelect: () => selectedCallback(name),
      ),
    );
  }
}
