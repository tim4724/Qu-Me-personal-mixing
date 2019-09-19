import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:qu_me/core/faderModel.dart';
import 'package:qu_me/core/mixerConnectionModel.dart';
import 'package:qu_me/core/personalMixingModel.dart';
import 'package:qu_me/entities/mix.dart';
import 'package:qu_me/io/network.dart' as network;
import 'package:qu_me/widget/fader.dart';
import 'package:qu_me/widget/groupWheel.dart';
import 'package:qu_me/widget/pageGroup.dart';
import 'package:qu_me/widget/pageLogin.dart';

class PageHome extends StatefulWidget {
  PageHome({Key key}) : super(key: key) {}

  final mixerModel = MixerConnectionModel();
  final mixingModel = MixingModel();
  final faderModel = FaderModel();

  @override
  _PageHomeState createState() => _PageHomeState();
}

class _PageHomeState extends State<PageHome> {
  var activeWheel = -1;
  Mix mix;

  @protected
  void initState() {
    super.initState();
    setState(() {
      // TODO make changeable
      mix = widget.mixingModel.availableMixes[0];
    });
  }

  @override
  Widget build(BuildContext context) {
    // TODO: fade pagegroup widget
    return WillPopScope(
      onWillPop: () => logout(),
      child: Stack(children: [
        if (activeWheel != -1) PageGroup(activeWheel, ""),
        AnimatedOpacity(
          child: Scaffold(
            appBar: AppBar(
              title: Selector<MixerConnectionModel, String>(
                  selector: (_, model) => model.name,
                  builder: (_, name, child) => Text(name)),
              leading: new IconButton(
                icon: new Icon(Icons.close),
                tooltip: "Logout",
                onPressed: () => logout(),
              ),
              actions: <Widget>[
                // action button
                FlatButton(
                  child: Text("Select Mix"),
                  onPressed: () {
                    showSelectMixDialog();
                  },
                )
              ],
            ),
            body: OrientationBuilder(
              builder: (context, orientation) {
                final land = orientation == Orientation.landscape;
                return land ? buildBodyLandscape() : buildBodyPortrait();
              },
            ),
          ),
          opacity: activeWheel != -1 ? 0.4 : 1,
          duration: Duration(milliseconds: activeWheel != -1 ? 500 : 0),
        ),
      ]),
    );
  }

  void onWheelChanged(int id, double delta) {
    setState(() {
      if (activeWheel == -1) {
        activeWheel = id;
      }
      if (activeWheel == id) {
        final sends = widget.mixingModel.getSendsForGroup(id);
        widget.faderModel.onTrim(sends, delta);
      }
    });
  }

  void onWheelReleased(int id) {
    setState(() {
      if (activeWheel == id) {
        activeWheel = -1;
      }
    });
  }

  logout() {
    network.close();
    widget.mixerModel.reset();
    widget.mixingModel.reset();
    final route = MaterialPageRoute(builder: (context) => PageLogin());
    Navigator.pushReplacement(context, route);
  }

  Widget buildBodyPortrait() {
    return Padding(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [buildGroup(0), buildGroup(2)],
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [buildGroup(1), buildGroup(3)],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(4),
            child: VerticalFader(mix.id, mix.name, mix.technicalName,
                mix.personName, mix.color, mix.stereo),
          ),
        ],
      ),
      padding: EdgeInsets.all(4),
    );
  }

  Widget buildBodyLandscape() {
    return Padding(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          buildGroup(0),
          buildGroup(1),
          buildGroup(2),
          buildGroup(3),
          Padding(
            padding: EdgeInsets.all(4),
            child: VerticalFader(mix.id, mix.name, mix.technicalName,
                mix.personName, mix.color, mix.stereo),
          ),
        ],
      ),
      padding: EdgeInsets.all(4),
    );
  }

  Widget buildGroup(int index) {
    final name = widget.mixingModel.getNameForGroup(index);
    final color = Color.fromARGB(128, 0, 0, 0);
    return Expanded(
      child: Padding(
        padding: EdgeInsets.all(4),
        child: GroupWheel(index, name, color, onWheelChanged, onWheelReleased),
      ),
    );
  }

  void showSelectMixDialog() {
    final availableMixes = widget.mixingModel.availableMixes;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          title: const Text("Select Mix"),
          children: availableMixes.map<SimpleDialogOption>(
            (e) {
              return SimpleDialogOption(
                onPressed: () {
                  widget.mixingModel.onMixSelected(e.id);
                },
                child: Row(
                  children: [
                    Text(
                      e.technicalName,
                      style: TextStyle(fontSize: 20),
                    ),
                    Expanded(
                      child: Text(
                        e.name,
                        textAlign: TextAlign.center,
                      ),
                    )
                  ],
                ),
              );
            },
          ).toList(),
        );
      },
    );
  }
}
