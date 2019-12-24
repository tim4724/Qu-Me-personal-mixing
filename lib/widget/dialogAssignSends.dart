import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:provider/provider.dart';
import 'package:qu_me/app/localizations.dart';
import 'package:qu_me/core/model/mainSendMixModel.dart';
import 'package:qu_me/core/model/sendGroupModel.dart';
import 'package:qu_me/entities/group.dart';
import 'package:qu_me/entities/send.dart';
import 'package:qu_me/widget/quCheckButton.dart';

import 'quDialog.dart';

class DialogAssignSends extends StatelessWidget {
  final int currentGroupId;

  DialogAssignSends(this.currentGroupId, {Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final content = Selector<SendGroupModel, List<int>>(
      selector: (_, model) {
        // TODO: Lists are, by default, only equal to themselves.
        // Even if other is also a list,
        // the equality comparison does not compare the elements of the two lists.
        return List<int>.from(model.availableSendIds);
      },
      builder: (BuildContext context, List<int> sendIds, _) {
        if (sendIds.isEmpty) {
          final theme = Theme.of(context);
          return Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              QuLocalizations.get(Strings.EmptySends),
              textAlign: TextAlign.center,
              style: theme.textTheme.caption,
              textScaleFactor: 1.2,
            ),
          );
        }
        return Wrap(
          runSpacing: 2.0,
          spacing: 4.0,
          alignment: WrapAlignment.spaceEvenly,
          children: sendIds.map((sendId) => buildSendChild(sendId)).toList(),
        );
      },
    );
    final doneAction = PlatformButton(
      child: Text(QuLocalizations.get(Strings.Done)),
      androidFlat: (context) => MaterialFlatButtonData(),
      onPressed: () => Navigator.of(context).pop(),
    );

    String name = sendGroupModel.getGroupShortNameForId(currentGroupId);
    return QuDialog(
      title: QuLocalizations.get(Strings.AssignSendToGroup, [name]),
      body: content,
      action: doneAction,
    );
  }

  Widget buildSendChild(int sendId) {
    return Selector<SendGroupModel, SendGroup>(
      selector: (context, model) => model.getGroupForSendId(sendId),
      builder: (context, group, child) {
        final isInCurrentGroup = group != null && group.id == currentGroupId;
        return ValueListenableBuilder<Send>(
          valueListenable: mainSendMixModel.getSendNotifierForId(sendId),
          builder: (BuildContext context, Send send, _) => Stack(
            children: [
              buildButton(isInCurrentGroup, send),
              buildAvatar(group, isInCurrentGroup),
            ],
          ),
        );
      },
    );
  }

  Widget buildAvatar(SendGroup group, bool isInCurrentGroup) {
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
                  SendGroupModel.getGroupShortName(group),
                  minFontSize: 8,
                  maxFontSize: 20,
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
    String primary;
    String secondary;
    if (send.sendType != SendType.fxReturn) {
      primary = send.name;
      if (send.personName != null && send.personName.isNotEmpty) {
        secondary = send.personName;
      } else {
        secondary = send.technicalName;
      }
    } else {
      primary = send.technicalName;
      secondary = send.name;
    }

    return QuCheckButton(
      selected: isInCurrentGroup,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          AutoSizeText(
            primary,
            maxLines: 1,
            minFontSize: 8,
            maxFontSize: 16,
          ),
          AutoSizeText(
            secondary,
            maxLines: 1,
            minFontSize: 8,
            maxFontSize: 16,
            textScaleFactor: 0.8,
          ),
        ],
      ),
      onSelect: () {
        sendGroupModel.toggleSendAssignement(currentGroupId, send.id);
      },
      margin: EdgeInsets.only(bottom: 6),
      padding: EdgeInsets.all(4),
      width: 64,
      height: 42,
    );
  }
}
