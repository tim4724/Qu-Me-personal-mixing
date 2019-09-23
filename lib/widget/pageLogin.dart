import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:qu_me/core/connectionModel.dart';
import 'package:qu_me/core/mixingModel.dart';
import 'package:qu_me/io/quFind.dart' as quFind;
import 'package:qu_me/widget/pageHome.dart';

class PageLogin extends StatefulWidget {
  PageLogin({Key key}) : super(key: key);
  final String title = "QU ME";

  @override
  _PageLoginState createState() => _PageLoginState();
}

class _PageLoginState extends State<PageLogin> {
  final _mixerModel = ConnectionModel();
  final _mixingModel = MixingModel();
  final _mixers = {"Demo": InternetAddress.loopbackIPv4};
  var _loading = false;

  @protected
  void initState() {
    super.initState();
    _mixerModel.addListener(connectStateChanged);
    _mixingModel.addListener(connectStateChanged);
    quFind.findQuMixers((name, address, foundTime) {
      setState(() {
        _mixers[name] = address;
      });
    });
    // todo stop on stop ;)
  }

  @override
  Widget build(BuildContext context) {
    return PlatformScaffold(
      body: Center(
        child: Stack(
          alignment: AlignmentDirectional.center,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Placeholder(
                  fallbackHeight: 100,
                  fallbackWidth: 100,
                ),
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    widget.title,
                    style: TextStyle(color: Color(0xFFFFFFFF)),
                  ),
                ),
                Container(
                  padding: EdgeInsets.all(8),
                  height: 200,
                  width: 200,
                  decoration: BoxDecoration(
                    color: Color.fromARGB(255, 21, 21, 21),
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ),
                  child: ListView.builder(
                    itemCount: _mixers.length,
                    padding: EdgeInsets.all(0),
                    itemBuilder: (BuildContext context, int i) {
                      return _MixerItem(
                          _mixers.keys.elementAt(i), onMixerSelected);
                    },
                  ),
                ),
              ],
            ),
            if (_loading) PlatformCircularProgressIndicator(),
          ],
        ),
      ),
    );
  }

  void onMixerSelected(String name) {
    setState(() => _loading = true);
    ConnectionModel().onStartConnect(name, _mixers[name]);
  }

  void connectStateChanged() {
    if (_mixerModel.initialized && _mixingModel.initialized) {
      _mixerModel.removeListener(connectStateChanged);
      _mixingModel.removeListener(connectStateChanged);
      Navigator.of(context).pushReplacement(
        platformPageRoute(builder: (context) => PageHome(), context: context),
      );
      quFind.stop();
      setState(() => _loading = false);
    }
  }
}

typedef _MixerSelectedCallback = Function(String name);

class _MixerItem extends StatelessWidget {
  final String _mixerName;
  final _MixerSelectedCallback _selectedCallback;

  const _MixerItem(this._mixerName, this._selectedCallback, {Key key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PlatformButton(
      onPressed: () {
        _selectedCallback(_mixerName);
      },
      child: Container(
        padding: EdgeInsets.all(8),
        child: Text(
          _mixerName,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
