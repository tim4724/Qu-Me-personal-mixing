import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:qu_me/widget/fader.dart';
import 'package:qu_me/widget/groupWheel.dart';
import 'package:qu_me/widget/pageGroup.dart';

class PageHome extends StatefulWidget {
  PageHome({Key key}) : super(key: key);
  final String title = "QU ME";

  @override
  _PageHomeState createState() => _PageHomeState();
}

class _PageHomeState extends State<PageHome> {
  bool wheelActive = false;
  bool wheelSelected = false;

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      PageGroup(),
      AnimatedOpacity(
        child: Scaffold(
          appBar: AppBar(
            title: Text(widget.title),
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
    print("delta: $delta");
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [buildGroup("Group 1"), buildGroup("Group 2")],
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [buildGroup("Group 2"), buildGroup("Me")],
          ),
        ),
        Padding(
          padding: EdgeInsets.all(8),
          child: VerticalFader("Keys", "Mix 5/6", "Joschi",
              Colors.deepPurple.withAlpha(128), true),
        ),
      ],
    );
  }

  Widget buildBodyLandscape() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        buildGroup("Group 1"),
        buildGroup("Group 2"),
        buildGroup("Group 3"),
        buildGroup("Me"),
        Padding(
          padding: EdgeInsets.all(8),
          child: Column(
            children: <Widget>[
              Expanded(
                child: VerticalFader("Keys", "Mix 5/6", "Joschi",
                    Colors.deepPurple.withAlpha(128), true),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget buildGroup(String name) {
    return Expanded(
      child: Padding(
        padding: EdgeInsets.all(8),
        child: GroupWheel(
            Colors.black.withAlpha(128), name, onWheelChanged, onWheelReleased),
      ),
    );
  }
}
