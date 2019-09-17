import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:qu_me/core/PersonalMixingModel.dart';
import 'package:qu_me/entities/send.dart';
import 'package:qu_me/widget/fader.dart';

class PageGroup extends StatefulWidget {
  PageGroup({Key key}) : super(key: key);
  final String title = "Instr";

  @override
  _PageGroupState createState() => _PageGroupState();
}

class _PageGroupState extends State<PageGroup> {
  @protected
  void initState() {
    super.initState();
  }

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
    return Selector<MixingModel, List<Send>>(
        selector: (_, model) => model.getForGroup(0),
        builder: (_, sends, child) {
          print("rebuild list");
          return ListView.builder(
            itemCount: sends.length,
            scrollDirection: Axis.horizontal,
            itemBuilder: (BuildContext context, int index) {
              final send = sends[index];
              return Padding(
                padding: EdgeInsets.all(2.0),
                child: Align(
                  child: VerticalFader(send.id, send.name, "${send.id}", "",
                      send.color, send.stereo),
                ),
              );
            },
          );
        });
  }

  Widget buildBodyPortrait() {
    return Selector<MixingModel, List<Send>>(
      selector: (_, model) {
        return model.getForGroup(0);},
      builder: (_, sends, child) {
        return ListView.builder(
          itemCount: sends.length,
          itemBuilder: (BuildContext context, int index) {
            final send = sends[index];
            return Padding(
              padding: EdgeInsets.all(2.0),
              child: HorizontalFader(send.id, send.name, "${send.id}", "Tom",
                  send.color, send.stereo),
            );
          },
        );
      },
    );
  }
}
