import 'package:declarative_animated_list/declarative_animated_list.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:provider/provider.dart';
import 'package:qu_me/core/model/mainSendMixModel.dart';
import 'package:qu_me/core/model/sendGroupModel.dart';
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
  final groupModel = SendGroupModel();
  final mainSendModel = MainSendMixModel();
  bool panMode = false;

  @override
  Widget build(BuildContext context) {
    final group = groupModel.getGroup(widget.groupId);

    final textController = TextEditingController.fromValue(
      TextEditingValue(
        text: group.name,
        selection: TextSelection.collapsed(offset: group.name.length),
      ),
    );

    Widget titleWidget;
    if (group.nameUserDefined) {
      titleWidget = Container(
        constraints: BoxConstraints(maxWidth: 120),
        child: PlatformTextField(
          maxLines: 1,
          maxLength: 12,
          android: (context) => MaterialTextFieldData(
            decoration: InputDecoration(
              hintText: "Name",
              counterText: "",
            ),
          ),
          style: TextStyle(color: Color(0xFFFFFFFF)),
          controller: textController,
          onChanged: (name) => groupModel.setGroupName(widget.groupId, name),
        ),
      );
    } else {
      titleWidget = Text(group.name, textAlign: TextAlign.center);
    }

    List<Widget> trailingActions;
    if (group.assignmentUserDefined) {
      trailingActions = [
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
      ];
    }

    return OrientationBuilder(
      builder: (context, orientation) => PlatformScaffold(
        appBar: PlatformAppBar(
          title: titleWidget,
          trailingActions: trailingActions,
        ),
        iosContentPadding: orientation == Orientation.landscape,
        body: buildBody(orientation),
      ),
    );
  }

  Widget buildBody(Orientation orientation) {
    bool landscape = orientation == Orientation.landscape;
    final buildListItem = (_, int sendId, i, Animation<double> anim) {
      return buildFader(anim, sendId, landscape);
    };
    return Selector<SendGroupModel, List<int>>(
      selector: (_, model) {
        // TODO: Lists are, by default, only equal to themselves. Even if other is also a list,
        // the equality comparison does not compare the elements of the two lists.
        return List.from(model.getSendIdsForGroup(widget.groupId));
      },
      builder: (_, sendIds, child) {
        return DeclarativeList(
          items: [-1]..addAll(sendIds),
          scrollDirection: landscape ? Axis.horizontal : Axis.vertical,
          itemBuilder: buildListItem,
          removeBuilder: buildListItem,
          equalityCheck: (a, b) => a == b,
        );
      },
    );
  }

  Widget buildFader(Animation<double> anim, int sendId, bool landscape) {
    if (sendId == -1) {
      return CupertinoSegmentedControl(
        children: {
          false: Text("Level"),
          true: Text("Panorama"),
        },
        groupValue: panMode,
        padding: EdgeInsets.all(8),
        unselectedColor: Color(0xFF000000),
        onValueChanged: (key) {
          setState(() {
            panMode = key;
          });
        },
      );
    }

    final sendNotifier = mainSendModel.getSendNotifierForId(sendId);
    bool showTechnicalName = sendNotifier.value.sendType == SendType.fxReturn;

    return FadeTransition(
      opacity: anim,
      child: SizeTransition(
        sizeFactor: anim,
        axisAlignment: 0.0,
        child: Padding(
          padding: EdgeInsets.all(2.0),
          child: landscape
              ? VerticalFader(sendNotifier, panMode,
                  forceDisplayTechnicalName: showTechnicalName)
              : HorizontalFader(sendNotifier, panMode,
                  forceDisplayTechnicalName: showTechnicalName),
        ),
      ),
    );
  }
}
