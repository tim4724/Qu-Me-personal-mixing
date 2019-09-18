import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:qu_me/core/personalMixingModel.dart';
import 'package:qu_me/entities/send.dart';
import 'package:qu_me/widget/fader.dart';

class PageGroup extends StatefulWidget {
  final int groupIndex;
  final String title;

  PageGroup(this.groupIndex, this.title, {Key key}) : super(key: key);

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
        selector: (_, model) => model.getSendsForGroup(widget.groupIndex),
        builder: (_, sends, child) {
          return ListView.builder(
            itemCount: sends.length,
            scrollDirection: Axis.horizontal,
            itemBuilder: (BuildContext context, int index) {
              final send = sends[index];
              return Padding(
                padding: EdgeInsets.all(2.0),
                child: Align(
                  child: VerticalFader(send.id, send.name, send.technicalName,
                      send.personName, send.color, send.stereo),
                ),
              );
            },
          );
        });
  }

  Widget buildBodyPortrait() {
    return Selector<MixingModel, List<Send>>(
      selector: (_, model) {
        return model.getSendsForGroup(widget.groupIndex);
      },
      builder: (_, sends, child) {
        return ListView.builder(
          itemCount: sends.length,
          itemBuilder: (BuildContext context, int index) {
            final send = sends[index];
            return Padding(
              padding: EdgeInsets.all(2.0),
              child: HorizontalFader(send.id, send.name, send.technicalName,
                  send.personName, send.color, send.stereo),
            );
          },
        );
      },
    );
  }
}
