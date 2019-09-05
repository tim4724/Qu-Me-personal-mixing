import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:qu_me/widget/fader.dart';

class PageGroup extends StatefulWidget {
  PageGroup({Key key}) : super(key: key);
  final String title = "Instr";

  @override
  _PageGroupState createState() => _PageGroupState();
}

class _PageGroupState extends State<PageGroup> {
  static const ids = [
    1,
    2,
    3,
    4,
    5,
    6,
    7,
    8,
    9,
  ];
  static const channelNames = [
    "Kick",
    "Snare",
    "Drum",
    "Git",
    "Bass",
    "Keys",
    "Pads",
    "Syn",
    "Hall",
  ];
  static const stereo = [
    false,
    false,
    true,
    false,
    false,
    true,
    true,
    false,
    false
  ];
  static const userNames = [
    "Peter",
    "Peter",
    "Peter",
    "Mark",
    "Paul",
    "Tony",
    "Max",
    "Max",
    "Instruments",
  ];
  static const channels = [
    "Ch 1",
    "Ch 2",
    "Ch 3/4",
    "Ch 5",
    "Ch 4",
    "Ch ST1",
    "Ch 11/12345",
    "Ch 9",
    "Fx2 Ret",
  ];
  final colors = [
    Colors.black.withAlpha(128),
    Colors.black.withAlpha(128),
    Colors.black.withAlpha(128),
    Colors.red.withAlpha(128),
    Colors.orange.withAlpha(128),
    Colors.deepPurple.withAlpha(128),
    Colors.blue.withAlpha(128),
    Colors.green.withAlpha(128),
    Color.fromARGB(128, 0, 0, 200),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
    );
  }

  Widget buildBodyLandscape() {
    return ListView.builder(
      itemCount: channelNames.length,
      scrollDirection: Axis.horizontal,
      itemBuilder: (BuildContext context, int index) {
        return Padding(
          padding: EdgeInsets.all(2.0),
          child: Align(
            child: VerticalFader(ids[index], channelNames[index], channels[index],
                userNames[index], colors[index], stereo[index]),
          ),
        );
      },
    );
  }

  Widget buildBodyPortrait() {
    return ListView.builder(
      itemCount: channelNames.length,
      itemBuilder: (BuildContext context, int index) {
        return Padding(
          padding: EdgeInsets.all(2.0),
          child: HorizontalFader(ids[index], channelNames[index], channels[index],
              userNames[index], colors[index], stereo[index]),
        );
      },
    );
  }
}
