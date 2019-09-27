import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:provider/provider.dart';
import 'package:qu_me/core/model/groupModel.dart';
import 'package:qu_me/core/model/mainSendMixModel.dart';
import 'package:qu_me/entities/group.dart';
import 'package:qu_me/entities/send.dart';
import 'package:qu_me/widget/quCheckButton.dart';

import 'quDialog.dart';

class DialogAssignSends extends StatelessWidget {
  final int currentGroupId;
  final groupModel = GroupModel();
  final sendModel = MainSendMixModel();

  DialogAssignSends(this.currentGroupId, {Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final content = Selector<GroupModel, List<int>>(
      selector: (context, model) => model.availableSendIds,
      builder: (context, sendIds, child) {
        return Wrap(
          runSpacing: 2.0,
          spacing: 8.0,
          alignment: WrapAlignment.spaceEvenly,
          children: sendIds.map((sendId) => buildSendChild(sendId)).toList(),
        );
      },
    );
    final doneAction = PlatformButton(
      child: Text("Done"),
      androidFlat: (context) => MaterialFlatButtonData(),
      onPressed: () => Navigator.of(context).pop(),
    );
    return QuDialog(
      title: 'Assign to ${groupModel.getGroup(currentGroupId).technicalName}',
      content: content,
      action: doneAction,
    );
  }

  Widget buildSendChild(int sendId) {
    return Selector<GroupModel, Group>(
      selector: (context, model) => model.getGroupForSend(sendId),
      builder: (context, group, child) {
        final isInCurrentGroup = group != null && group.id == currentGroupId;
        return ValueListenableBuilder<Send>(
          valueListenable: sendModel.getSendNotifierForId(sendId),
          builder: (context, send, child) => Stack(
            children: [
              buildButton(isInCurrentGroup, send),
              buildAvatar(group, isInCurrentGroup),
            ],
          ),
        );
      },
    );
  }

  Widget buildAvatar(Group group, bool isInCurrentGroup) {
    return Positioned(
      right: 0,
      bottom: 0,
      child: IgnorePointer(
        child: AnimatedOpacity(
          child: Container(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(3),
                child: AutoSizeText(
                  group != null ? group.displayId : "",
                  minFontSize: 8,
                  maxFontSize: 20,
                  style: TextStyle(color: Color(0xFFFFFFFF)),
                ),
              ),
            ),
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: isInCurrentGroup
                  ? Colors.green[700].withAlpha(220)
                  : Colors.grey[700].withAlpha(220),
              shape: BoxShape.circle,
            ),
          ),
          duration: Duration(milliseconds: 200),
          opacity: group != null ? 1 : 0,
        ),
      ),
    );
  }

  Widget buildButton(bool isInCurrentGroup, Send send) {
    String secondary = send.sendType != SendType.fxReturn
        ? send.personName
        : send.technicalName;
    return QuCheckButton(
      selected: isInCurrentGroup,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          AutoSizeText(
            send.name,
            maxLines: 1,
            minFontSize: 8,
            maxFontSize: 16,
          ),
          AutoSizeText(
            secondary,
            maxLines: 1,
            minFontSize: 8,
            maxFontSize: 16,
            textScaleFactor: 0.7,
          ),
        ],
      ),
      onSelect: () {
        groupModel.toggleSendAssignement(
            currentGroupId, send.id, send.faderLinked);
      },
      margin: EdgeInsets.only(bottom: 6),
      padding: EdgeInsets.all(4),
      width: 64,
      height: 42,
    );
  }
}
