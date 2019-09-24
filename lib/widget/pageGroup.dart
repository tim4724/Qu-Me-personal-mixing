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

  PageGroup(this.groupId, {Key key}) : super(key: key);

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
            title: Selector<MixingModel, String>(
                selector: (_, model) => model.getGroup(widget.groupId).name,
                builder: (_, title, __) => Text(title)),
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
            child: buildBody(orientation),
          ),
        );
      },
    );
  }

  Widget buildBody(Orientation orientation) {
    bool landscape = orientation == Orientation.landscape;
    return Selector<MixingModel, List<Send>>(
      selector: (_, model) => model.getSendsForGroup(widget.groupId),
      builder: (_, sends, child) => ListView.builder(
        itemCount: sends.length,
        scrollDirection: landscape ? Axis.horizontal : Axis.vertical,
        itemBuilder: (BuildContext context, int index) {
          final send = sends[index];
          return Padding(
            padding: EdgeInsets.all(2.0),
            child: landscape
                ? VerticalFader(send.id, send.name, send.technicalName,
                    send.personName, send.color, send.stereo)
                : HorizontalFader(send.id, send.name, send.technicalName,
                    send.personName, send.color, send.stereo),
          );
        },
      ),
    );
  }
}
