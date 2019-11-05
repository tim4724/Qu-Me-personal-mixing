import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:qu_me/core/model/connectionModel.dart';
import 'package:qu_me/core/model/mainSendMixModel.dart';
import 'package:qu_me/io/quFind.dart' as quFind;
import 'package:qu_me/widget/pageHome.dart';
import 'package:qu_me/widget/quCheckButton.dart';

class PageLogin extends StatefulWidget {
  PageLogin({Key key}) : super(key: key);
  final String title = "QU ME";

  @override
  _PageLoginState createState() => _PageLoginState();
}

class _PageLoginState extends State<PageLogin> {
  final connectionModel = ConnectionModel();
  final mixingModel = MainSendMixModel();
  final mixers = {"Demo": InternetAddress.loopbackIPv4};
  var loading = false;

  @protected
  void initState() {
    super.initState();
    connectionModel.addListener(connectStateChanged);
    mixingModel.initializedNotifier.addListener(connectStateChanged);
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
    return PlatformScaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
              width: 100,
              height: 100,
              child: Placeholder(),
            ),
            Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                widget.title,
              ),
            ),
            Stack(
              alignment: AlignmentDirectional.center,
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  height: 200,
                  width: 200,
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: const BorderRadius.all(Radius.circular(8)),
                  ),
                  child: ListView.builder(
                    itemCount: mixers.length,
                    padding: const EdgeInsets.all(0),
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
      ),
    );
  }

  void onMixerSelected(String name) {
    ConnectionModel().onStartConnect(name, mixers[name]);
    setState(() => loading = true);
  }

  void connectStateChanged() {
    if (connectionModel.initialized && mixingModel.initializedNotifier.value) {
      connectionModel.removeListener(connectStateChanged);
      mixingModel.initializedNotifier.removeListener(connectStateChanged);
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
