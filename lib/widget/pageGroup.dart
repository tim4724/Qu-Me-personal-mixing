import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:provider/provider.dart';
import 'package:qu_me/core/mixingModel.dart';
import 'package:qu_me/entities/send.dart';
import 'package:qu_me/widget/fader.dart';

import 'dialogAssignSends.dart';

class PageGroup extends StatefulWidget {
  final int groupId;
  final String title;

  PageGroup(this.groupId, this.title, {Key key}) : super(key: key);

  @override
  _PageGroupState createState() => _PageGroupState();
}

class _PageGroupState extends State<PageGroup> {
  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(
      builder: (context, orientation) {
        return PlatformScaffold(
          appBar: PlatformAppBar(
            title: Text(widget.title),
            trailingActions: <Widget>[
              PlatformButton(
                padding: EdgeInsets.zero,
                child: Text('Assign'),
                androidFlat: (context) => MaterialFlatButtonData(),
                onPressed: () {
                  showPlatformDialog(
                    context: context,
                    androidBarrierDismissible: true,
                    builder: (BuildContext context) =>
                        DialogAssignSends(widget.groupId),
                  );
                },
              ),
            ],
          ),
          body: SafeArea(
            child: orientation == Orientation.landscape
                ? buildBodyLandscape()
                : buildBodyPortrait(),
          ),
        );
      },
    );
  }

  Widget buildBodyLandscape() {
    return Selector<MixingModel, List<Send>>(selector: (_, model) {
      print("pagegroup selector");
      return model.getSendsForGroup(widget.groupId);
    }, builder: (_, sends, child) {
      print("pagegroup builder");
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
    return Selector<MixingModel, List<Send>>(selector: (_, model) {
      print("pagegroup selector");
      return model.getSendsForGroup(widget.groupId);
    }, builder: (_, sends, child) {
      print("pagegroup builder");
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
    });
  }
}
