import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:qu_me/core/MixerConnectionModel.dart';
import 'package:qu_me/widget/fader.dart';
import 'package:qu_me/widget/groupWheel.dart';
import 'package:qu_me/widget/pageGroup.dart';

class PageHome extends StatefulWidget {
  PageHome({Key key}) : super(key: key) {}

  final mixerModel = MixerConnectionModel();

  @override
  _PageHomeState createState() => _PageHomeState();
}

class _PageHomeState extends State<PageHome> {
  bool wheelActive = false;
  bool wheelSelected = false;

  @protected
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      PageGroup(),
      AnimatedOpacity(
        child: Scaffold(
          appBar: AppBar(
            title: Selector<MixerConnectionModel, String>(
                selector: (_, model) => model.name,
                builder: (_, name, child) => Text(name)),
          ),
          body: OrientationBuilder(
            builder: (context, orientation) {
              return orientation == Orientation.landscape
                  ? buildBodyLandscape()
                  : buildBodyPortrait();
            },
          ),
        ),
        opacity: wheelActive ? 0.4 : 1,
        duration: Duration(milliseconds: 500),
      ),
    ]);
  }

  onWheelChanged(double delta) {
    setState(() {
      wheelActive = true;
    });
  }

  onWheelReleased() {
    setState(() {
      wheelActive = false;
    });
  }

  onWheelSelected() {
    setState(() {
      wheelSelected = false;
    });
  }

  Widget buildBodyPortrait() {
    return Padding(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [buildGroup("Group 1"), buildGroup("Group 3")],
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [buildGroup("Group 2"), buildGroup("Me")],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(4),
            child: VerticalFader(39, "Voc 1", "Mix 1", "Tony",
                Colors.deepPurple.withAlpha(128), true),
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
          buildGroup("Group 1"),
          buildGroup("Group 2"),
          buildGroup("Group 3"),
          buildGroup("Me"),
          Padding(
            padding: EdgeInsets.all(4),
            child: VerticalFader(39, "Voc 1", "Mix 51", "Tony",
                Colors.deepPurple.withAlpha(128), true),
          ),
        ],
      ),
      padding: EdgeInsets.all(4),
    );
  }

  Widget buildGroup(String name) {
    return Expanded(
      child: Padding(
        padding: EdgeInsets.all(4),
        child: GroupWheel(
            Colors.black.withAlpha(128), name, onWheelChanged, onWheelReleased),
      ),
    );
  }
}
