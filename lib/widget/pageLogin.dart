import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:qu_me/app/localizations.dart';
import 'package:qu_me/app/myApp.dart';
import 'package:qu_me/core/model/connectionModel.dart';
import 'package:qu_me/entities/mixer.dart';
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
  final mixers = {
    QuLocalizations.get(Strings.Demo): InternetAddress.loopbackIPv4
  };

  @protected
  void initState() {
    super.initState();
    connectionModel.connectionStateListenable.addListener(sceneLoadingChanged);
    quFind.findQuMixers((name, address, foundTime) {
      setState(() => mixers[name] = address);
    });
    // TODO: remove old?
    // todo stop on stop ;)
  }

  @override
  Widget build(BuildContext context) {
    return PlatformScaffold(
      body: Center(
        child: OrientationBuilder(
          builder: (BuildContext context, Orientation orientation) {
            final landscape = orientation == Orientation.landscape;
            return SingleChildScrollView(child: buildBody(context, landscape));
          },
        ),
      ),
    );
  }

  Widget buildBody(BuildContext context, bool landscape) {
    final theme = Theme.of(context);
    final quTheme = MyApp.quTheme;

    return Column(
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
        ValueListenableBuilder<QuConnectionState>(
            valueListenable: connectionModel.connectionStateListenable,
            builder: (BuildContext context, QuConnectionState state, _) {
              final loading = state == QuConnectionState.LOADING_SCENE;
              return Stack(alignment: Alignment.center, children: [
                Container(
                  padding: EdgeInsets.all(8),
                  height: 200,
                  width: 200,
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: quTheme.borderRadius,
                  ),
                  child: ValueListenableBuilder(
                    valueListenable: connectionModel.mixerListenable,
                    builder: (BuildContext context, Mixer selectedMixer, _) {
                      return ListView.builder(
                        itemCount: mixers.length,
                        padding: EdgeInsets.zero,
                        itemBuilder: (BuildContext context, int i) {
                          final name = mixers.keys.elementAt(i);
                          return QuCheckButton.simpleText(
                            name,
                            selected: loading && name == selectedMixer.name,
                            onSelect: () => connect(name),
                            margin: EdgeInsets.only(top: 2, bottom: 2),
                          );
                        },
                      );
                    },
                  ),
                ),
                if (loading) PlatformCircularProgressIndicator()
              ]);
            }),
      ],
    );
  }

  void connect(final mixerName) {
    connectionModel.connect(mixerName, mixers[mixerName]);
  }

  void sceneLoadingChanged() {
    if (connectionModel.connectionState == QuConnectionState.READY) {
      connectionModel.connectionStateListenable
          .removeListener(sceneLoadingChanged);
      quFind.stop();
      Navigator.of(context).pushReplacement(
        platformPageRoute(
          builder: (context) => PageHome(),
          context: context,
        ),
      );
    }
  }
}
