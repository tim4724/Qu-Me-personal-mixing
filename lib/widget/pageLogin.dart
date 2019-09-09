import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:qu_me/entities/mixer.dart';
import 'package:qu_me/io/network.dart' as network;
import 'package:qu_me/io/quFind.dart' as quFind;
import 'package:qu_me/widget/pageHome.dart';

class PageLogin extends StatefulWidget {
  PageLogin({Key key}) : super(key: key);
  final String title = "QU ME";

  @override
  _PageLoginState createState() => _PageLoginState();
}

class _PageLoginState extends State<PageLogin> {
  var _loading = false;
  var mixers = [
    Mixer("Demo", InternetAddress.loopbackIPv4,
        DateTime.now().add(Duration(days: 365)))
  ];

  @protected
  void initState() {
    super.initState();
    // todo stop on stop ;)
    quFind.findQuMixers().listen((newMixer) {
      setState(() {
        mixers.removeWhere((m) => m.name == newMixer.name);
        mixers.add(newMixer);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Stack(
          alignment: AlignmentDirectional.center,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                FlutterLogo(size: 100),
                Container(
                  margin: EdgeInsets.all(16),
                  child: Text(
                    widget.title,
                    style: Theme.of(context).textTheme.headline,
                  ),
                ),
                Container(
                  padding: EdgeInsets.all(8),
                  height: 200,
                  width: 200,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ),
                  child: ListView.builder(
                    itemCount: mixers.length,
                    padding: EdgeInsets.all(0),
                    itemBuilder: (BuildContext context, int i) {
                      return _MixerItem(mixers[i], onMixerSelected);
                    },
                  ),
                ),
              ],
            ),
            _loading ? CircularProgressIndicator() : Container(),
          ],
        ),
      ),
    );
  }

  void onMixerSelected(Mixer mixer) {
    setState(() => _loading = true);
    network.connect(mixer, (mixer) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => PageHome()),
      );
      quFind.stop();
      setState(() => _loading = false);
    }, (e) {
      print(e);
      setState(() => _loading = false);
    });
  }
}

typedef _MixerSelectedCallback = Function(Mixer address);

class _MixerItem extends StatelessWidget {
  final Mixer _mixer;
  final _MixerSelectedCallback selectedCallback;

  const _MixerItem(this._mixer, this.selectedCallback, {Key key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () {
          selectedCallback(_mixer);
        },
        child: Container(
          padding: EdgeInsets.all(8),
          child: Text(
            _mixer.name,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
        ),
      ),
    );
  }
}
