import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
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
  bool _loading = false;

  @protected
  void initState() {
    super.initState();
    quFind.findQuMixers().listen((data) {
      print('received $data');
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
                    itemCount: 2,
                    padding: EdgeInsets.all(0),
                    itemBuilder: (BuildContext context, int index) {
                      return _MixerItem(
                        "Demo " + index.toString(),
                        InternetAddress.loopbackIPv4,
                        onMixerSelected,
                      );
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

  void onMixerSelected(InternetAddress address) {
    setState(() => _loading = true);
    network.connect(address, () {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => PageHome()),
      );
      setState(() => _loading = false);
    }, (e) {
      print(e);
      setState(() => _loading = false);
    });
  }
}

typedef _MixerSelectedCallback = Function(InternetAddress address);

class _MixerItem extends StatelessWidget {
  final String name;
  final InternetAddress address;
  final _MixerSelectedCallback selectedCallback;

  const _MixerItem(this.name, this.address, this.selectedCallback, {Key key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () {
          selectedCallback(address);
        },
        child: Container(
          padding: EdgeInsets.all(8),
          child: Text(
            this.name,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
        ),
      ),
    );
  }
}
