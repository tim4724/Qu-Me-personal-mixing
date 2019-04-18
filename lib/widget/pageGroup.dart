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
    "Wenjun",
    "Wenjun",
    "Wenjunn",
    "Ben",
    "Moise",
    "Hanna",
    "Joschi",
    "Joschi",
    "Instrumente",
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
      body: ListView.builder(
        itemCount: channelNames.length,
        itemBuilder: (BuildContext context, int index) {
          return Padding(
            padding: EdgeInsets.all(2.0),
            child: HorizontalFader(channelNames[index], channels[index],
                userNames[index], colors[index], stereo[index]),
          );
        },
      ),
    );
  }
}
