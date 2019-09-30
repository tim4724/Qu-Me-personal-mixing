import 'package:declarative_animated_list/declarative_animated_list.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:provider/provider.dart';
import 'package:qu_me/core/model/groupModel.dart';
import 'package:qu_me/core/model/mainSendMixModel.dart';
import 'package:qu_me/widget/fader.dart';

import 'dialogAssignSends.dart';

class PageGroup extends StatelessWidget {
  final int groupId;
  final groupModel = GroupModel();
  final mainSendModel = MainSendMixModel();

  PageGroup(this.groupId, {Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final group = groupModel.getGroup(groupId);

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
          onChanged: (name) => groupModel.setGroupName(groupId, name),
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
              builder: (BuildContext context) => DialogAssignSends(groupId),
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
        body: SafeArea(child: buildBody(orientation)),
      ),
    );
  }

  Widget buildBody(Orientation orientation) {
    bool landscape = orientation == Orientation.landscape;
    final buildListItem = (_, int sendId, i, Animation<double> anim) {
      return buildFader(anim, sendId, landscape);
    };
    return Selector<GroupModel, List<int>>(
      selector: (_, model) => List.from(model.getSendIdsForGroup(groupId)),
      builder: (_, sendIds, child) => DeclarativeList(
        items: sendIds,
        scrollDirection: landscape ? Axis.horizontal : Axis.vertical,
        itemBuilder: buildListItem,
        removeBuilder: buildListItem,
        equalityCheck: (a, b) => a == b,
      ),
    );
  }

  Widget buildFader(Animation<double> anim, int sendId, bool landscape) {
    return FadeTransition(
      opacity: anim,
      child: SizeTransition(
        sizeFactor: anim,
        axisAlignment: 0.0,
        child: Padding(
          padding: EdgeInsets.all(2.0),
          child: landscape
              ? VerticalFader(mainSendModel.getSendNotifierForId(sendId))
              : HorizontalFader(mainSendModel.getSendNotifierForId(sendId)),
        ),
      ),
    );
  }
}
